import 'dart:developer';
import 'package:purewill/domain/model/reminder_setting_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReminderSettingRepository {
  final SupabaseClient _supabaseClient;
  static const String _reminderSettingTableName = 'reminder_settings';

  ReminderSettingRepository(this._supabaseClient);

  Future<ReminderSettingModel> createReminderSetting(
    ReminderSettingModel reminderSetting,
  ) async {
    try {
      final reminderSettingData = reminderSetting.toJson();

      // Remove id if empty (for create new)
      if (reminderSetting.id.isEmpty) {
        reminderSettingData.remove('id');
      }

      // debugPrint('📦 CREATE REMINDER REQUEST DATA: $reminderSettingData');

      final response = await _supabaseClient
          .from(_reminderSettingTableName)
          .insert(reminderSettingData)
          .select()
          .single();

      // debugPrint('📦 CREATE REMINDER RESPONSE: $response');
      
      return ReminderSettingModel.fromJson(response);
    } catch (e, stackTrace) {
      log(
        'CREATE REMINDER SETTING FAILURE: Failed to create reminder setting for habit ${reminderSetting.habitId}.',
        error: e,
        stackTrace: stackTrace,
        name: 'REMINDER_SETTING_REPO',
      );
      rethrow;
    }
  }

  Future<ReminderSettingModel> fetchReminderSettingsByHabit(
    int habitId,
  ) async {
    try {
      // debugPrint('📦 FETCHING REMINDERS FOR HABIT: $habitId');

      final response = await _supabaseClient
          .from(_reminderSettingTableName)
          .select('*')
          .eq('habit_id', habitId)
          .order('time', ascending: true)
          .single();

      return ReminderSettingModel.fromJson(response);
    } catch (e, stackTrace) {
      log(
        'FETCH REMINDER SETTINGS FAILURE: Failed to fetch reminder settings for habit $habitId.',
        error: e,
        stackTrace: stackTrace,
        name: 'REMINDER_SETTING_REPO',
      );
      rethrow;
    }
  }

  Future<void> updateReminderSetting({
    required String reminderSettingId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      // debugPrint('📦 UPDATING REMINDER: $reminderSettingId');

      final cleanUpdates = Map<String, dynamic>.from(updates);
      cleanUpdates.remove('id');
      cleanUpdates.remove('created_at');
      cleanUpdates.remove('habit_id');

      // Convert ID to int for Supabase query
      final intId = int.tryParse(reminderSettingId);
      if (intId == null) {
        throw Exception('Invalid reminder setting ID: $reminderSettingId');
      }

      await _supabaseClient
          .from(_reminderSettingTableName)
          .update(cleanUpdates)
          .eq('id', intId);

      // debugPrint('✅ UPDATE REMINDER SETTING SUCCESS: Reminder setting $reminderSettingId updated');
    } catch (e, stackTrace) {
      log(
        'UPDATE REMINDER SETTING FAILURE: Failed to update reminder setting $reminderSettingId.',
        error: e,
        stackTrace: stackTrace,
        name: 'REMINDER_SETTING_REPO',
      );
      rethrow;
    }
  }

  Future<void> deleteReminderSetting(int habitId) async {
    try {
      // debugPrint('📦 DELETING REMINDER: $reminderSettingId');

      // final intId = int.tryParse(reminderSettingId);
      // if (intId == null) {
      //   throw Exception('Invalid reminder setting ID: $reminderSettingId');
      // }

      await _supabaseClient
          .from(_reminderSettingTableName)
          .delete()
// <<<<<<< HEAD
          .eq('habit_id', habitId);

      log(
        'DELETE REMINDER SETTING SUCCESS: Reminder setting $habitId deleted.',
        name: 'REMINDER_SETTING_REPO',
      );
// =======
          // .eq('id', intId);

      // debugPrint('✅ DELETE REMINDER SETTING SUCCESS: Reminder setting $reminderSettingId deleted.');
// >>>>>>> f2d2932ae1d617906d117abaeeb90fd7045aea0c
    } catch (e, stackTrace) {
      log(
        'DELETE REMINDER SETTING FAILURE: Failed to delete reminder setting $habitId.',
        error: e,
        stackTrace: stackTrace,
        name: 'REMINDER_SETTING_REPO',
      );
      rethrow;
    }
  }

  Future<void> deleteAllReminderSettingsForHabit(int habitId) async {
    try {
      // debugPrint('📦 DELETING ALL REMINDERS FOR HABIT: $habitId');

      await _supabaseClient
          .from(_reminderSettingTableName)
          .delete()
          .eq('habit_id', habitId);

      // debugPrint('✅ DELETE ALL REMINDERS SUCCESS: All reminders deleted for habit $habitId.');
    } catch (e, stackTrace) {
      log(
        'DELETE ALL REMINDER SETTINGS FAILURE: Failed to delete all reminder settings for habit $habitId.',
        error: e,
        stackTrace: stackTrace,
        name: 'REMINDER_SETTING_REPO',
      );
      rethrow;
    }
  }
}