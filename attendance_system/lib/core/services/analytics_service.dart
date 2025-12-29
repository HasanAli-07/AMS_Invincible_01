import '../models/attendance_model.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/student_repository.dart';
import '../repositories/teacher_repository.dart';
import '../repositories/class_repository.dart';

/// Service for analytics and reporting
class AnalyticsService {
  final AttendanceRepository attendanceRepo;
  final StudentRepository studentRepo;
  final TeacherRepository teacherRepo;
  final ClassRepository classRepo;

  AnalyticsService({
    required this.attendanceRepo,
    required this.studentRepo,
    required this.teacherRepo,
    required this.classRepo,
  });

  /// Get 7-day attendance trend
  Future<List<double>> getWeeklyTrend(String? classId) async {
    final now = DateTime.now();
    final List<double> trend = [];
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final sessions = classId != null
          ? await attendanceRepo.getSessionsByClass(classId)
          : await attendanceRepo.getSessionsByTeacher('all');
      
      final daySessions = sessions.where((s) => 
        s.date.year == date.year &&
        s.date.month == date.month &&
        s.date.day == date.day
      ).toList();
      
      if (daySessions.isEmpty) {
        trend.add(0.0);
        continue;
      }
      
      int totalRecords = 0;
      int presentRecords = 0;
      
      for (final session in daySessions) {
        for (final record in session.records) {
          totalRecords++;
          if (record.status == AttendanceStatus.present || 
              record.status == AttendanceStatus.late) {
            presentRecords++;
          }
        }
      }
      
      final percentage = totalRecords > 0 
          ? (presentRecords / totalRecords) * 100 
          : 0.0;
      trend.add(percentage);
    }
    
    return trend;
  }

  /// Get class-wise performance
  Future<Map<String, double>> getClassWisePerformance() async {
    final classes = await classRepo.getAllClasses();
    final Map<String, double> performance = {};
    
    for (final classModel in classes) {
      final stats = await attendanceRepo.getClassAttendancePercentages(classModel.id);
      final overall = stats.values.isEmpty 
          ? 0.0 
          : stats.values.reduce((a, b) => a + b) / stats.length;
      performance[classModel.name] = overall;
    }
    
    return performance;
  }

  /// Get teacher consistency (submission rate)
  Future<Map<String, double>> getTeacherConsistency() async {
    final teachers = await teacherRepo.getAllTeachers();
    final Map<String, double> consistency = {};
    
    for (final teacher in teachers) {
      final sessions = await attendanceRepo.getSessionsByTeacher(teacher.id);
      final total = sessions.length;
      final confirmed = sessions.where((s) => s.isConfirmed).length;
      
      consistency[teacher.name] = total > 0 ? (confirmed / total) * 100 : 0.0;
    }
    
    return consistency;
  }

  /// Get institution overview statistics
  Future<Map<String, dynamic>> getInstitutionOverview() async {
    final students = await studentRepo.getAllStudents();
    final teachers = await teacherRepo.getAllTeachers();
    final classes = await classRepo.getAllClasses();
    
    // Calculate overall attendance
    double totalAttendance = 0.0;
    int count = 0;
    
    for (final student in students) {
      if (student.subjectAttendance.isNotEmpty) {
        totalAttendance += student.overallAttendance;
        count++;
      }
    }
    
    final overallAttendance = count > 0 ? totalAttendance / count : 0.0;
    
    return {
      'totalStudents': students.length,
      'totalTeachers': teachers.length,
      'totalClasses': classes.length,
      'overallAttendance': overallAttendance,
    };
  }
}

