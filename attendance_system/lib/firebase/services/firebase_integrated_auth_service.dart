/// Integrated Firebase Authentication Service
/// 
/// Combines Firebase Auth with Firestore user profile management
/// This is the main service to use for authentication in the app
/// 
/// Handles:
/// - Signup (creates Auth user + Firestore profile)
/// - Login (authenticates + loads profile)
/// - Logout
/// - Current user session

import 'package:flutter/foundation.dart';
import '../../core/models/user_model.dart';
import 'firebase_auth_service.dart';
import 'firestore_user_service.dart';

class FirebaseIntegratedAuthService {
  final FirebaseAuthService _authService;
  final FirestoreUserService _userService;

  FirebaseIntegratedAuthService({
    required FirebaseAuthService authService,
    required FirestoreUserService userService,
  })  : _authService = authService,
        _userService = userService;

  /// Sign up new user
  /// 
  /// Creates:
  /// 1. Firebase Auth user
  /// 2. Firestore user profile
  /// 
  /// Returns User model
  Future<User> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? academicUnitId, // classId for students, department for teachers
  }) async {
    try {
      // Step 1: Create Firebase Auth user
      final credential = await _authService.signUp(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create Firebase Auth user');
      }

      // Step 2: Create Firestore user profile
      await _userService.createUserProfile(
        userId: firebaseUser.uid,
        name: name,
        email: email,
        role: role,
        academicUnitId: academicUnitId,
      );

      // Step 3: Return User model
      final user = await _userService.getUserById(firebaseUser.uid);
      if (user == null) {
        throw Exception('Failed to retrieve user profile');
      }

      debugPrint('User signed up successfully: ${user.id}');
      return user;
    } catch (e) {
      debugPrint('Sign up error: $e');
      // If Firestore creation fails, delete Auth user
      try {
        await _authService.currentFirebaseUser?.delete();
      } catch (_) {
        // Ignore cleanup errors
      }
      rethrow;
    }
  }

  /// Sign in existing user
  /// 
  /// Authenticates and loads user profile
  /// Returns User model
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: Authenticate with Firebase Auth
      final credential = await _authService.signIn(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to sign in');
      }

      // Step 2: Load user profile from Firestore
      final user = await _userService.getUserById(firebaseUser.uid);
      if (user == null) {
        throw Exception('User profile not found');
      }

      debugPrint('User signed in successfully: ${user.id}');
      return user;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _authService.signOut();
  }

  /// Get current user
  /// 
  /// Returns User model if authenticated, null otherwise
  Future<User?> getCurrentUser() async {
    final firebaseUserId = _authService.currentUserId;
    if (firebaseUserId == null) {
      return null;
    }

    return await _userService.getUserById(firebaseUserId);
  }

  /// Stream current user (real-time updates)
  Stream<User?> streamCurrentUser() {
    return _authService.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return await _userService.getUserById(firebaseUser.uid);
    });
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _authService.isAuthenticated;

  /// Get current user ID
  String? get currentUserId => _authService.currentUserId;

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  /// Update user password
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _authService.updatePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}

