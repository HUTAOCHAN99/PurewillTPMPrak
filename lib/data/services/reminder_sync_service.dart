// lib/data/services/reminder_sync_service.dart
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

  RealtimeChannel? _reminderChannel;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _repository = ReminderSettingRepository(_supabaseClient);
    await _setupRealtimeSubscription();
    await rescheduleAllReminders();
    _isInitialized = true;
  }

  Future<void> _setupRealtimeSubscription() async {
    try {
      _reminderChannel = _supabaseClient
          .channel('reminder_settings_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'reminder_settings',
            callback: (payload) {
              debugPrint('🔄 Realtime update received for reminders');
              _handleReminderUpdate(payload);
            },
          )
          .subscribe();

      debugPrint('✅ Realtime subscription for reminders started');
    } catch (e) {
      debugPrint('❌ Failed to setup realtime subscription: $e');
    }
  }

  void _handleReminderUpdate(PostgresChangePayload payload) {
    try {
      final eventType = payload.eventType;
      final record = payload.newRecord;
      
      if (record.isNotEmpty) {
        final reminder = ReminderSettingModel.fromJson(record);

        switch (eventType) {
          case PostgresChangeEvent.insert:
            debugPrint('📝 New reminder inserted for habit ${reminder.habitId}');
            _scheduleReminderNotification(reminder);
            break;
          case PostgresChangeEvent.update:
            debugPrint('✏️ Reminder updated for habit ${reminder.habitId}');
            _updateScheduledReminder(reminder);
            break;
          case PostgresChangeEvent.delete:
            debugPrint('🗑️ Reminder deleted for habit ${reminder.habitId}');
            _cancelReminderNotification(reminder);
            break;
          case PostgresChangeEvent.all:
            debugPrint('📢 All event type received');
            break;
        }
      }
    } catch (e) {
      debugPrint('❌ Error handling reminder update: $e');
    }
  }

  Future<void> rescheduleAllReminders() async {
    try {
      debugPrint('🔄 ========== RESCHEDULING ALL REMINDERS ==========');

      // Cancel all notifications first
      await _notificationService.cancelAllNotifications();
      debugPrint('   ✅ Cancelled all existing notifications');

      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No user logged in, skipping reminder reschedule');
        return;
      }

      debugPrint('   👤 User ID: ${currentUser.id}');

      // Get all active habits with reminders
      final habitsResponse = await _supabaseClient
          .from('habits')
          .select('id, name, reminder_enabled, reminder_time')
          .eq('user_id', currentUser.id)
          .eq('is_active', true);

      debugPrint('📋 Found ${habitsResponse.length} active habits');

      int scheduledCount = 0;
      int enabledReminderCount = 0;

      for (final habit in habitsResponse) {
        final habitId = habit['id'] as int;
        final habitName = habit['name'] as String;
        final reminderEnabled = habit['reminder_enabled'] as bool? ?? false;

        if (!reminderEnabled) {
          debugPrint('⏭️ Reminder disabled for: $habitName');
          continue;
        }

        enabledReminderCount++;

        try {
          // Fetch full reminder settings
          final reminder = await _repository.fetchReminderSettingsByHabit(
            habitId,
          );

          if (reminder.id.isNotEmpty && reminder.isEnabled) {
            debugPrint('⏰ Scheduling reminder for: $habitName');
            debugPrint('   - Time: ${reminder.time.hour}:${reminder.time.minute}');
            debugPrint('   - Sound: ${reminder.isSoundEnabled}');
            debugPrint('   - Vibration: ${reminder.isVibrationEnabled}');
            debugPrint('   - Repeat daily: ${reminder.repeatDaily}');
            
            await _scheduleReminderNotification(reminder, habitName: habitName);
            scheduledCount++;
          } else {
            debugPrint('⚠️ Reminder exists but not enabled for: $habitName');
            debugPrint('   - ID: ${reminder.id}');
            debugPrint('   - Enabled: ${reminder.isEnabled}');
          }
        } catch (e) {
          debugPrint('⚠️ Error processing reminder for $habitName: $e');
          // Try to schedule using habit table data as fallback
          await _scheduleFallbackReminder(habit);
          scheduledCount++;
          continue;
        }
      }

      debugPrint('📊 Summary:');
      debugPrint('   - Total active habits: ${habitsResponse.length}');
      debugPrint('   - Habits with reminder enabled: $enabledReminderCount');
      debugPrint('   - Successfully scheduled: $scheduledCount');
      debugPrint('✅ All reminders rescheduled successfully');
      
      // Verify scheduled notifications
      await _verifyScheduledNotifications();
      
    } catch (e) {
      debugPrint('❌ Error rescheduling reminders: $e');
    }
  }

  Future<void> _scheduleFallbackReminder(Map<String, dynamic> habit) async {
    try {
      final habitId = habit['id'] as int;
      final habitName = habit['name'] as String;
      final reminderTimeStr = habit['reminder_time'] as String?;
      
      if (reminderTimeStr == null) {
        debugPrint('   ⚠️ No reminder_time in habit table for $habitName');
        return;
      }
      
      final timeParts = reminderTimeStr.split(':');
      if (timeParts.length >= 2) {
        final time = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
        
        debugPrint('   📱 Using fallback reminder for $habitName at ${time.hour}:${time.minute}');
        
        await _notificationService.scheduleHabitReminder(
          id: habitId,
          title: 'Habit Reminder: $habitName',
          body: 'Time to complete your habit!',
          time: time,
          habitId: habitId.toString(),
          repeatDaily: true,
          enableSound: true,
          enableVibration: true,
        );
      }
    } catch (e) {
      debugPrint('   ❌ Fallback scheduling failed: $e');
    }
  }

  Future<void> _verifyScheduledNotifications() async {
    try {
      final pending = await _notificationService.getPendingNotifications();
      debugPrint('📋 Verification: ${pending.length} total notifications pending');
      
      if (pending.isEmpty) {
        debugPrint('⚠️ WARNING: No pending notifications found!');
      } else {
        for (final notification in pending) {
          debugPrint('   - ID: ${notification.id}, Title: ${notification.title}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error verifying notifications: $e');
    }
  }

  Future<void> _scheduleReminderNotification(
    ReminderSettingModel reminder, {
    String? habitName,
  }) async {
    try {
      if (!reminder.isEnabled) {
        debugPrint('   ⏭️ Reminder not enabled for habit ${reminder.habitId}');
        return;
      }

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

      final timeOfDay = reminder.time;
      // Use habit ID as stable notification ID
      final notificationId = reminder.habitId;

      debugPrint('🔔 ========== SCHEDULING REMINDER ==========');
      debugPrint('   Habit: $finalHabitName (ID: ${reminder.habitId})');
      debugPrint('   Notification ID: $notificationId');
      debugPrint('   Time: ${timeOfDay.hour}:${timeOfDay.minute}');
      debugPrint('   Sound enabled: ${reminder.isSoundEnabled}');
      debugPrint('   Vibration enabled: ${reminder.isVibrationEnabled}');
      debugPrint('   Repeat daily: ${reminder.repeatDaily}');

      await _notificationService.scheduleHabitReminder(
        id: notificationId,
        title: 'Habit Reminder: $finalHabitName',
        body: 'Time to complete your habit!',
        time: timeOfDay,
        habitId: reminder.habitId.toString(),
        repeatDaily: reminder.repeatDaily,
        enableSound: reminder.isSoundEnabled,
        enableVibration: reminder.isVibrationEnabled,
      );

      debugPrint('✅ Reminder scheduled successfully with ID: $notificationId');
      debugPrint('   =========================================');
    } catch (e, stackTrace) {
      debugPrint('❌ Error scheduling reminder: $e');
      debugPrint('   Stack trace: $stackTrace');
    }
  }

  Future<void> _updateScheduledReminder(ReminderSettingModel reminder) async {
    try {
      debugPrint('🔄 Updating reminder for habit ${reminder.habitId}');
      await _cancelReminderNotification(reminder);

      if (reminder.isEnabled) {
        await _scheduleReminderNotification(reminder);
      }

      debugPrint('✅ Reminder updated for habit ${reminder.habitId}');
    } catch (e) {
      debugPrint('❌ Error updating reminder: $e');
    }
  }

  Future<void> _cancelReminderNotification(
    ReminderSettingModel reminder,
  ) async {
    try {
      final notificationId = reminder.habitId;
      await _notificationService.cancelNotification(notificationId);
      debugPrint('✅ Reminder cancelled for habit ${reminder.habitId} (ID: $notificationId)');
    } catch (e) {
      debugPrint('❌ Error cancelling reminder: $e');
    }
  }

  // ============================================================
  // METHOD INI YANG DIPANGGIL DARI main.dart
  // ============================================================
  Future<void> rescheduleReminderForHabit(int habitId) async {
    try {
      debugPrint('🔄 [RESCHEDULE] Rescheduling reminder for habit: $habitId');
      
      final reminder = await _repository.fetchReminderSettingsByHabit(habitId);
      
      if (reminder.isEnabled) {
        // Cancel old notification
        await _notificationService.cancelNotification(habitId);
        
        // Get habit name
        String habitName = '';
        try {
          final habitResponse = await _supabaseClient
              .from('habits')
              .select('name')
              .eq('id', habitId)
              .single();
          habitName = habitResponse['name'] as String;
        } catch (e) {
          habitName = 'Habit $habitId';
        }
        
        // Schedule for tomorrow (one-time, will be rescheduled again when it fires)
        debugPrint('   📅 Scheduling for tomorrow at ${reminder.time.hour}:${reminder.time.minute}');
        
        await _notificationService.scheduleHabitReminder(
          id: habitId,
          title: 'Habit Reminder: $habitName',
          body: 'Time to complete your habit!',
          time: reminder.time,
          habitId: habitId.toString(),
          repeatDaily: false, // One-time, will be rescheduled again by this method
          enableSound: reminder.isSoundEnabled,
          enableVibration: reminder.isVibrationEnabled,
        );
        
        debugPrint('✅ [RESCHEDULE] Successfully rescheduled reminder for habit $habitId');
      } else {
        debugPrint('⚠️ [RESCHEDULE] Reminder not enabled for habit $habitId, skipping reschedule');
      }
    } catch (e) {
      debugPrint('❌ [RESCHEDULE] Error rescheduling reminder for habit $habitId: $e');
    }
  }

  Future<void> dispose() async {
    await _reminderChannel?.unsubscribe();
    _isInitialized = false;
    debugPrint('🛑 Reminder sync service disposed');
  }
}