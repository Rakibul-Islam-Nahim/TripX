import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ===================== SIGN UP =====================
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      print('🔄 Starting signup for: $email');

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
          print('✅ Display name updated');
        }

        final userModel = UserModel(
          uid: user.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
          friends: [], // ADDED: Initialize empty friends list
        );

        print('🔄 Creating Firestore document...');
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toFirestore());
        print('✅ Firestore document created');

        return userModel;
      }
    } catch (e, stack) {
      print("🔥 SIGNUP ERROR: $e");
      print("🔥 STACK: $stack");
      rethrow;
    }

    return null;
  }

  // ===================== SIGN IN =====================
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        final snap = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (snap.exists) {
          final typed = snap as DocumentSnapshot<Map<String, Object?>>;
          return UserModel.fromFirestore(typed);
        }
      }
    } catch (e) {
      print("LOGIN ERROR: $e");
      rethrow;
    }
    return null;
  }

  // ===================== GET USER DATA =====================
  Future<UserModel?> getUserData(String uid) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (snap.exists) {
        final typed = snap as DocumentSnapshot<Map<String, Object?>>;
        return UserModel.fromFirestore(typed);
      }
    } catch (e) {
      print("FETCH USER ERROR: $e");
    }
    return null;
  }

  // ===================== SIGN OUT =====================
  Future<void> signOut() async {
    await _auth.signOut();
  }
}