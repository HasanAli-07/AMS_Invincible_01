import 'package:flutter/material.dart';

class ScheduleSlot {
  final String id;
  final String subjectId;
  final String classId;
  final String teacherId;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? room;
  final String? building;

  const ScheduleSlot({
    required this.id,
    required this.subjectId,
    required this.classId,
    required this.teacherId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    this.building,
  });

  ScheduleSlot copyWith({
    String? id,
    String? subjectId,
    String? classId,
    String? teacherId,
    int? dayOfWeek,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? room,
    String? building,
  }) {
    return ScheduleSlot(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      teacherId: teacherId ?? this.teacherId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      building: building ?? this.building,
    );
  }
}

