import 'package:flutter/foundation.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/models/class_model.dart';
import '../../../core/models/student_model.dart';
import '../../../core/models/schedule_model.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/state/app_state.dart';
import '../../../core/models/user_model.dart';

/// ViewModel for Teacher Dashboard
class TeacherViewModel extends ChangeNotifier {
  final AppState appState;
  final String teacherId;

  TeacherViewModel({
    required this.appState,
    required this.teacherId,
  }) {
    _loadData();
  }

  // Data
  List<Subject> _subjects = [];
  List<Class> _classes = [];
  List<AttendanceSession> _sessions = [];
  List<ScheduleSlot> _schedule = [];
  List<Notification> _notifications = [];
  AttendanceSession? _currentSession;
  
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Subject> get subjects => _subjects;
  List<Class> get classes => _classes;
  List<AttendanceSession> get sessions => _sessions;
  List<ScheduleSlot> get schedule => _schedule;
  List<Notification> get notifications => _notifications;
  AttendanceSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final teacher = await appState.teacherRepo.getTeacherById(teacherId);
      if (teacher != null) {
        _subjects = [];
        for (final subjectId in teacher.subjectIds) {
          final subject = await appState.subjectRepo.getSubjectById(subjectId);
          if (subject != null) _subjects.add(subject);
        }
        
        _classes = [];
        for (final classId in teacher.classIds) {
          final classModel = await appState.classRepo.getClassById(classId);
          if (classModel != null) _classes.add(classModel);
        }
      }
      
      _sessions = await appState.attendanceRepo.getSessionsByTeacher(teacherId);
      _schedule = await appState.scheduleRepo.getScheduleByTeacher(teacherId);
      _notifications = await appState.notificationRepo.getNotificationsByUser(
        teacherId,
        UserRole.teacher,
      );
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create attendance session
  Future<AttendanceSession> createAttendanceSession({
    required String subjectId,
    required String classId,
    required DateTime date,
  }) async {
    try {
      final students = await appState.studentRepo.getStudentsByClass(classId);
      final studentIds = students.map((s) => s.id).toList();
      
      final session = await appState.attendanceService.createAttendanceSession(
        subjectId: subjectId,
        classId: classId,
        teacherId: teacherId,
        date: date,
        studentIds: studentIds,
      );
      
      _currentSession = session;
      _sessions.insert(0, session);
      notifyListeners();
      
      return session;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update attendance record
  Future<void> updateAttendanceStatus({
    required String sessionId,
    required String studentId,
    required AttendanceStatus status,
  }) async {
    try {
      final updated = await appState.attendanceService.updateRecordStatus(
        sessionId: sessionId,
        studentId: studentId,
        status: status,
      );
      
      _currentSession = updated;
      final index = _sessions.indexWhere((s) => s.id == sessionId);
      if (index != -1) {
        _sessions[index] = updated;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Confirm attendance session
  Future<void> confirmSession(String sessionId) async {
    try {
      final confirmed = await appState.attendanceService.confirmSession(sessionId);
      final index = _sessions.indexWhere((s) => s.id == sessionId);
      if (index != -1) {
        _sessions[index] = confirmed;
      }
      _currentSession = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Get today's schedule
  Future<List<ScheduleSlot>> getTodaySchedule() async {
    final today = DateTime.now().weekday;
    return _schedule.where((s) => s.dayOfWeek == today).toList()
      ..sort((a, b) => a.startTime.hour.compareTo(b.startTime.hour));
  }

  // Mark notification as read
  Future<void> markNotificationRead(String notificationId) async {
    try {
      await appState.notificationRepo.markAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await _loadData();
  }
}

