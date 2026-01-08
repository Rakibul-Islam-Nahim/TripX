import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final List<String>? friends;  // NEW FIELD

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.friends,  // NEW PARAMETER
  });

  // ---- Read From Firestore ----
  factory UserModel.fromFirestore(
      DocumentSnapshot<Map<String, Object?>> doc) {
    final data = doc.data()!;

    final createdAtRaw = data['createdAt'];

    DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.parse(createdAtRaw);
    } else {
      createdAt = DateTime.now();
    }

    return UserModel(
      uid: data['uid'] as String,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: createdAt,
      friends: data['friends'] != null
          ? List<String>.from(data['friends'] as List)
          : null,
    );
  }


  // ---- Write To Firestore ----
  Map<String, Object?> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'friends': friends ?? [],  // NEW FIELD
    };
  }
}