import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/friend_request_model.dart';

class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search users by name or email
  Future<List<UserModel>> searchUsers(String query, String currentUserId) async {
    if (query.isEmpty) return [];

    try {
      final queryLower = query.toLowerCase();

      // Search by email
      QuerySnapshot<Map<String, dynamic>> emailSnapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: queryLower)
          .where('email', isLessThan: '${queryLower}z')
          .limit(10)
          .get();

      // Search by display name
      QuerySnapshot<Map<String, dynamic>> nameSnapshot = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: '${query}z')
          .limit(10)
          .get();

      Set<UserModel> users = {};

      for (var doc in emailSnapshot.docs) {
        if (doc.id != currentUserId) {
          users.add(UserModel.fromFirestore(doc));
        }
      }

      for (var doc in nameSnapshot.docs) {
        if (doc.id != currentUserId) {
          users.add(UserModel.fromFirestore(doc));
        }
      }

      return users.toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Send friend request
  Future<bool> sendFriendRequest(UserModel sender, UserModel receiver) async {
    try {
      // Check if request already exists
      final existingRequest = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: sender.uid)
          .where('receiverId', isEqualTo: receiver.uid)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        print('Friend request already sent');
        return false;
      }

      // Check reverse request
      final reverseRequest = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: receiver.uid)
          .where('receiverId', isEqualTo: sender.uid)
          .get();

      if (reverseRequest.docs.isNotEmpty) {
        print('User already sent you a request');
        return false;
      }

      final friendRequest = FriendRequestModel(
        id: '',
        senderId: sender.uid,
        senderName: sender.displayName ?? sender.email,
        senderEmail: sender.email,
        senderPhotoUrl: sender.photoUrl,
        receiverId: receiver.uid,
        receiverName: receiver.displayName ?? receiver.email,
        receiverEmail: receiver.email,
        receiverPhotoUrl: receiver.photoUrl,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('friendRequests').add(friendRequest.toFirestore());
      return true;
    } catch (e) {
      print('Error sending friend request: $e');
      return false;
    }
  }

  // Get received friend requests
  Stream<List<FriendRequestModel>> getReceivedRequests(String userId) {
    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FriendRequestModel.fromFirestore(doc))
        .toList());
  }

  // Get sent friend requests
  Stream<List<FriendRequestModel>> getSentRequests(String userId) {
    return _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FriendRequestModel.fromFirestore(doc))
        .toList());
  }

  // Accept friend request
  Future<bool> acceptFriendRequest(String requestId, String senderId, String receiverId) async {
    try {
      print('🔄 Accepting friend request...');
      print('  Request ID: $requestId');
      print('  Sender ID: $senderId');
      print('  Receiver ID: $receiverId');

      // Update request status
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': 'accepted',
        'respondedAt': Timestamp.now(),
      });
      print('✅ Request status updated');

      // Add sender to receiver's friends list
      await _firestore.collection('users').doc(receiverId).update({
        'friends': FieldValue.arrayUnion([senderId])
      });
      print('✅ Sender added to receiver\'s friends list');

      // Add receiver to sender's friends list
      await _firestore.collection('users').doc(senderId).update({
        'friends': FieldValue.arrayUnion([receiverId])
      });
      print('✅ Receiver added to sender\'s friends list');

      print('🎉 Friend request accepted successfully!');
      return true;
    } catch (e) {
      print('❌ Error accepting friend request: $e');
      return false;
    }
  }

  // Reject friend request
  Future<bool> rejectFriendRequest(String requestId) async {
    try {
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': 'rejected',
        'respondedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error rejecting friend request: $e');
      return false;
    }
  }

  // Get friends list
  Stream<List<UserModel>> getFriends(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((doc) async {
      final data = doc.data();
      final friendIds = List<String>.from(data?['friends'] ?? []);

      if (friendIds.isEmpty) return <UserModel>[];

      final friendDocs = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: friendIds)
          .get();

      return friendDocs.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    });
  }

  // Check if users are friends
  Future<bool> areFriends(String userId1, String userId2) async {
    try {
      final doc = await _firestore.collection('users').doc(userId1).get();
      final friends = List<String>.from(doc.data()?['friends'] ?? []);
      return friends.contains(userId2);
    } catch (e) {
      return false;
    }
  }

  // Check friend request status
  Future<String?> checkFriendRequestStatus(String senderId, String receiverId) async {
    try {
      // Check if current user sent request
      final sentRequest = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (sentRequest.docs.isNotEmpty) return 'sent';

      // Check if current user received request
      final receivedRequest = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: receiverId)
          .where('receiverId', isEqualTo: senderId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (receivedRequest.docs.isNotEmpty) return 'received';

      return null;
    } catch (e) {
      return null;
    }
  }
}