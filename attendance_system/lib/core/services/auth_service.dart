import '../models/user_model.dart';
import '../repositories/user_repository.dart';

/// Service for authentication and authorization
class AuthService {
  final UserRepository userRepo;
  User? _currentUser;

  AuthService({required this.userRepo});

  User? get currentUser => _currentUser;

  /// Authenticate user with email/username and password
  Future<User?> authenticate(String username, String password) async {
    // In a real app, this would verify password hash
    // For now, we use simple credential matching
    
    // Try to get user by email or username
    // Support both email (principal@school.com) and username (principal)
    final normalized = username.toLowerCase().trim();
    
    // First try as email
    User? user = await userRepo.getUserByEmail(normalized);
    
    // If not found, try as username (email prefix)
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
        // User not found
      }
    }
    
    if (user != null) {
      // Simple password check - in production, use hashing
      final expectedPassword = _getPasswordForUser(user.email);
      if (password == expectedPassword) {
        _currentUser = user;
        return user;
      }
    }
    
    return null;
  }

  /// Get password for user (dummy implementation)
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

