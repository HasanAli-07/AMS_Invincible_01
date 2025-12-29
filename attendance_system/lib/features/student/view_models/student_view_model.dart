import 'package:flutter/foundation.dart';
import '../../../core/models/student_model.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/models/schedule_model.dart';
import '../../../core/models/post_model.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/state/app_state.dart';
import '../../../core/models/user_model.dart';

/// ViewModel for Student Dashboard
class StudentViewModel extends ChangeNotifier {
  final AppState appState;
  final String studentId;

  StudentViewModel({
    required this.appState,
    required this.studentId,
  }) {
    _loadData();
  }

  // Data
  Student? _student;
  Map<String, double> _attendancePercentages = {};
  List<AttendanceRecord> _recentRecords = [];
  List<ScheduleSlot> _schedule = [];
  List<Post> _posts = [];
  List<Notification> _notifications = [];
  
  bool _isLoading = false;
  String? _error;

  // Getters
  Student? get student => _student;
  Map<String, double> get attendancePercentages => _attendancePercentages;
  List<AttendanceRecord> get recentRecords => _recentRecords;
  List<ScheduleSlot> get schedule => _schedule;
  List<Post> get posts => _posts;
  List<Notification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get overallAttendance {
    if (_attendancePercentages.isEmpty) return 0.0;
    final total = _attendancePercentages.values.reduce((a, b) => a + b);
    return total / _attendancePercentages.length;
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _student = await appState.studentRepo.getStudentById(studentId);
      
      if (_student != null) {
        _attendancePercentages = await appState.attendanceRepo.getAttendancePercentages(studentId);
        _recentRecords = await appState.attendanceRepo.getRecordsByStudent(studentId, null);
        _recentRecords.sort((a, b) => b.date.compareTo(a.date));
        _recentRecords = _recentRecords.take(10).toList();
        
        if (_student!.classId != null) {
          _schedule = await appState.scheduleRepo.getScheduleByStudent(
            studentId,
            _student!.classId!,
          );
        }
      }
      
      _posts = await appState.postRepo.getPostsByRole(UserRole.student);
      _notifications = await appState.notificationRepo.getNotificationsByUser(
        studentId,
        UserRole.student,
      );
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get today's schedule
  Future<List<ScheduleSlot>> getTodaySchedule() async {
    if (_student?.classId == null) return [];
    return await appState.scheduleRepo.getTodaySchedule(_student!.classId!);
  }

  // Get attendance by subject
  Future<List<AttendanceRecord>> getAttendanceBySubject(String subjectId) async {
    return await appState.attendanceRepo.getRecordsByStudent(studentId, subjectId);
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

