import '../models/teacher_model.dart';

abstract class TeacherRepository {
  Future<List<Teacher>> getAllTeachers();
  Future<Teacher?> getTeacherById(String id);
  Future<List<Teacher>> getTeachersByDepartment(String department);
  Future<Teacher> createTeacher(Teacher teacher);
  Future<Teacher> updateTeacher(Teacher teacher);
  Future<void> deleteTeacher(String id);
}

class InMemoryTeacherRepository implements TeacherRepository {
  final Map<String, Teacher> _teachers = {};

  @override
  Future<List<Teacher>> getAllTeachers() async {
    return _teachers.values.toList();
  }

  @override
  Future<Teacher?> getTeacherById(String id) async {
    return _teachers[id];
  }

  @override
  Future<List<Teacher>> getTeachersByDepartment(String department) async {
    return _teachers.values.where((t) => t.department == department).toList();
  }

  @override
  Future<Teacher> createTeacher(Teacher teacher) async {
    _teachers[teacher.id] = teacher;
    return teacher;
  }

  @override
  Future<Teacher> updateTeacher(Teacher teacher) async {
    _teachers[teacher.id] = teacher;
    return teacher;
  }

  @override
  Future<void> deleteTeacher(String id) async {
    _teachers.remove(id);
  }
}

