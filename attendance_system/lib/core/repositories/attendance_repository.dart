import '../models/attendance_model.dart';
import '../models/student_model.dart';
import '../models/subject_model.dart';

/// Repository for attendance data operations
/// In a real app, this would connect to a database or API
abstract class AttendanceRepository {
  Future<List<AttendanceSession>> getSessionsByTeacher(String teacherId);
  Future<List<AttendanceSession>> getSessionsByClass(String classId);
  Future<List<AttendanceSession>> getSessionsByStudent(String studentId);
  Future<AttendanceSession?> getSessionById(String sessionId);
  Future<AttendanceSession> createSession(AttendanceSession session);
  Future<AttendanceSession> updateSession(AttendanceSession session);
  Future<void> deleteSession(String sessionId);
  Future<List<AttendanceRecord>> getRecordsByStudent(String studentId, String? subjectId);
  Future<Map<String, double>> getAttendancePercentages(String studentId);
  Future<Map<String, double>> getClassAttendancePercentages(String classId);
}

/// In-memory implementation for demo
class InMemoryAttendanceRepository implements AttendanceRepository {
  final List<AttendanceSession> _sessions = [];
  final List<AttendanceRecord> _records = [];

  @override
  Future<List<AttendanceSession>> getSessionsByTeacher(String teacherId) async {
    return _sessions.where((s) => s.teacherId == teacherId).toList();
  }

  @override
  Future<List<AttendanceSession>> getSessionsByClass(String classId) async {
    return _sessions.where((s) => s.classId == classId).toList();
  }

  @override
  Future<List<AttendanceSession>> getSessionsByStudent(String studentId) async {
    return _sessions.where((s) => 
      s.records.any((r) => r.studentId == studentId)
    ).toList();
  }

  @override
  Future<AttendanceSession?> getSessionById(String sessionId) async {
    try {
      return _sessions.firstWhere((s) => s.id == sessionId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<AttendanceSession> createSession(AttendanceSession session) async {
    _sessions.add(session);
    _records.addAll(session.records);
    return session;
  }

  @override
  Future<AttendanceSession> updateSession(AttendanceSession session) async {
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      _sessions[index] = session;
      // Update records
      _records.removeWhere((r) => r.id.startsWith(session.id));
      _records.addAll(session.records);
    }
    return session;
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    _records.removeWhere((r) => r.id.startsWith(sessionId));
  }

  @override
  Future<List<AttendanceRecord>> getRecordsByStudent(String studentId, String? subjectId) async {
    var records = _records.where((r) => r.studentId == studentId);
    if (subjectId != null) {
      records = records.where((r) => r.subjectId == subjectId);
    }
    return records.toList();
  }

  @override
  Future<Map<String, double>> getAttendancePercentages(String studentId) async {
    final records = await getRecordsByStudent(studentId, null);
    final Map<String, List<AttendanceRecord>> bySubject = {};
    
    for (final record in records) {
      bySubject.putIfAbsent(record.subjectId, () => []).add(record);
    }

    final Map<String, double> percentages = {};
    for (final entry in bySubject.entries) {
      final total = entry.value.length;
      final present = entry.value.where((r) => 
        r.status == AttendanceStatus.present || r.status == AttendanceStatus.late
      ).length;
      percentages[entry.key] = total > 0 ? (present / total) * 100 : 0.0;
    }
    return percentages;
  }

  @override
  Future<Map<String, double>> getClassAttendancePercentages(String classId) async {
    final sessions = await getSessionsByClass(classId);
    final Map<String, List<AttendanceRecord>> bySubject = {};
    
    for (final session in sessions) {
      for (final record in session.records) {
        bySubject.putIfAbsent(record.subjectId, () => []).add(record);
      }
    }

    final Map<String, double> percentages = {};
    for (final entry in bySubject.entries) {
      final total = entry.value.length;
      final present = entry.value.where((r) => 
        r.status == AttendanceStatus.present || r.status == AttendanceStatus.late
      ).length;
      percentages[entry.key] = total > 0 ? (present / total) * 100 : 0.0;
    }
    return percentages;
  }
}

