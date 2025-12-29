/// Firebase Authentication Service
/// 
/// Handles:
/// - Email/Password signup
/// - Email/Password login
/// - Logout
/// - Current user session
/// 
/// Uses ONLY Firebase FREE tier (Email/Password auth)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/models/user_model.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current Firebase user
  User? get currentFirebaseUser => _auth.currentUser;

  /// Get current user stream (for listening to auth state changes)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  /// 
  /// Returns Firebase User on success
  /// Throws FirebaseAuthException on failure
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      
      debugPrint('User signed up: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign up error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Sign in with email and password
  /// 
  /// Returns Firebase User on success
  /// Throws FirebaseAuthException on failure
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Support both email and username (email prefix)
      String emailToUse = email.trim().toLowerCase();
      
      // If it doesn't contain @, try to find email by username
      if (!emailToUse.contains('@')) {
        // This is a username, we'll need to look it up
        // For now, assume it's a complete email or handle in calling code
        // In production, you might want to maintain a username->email mapping
      }
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );
      
      debugPrint('User signed in: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign in error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('User signed out');
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  /// Send password reset email
  /// 
  /// FREE tier feature
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      debugPrint('Password reset email sent');
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Update user password
  /// 
  /// Requires re-authentication for security
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
      debugPrint('Password updated');
    } on FirebaseAuthException catch (e) {
      debugPrint('Password update error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Delete current user account
  /// 
  /// Requires re-authentication
  Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete account
      await user.delete();
      debugPrint('Account deleted');
    } on FirebaseAuthException catch (e) {
      debugPrint('Account deletion error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get current user email
  String? get currentUserEmail => _auth.currentUser?.email;
}

