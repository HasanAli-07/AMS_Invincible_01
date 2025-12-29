import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import '../services/analytics_service.dart';
import '../repositories/user_repository.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/student_repository.dart';
import '../repositories/teacher_repository.dart';
import '../repositories/class_repository.dart';
import '../repositories/subject_repository.dart';
import '../repositories/post_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/schedule_repository.dart';

/// Global application state management
class AppState extends ChangeNotifier {
  // Repositories
  late final UserRepository userRepo;
  late final AttendanceRepository attendanceRepo;
  late final StudentRepository studentRepo;
  late final TeacherRepository teacherRepo;
  late final ClassRepository classRepo;
  late final SubjectRepository subjectRepo;
  late final PostRepository postRepo;
  late final NotificationRepository notificationRepo;
  late final ScheduleRepository scheduleRepo;

  // Services
  late final AuthService authService;
  late final AttendanceService attendanceService;
  late final AnalyticsService analyticsService;

  // Current state
  User? _currentUser;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _currentUser != null;

  AppState() {
    _initializeRepositories();
    _initializeServices();
  }

  void _initializeRepositories() {
    userRepo = InMemoryUserRepository();
    attendanceRepo = InMemoryAttendanceRepository();
    studentRepo = InMemoryStudentRepository();
    teacherRepo = InMemoryTeacherRepository();
    classRepo = InMemoryClassRepository();
    subjectRepo = InMemorySubjectRepository();
    postRepo = InMemoryPostRepository();
    notificationRepo = InMemoryNotificationRepository();
    scheduleRepo = InMemoryScheduleRepository();
  }

  void _initializeServices() {
    authService = AuthService(userRepo: userRepo);
    attendanceService = AttendanceService(
      attendanceRepo: attendanceRepo,
      studentRepo: studentRepo,
    );
    analyticsService = AnalyticsService(
      attendanceRepo: attendanceRepo,
      studentRepo: studentRepo,
      teacherRepo: teacherRepo,
      classRepo: classRepo,
    );
  }

  /// Initialize app with default data
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await (userRepo as InMemoryUserRepository).initializeWithDefaults();
    await _seedDefaultData();
    
    _isInitialized = true;
    notifyListeners();
  }

  /// Seed default data for demo
  Future<void> _seedDefaultData() async {
    // This would be called once to populate initial data
    // Implementation would add sample students, teachers, subjects, etc.
  }

  /// Login user
  Future<User?> login(String username, String password) async {
    final user = await authService.authenticate(username, password);
    if (user != null) {
      _currentUser = user;
      notifyListeners();
    }
    return user;
  }

  /// Logout user
  void logout() {
    authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  /// Check if user has permission
  bool hasPermission(UserRole role) {
    return authService.hasPermission(role);
  }
}

