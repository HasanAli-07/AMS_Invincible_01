import 'package:flutter/foundation.dart';
import '../../../core/models/student_model.dart';
import '../../../core/models/teacher_model.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/models/class_model.dart';
import '../../../core/models/post_model.dart';
import '../../../core/state/app_state.dart';

/// ViewModel for Principal Dashboard
class PrincipalViewModel extends ChangeNotifier {
  final AppState appState;

  PrincipalViewModel({required this.appState}) {
    _loadData();
  }

  // Data
  List<Student> _students = [];
  List<Teacher> _teachers = [];
  List<Subject> _subjects = [];
  List<Class> _classes = [];
  List<Post> _posts = [];
  
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Student> get students => _students;
  List<Teacher> get teachers => _teachers;
  List<Subject> get subjects => _subjects;
  List<Class> get classes => _classes;
  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _students = await appState.studentRepo.getAllStudents();
      _teachers = await appState.teacherRepo.getAllTeachers();
      _subjects = await appState.subjectRepo.getAllSubjects();
      _classes = await appState.classRepo.getAllClasses();
      _posts = await appState.postRepo.getAllPosts();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Institution Overview
  Map<String, dynamic> getInstitutionOverview() {
    final totalStudents = _students.length;
    final totalTeachers = _teachers.length;
    final totalClasses = _classes.length;
    
    double totalAttendance = 0.0;
    int count = 0;
    for (final student in _students) {
      if (student.subjectAttendance.isNotEmpty) {
        totalAttendance += student.overallAttendance;
        count++;
      }
    }
    final overallAttendance = count > 0 ? totalAttendance / count : 0.0;

    return {
      'totalStudents': totalStudents,
      'totalTeachers': totalTeachers,
      'totalClasses': totalClasses,
      'overallAttendance': overallAttendance,
    };
  }

  // Student Management
  Future<void> uploadStudentsCSV(String csvData) async {
    try {
      final newStudents = await appState.studentRepo.importStudentsFromCSV(csvData);
      _students.addAll(newStudents);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Teacher Management
  Future<void> createTeacher(Teacher teacher) async {
    try {
      await appState.teacherRepo.createTeacher(teacher);
      _teachers.add(teacher);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTeacher(Teacher teacher) async {
    try {
      await appState.teacherRepo.updateTeacher(teacher);
      final index = _teachers.indexWhere((t) => t.id == teacher.id);
      if (index != -1) {
        _teachers[index] = teacher;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTeacher(String teacherId) async {
    try {
      await appState.teacherRepo.deleteTeacher(teacherId);
      _teachers.removeWhere((t) => t.id == teacherId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Subject Management
  Future<void> createSubject(Subject subject) async {
    try {
      await appState.subjectRepo.createSubject(subject);
      _subjects.add(subject);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Class Management
  Future<void> createClass(Class classModel) async {
    try {
      await appState.classRepo.createClass(classModel);
      _classes.add(classModel);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Post Management
  Future<void> createPost(Post post) async {
    try {
      await appState.postRepo.createPost(post);
      _posts.insert(0, post);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await appState.postRepo.deletePost(postId);
      _posts.removeWhere((p) => p.id == postId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await _loadData();
  }
}

