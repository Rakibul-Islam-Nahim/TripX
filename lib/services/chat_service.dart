import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get or create chat between two users
  Future<String> getOrCreateChat(String userId1, String userId2,
      Map<String, dynamic> user1Details, Map<String, dynamic> user2Details) async {
    try {
      print('🔍 Looking for existing chat between $userId1 and $userId2');

      // Check if chat already exists
      final existingChat = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId1)
          .get();

      for (var doc in existingChat.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(userId2)) {
          print('✅ Found existing chat: ${doc.id}');
          return doc.id;
        }
      }

      print('🆕 Creating new chat...');
      // Create new chat
      final chatData = {
        'participants': [userId1, userId2],
        'participantDetails': {
          userId1: user1Details,
          userId2: user2Details,
        },
        'unreadCount': {
          userId1: 0,
          userId2: 0,
        },
        'createdAt': Timestamp.now(),
      };

      final chatDoc = await _firestore.collection('chats').add(chatData);
      print('✅ Chat created: ${chatDoc.id}');
      return chatDoc.id;
    } catch (e) {
      print('❌ Error getting/creating chat: $e');
      rethrow;
    }
  }

  // Send message
  Future<bool> sendMessage(String chatId, String senderId, String senderName,
      String receiverId, String content) async {
    try {
      print('📤 Sending message in chat: $chatId');

      final message = MessageModel(
        id: '',
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
      );

      await _firestore.collection('messages').add(message.toFirestore());
      print('✅ Message saved to Firestore');

      // Update chat with last message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': content,
        'lastMessageTime': Timestamp.now(),
        'lastSenderId': senderId,
        'unreadCount.$receiverId': FieldValue.increment(1),
      });
      print('✅ Chat updated with last message');

      return true;
    } catch (e) {
      print('❌ Error sending message: $e');
      return false;
    }
  }

  // Get messages stream - FIXED VERSION
  Stream<List<MessageModel>> getMessages(String chatId) {
    print('📥 Listening for messages in chat: $chatId');

    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      print('📨 Received ${snapshot.docs.length} messages from Firestore');

      if (snapshot.docs.isEmpty) {
        print('⚠️ No messages found for chatId: $chatId');
      }

      return snapshot.docs.map((doc) {
        try {
          print('📄 Processing message: ${doc.id}');
          final data = doc.data();
          print('   Data: $data');

          // Cast to the correct type
          final typedDoc = doc;

          return MessageModel.fromFirestore(typedDoc);
        } catch (e) {
          print('❌ Error parsing message ${doc.id}: $e');
          rethrow;
        }
      }).toList();
    });
  }

  // Get user chats - FIXED VERSION
  Stream<List<ChatModel>> getUserChats(String userId) {
    print('📥 Listening for chats for user: $userId');

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      print('💬 Received ${snapshot.docs.length} chats from Firestore');

      return snapshot.docs.map((doc) {
        try {
          // Cast to the correct type
          final typedDoc = doc;
          return ChatModel.fromFirestore(typedDoc);
        } catch (e) {
          print('❌ Error parsing chat ${doc.id}: $e');
          rethrow;
        }
      }).toList();
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      print('📖 Marking messages as read for user: $userId in chat: $chatId');

      final unreadMessages = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      print('📖 Found ${unreadMessages.docs.length} unread messages');

      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      // Reset unread count
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': 0,
      });

      print('✅ Messages marked as read');
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }
}