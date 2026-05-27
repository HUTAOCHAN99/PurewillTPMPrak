// lib/domain/model/reminder_setting_model.dart
import 'package:flutter/material.dart';

class ReminderSettingModel {
  final String id;
  final int habitId;
  final bool isEnabled;
  final TimeOfDay time;
  final int snoozeDuration;
  final bool repeatDaily;
  final bool isSoundEnabled;
  final bool isVibrationEnabled;
  final DateTime createdAt;

  ReminderSettingModel({
    required this.id,
    required this.habitId,
    required this.isEnabled,
    required this.time,
    required this.snoozeDuration,
    required this.repeatDaily,
    required this.isSoundEnabled,
    required this.isVibrationEnabled,
    required this.createdAt,
  });

  factory ReminderSettingModel.fromJson(Map<String, dynamic> json) {
    // Parse time dari format "HH:MM:SS" atau "HH:MM"
    TimeOfDay parsedTime;
    if (json['time'] is String) {
      final timeStr = json['time'] as String;
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        parsedTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } else {
        parsedTime = TimeOfDay.now();
      }
    } else {
      parsedTime = TimeOfDay.now();
    }

    return ReminderSettingModel(
      id: json['id']?.toString() ?? '',
      habitId: json['habit_id'] as int? ?? 0,
      isEnabled: json['is_enabled'] as bool? ?? false,
      time: parsedTime,
      snoozeDuration: json['snooze_duration'] as int? ?? 10,
      repeatDaily: json['repeat_daily'] as bool? ?? true,
      isSoundEnabled: json['is_sound_enabled'] as bool? ?? true,
      isVibrationEnabled: json['is_vibration_enabled'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    // Format waktu untuk database: "HH:MM:SS"
    final timeString = '${time.hour.toString().padLeft(2, '0')}:'
                       '${time.minute.toString().padLeft(2, '0')}:00';
    
    final json = <String, dynamic>{
      'habit_id': habitId,
      'is_enabled': isEnabled,
      'time': timeString,
      'snooze_duration': snoozeDuration,
      'repeat_daily': repeatDaily,
      'is_sound_enabled': isSoundEnabled,
      'is_vibration_enabled': isVibrationEnabled,
      'created_at': createdAt.toIso8601String(),
    };

    if (id.isNotEmpty) {
      final intId = int.tryParse(id);
      if (intId != null) {
        json['id'] = intId;
      }
    }

    debugPrint('🎯 REMINDER TO JSON:');
    debugPrint('   - TimeOfDay: ${time.hour}:${time.minute}');
    debugPrint('   - Formatted for DB: $timeString');

    return json;
  }

  // Create empty/default instance
  factory ReminderSettingModel.empty({required int habitId}) {
    return ReminderSettingModel(
      id: '',
      habitId: habitId,
      isEnabled: false,
      time: TimeOfDay.now(),
      snoozeDuration: 10,
      repeatDaily: true,
      isSoundEnabled: true,
      isVibrationEnabled: false,
      createdAt: DateTime.now(),
    );
  }

  ReminderSettingModel copyWith({
    String? id,
    int? habitId,
    bool? isEnabled,
    TimeOfDay? time,
    int? snoozeDuration,
    bool? repeatDaily,
    bool? isSoundEnabled,
    bool? isVibrationEnabled,
    DateTime? createdAt,
  }) {
    return ReminderSettingModel(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      isEnabled: isEnabled ?? this.isEnabled,
      time: time ?? this.time,
      snoozeDuration: snoozeDuration ?? this.snoozeDuration,
      repeatDaily: repeatDaily ?? this.repeatDaily,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      isVibrationEnabled: isVibrationEnabled ?? this.isVibrationEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ReminderSettingModel{id: $id, habitId: $habitId, isEnabled: $isEnabled, time: ${time.hour}:${time.minute}, snoozeDuration: $snoozeDuration, repeatDaily: $repeatDaily}';
  }

  // Helper methods
  bool get isEmpty => id.isEmpty;
  
  bool get isPastForToday {
    final now = TimeOfDay.now();
    if (time.hour < now.hour) return true;
    if (time.hour == now.hour && time.minute <= now.minute) return true;
    return false;
  }

  String get formattedTime {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
  
  String get timeString {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}