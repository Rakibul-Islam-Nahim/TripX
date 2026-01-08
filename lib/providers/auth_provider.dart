import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  // ===================== SIGN UP =====================
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use only the result of signUpWithEmail, no extra Firestore read
      final userModel = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (userModel != null) {
        _user = userModel;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _mapError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ===================== SIGN IN =====================
  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userModel = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (userModel != null) {
        _user = userModel;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _mapError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ===================== SIGN OUT =====================
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  // ===================== CHECK AUTH ON START =====================
  Future<void> checkAuthState() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      print("✅ User is logged in");
      print("UID: ${currentUser.uid}");
      print("Email: ${currentUser.email}");
      print("Phone: ${currentUser.phoneNumber}");
      print("Provider data:");
      // This uses the typed getUserData from AuthService
      final userModel = await _authService.getUserData(currentUser.uid);
      if (userModel != null) {
        _user = userModel;
        notifyListeners();
      }
    }
  }

  // Future<void> checkAuthState() async {
  //   User? user = FirebaseAuth.instance.currentUser;

  //   print("🔍 Checking Auth State...");
  //   print("User: $user");

  //   if (user != null) {
  //     print("✅ User is logged in");
  //     print("UID: ${user.uid}");
  //     print("Email: ${user.email}");
  //     print("Phone: ${user.phoneNumber}");
  //     print("Provider data:");
  //     for (var provider in user.providerData) {
  //       print(" - Provider ID: ${provider.providerId}");
  //       print(" - UID: ${provider.uid}");
  //       print(" - Email: ${provider.email}");
  //       print(" - Display Name: ${provider.displayName}");
  //     }

  //     isAuthenticated = true;
  //   } else {
  //     print("❌ No authenticated user");
  //     isAuthenticated = false;
  //   }

  //   notifyListeners();
  // }

  // ===================== ERROR MAPPING =====================
  String _mapError(String error) {
    if (error.contains('email-already-in-use')) {
      return 'This email is already registered';
    } else if (error.contains('invalid-email')) {
      return 'Invalid email address';
    } else if (error.contains('weak-password')) {
      return 'Password should be at least 6 characters';
    } else if (error.contains('user-not-found')) {
      return 'No user found with this email';
    } else if (error.contains('wrong-password')) {
      return 'Incorrect password';
    }
    return 'An error occurred. Please try again';
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
