import '../models/class_model.dart';

abstract class ClassRepository {
  Future<List<Class>> getAllClasses();
  Future<Class?> getClassById(String id);
  Future<List<Class>> getClassesByDepartment(String department);
  Future<Class> createClass(Class classModel);
  Future<Class> updateClass(Class classModel);
  Future<void> deleteClass(String id);
}

class InMemoryClassRepository implements ClassRepository {
  final Map<String, Class> _classes = {};

  @override
  Future<List<Class>> getAllClasses() async {
    return _classes.values.toList();
  }

  @override
  Future<Class?> getClassById(String id) async {
    return _classes[id];
  }

  @override
  Future<List<Class>> getClassesByDepartment(String department) async {
    return _classes.values.where((c) => c.department == department).toList();
  }

  @override
  Future<Class> createClass(Class classModel) async {
    _classes[classModel.id] = classModel;
    return classModel;
  }

  @override
  Future<Class> updateClass(Class classModel) async {
    _classes[classModel.id] = classModel;
    return classModel;
  }

  @override
  Future<void> deleteClass(String id) async {
    _classes.remove(id);
  }
}

