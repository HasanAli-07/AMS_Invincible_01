import '../models/student_model.dart';

abstract class StudentRepository {
  Future<List<Student>> getAllStudents();
  Future<Student?> getStudentById(String id);
  Future<List<Student>> getStudentsByClass(String classId);
  Future<Student> createStudent(Student student);
  Future<Student> updateStudent(Student student);
  Future<void> deleteStudent(String id);
  Future<List<Student>> importStudentsFromCSV(String csvData);
}

class InMemoryStudentRepository implements StudentRepository {
  final Map<String, Student> _students = {};

  @override
  Future<List<Student>> getAllStudents() async {
    return _students.values.toList();
  }

  @override
  Future<Student?> getStudentById(String id) async {
    return _students[id];
  }

  @override
  Future<List<Student>> getStudentsByClass(String classId) async {
    return _students.values.where((s) => s.classId == classId).toList();
  }

  @override
  Future<Student> createStudent(Student student) async {
    _students[student.id] = student;
    return student;
  }

  @override
  Future<Student> updateStudent(Student student) async {
    _students[student.id] = student;
    return student;
  }

  @override
  Future<void> deleteStudent(String id) async {
    _students.remove(id);
  }

  @override
  Future<List<Student>> importStudentsFromCSV(String csvData) async {
    // Simple CSV parser - in production, use a proper CSV library
    final lines = csvData.split('\n');
    final List<Student> students = [];
    
    for (int i = 1; i < lines.length; i++) { // Skip header
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      final parts = line.split(',');
      if (parts.length >= 4) {
        final student = Student(
          id: 'student-${DateTime.now().millisecondsSinceEpoch + i}',
          name: parts[0].trim(),
          email: parts[1].trim(),
          rollNumber: parts[2].trim(),
          classId: parts[3].trim(),
          enrollmentDate: DateTime.now(),
        );
        students.add(student);
        await createStudent(student);
      }
    }
    return students;
  }
}

