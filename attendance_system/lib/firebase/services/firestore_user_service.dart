/// Firestore User Service
/// 
/// Handles user profile CRUD operations in Firestore
/// 
/// Collection: users
/// Document ID: Firebase Auth UID
/// 
/// Structure:
/// {
///   name: string
///   email: string
///   role: 'student' | 'teacher' | 'principal' | 'admin'
///   academicUnitId: string? (classId for students, department for teachers)
///   createdAt: Timestamp
///   updatedAt: Timestamp
/// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/models/user_model.dart';

class FirestoreUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  /// Create user profile in Firestore
  /// 
  /// Called after Firebase Auth signup
  /// Document ID must match Firebase Auth UID
  Future<void> createUserProfile({
    required String userId, // Firebase Auth UID
    required String name,
    required String email,
    required UserRole role,
    String? academicUnitId, // classId for students, department for teachers
  }) async {
    try {
      final userData = {
        'name': name,
        'email': email.toLowerCase(),
        'role': role.toString().split('.').last, // 'student', 'teacher', etc.
        'academicUnitId': academicUnitId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(_collection)
          .doc(userId)
          .set(userData, SetOptions(merge: false));

      debugPrint('User profile created: $userId');
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  /// Get user profile by ID
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      return _documentToUser(doc);
    } catch (e) {
      debugPrint('Error getting user: $e');
      rethrow;
    }
  }

  /// Get user by email
  Future<User?> getUserByEmail(String email) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      return _documentToUser(query.docs.first);
    } catch (e) {
      debugPrint('Error getting user by email: $e');
      rethrow;
    }
  }

  /// Get users by role
  Future<List<User>> getUsersByRole(UserRole role) async {
    try {
      final roleString = role.toString().split('.').last;
      final query = await _firestore
          .collection(_collection)
          .where('role', isEqualTo: roleString)
          .get();

      return query.docs.map((doc) => _documentToUser(doc)).toList();
    } catch (e) {
      debugPrint('Error getting users by role: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    UserRole? role,
    String? academicUnitId,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email.toLowerCase();
      if (role != null) {
        updates['role'] = role.toString().split('.').last;
      }
      if (academicUnitId != null) {
        updates['academicUnitId'] = academicUnitId;
      }

      await _firestore.collection(_collection).doc(userId).update(updates);

      debugPrint('User profile updated: $userId');
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Delete user profile
  Future<void> deleteUserProfile(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).delete();
      debugPrint('User profile deleted: $userId');
    } catch (e) {
      debugPrint('Error deleting user profile: $e');
      rethrow;
    }
  }

  /// Stream user profile (real-time updates)
  Stream<User?> streamUser(String userId) {
    return _firestore
        .collection(_collection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? _documentToUser(doc) : null);
  }

  /// Convert Firestore document to User model
  User _documentToUser(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse role
    UserRole role;
    final roleString = data['role'] as String? ?? 'student';
    switch (roleString) {
      case 'admin':
        role = UserRole.admin;
        break;
      case 'principal':
        role = UserRole.principal;
        break;
      case 'teacher':
        role = UserRole.teacher;
        break;
      case 'student':
        role = UserRole.student;
        break;
      default:
        role = UserRole.student;
    }

    // Parse timestamps
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return User(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: role,
      department: role == UserRole.teacher || role == UserRole.principal
          ? data['academicUnitId'] as String?
          : null,
      classId: role == UserRole.student ? data['academicUnitId'] as String? : null,
      createdAt: createdAt,
    );
  }
}

