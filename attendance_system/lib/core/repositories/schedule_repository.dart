import '../models/schedule_model.dart';
import 'package:flutter/material.dart';

abstract class ScheduleRepository {
  Future<List<ScheduleSlot>> getScheduleByClass(String classId);
  Future<List<ScheduleSlot>> getScheduleByTeacher(String teacherId);
  Future<List<ScheduleSlot>> getScheduleByStudent(String studentId, String classId);
  Future<List<ScheduleSlot>> getTodaySchedule(String classId);
  Future<ScheduleSlot> createSlot(ScheduleSlot slot);
  Future<ScheduleSlot> updateSlot(ScheduleSlot slot);
  Future<void> deleteSlot(String id);
}

class InMemoryScheduleRepository implements ScheduleRepository {
  final Map<String, ScheduleSlot> _slots = {};

  @override
  Future<List<ScheduleSlot>> getScheduleByClass(String classId) async {
    return _slots.values.where((s) => s.classId == classId).toList()
      ..sort((a, b) {
        if (a.dayOfWeek != b.dayOfWeek) {
          return a.dayOfWeek.compareTo(b.dayOfWeek);
        }
        return a.startTime.hour.compareTo(b.startTime.hour);
      });
  }

  @override
  Future<List<ScheduleSlot>> getScheduleByTeacher(String teacherId) async {
    return _slots.values.where((s) => s.teacherId == teacherId).toList()
      ..sort((a, b) {
        if (a.dayOfWeek != b.dayOfWeek) {
          return a.dayOfWeek.compareTo(b.dayOfWeek);
        }
        return a.startTime.hour.compareTo(b.startTime.hour);
      });
  }

  @override
  Future<List<ScheduleSlot>> getScheduleByStudent(String studentId, String classId) async {
    return getScheduleByClass(classId);
  }

  @override
  Future<List<ScheduleSlot>> getTodaySchedule(String classId) async {
    final today = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
    final allSlots = await getScheduleByClass(classId);
    return allSlots.where((s) => s.dayOfWeek == today).toList()
      ..sort((a, b) => a.startTime.hour.compareTo(b.startTime.hour));
  }

  @override
  Future<ScheduleSlot> createSlot(ScheduleSlot slot) async {
    _slots[slot.id] = slot;
    return slot;
  }

  @override
  Future<ScheduleSlot> updateSlot(ScheduleSlot slot) async {
    _slots[slot.id] = slot;
    return slot;
  }

  @override
  Future<void> deleteSlot(String id) async {
    _slots.remove(id);
  }
}

