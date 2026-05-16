import 'dart:developer';
import 'package:purewill/domain/model/daily_log_model.dart';
import 'package:purewill/domain/model/habit_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyLogRepository {
  final SupabaseClient _supabaseClient;
  static const String _logTableName = 'daily_logs';

  DailyLogRepository(this._supabaseClient);


  Future<void> addLogsForNewHabit(HabitModel habit) async {
    try {
      final logData = {
        'habit_id': habit.id,
        'log_date': DateTime.now().toIso8601String().substring(0, 10),
        'status': LogStatus.neutral.name,
        'actual_value': 0,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabaseClient
          .from(_logTableName)
          .insert(logData);

      log(
        'ADD LOGS FOR NEW HABIT SUCCESS: Log added for new habit ${habit.id}.',
        name: 'DAILY_LOG_REPO',
      );
    } catch (e, stackTrace) {
      log(
        'ADD LOGS FOR NEW HABIT FAILURE: Failed to add logs for new habit ${habit.id}.',
        error: e,
        stackTrace: stackTrace,
        name: 'DAILY_LOG_REPO',
      );
      rethrow;
    }
  }

  Future<DailyLogModel> recordLog({
    required int habitId,
    required DateTime date,
    required LogStatus status,
    double? actualValue,
  }) async {
    try {
      // print(
        // "akan diubah statusnya ke : $status for habitId: $habitId on date: ${date.toIso8601String().substring(0, 10)}",
      // );

      final logData = {
        'habit_id': habitId,
        'log_date': date.toIso8601String().substring(0, 10),
        'status': status.name,
        'actual_value': actualValue?.toInt(), // UBAH INI: convert ke int
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseClient
          .from(_logTableName)
          .upsert(logData, onConflict: 'habit_id, log_date')
          .select()
          .single();

      // print("success record log response: $response");

      return DailyLogModel.fromJson(response);
    } catch (e, stackTrace) {
      log(
        'RECORD LOG FAILURE: Failed to record log for habit $habitId on ${date.toIso8601String().substring(0, 10)}.',
        error: e,
        stackTrace: stackTrace,
        name: 'DAILY_LOG_REPO',
      );
      rethrow;
    }
  }

  Future<List<DailyLogModel>> fetchLogsByHabit(int habitId) async {
    try {
      final response = await _supabaseClient
          .from(_logTableName)
          .select('*')
          .eq('habit_id', habitId)
          .order('log_date', ascending: false);
      
      if (response.isEmpty) {
        return [];
      }

      return response.map((data) => DailyLogModel.fromJson(data)).toList();
    } catch (e, stackTrace) {
      log(
        'FETCH LOGS FAILURE: Failed to fetch logs for habit $habitId.',
        error: e,
        stackTrace: stackTrace,
        name: 'DAILY_LOG_REPO',
      );
      rethrow;
    }
  }

  Future<int> fetchHabitLogStreak(int habitId) async {
    try {
      final response = await _supabaseClient.rpc(
        'get_current_habit_streak',
        params: {'p_habit_id': habitId},
      );
      
      return response;
    } catch (e, stackTrace) {
      log(
        'FETCH HABIT STREAK FAILURE: Failed to fetch habit streak for habit $habitId.',
        error: e,
        stackTrace: stackTrace,
        name: 'DAILY_LOG_REPO',
      );
      rethrow;
    }
  }

  Future<List<DailyLogModel>> fetchLogsByDateRange({
    required int habitId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabaseClient
          .from(_logTableName)
          .select('*')
          .eq('habit_id', habitId)
          .gte('log_date', startDate.toIso8601String().substring(0, 10))
          .lte('log_date', endDate.toIso8601String().substring(0, 10))
          .order('log_date', ascending: true);

      return response.map((data) => DailyLogModel.fromJson(data)).toList();
    } catch (e, stackTrace) {
      log(
        'FETCH LOGS RANGE FAILURE: Failed to fetch logs for habit $habitId in range.',
        error: e,
        stackTrace: stackTrace,
        name: 'DAILY_LOG_REPO',
      );
      rethrow;
    }
  }

  Future<List<DailyLogModel>> fetchLogsByDate(DateTime date) async {
    try {
      final response = await _supabaseClient
          .from(_logTableName)
          .select('*')
          .eq('log_date', date.toIso8601String().substring(0, 10))
          .order('created_at', ascending: false);

      return response.map((data) => DailyLogModel.fromJson(data)).toList();
    } catch (e, stackTrace) {
      log(
        'FETCH LOGS BY DATE FAILURE: Failed to fetch logs for date ${date.toIso8601String().substring(0, 10)}.',
        error: e,
        stackTrace: stackTrace,
        name: 'DAILY_LOG_REPO',
      );
      rethrow;
    }
  }

  Future<DailyLogModel?> getTodayLogForHabit(int habitId) async {
    try {
      // print("fetching today log for habitId: $habitId");
      final today = DateTime.now().toIso8601String().substring(0, 10);

      final response = await _supabaseClient
          .from(_logTableName)
          .select('*')
          .eq('habit_id', habitId)
          .eq('log_date', today)
          .maybeSingle();

      // print("anjing");
      // print("response for getTodayLogForHabit: $response");

      if (response != null) {
        return DailyLogModel.fromJson(response);
      }
      return null;
    } catch (e, stackTrace) {
      // print(e);
      // print(stackTrace);
      log(
        'GET TODAY LOG FAILURE: Failed to fetch today log for habit $habitId.',
        error: e,
        stackTrace: stackTrace,
        name: 'DAILY_LOG_REPO',
      );
      return null;
    }
  }

  Future<void> deleteLog({required int habitId, required DateTime date}) async {
    try {
      await _supabaseClient
          .from(_logTableName)
          .delete()
          .eq('habit_id', habitId)
          .eq('log_date', date.toIso8601String().substring(0, 10));

      log(
        'DELETE LOG SUCCESS: Log deleted for habit $habitId on ${date.toIso8601String().substring(0, 10)}.',
        name: 'DAILY_LOG_REPO',
      );
    } catch (e, stackTrace) {
      log(
        'DELETE LOG FAILURE: Failed to delete log for habit $habitId.',
        error: e,
        stackTrace: stackTrace,
        name: 'DAILY_LOG_REPO',
      );
      rethrow;
    }
  }

  Future<void> deleteLogsByHabit(int habitId) async {
    try {
      await _supabaseClient
          .from(_logTableName)
          .delete()
          .eq('habit_id', habitId);

      log(
        'DELETE LOGS BY HABIT SUCCESS: Logs deleted for habit $habitId.',
        name: 'DAILY_LOG_REPO',
      );
    } catch (e, stackTrace) {
      log(
        'DELETE LOGS BY HABIT FAILURE: Failed to delete logs for habit $habitId.',
        error: e,
        stackTrace: stackTrace,
        name: 'DAILY_LOG_REPO',
      );
      rethrow;
    }
  }

  Future<void> deleteLogsBeforeDate({
    required int habitId,
    required DateTime date,
  }) async {
    try {
      await _supabaseClient
          .from(_logTableName)
          .delete()
          .eq('habit_id', habitId)
          .lt('log_date', date.toIso8601String().substring(0, 10));

      log(
        'DELETE LOGS BEFORE DATE SUCCESS: Logs deleted for habit $habitId before ${date.toIso8601String().substring(0, 10)}.',
        name: 'DAILY_LOG_REPO',
      );
    } catch (e, stackTrace) {
      log(
        'DELETE LOGS BEFORE DATE FAILURE: Failed to delete logs for habit $habitId before date.',
        error: e,
        stackTrace: stackTrace,
        name: 'DAILY_LOG_REPO',
      );
      rethrow;
    }
  }

  Future<void> deleteLogsAfterDate({
    required int habitId,
    required DateTime date,
  }) async {
    try {
      await _supabaseClient
          .from(_logTableName)
          .delete()
          .eq('habit_id', habitId)
          .gt('log_date', date.toIso8601String().substring(0, 10));

      log(
        'DELETE LOGS AFTER DATE SUCCESS: Logs deleted for habit $habitId after ${date.toIso8601String().substring(0, 10)}.',
        name: 'DAILY_LOG_REPO',
      );
    } catch (e, stackTrace) {
      log(
        'DELETE LOGS AFTER DATE FAILURE: Failed to delete logs for habit $habitId after date.',
        error: e,
        stackTrace: stackTrace,
        name: 'DAILY_LOG_REPO',
      );
      rethrow;
    }
  }
}
