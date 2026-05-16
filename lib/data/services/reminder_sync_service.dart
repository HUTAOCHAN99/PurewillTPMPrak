import 'dart:async';
import 'package:flutter/material.dart';
import 'package:purewill/data/repository/reminder_setting_repository.dart';
import 'package:purewill/data/services/local_notification_service.dart';
import 'package:purewill/domain/model/reminder_setting_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReminderSyncService {
  static final ReminderSyncService _instance = ReminderSyncService._internal();
  factory ReminderSyncService() => _instance;
  ReminderSyncService._internal();

  final LocalNotificationService _notificationService =
      LocalNotificationService();
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  late ReminderSettingRepository _repository;

  StreamSubscription? _reminderSubscription;

  Future<void> initialize() async {
    _repository = ReminderSettingRepository(_supabaseClient);
    await _setupRealtimeSubscription();
    await rescheduleAllReminders();
  }

  // Setup realtime subscription
  Future<void> _setupRealtimeSubscription() async {
    try {
      _reminderSubscription = _supabaseClient
          .from('reminder_settings')
          .stream(primaryKey: ['id'])
          .listen((event) {
            // debugPrint('🔄 Realtime update received for reminders');
            _handleReminderUpdates(event);
          });

      // debugPrint('✅ Realtime subscription for reminders started');
    } catch (e) {
      // debugPrint('❌ Failed to setup realtime subscription: $e');
    }
  }

  void _handleReminderUpdates(List<Map<String, dynamic>> updates) {
    for (final update in updates) {
      final eventType = update['type'] ?? 'UPDATE';
      final record = update['new'] ?? update['old'];

      if (record != null) {
        final reminder = ReminderSettingModel.fromJson(record);

        switch (eventType) {
          case 'INSERT':
            _scheduleReminderNotification(reminder);
            break;
          case 'UPDATE':
            _updateScheduledReminder(reminder);
            break;
          case 'DELETE':
            _cancelReminderNotification(reminder);
            break;
        }
      }
    }
  }

  // Reschedule all reminders from database
  Future<void> rescheduleAllReminders() async {
    try {
      // debugPrint('🔄 Rescheduling all reminders...');

      // Cancel all existing notifications first
      await _notificationService.cancelAllNotifications();

      // Get current user
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) {
        // debugPrint('❌ No user logged in, skipping reminder reschedule');
        return;
      }

      // Get all active habits for current user
      final habitsResponse = await _supabaseClient
          .from('habits')
          .select('id, name')
          .eq('user_id', currentUser.id)
          .eq('is_active', true);

      // debugPrint('📋 Found ${habitsResponse.length} active habits');

      for (final habit in habitsResponse) {
        final habitId = habit['id'] as int;
        final habitName = habit['name'] as String;

        try {
          // Get reminder settings for this habit
          final reminder = await _repository.fetchReminderSettingsByHabit(
            habitId,
          );

          // Check if reminder exists and is enabled
          if (reminder.id.isNotEmpty && reminder.isEnabled) {
            // debugPrint('⏰ Scheduling reminder for: $habitName');
            await _scheduleReminderNotification(reminder, habitName: habitName);
          } else {
            // debugPrint('⏭️ No enabled reminder for: $habitName');
          }
        } catch (e) {
          // debugPrint('⚠️ Error processing reminder for $habitName: $e');
          continue; // Skip this habit and continue with others
        }
      }

      // debugPrint('✅ All reminders rescheduled successfully');
    } catch (e) {
      // debugPrint('❌ Error rescheduling reminders: $e');
    }
  }

  // Schedule notification for reminder
  Future<void> _scheduleReminderNotification(
    ReminderSettingModel reminder, {
    String? habitName,
  }) async {
    try {
      if (!reminder.isEnabled) return;

      // Get habit name if not provided
      String finalHabitName = habitName ?? '';
      if (finalHabitName.isEmpty) {
        try {
          final habitResponse = await _supabaseClient
              .from('habits')
              .select('name')
              .eq('id', reminder.habitId)
              .single();
          finalHabitName = habitResponse['name'] as String;
        } catch (e) {
          finalHabitName = 'Habit ${reminder.habitId}';
        }
      }

      final time = TimeOfDay.fromDateTime(reminder.time);
      final notificationId = _generateNotificationId(reminder);

      // debugPrint('🔔 Scheduling: $finalHabitName at ${time.hour}:${time.minute}');

      await _notificationService.scheduleHabitReminder(
        id: notificationId,
        title: 'Habit Reminder: $finalHabitName',
        body: 'Time to complete your habit!',
        time: time,
        habitId: reminder.habitId.toString(),
        repeatDaily: reminder.repeatDaily,
      );

      // debugPrint('✅ Reminder scheduled successfully');
    } catch (e) {
      // debugPrint('❌ Error scheduling reminder: $e');
    }
  }

  // Update scheduled reminder
  Future<void> _updateScheduledReminder(ReminderSettingModel reminder) async {
    try {
      await _cancelReminderNotification(reminder);

      if (reminder.isEnabled) {
        await _scheduleReminderNotification(reminder);
      }

      // debugPrint('✅ Reminder updated for habit ${reminder.habitId}');
    } catch (e) {
      // debugPrint('❌ Error updating reminder: $e');
    }
  }

  // Cancel reminder notification
  Future<void> _cancelReminderNotification(
    ReminderSettingModel reminder,
  ) async {
    try {
      final notificationId = _generateNotificationId(reminder);
      await _notificationService.cancelNotification(notificationId);
      // debugPrint('✅ Reminder cancelled: $notificationId');
    } catch (e) {
      // debugPrint('❌ Error cancelling reminder: $e');
    }
  }

  // Generate notification ID from reminder
  int _generateNotificationId(ReminderSettingModel reminder) {
    return reminder.id.hashCode & 0x7FFFFFFF; // Positive integer
  }

  // Cleanup
  Future<void> dispose() async {
    await _reminderSubscription?.cancel();
    // debugPrint('🛑 Reminder sync service disposed');
  }
}
