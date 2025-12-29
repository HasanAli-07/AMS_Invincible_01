import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';

/// Repository for user data operations
abstract class UserRepository {
  Future<User?> getUserById(String id);
  Future<User?> getUserByEmail(String email);
  Future<List<User>> getUsersByRole(UserRole role);
  Future<User> createUser(User user);
  Future<User> updateUser(User user);
  Future<void> deleteUser(String id);
}

/// In-memory implementation
class InMemoryUserRepository implements UserRepository {
  final Map<String, User> _users = {};

  @override
  Future<User?> getUserById(String id) async {
    return _users[id];
  }

  @override
  Future<User?> getUserByEmail(String email) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();
      return _users.values.firstWhere(
        (u) => u.email.toLowerCase() == normalizedEmail,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get user by email or username (for login flexibility)
  Future<User?> getUserByIdentifier(String identifier) async {
    final normalized = identifier.toLowerCase().trim();
    
    // Try email first
    final userByEmail = await getUserByEmail(normalized);
    if (userByEmail != null) return userByEmail;
    
    // Try username (email without @domain)
    try {
      return _users.values.firstWhere(
        (u) => u.email.toLowerCase().split('@')[0] == normalized,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<User>> getUsersByRole(UserRole role) async {
    return _users.values.where((u) => u.role == role).toList();
  }

  @override
  Future<User> createUser(User user) async {
    _users[user.id] = user;
    return user;
  }

  @override
  Future<User> updateUser(User user) async {
    _users[user.id] = user;
    return user;
  }

  @override
  Future<void> deleteUser(String id) async {
    _users.remove(id);
  }

  // Helper methods
  Future<void> initializeWithDefaults() async {
    // Create default users for testing
    final now = DateTime.now();
    
    await createUser(User(
      id: 'admin-1',
      name: 'Admin User',
      email: 'admin@school.com',
      role: UserRole.admin,
      createdAt: now,
    ));

    await createUser(User(
      id: 'principal-1',
      name: 'Dr. Meera Singh',
      email: 'principal@school.com',
      role: UserRole.principal,
      department: 'Principal',
      createdAt: now,
    ));

    await createUser(User(
      id: 'teacher-1',
      name: 'Prof. Smith',
      email: 'teacher@school.com',
      role: UserRole.teacher,
      department: 'Computer Science Dept.',
      createdAt: now,
    ));

    await createUser(User(
      id: 'student-1',
      name: 'John Doe',
      email: 'student@school.com',
      role: UserRole.student,
      classId: 'class-10a',
      createdAt: now,
    ));
  }
}

