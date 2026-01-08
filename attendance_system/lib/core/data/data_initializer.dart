import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../models/subject_model.dart';
import '../models/class_model.dart';
import '../models/schedule_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../repositories/student_repository.dart';
import '../repositories/teacher_repository.dart';
import '../repositories/subject_repository.dart';
import '../repositories/class_repository.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/post_repository.dart';
import 'package:flutter/material.dart';

/// Initialize app with default demo data
class DataInitializer {
  static Future<void> initialize({
    required StudentRepository studentRepo,
    required TeacherRepository teacherRepo,
    required SubjectRepository subjectRepo,
    required ClassRepository classRepo,
    required ScheduleRepository scheduleRepo,
    required PostRepository postRepo,
  }) async {
    // Create subjects
    final subjects = [
      Subject(id: 'subj-1', name: 'Mathematics', code: 'MATH101', department: 'Science', credits: 4, isLab: false),
      Subject(id: 'subj-2', name: 'Physics', code: 'PHY101', department: 'Science', credits: 4, isLab: false),
      Subject(id: 'subj-3', name: 'Chemistry', code: 'CHEM101', department: 'Science', credits: 4, isLab: false),
      Subject(id: 'subj-4', name: 'Computer Science', code: 'CS101', department: 'Computer Science', credits: 3, isLab: false),
      Subject(id: 'subj-5', name: 'English', code: 'ENG101', department: 'Languages', credits: 3, isLab: false),
    ];

    for (final subject in subjects) {
      await subjectRepo.createSubject(subject);
    }

    // Create classes
    final classes = [
      Class(id: 'class-10a', name: '10-A', department: 'Science', academicYear: '2024-25', totalStudents: 30),
      Class(id: 'class-10b', name: '10-B', department: 'Science', academicYear: '2024-25', totalStudents: 28),
      Class(id: 'class-11a', name: '11-A', department: 'Science', academicYear: '2024-25', totalStudents: 32),
      Class(id: 'class-cs2024', name: 'CS-2024', department: 'Computer Science', academicYear: '2024-25', totalStudents: 25),
    ];

    for (final classModel in classes) {
      await classRepo.createClass(classModel);
    }

    // Create teachers
    final teachers = [
      Teacher(
        id: 'teacher-1',
        name: 'Prof. Smith',
        email: 'teacher@school.com',
        department: 'Computer Science Dept.',
        subjectIds: ['subj-4'],
        classIds: ['class-cs2024'],
        joinDate: DateTime(2020, 1, 1),
      ),
      Teacher(
        id: 'teacher-2',
        name: 'Dr. Sarah Mitchell',
        email: 'sarah@school.com',
        department: 'Computer Science & Engineering',
        subjectIds: ['subj-4', 'subj-1'],
        classIds: ['class-10a', 'class-11a'],
        joinDate: DateTime(2019, 6, 1),
      ),
    ];

    for (final teacher in teachers) {
      await teacherRepo.createTeacher(teacher);
    }

    // Create students
    final students = [
      Student(
        id: 'student-1',
        name: 'John Doe',
        email: 'student@school.com',
        rollNumber: '10A001',
        classId: 'class-10a',
        enrollmentDate: DateTime(2024, 4, 1),
        subjectAttendance: {
          'subj-1': 92.5,
          'subj-2': 88.3,
          'subj-3': 91.8,
          'subj-4': 95.2,
          'subj-5': 89.5,
        },
      ),
      Student(
        id: 'student-2',
        name: 'Jane Smith',
        email: 'jane@school.com',
        rollNumber: '10A002',
        classId: 'class-10a',
        enrollmentDate: DateTime(2024, 4, 1),
        subjectAttendance: {
          'subj-1': 88.0,
          'subj-2': 91.5,
          'subj-3': 87.2,
          'subj-4': 93.8,
          'subj-5': 90.0,
        },
      ),
    ];

    for (final student in students) {
      await studentRepo.createStudent(student);
    }

    // Create schedule
    final schedules = [
      ScheduleSlot(
        id: 'schedule-1',
        subjectId: 'subj-4',
        classId: 'class-10a',
        teacherId: 'teacher-1',
        dayOfWeek: 1, // Monday
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 30),
        room: 'Lab-101',
      ),
      ScheduleSlot(
        id: 'schedule-2',
        subjectId: 'subj-1',
        classId: 'class-10a',
        teacherId: 'teacher-2',
        dayOfWeek: 1, // Monday
        startTime: const TimeOfDay(hour: 11, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        room: 'Room-201',
      ),
    ];

    for (final schedule in schedules) {
      await scheduleRepo.createSlot(schedule);
    }

    // Create posts
    final posts = [
      Post(
        id: 'post-1',
        title: 'Welcome to New Academic Year',
        content: 'We are excited to welcome all students and teachers to the new academic year 2024-25.',
        authorId: 'principal-1',
        authorRole: UserRole.principal,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        targetRoles: ['student', 'teacher'],
      ),
      Post(
        id: 'post-2',
        title: 'Attendance Policy Update',
        content: 'Please note that attendance below 75% will require parent meeting.',
        authorId: 'principal-1',
        authorRole: UserRole.principal,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        targetRoles: ['student', 'teacher'],
      ),
    ];

    for (final post in posts) {
      await postRepo.createPost(post);
    }
  }
}

