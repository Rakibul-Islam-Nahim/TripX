import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus {
  pending,
  accepted,
  rejected,
}

class FriendRequestModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String? senderPhotoUrl;
  final String receiverId;
  final String receiverName;
  final String receiverEmail;
  final String? receiverPhotoUrl;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    this.senderPhotoUrl,
    required this.receiverId,
    required this.receiverName,
    required this.receiverEmail,
    this.receiverPhotoUrl,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  // ---- Read From Firestore ----
  factory FriendRequestModel.fromFirestore(
      DocumentSnapshot<Map<String, Object?>> doc) {
    final data = doc.data()!;

    return FriendRequestModel(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderEmail: data['senderEmail'] as String? ?? '',
      senderPhotoUrl: data['senderPhotoUrl'] as String?,
      receiverId: data['receiverId'] as String? ?? '',
      receiverName: data['receiverName'] as String? ?? '',
      receiverEmail: data['receiverEmail'] as String? ?? '',
      receiverPhotoUrl: data['receiverPhotoUrl'] as String?,
      status: FriendRequestStatus.values.firstWhere(
            (e) => e.toString() == 'FriendRequestStatus.${data['status']}',
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // ---- Write To Firestore ----
  Map<String, Object?> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'senderPhotoUrl': senderPhotoUrl,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverEmail': receiverEmail,
      'receiverPhotoUrl': receiverPhotoUrl,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }
}