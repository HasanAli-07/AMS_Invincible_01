import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../../firebase/services/firestore_teacher_service.dart';

/// Service for authentication and authorization
class AuthService {
  final UserRepository userRepo;
  final FirestoreTeacherService? _teacherService;
  User? _currentUser;

  AuthService({
    required this.userRepo,
    FirestoreTeacherService? teacherService,
  }) : _teacherService = teacherService;

  FirestoreTeacherService get teacherService => _teacherService ?? FirestoreTeacherService();

  User? get currentUser => _currentUser;

  /// Authenticate user with email/username and password
  Future<User?> authenticate(String username, String password) async {
    // In a real app, this would verify password hash
    // For now, we use simple credential matching
    
    // Try to get user by email or username
    // Support both email (principal@school.com) and username (principal)
    final normalized = username.toLowerCase().trim();
    
    // First try as email from in-memory repository (for default users)
    User? user = await userRepo.getUserByEmail(normalized);
    
    // If not found, try as username (email prefix) from in-memory repository
    if (user == null) {
      try {
        final allUsers = <User>[];
        allUsers.addAll(await userRepo.getUsersByRole(UserRole.admin));
        allUsers.addAll(await userRepo.getUsersByRole(UserRole.principal));
        allUsers.addAll(await userRepo.getUsersByRole(UserRole.teacher));
        allUsers.addAll(await userRepo.getUsersByRole(UserRole.student));
        
        user = allUsers.firstWhere(
          (u) => u.email.toLowerCase().split('@')[0] == normalized,
        );
      } catch (e) {
        // User not found in in-memory repository
      }
    }
    
    // If user found in in-memory repository, check password
    if (user != null) {
      final expectedPassword = _getPasswordForUser(user.email);
      if (password == expectedPassword) {
        _currentUser = user;
        return user;
      }
      return null; // Password mismatch
    }
    
    // If not found in in-memory repository, try Firestore for teachers
    try {
      final allTeachers = await teacherService.getAllTeachers();
      final teacher = allTeachers.firstWhere(
        (t) {
          final teacherEmail = (t['email'] as String?)?.toLowerCase() ?? '';
          return teacherEmail == normalized || 
                 teacherEmail.split('@')[0] == normalized;
        },
        orElse: () => {},
      );
      
      if (teacher.isNotEmpty) {
        // Get password from Firestore
        final teacherPassword = teacher['password'] as String? ?? '123456';
        
        if (password == teacherPassword) {
          // Convert teacher to User model
          user = User(
            id: teacher['id'] as String,
            name: teacher['name'] as String? ?? '',
            email: teacher['email'] as String? ?? '',
            role: UserRole.teacher,
            department: teacher['department'] as String?,
            createdAt: (teacher['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
          _currentUser = user;
          return user;
        }
      }
    } catch (e) {
      debugPrint('Error fetching teacher from Firestore: $e');
      // Continue to return null
    }
    
    return null;
  }

  /// Get password for user (for in-memory default users)
  String _getPasswordForUser(String email) {
    if (email.contains('admin')) return 'admin123';
    if (email.contains('principal')) return 'principal123';
    if (email.contains('teacher')) return 'teacher123';
    if (email.contains('student')) return 'student123';
    return 'password123'; // Default
  }

  /// Logout current user
  void logout() {
    _currentUser = null;
  }

  /// Check if user has permission for an action
  bool hasPermission(UserRole requiredRole) {
    if (_currentUser == null) return false;
    
    // Admin has all permissions
    if (_currentUser!.role == UserRole.admin) return true;
    
    // Principal has most permissions
    if (requiredRole == UserRole.principal && 
        _currentUser!.role == UserRole.principal) return true;
    
    // Role must match exactly for teacher and student
    return _currentUser!.role == requiredRole;
  }

  /// Check if user can access a resource
  bool canAccessResource(String resourceId, UserRole? resourceOwnerRole) {
    if (_currentUser == null) return false;
    
    // Admin can access everything
    if (_currentUser!.role == UserRole.admin) return true;
    
    // Principal can access most resources
    if (_currentUser!.role == UserRole.principal) {
      return resourceOwnerRole != UserRole.admin;
    }
    
    // Teachers can access their own resources
    if (_currentUser!.role == UserRole.teacher) {
      return resourceOwnerRole == UserRole.teacher;
    }
    
    // Students can only access their own resources
    if (_currentUser!.role == UserRole.student) {
      return resourceOwnerRole == UserRole.student && 
             _currentUser!.id == resourceId;
    }
    
    return false;
  }
}

