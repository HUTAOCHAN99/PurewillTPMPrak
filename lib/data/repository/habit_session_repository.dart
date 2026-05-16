import 'package:supabase_flutter/supabase_flutter.dart';

class HabitSessionModel {
  final int id;
  final int habitId;
  final String userId;
  final DateTime startDate;
  final DateTime? endDate;
  final int? finalStreakLength;
  final String? relapseNotes;
  final bool isActive;

  HabitSessionModel({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.startDate,
    this.endDate,
    this.finalStreakLength,
    this.relapseNotes,
    required this.isActive,
  });

  factory HabitSessionModel.fromJson(Map<String, dynamic> json) {
    return HabitSessionModel(
      id: json['id'] as int,
      habitId: json['habit_id'] as int,
      userId: json['user_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      finalStreakLength: json['final_streak_length'] as int?,
      relapseNotes: json['relapse_notes'] as String?,
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habit_id': habitId,
      'user_id': userId,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'final_streak_length': finalStreakLength,
      'relapse_notes': relapseNotes,
      'is_active': isActive,
    };
  }
}

class HabitSessionRepository {
  final SupabaseClient _supabaseClient;

  HabitSessionRepository(this._supabaseClient);

  Future<HabitSessionModel> addHabitSession({
    required int habitId,
    required String userId,
    required DateTime startDate,
  }) async {
    try {
      // Deactivate any existing active session for this habit and user
      await _supabaseClient
          .from('habit_sessions')
          .update({'is_active': false})
          .eq('habit_id', habitId)
          .eq('user_id', userId)
          .eq('is_active', true);

      // Create new active session
      final response = await _supabaseClient
          .from('habit_sessions')
          .insert({
            'habit_id': habitId,
            'user_id': userId,
            'start_date': startDate.toIso8601String().split('T')[0],
            'is_active': true,
          })
          .select()
          .single();

      return HabitSessionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add habit session: $e');
    }
  }

  Future<HabitSessionModel> updateHabitSession({
    required int sessionId,
    DateTime? endDate,
    int? finalStreakLength,
    String? relapseNotes,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (endDate != null) {
        updateData['end_date'] = endDate.toIso8601String();
      }

      if (finalStreakLength != null) {
        updateData['final_streak_length'] = finalStreakLength;
      }

      if (relapseNotes != null) {
        updateData['relapse_notes'] = relapseNotes;
      }

      if (isActive != null) {
        updateData['is_active'] = isActive;
      }

      if (updateData.isEmpty) {
        throw Exception('No data to update');
      }

      final response = await _supabaseClient
          .from('habit_sessions')
          .update(updateData)
          .eq('id', sessionId)
          .select()
          .single();

      return HabitSessionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update habit session: $e');
    }
  }

  Future<int> fetchNofapHabitLongestStreak({
    required int habitId,
    required String userId,
  }) async {
    try {
      final response = await _supabaseClient.rpc(
        'get_longest_streak',
        params: {'p_habit_id': habitId, 'p_user_id': userId},
      );

      if (response == null) {
        return 0;
      }

      return response as int;
    } catch (e) {
      throw Exception('Failed to fetch longest streak: $e');
    }
  }

  Future<int> fetchNofapHabitCurrentStreak({
    required int habitId,
    required String userId,
  }) async {
    try {
      final response = await _supabaseClient.rpc(
        'get_current_streak',
        params: {'p_habit_id': habitId, 'p_user_id': userId},
      );

      if (response == null) {
        return 0;
      }

      return response as int;
    } catch (e) {
      throw Exception('Failed to fetch current streak: $e');
    }
  }

  Future<int> getRelapseCount({
    required int habitId,
    required String userId,
  }) async {
    try {
      final response = await _supabaseClient
          .from('habit_sessions')
          .select()
          .eq('habit_id', habitId)
          .eq('user_id', userId)
          .not('end_date', 'is', null);

      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to get relapse count: $e');
    }
  }

  Future<List<DateTime>> getSuccessDays({
    required int habitId,
    required String userId,
  }) async {
    try {
      final response = await _supabaseClient
          .from('habit_sessions')
          .select()
          .eq('habit_id', habitId)
          .eq('user_id', userId)
          .not('end_date', 'is', null);

      final sessions = (response as List)
          .map((session) => HabitSessionModel.fromJson(session))
          .toList();

      final successDays = <DateTime>[];

      for (var session in sessions) {
        if (session.finalStreakLength != null &&
            session.finalStreakLength! > 0 &&
            session.endDate != null) {
          for (int i = 0; i < session.finalStreakLength!; i++) {
            successDays.add(session.startDate.add(Duration(days: i)));
          }
        }
      }

      return successDays;
    } catch (e) {
      throw Exception('Failed to get success days: $e');
    }
  }

  Future<void> deleteHabitSession({required int sessionId}) async {
    try {
      await _supabaseClient.from('habit_sessions').delete().eq('id', sessionId);
    } catch (e) {
      throw Exception('Failed to delete habit session: $e');
    }
  }

  Future<HabitSessionModel?> getActiveHabitSession({
    required int habitId,
    required String userId,
  }) async {
    print("habitId: $habitId, userId: $userId");
    try {
      final response = await _supabaseClient
          .from('habit_sessions')
          .select()
          .eq('habit_id', habitId)
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return HabitSessionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get active habit session: $e');
    }
  }

  Future<List<HabitSessionModel>> getHabitSessionHistory({
    required int habitId,
    required String userId,
  }) async {
    try {
      final response = await _supabaseClient
          .from('habit_sessions')
          .select()
          .eq('habit_id', habitId)
          .eq('user_id', userId)
          .order('start_date', ascending: false);

      return (response as List)
          .map((session) => HabitSessionModel.fromJson(session))
          .toList();
    } catch (e) {
      throw Exception('Failed to get habit session history: $e');
    }
  }
}
