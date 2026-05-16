import 'package:flutter/material.dart';

class HabitModel {
  final int id;
  final String userId;
  final String name;
  final String frequency;
  final DateTime startDate;
  final bool isActive;
  final int? categoryId;
  final String? notes;
  final DateTime? endDate;
  final int? targetValue;
  final String? unit;
  final String status;
  final bool reminderEnabled;
  final TimeOfDay? reminderTime;
  final bool isDefault;

  HabitModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.frequency,
    required this.startDate,
    this.isActive = true,
    this.categoryId,
    this.notes,
    this.endDate,
    this.targetValue,
    this.unit,
    this.status = 'neutral',
    this.reminderEnabled = false,
    this.reminderTime,
    this.isDefault = false,
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseReminderTime(dynamic time) {
      if (time is String) {
        final parts = time.split(':');
        if (parts.length == 2) {
          return TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      }
      return null;
    }

    return HabitModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      frequency: json['frecuency_type'] ?? 'daily',
      startDate: DateTime.parse(json['start_date']),
      isActive: json['is_active'] ?? true,
      categoryId: json['category_id'],
      notes: json['notes'],
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      targetValue: json['target_value'],
      unit: json['unit'], // TAMBAHAN
      status: json['status'] ?? 'neutral',
      reminderEnabled: json['reminder_enabled'] ?? false,
      reminderTime: parseReminderTime(json['reminder_time']),
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'user_id': userId,
      'name': name,
      'frecuency_type': frequency,
      'start_date': startDate.toIso8601String(),
      'is_active': isActive,
      'status': status,
      'reminder_enabled': reminderEnabled,
      'is_default': isDefault,
    };

    if (reminderTime != null) {
      json['reminder_time'] =
          '${reminderTime!.hour.toString().padLeft(2, '0')}:${reminderTime!.minute.toString().padLeft(2, '0')}';
    }

    if (categoryId != null) {
      json['category_id'] = categoryId!;
    }
    if (notes != null) {
      json['notes'] = notes!;
    }
    if (endDate != null) {
      json['end_date'] = endDate!.toIso8601String();
    }
    if (targetValue != null) {
      json['target_value'] = targetValue!;
    }
    if (unit != null) {
      json['unit'] = unit!; // TAMBAHAN
    }

    return json;
  }

  @override
  String toString() {
    return 'HabitModel{id: $id, name: $name, targetValue: $targetValue, unit: $unit, isDefault: $isDefault}';
  }
}
