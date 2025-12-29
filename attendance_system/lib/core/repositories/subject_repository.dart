import '../models/subject_model.dart';

abstract class SubjectRepository {
  Future<List<Subject>> getAllSubjects();
  Future<Subject?> getSubjectById(String id);
  Future<List<Subject>> getSubjectsByDepartment(String department);
  Future<Subject> createSubject(Subject subject);
  Future<Subject> updateSubject(Subject subject);
  Future<void> deleteSubject(String id);
}

class InMemorySubjectRepository implements SubjectRepository {
  final Map<String, Subject> _subjects = {};

  @override
  Future<List<Subject>> getAllSubjects() async {
    return _subjects.values.toList();
  }

  @override
  Future<Subject?> getSubjectById(String id) async {
    return _subjects[id];
  }

  @override
  Future<List<Subject>> getSubjectsByDepartment(String department) async {
    return _subjects.values.where((s) => s.department == department).toList();
  }

  @override
  Future<Subject> createSubject(Subject subject) async {
    _subjects[subject.id] = subject;
    return subject;
  }

  @override
  Future<Subject> updateSubject(Subject subject) async {
    _subjects[subject.id] = subject;
    return subject;
  }

  @override
  Future<void> deleteSubject(String id) async {
    _subjects.remove(id);
  }
}

