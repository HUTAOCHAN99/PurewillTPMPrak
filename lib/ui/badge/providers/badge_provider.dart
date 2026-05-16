import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/domain/model/badge_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final badgesProvider = FutureProvider<List<Badge>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  try {
    // Get user's profile ID
    final profileResponse = await supabase
        .from('profiles')
        .select('id')
        .eq('user_id', user.id)
        .single();
    
    final profileId = profileResponse['id'] as int;

    // Get badges with user progress and earned status
    final response = await supabase
        .from('badges')
        .select('''
          *,
          user_badges!left(earned_at, profile_id)
        ''')
        .order('trigger_value', ascending: true);

    final badges = (response as List).map((json) => Badge.fromJson(json, user.id)).toList();

    // Calculate progress for each badge
    final badgesWithProgress = await Future.wait(
      badges.map((badge) => _calculateBadgeProgress(badge, profileId, user.id, supabase))
    );

    return badgesWithProgress;
  } catch (e) {
    throw Exception('Failed to load badges: $e');
  }
});

Future<Badge> _calculateBadgeProgress(Badge badge, int profileId, String userId, SupabaseClient supabase) async {
  int progress = 0;
  
  try {
    switch (badge.triggerType) {
      case 'first_habit_completion':
        // Check if user has completed any habit
        final completedHabits = await supabase
            .from('daily_logs')
            .select('id')
            .limit(1);
        progress = completedHabits.isNotEmpty ? 1 : 0;
        break;
        
      case 'streak':
        // Calculate max streak from user's habits
        final habitsResponse = await supabase
            .from('habits')
            .select('id')
            .eq('user_id', userId)
            .eq('is_active', true);
        
        int maxStreak = 0;
        for (final habit in habitsResponse) {
          final streak = await _calculateHabitStreak(habit['id'] as int, supabase);
          if (streak > maxStreak) {
            maxStreak = streak;
          }
        }
        progress = maxStreak;
        break;
        
      case 'habit_count':
        // Count active habits
        final habitCount = await supabase
            .from('habits')
            .select('id')
            .eq('user_id', userId)
            .eq('is_active', true);
        progress = habitCount.length;
        break;
        
      case 'perfect_week':
        // Simplified perfect week calculation
        final perfectWeeks = await _getPerfectWeeksCount(userId, supabase);
        progress = perfectWeeks;
        break;
        
      case 'category_variety':
        // Count unique categories used
        final categories = await supabase
            .from('habits')
            .select('category_id')
            .eq('user_id', userId)
            .eq('is_active', true);
        final uniqueCategories = categories
            .where((c) => c['category_id'] != null)
            .map((c) => c['category_id'])
            .toSet();
        progress = uniqueCategories.length;
        break;
        
      case 'morning_completion':
        // Count habits completed before 8 AM
        final completions = await supabase
            .from('daily_logs')
            .select('''
              *,
              habits!inner(user_id)
            ''')
            .eq('status', 'completed')
            .eq('habits.user_id', userId);
        
        int morningCount = 0;
        for (final completion in completions) {
          final createdAt = DateTime.parse(completion['created_at'] as String);
          if (createdAt.hour < 8) {
            morningCount++;
          }
        }
        progress = morningCount;
        break;
    }
  } catch (e) {
    // debugPrint('Error calculating progress for badge ${badge.id}: $e');
  }
  
  return badge.copyWith(progress: progress);
}

Future<int> _calculateHabitStreak(int habitId, SupabaseClient supabase) async {
  try {
    // Get completed logs ordered by date descending
    final completedLogs = await supabase
        .from('daily_logs')
        .select('log_date')
        .eq('habit_id', habitId)
        .eq('status', 'completed')
        .order('log_date', ascending: false);

    if (completedLogs.isEmpty) return 0;

    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    for (final log in completedLogs) {
      final logDate = DateTime.parse(log['log_date'] as String);
      final difference = currentDate.difference(logDate).inDays;
      
      // If it's today or yesterday, continue streak
      if (difference <= 1) {
        streak++;
        currentDate = logDate;
      } else {
        break;
      }
    }
    
    return streak;
  } catch (e) {
    // debugPrint('Error calculating streak: $e');
    return 0;
  }
}

Future<int> _getPerfectWeeksCount(String userId, SupabaseClient supabase) async {
  try {
    // Get completed logs with habit user info
    final weeklyCompletions = await supabase
        .from('daily_logs')
        .select('''
          created_at,
          habits!inner(user_id)
        ''')
        .eq('status', 'completed')
        .eq('habits.user_id', userId);
    
    // Group by week
    final weeks = <String, Set<DateTime>>{};
    
    for (final completion in weeklyCompletions) {
      final date = DateTime.parse(completion['created_at'] as String);
      final weekKey = '${date.year}-W${(date.day + date.weekday - 1) ~/ 7}';
      
      if (!weeks.containsKey(weekKey)) {
        weeks[weekKey] = <DateTime>{};
      }
      weeks[weekKey]!.add(DateTime(date.year, date.month, date.day));
    }
    
    // Consider a week perfect if at least 7 unique days
    int perfectWeeks = 0;
    for (final weekDays in weeks.values) {
      if (weekDays.length >= 7) {
        perfectWeeks++;
      }
    }
    
    return perfectWeeks;
  } catch (e) {
    // debugPrint('Error calculating perfect weeks: $e');
    return 0;
  }
}