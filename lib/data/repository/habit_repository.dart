import 'dart:developer';
import 'package:purewill/data/services/default_habits_service.dart';
import 'package:purewill/domain/model/habit_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HabitRepository {
  final SupabaseClient _supabaseClient;
  static const String _habitTableName = 'habits';

  HabitRepository(this._supabaseClient);

  Future<HabitModel> createHabit(HabitModel habit) async {
    try {
      final habitData = habit.toJson();
      // print(habitData);
      final response = await _supabaseClient
          .from(_habitTableName)
          .insert(habitData)
          .select()
          .single();

      return HabitModel.fromJson(response);
    } catch (e, stackTrace) {
      log(
        'CREATE HABIT FAILURE: Failed to create habit ${habit.name}.',
        error: e,
        stackTrace: stackTrace,
        name: 'HABIT_REPO',
      );
      rethrow;
    }
  }

  Future<List<HabitModel>> fetchUserHabits(String userId) async {
    try {
      final response = await _supabaseClient
          .from(_habitTableName)
          .select('*')
          .eq('user_id', userId)
          .order('start_date', ascending: true);

      final userHabits = response
          .map((data) => HabitModel.fromJson(data))
          .toList();

      // print(response);
      userHabits.map((h) => h.name).toSet();
      final allHabits = [...userHabits];

      // print('=== COMBINED HABITS ===');
      // print('User habits: ${userHabits.length}');
      // print('Total habits: ${allHabits.length}');

      // for (var habit in allHabits) {
      // print(
      //   'Habit: ${habit.name}, Target: ${habit.targetValue}, Unit: ${habit.unit}, IsDefault: ${habit.isDefault}, Habit id: ${habit.id}, Status: ${habit.status}',
      // );
      // }
      // print('========================');

      return allHabits;
    } catch (e, stackTrace) {
      // print(e.toString());
      log(
        'FETCH HABITS FAILURE: Failed to fetch habits for user $userId.',
        error: e,
        stackTrace: stackTrace,
        name: 'HABIT_REPO',
      );

      // Fallback: return default habits jika error
      // print('=== USING DEFAULT HABITS AS FALLBACK ===');
      final defaultHabits = DefaultHabitsService.getDefaultHabits();

      // Debug print untuk default habits
      // for (var habit in defaultHabits) {
      //   // print(
      //     'Default Habit: ${habit.name}, Target: ${habit.targetValue}, Unit: ${habit.unit}',
      //   );
      // }

      return defaultHabits;
    }
  }

  Future<HabitModel> initializeDefaultHabitsForUser(String userId) async {
    try {
      final defaultHabits = DefaultHabitsService.getDefaultHabits();

      var newHabit = defaultHabits.first;
      final habitToCreate = HabitModel(
        id: 0,
        userId: userId,
        frequency: newHabit.frequency,
        name: newHabit.name,
        notes: newHabit.notes,
        categoryId: newHabit.categoryId,
        targetValue: newHabit.targetValue,
        unit: newHabit.unit,
        startDate: DateTime.now(),
        endDate: null,
        isActive: false,
        isDefault: true,
      );

      final habit = await createHabit(habitToCreate);

      log(
        'INITIALIZE DEFAULT HABITS SUCCESS: Default habits initialized for user $userId.',
        name: 'HABIT_REPO',
      );

      return habit;
    } catch (e, stackTrace) {
      log(
        'INITIALIZE DEFAULT HABITS FAILURE: Failed to initialize default habits for user $userId.',
        error: e,
        stackTrace: stackTrace,
        name: 'HABIT_REPO',
      );
      rethrow;
    }
  }

  Future<HabitModel> activeNofapHabit(String userId, int habitId) async {
    try {

      final response = await _supabaseClient
          .from(_habitTableName)
          .update({'is_active': true})
          .eq('user_id', userId)
          .eq('id', habitId)
          .select()
          .single();

      return HabitModel.fromJson(response);
    } catch (e, stackTrace) {
      log(
        'ACTIVATE NOFAP HABIT FAILURE: Failed to activate NoFap habit for user $userId.',
        error: e,
        stackTrace: stackTrace,
        name: 'HABIT_REPO',
      );
      rethrow;
    }
  }

  Future<HabitModel> deactivateNofapHabit(String userId, int habitId) async {
    try {

      final response = await _supabaseClient
          .from(_habitTableName)
          .update({'is_active': false})
          .eq('user_id', userId)
          .eq('id', habitId)
          .select()
          .single();

      return HabitModel.fromJson(response);
    } catch (e, stackTrace) {
      log(
        'DEACTIVATE NOFAP HABIT FAILURE: Failed to deactivate NoFap habit for user $userId.',
        error: e,
        stackTrace: stackTrace,
        name: 'HABIT_REPO',
      );
      rethrow;
    }
  }

  Future<int> getNofapHabitId(String userId) async {
    try {
      final response = await _supabaseClient
          .from(_habitTableName)
          .select('id')
          .eq('user_id', userId)
          .eq('name', 'NoFap')
          .single();

      return response['id'] as int;
    } catch (e, stackTrace) {
      log(
        'GET NOFAP HABIT ID FAILURE: Failed to fetch NoFap habit ID for user $userId.',
        error: e,
        stackTrace: stackTrace,
        name: 'HABIT_REPO',
      );
      rethrow;
    }
  }

  Future<List<HabitModel>> fetchTodayUserHabits(String userId) async {
    try {
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final tomorrow = today.add(const Duration(days: 1));
      final tomorrowStart =
          '${tomorrow.toIso8601String().substring(0, 10)} 00:00:00+00';

      final todayStart =
          '${today.toIso8601String().substring(0, 10)} 00:00:00+00';

      final response = await _supabaseClient
          .from(_habitTableName)
          .select('*')
          .lt('start_date', tomorrowStart)
          .or('end_date.is.null,end_date.gte.$todayStart')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('start_date', ascending: true);

      return response.map((data) => HabitModel.fromJson(data)).toList();
    } catch (e, stackTrace) {
      log(
        'FETCH TODAY\'S HABITS FAILURE: Failed to fetch today\'s habits for user $userId.',
        error: e,
        stackTrace: stackTrace,
        name: 'HABIT_REPO',
      );
      rethrow;
    }
  }

  Future<void> updateHabitStatus({
    required int habitId,
    required String status,
  }) async {
    try {
      await _supabaseClient
          .from(_habitTableName)
          .update({'status': status})
          .eq('id', habitId);

      log(
        'UPDATE HABIT STATUS SUCCESS: Habit $habitId updated to $status.',
        name: 'HABIT_REPO',
      );
    } catch (e, stackTrace) {
      log(
        'UPDATE HABIT FAILURE: Failed to update status for habit $habitId.',
        error: e,
        stackTrace: stackTrace,
        name: 'HABIT_REPO',
      );
      rethrow;
    }
  }

  Future<void> updateHabit({
    required int habitId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _supabaseClient
          .from(_habitTableName)
          .update(updates)
          .eq('id', habitId);

      log(
        'UPDATE HABIT SUCCESS: Habit $habitId updated with $updates.',
        name: 'HABIT_REPO',
      );
    } catch (e, stackTrace) {
      log(
        'UPDATE HABIT FAILURE: Failed to update habit $habitId.',
        error: e,
        stackTrace: stackTrace,
        name: 'HABIT_REPO',
      );
      rethrow;
    }
  }

  Future<void> deleteHabit(int habitId) async {
    try {
      await _supabaseClient.from(_habitTableName).delete().eq('id', habitId);

      log('DELETE HABIT SUCCESS: Habit $habitId deleted.', name: 'HABIT_REPO');
    } catch (e, stackTrace) {
      log(
        'DELETE HABIT FAILURE: Failed to delete habit $habitId.',
        error: e,
        stackTrace: stackTrace,
        name: 'HABIT_REPO',
      );
      rethrow;
    }
  }

  Future<HabitModel?> getHabitById(int habitId) async {
    try {
      final response = await _supabaseClient
          .from(_habitTableName)
          .select('*')
          .eq('id', habitId)
          .maybeSingle();

      if (response != null) {
        return HabitModel.fromJson(response);
      }
      return null;
    } catch (e, stackTrace) {
      log(
        'GET HABIT BY ID FAILURE: Failed to fetch habit $habitId.',
        error: e,
        stackTrace: stackTrace,
        name: 'HABIT_REPO',
      );
      return null;
    }
  }

  Future<List<HabitModel>> getHabitsByCategory(int categoryId) async {
    try {
      final response = await _supabaseClient
          .from(_habitTableName)
          .select('*')
          .eq('category_id', categoryId)
          .order('name', ascending: true);

      return response.map((data) => HabitModel.fromJson(data)).toList();
    } catch (e, stackTrace) {
      log(
        'GET HABITS BY CATEGORY FAILURE: Failed to fetch habits for category $categoryId.',
        error: e,
        stackTrace: stackTrace,
        name: 'HABIT_REPO',
      );
      return [];
    }
  }

  Future<List<HabitModel>> searchHabits(String query) async {
    try {
      final response = await _supabaseClient
          .from(_habitTableName)
          .select('*')
          .ilike('name', '%$query%')
          .order('name', ascending: true);

      return response.map((data) => HabitModel.fromJson(data)).toList();
    } catch (e, stackTrace) {
      log(
        'SEARCH HABITS FAILURE: Failed to search habits with query: $query.',
        error: e,
        stackTrace: stackTrace,
        name: 'HABIT_REPO',
      );
      return [];
    }
  }

  Future<int> getHabitsCount(String userId) async {
    try {
      final response = await _supabaseClient
          .from(_habitTableName)
          .select()
          .eq('user_id', userId);

      return response.length;
    } catch (e, stackTrace) {
      log(
        'GET HABITS COUNT FAILURE: Failed to count habits for user $userId.',
        error: e,
        stackTrace: stackTrace,
        name: 'HABIT_REPO',
      );
      return 0;
    }
  }

  Future<List<HabitModel>> getActiveHabits(String userId) async {
    try {
      final response = await _supabaseClient
          .from(_habitTableName)
          .select('*')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('name', ascending: true);

      return response.map((data) => HabitModel.fromJson(data)).toList();
    } catch (e, stackTrace) {
      log(
        'GET ACTIVE HABITS FAILURE: Failed to fetch active habits for user $userId.',
        error: e,
        stackTrace: stackTrace,
        name: 'HABIT_REPO',
      );
      return [];
    }
  }

  Future<List<HabitModel>> getCompletedHabits(String userId) async {
    try {
      final response = await _supabaseClient
          .from(_habitTableName)
          .select('*')
          .eq('user_id', userId)
          .eq('status', 'completed')
          .order('name', ascending: true);

      return response.map((data) => HabitModel.fromJson(data)).toList();
    } catch (e, stackTrace) {
      log(
        'GET COMPLETED HABITS FAILURE: Failed to fetch completed habits for user $userId.',
        error: e,
        stackTrace: stackTrace,
        name: 'HABIT_REPO',
      );
      return [];
    }
  }
}
