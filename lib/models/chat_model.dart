import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final Map<String, dynamic> participantDetails;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastSenderId;
  final Map<String, int> unreadCount;

  ChatModel({
    required this.id,
    required this.participants,
    required this.participantDetails,
    this.lastMessage,
    this.lastMessageTime,
    this.lastSenderId,
    required this.unreadCount,
  });

  // ---- Read From Firestore ----
  factory ChatModel.fromFirestore(
      DocumentSnapshot<Map<String, Object?>> doc) {
    final data = doc.data()!;

    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] as List? ?? []),
      participantDetails: Map<String, dynamic>.from(
          data['participantDetails'] as Map? ?? {}),
      lastMessage: data['lastMessage'] as String?,
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      lastSenderId: data['lastSenderId'] as String?,
      unreadCount: Map<String, int>.from(data['unreadCount'] as Map? ?? {}),
    );
  }

  // ---- Write To Firestore ----
  Map<String, Object?> toFirestore() {
    return {
      'participants': participants,
      'participantDetails': participantDetails,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'lastSenderId': lastSenderId,
      'unreadCount': unreadCount,
    };
  }
}