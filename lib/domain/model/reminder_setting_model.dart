import 'package:flutter/material.dart';

class ReminderSettingModel {
  final String id;
  final int habitId;
  final bool isEnabled;
  final DateTime time;
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
    // debugPrint('🎯 REMINDER SETTING FROM JSON:');
    // debugPrint('   - Raw time from DB: ${json['time']}');

    // Parse the timestamp as-is
    DateTime parsedTime;
    try {
      if (json['time'] is String) {
        parsedTime = DateTime.parse(json['time'] as String);
        // debugPrint('   ✅ Parsed time as-is: $parsedTime');
      } else {
        parsedTime = DateTime.now();
        // debugPrint('   ⚠️  Time is not string, using current time');
      }
    } catch (e) {
      // debugPrint('❌ Error parsing time: $e');
      parsedTime = DateTime.now();
    }

    // debugPrint('   - Final time: $parsedTime');
    // debugPrint('   - Hour: ${parsedTime.hour}, Minute: ${parsedTime.minute}');

    return ReminderSettingModel(
      id: json['id']?.toString() ?? '',
      habitId: json['habit_id'] as int? ?? 0,
      isEnabled: json['is_enabled'] as bool? ?? false,
      time: parsedTime,
      snoozeDuration: json['snooze_duration'] as int? ?? 10,
      repeatDaily: json['repeat_daily'] as bool? ?? true,
      isSoundEnabled: json['is_sound_enabled'] as bool? ?? true,
      isVibrationEnabled: json['is_vibration_enabled'] as bool? ?? false,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'habit_id': habitId,
      'is_enabled': isEnabled,
      'time': time.toIso8601String(),
      'snooze_duration': snoozeDuration,
      'repeat_daily': repeatDaily,
      'is_sound_enabled': isSoundEnabled,
      'is_vibration_enabled': isVibrationEnabled,
    };

    // Only add id if not empty (for update)
    if (id.isNotEmpty) {
      json['id'] = int.tryParse(id) as Object;
    }

    // debugPrint('🎯 REMINDER SETTING TO JSON:');
    // debugPrint('   - Exact time to store: ${time.toIso8601String()}');
    // debugPrint('   - Hour: ${time.hour}, Minute: ${time.minute}');

    return json;
  }

  // Create empty/default instance
  factory ReminderSettingModel.empty({required int habitId}) {
    final now = DateTime.now();
    return ReminderSettingModel(
      id: '',
      habitId: habitId,
      isEnabled: false,
      time: now,
      snoozeDuration: 10,
      repeatDaily: true,
      isSoundEnabled: true,
      isVibrationEnabled: false,
      createdAt: now,
    );
  }

  ReminderSettingModel copyWith({
    String? id,
    int? habitId,
    bool? isEnabled,
    DateTime? time,
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
    return 'ReminderSettingModel{id: $id, habitId: $habitId, isEnabled: $isEnabled, time: $time, snoozeDuration: $snoozeDuration, repeatDaily: $repeatDaily, isSoundEnabled: $isSoundEnabled, isVibrationEnabled: $isVibrationEnabled, createdAt: $createdAt}';
  }

  // Helper methods
  bool get isEmpty => id.isEmpty;
  TimeOfDay get timeOfDay => TimeOfDay.fromDateTime(time);

  String get formattedTime {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  bool get isPastForToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderToday = DateTime(
      today.year,
      today.month,
      today.day,
      time.hour,
      time.minute,
    );
    return reminderToday.isBefore(now);
  }

  DateTime get nextScheduledTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var scheduled = DateTime(
      today.year,
      today.month,
      today.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  String get dynamicTimeDisplay {
    final nextTime = nextScheduledTime;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (nextTime.year == today.year &&
        nextTime.month == today.month &&
        nextTime.day == today.day) {
      return 'Today at $formattedTime';
    } else if (nextTime.year == tomorrow.year &&
        nextTime.month == tomorrow.month &&
        nextTime.day == tomorrow.day) {
      return 'Tomorrow at $formattedTime';
    } else {
      return '${nextTime.day}/${nextTime.month} at $formattedTime';
    }
  }
}