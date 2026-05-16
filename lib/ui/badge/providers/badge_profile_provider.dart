import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String userId;
  final String? fullName;
  final int level;
  final int currentXP;
  final int xpToNextLevel;
  final int totalBadges;
  final int streak;

  UserProfile({
    required this.id,
    required this.userId,
    this.fullName,
    required this.level,
    required this.currentXP,
    required this.xpToNextLevel,
    required this.totalBadges,
    required this.streak,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      fullName: json['full_name'] as String?,
      level: (json['level'] as int?) ?? 1,
      currentXP: (json['current_xp'] as int?) ?? 0,
      xpToNextLevel: (json['xp_to_next_level'] as int?) ?? 100,
      totalBadges: (json['total_badges'] as int?) ?? 0,
      streak: (json['current_streak'] as int?) ?? 0,
    );
  }

  // Helper methods
  double get progressPercentage {
    if (xpToNextLevel == 0) return 0.0;
    return currentXP / xpToNextLevel;
  }

  String get xpDisplay => '$currentXP/$xpToNextLevel XP';
  
  String get displayName => fullName ?? 'User';
  
  int get xpNeeded => xpToNextLevel - currentXP;
}

// Provider untuk user profile dengan XP dan badges
final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  
  if (user == null) {
    throw Exception('User not logged in');
  }

  try {
    // debugPrint('🔄 Loading user profile for badge system...');
    
    // Get basic profile data
    final profileResponse = await supabase
        .from('profiles')
        .select('id, user_id, full_name, level, current_xp, xp_to_next_level')
        .eq('user_id', user.id)
        .single();

    // Get total badges count (perbaikan query)
    final badgesResponse = await supabase
        .from('user_badges')
        .select('*')
        .eq('profile_id', profileResponse['id'] as int);

    // Get current streak
    final streak = await _calculateCurrentStreak(user.id, supabase);

    // Combine all data
    final userProfileData = {
      ...profileResponse,
      'total_badges': badgesResponse.length,
      'current_streak': streak,
    };

    final profile = UserProfile.fromJson(userProfileData);
    
    // debugPrint('✅ User profile loaded: ${profile.displayName}, Level ${profile.level}, ${profile.totalBadges} badges');
    
    return profile;
  } catch (e, stack) {
    // debugPrint('❌ Error loading user profile: $e');
    // debugPrint('Stack trace: $stack');
    throw Exception('Failed to load user profile: $e');
  }
});

// Helper function untuk menghitung streak
Future<int> _calculateCurrentStreak(String userId, SupabaseClient supabase) async {
  try {
    // Get user's active habits
    final activeHabits = await supabase
        .from('habits')
        .select('id')
        .eq('user_id', userId)
        .eq('is_active', true);

    if (activeHabits.isEmpty) return 0;

    int maxStreak = 0;
    
    // Calculate streak for each habit and take the maximum
    for (final habit in activeHabits) {
      final habitId = habit['id'] as int;
      final habitStreak = await _calculateHabitStreak(habitId, supabase);
      if (habitStreak > maxStreak) {
        maxStreak = habitStreak;
      }
    }
    
    return maxStreak;
  } catch (e) {
    // debugPrint('❌ Error calculating current streak: $e');
    return 0;
  }
}

Future<int> _calculateHabitStreak(int habitId, SupabaseClient supabase) async {
  try {
    // Get completed logs ordered by date descending
    final completedLogs = await supabase
        .from('daily_logs')
        .select('log_date')
        .eq('habit_id', habitId)
        .eq('status', 'success')
        .order('log_date', ascending: false);

    if (completedLogs.isEmpty) return 0;

    int streak = 0;
    DateTime currentDate = DateTime.now().toUtc();
    
    for (final log in completedLogs) {
      final logDate = DateTime.parse(log['log_date'] as String).toUtc();
      final difference = currentDate.difference(logDate).inDays;
      
      // If it's today or consecutive days, continue streak
      if (difference == streak) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  } catch (e) {
    // debugPrint('❌ Error calculating habit streak: $e');
    return 0;
  }
}

// Provider untuk refresh profile
final refreshUserProfileProvider = Provider<void>((ref) {
  // ref.refresh(userProfileProvider);
});

// Provider untuk level up notification
final levelUpProvider = StateProvider<bool>((ref) => false);