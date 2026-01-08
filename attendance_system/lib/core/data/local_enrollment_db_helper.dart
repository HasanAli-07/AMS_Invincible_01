import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/student_model.dart';

class LocalEnrollmentDbHelper {
  static final LocalEnrollmentDbHelper instance = LocalEnrollmentDbHelper._init();
  static Database? _database;

  LocalEnrollmentDbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('enrollment_temp.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pending_students (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        enrollment_no TEXT NOT NULL,
        semester TEXT NOT NULL,
        department TEXT NOT NULL,
        batch TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertPendingStudent(Map<String, dynamic> studentData) async {
    final db = await database;
    return await db.insert('pending_students', studentData,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPendingStudents() async {
    final db = await database;
    return await db.query('pending_students');
  }

  Future<int> clearPendingStudents() async {
    final db = await database;
    return await db.delete('pending_students');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
