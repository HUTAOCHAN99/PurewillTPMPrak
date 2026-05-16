import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purewill/data/services/badge_service.dart';

class BadgeTriggerService {
  final SupabaseClient _supabase;
  final BadgeService _badgeService;

  BadgeTriggerService(this._supabase, this._badgeService);

  // Trigger badge check ketika habit selesai
  Future<void> onHabitCompleted(String userId) async {
    try {
      if (userId.isEmpty) return;

      // debugPrint('🏆 Habit completed, checking badges for user: $userId');
      
      // Tunggu sebentar untuk memastikan data tersimpan
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Trigger badge check
      await _badgeService.checkAllBadges(userId);
      
    } catch (e, stack) {
      // debugPrint('❌ Error triggering badge check: $e');
      // debugPrint('Stack trace: $stack');
    }
  }

  // Trigger badge check ketika habit baru dibuat
  Future<void> onHabitCreated(String userId) async {
    try {
      if (userId.isEmpty) return;

      // debugPrint('🏆 New habit created, checking badges for user: $userId');
      
      // Tunggu sebentar
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Trigger badge check untuk habit_count badges
      await _badgeService.checkAllBadges(userId);
      
    } catch (e, stack) {
      // debugPrint('❌ Error triggering badge check: $e');
      // debugPrint('Stack trace: $stack');
    }
  }

  // Trigger badge check untuk morning completion
  Future<void> onMorningCompletion(String userId) async {
    try {
      if (userId.isEmpty) return;

      // debugPrint('🌅 Morning completion detected, checking badges for user: $userId');
      
      await Future.delayed(const Duration(milliseconds: 500));
      await _badgeService.checkAllBadges(userId);
      
    } catch (e, stack) {
      // debugPrint('❌ Error checking morning completion badges: $e');
      // debugPrint('Stack trace: $stack');
    }
  }

  // Trigger badge check ketika streak berubah
  Future<void> onStreakChanged(String userId) async {
    try {
      if (userId.isEmpty) return;

      // debugPrint('🔥 Streak changed, checking badges for user: $userId');
      
      // Tunggu sebentar
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Trigger badge check untuk streak badges
      await _badgeService.checkAllBadges(userId);
      
    } catch (e, stack) {
      // debugPrint('❌ Error checking streak badges: $e');
      // debugPrint('Stack trace: $stack');
    }
  }

  // Trigger badge check ketika kategori ditambahkan
  Future<void> onCategoryAdded(String userId) async {
    try {
      if (userId.isEmpty) return;

      // debugPrint('🏷️ Category added, checking badges for user: $userId');
      
      await Future.delayed(const Duration(milliseconds: 500));
      await _badgeService.checkAllBadges(userId);
      
    } catch (e, stack) {
      // debugPrint('❌ Error checking category badges: $e');
      // debugPrint('Stack trace: $stack');
    }
  }

  // Trigger badge check secara manual
  Future<void> manualTrigger(String userId) async {
    try {
      if (userId.isEmpty) {
        // debugPrint('⚠️ No user ID provided, cannot trigger badge check');
        return;
      }

      // debugPrint('🔄 Manually triggering badge check for user: $userId');
      
      // Jalankan badge check
      await _badgeService.checkAllBadges(userId);
      
      // Tampilkan summary
      final badges = await _badgeService.getUserBadges(userId);
      // debugPrint('📊 User has ${badges.length} total badges');
      
    } catch (e, stack) {
      // debugPrint('❌ Error in manual trigger: $e');
      // debugPrint('Stack trace: $stack');
    }
  }

  // Check apakah user sudah mendapatkan badge tertentu
  Future<bool> hasBadge(String userId, int badgeId) async {
    try {
      final badges = await _badgeService.getUserBadges(userId);
      return badges.any((badge) => badge['badge_id'] == badgeId);
    } catch (e) {
      // debugPrint('❌ Error checking if user has badge: $e');
      return false;
    }
  }

  // Get progress menuju badge tertentu - METODE ALTERNATIF - FIXED: Filter user_id
  Future<Map<String, dynamic>> getBadgeProgress(String userId, int badgeId) async {
    try {
      // Ambil detail badge
      final badgeDetails = await _supabase
          .from('badges')
          .select('*')
          .eq('id', badgeId)
          .single();

      final triggerType = badgeDetails['trigger_type'] as String;
      final triggerValue = int.parse(badgeDetails['trigger_value'].toString());
      
      int currentProgress = 0;

      // Hitung progress berdasarkan trigger type
      switch (triggerType) {
        case 'STREAK':
        case 'streak':
          // Hitung streak dari habit terpanjang
          final activeHabits = await _supabase
              .from('habits')
              .select('id')
              .eq('user_id', userId)
              .eq('is_active', true);
          
          int maxStreak = 0;
          for (final habit in activeHabits) {
            final streak = await _calculateHabitStreak(habit['id'] as int);
            if (streak > maxStreak) maxStreak = streak;
          }
          currentProgress = maxStreak;
          break;
          
        case 'TOTAL':
        case 'habit_count':
          final habitCount = await _supabase
              .from('habits')
              .select('id')
              .eq('user_id', userId)
              .eq('is_active', true);
          currentProgress = habitCount.length;
          break;
          
        case 'first_habit_completion':
          // FIXED: Filter berdasarkan user_id
          final completedHabits = await _supabase
              .from('daily_logs')
              .select('''
                id,
                habits!inner(user_id)
              ''')
              .eq('status', 'success')
              .eq('habits.user_id', userId)  // Filter user_id
              .limit(1);
          currentProgress = completedHabits.isNotEmpty ? 1 : 0;
          break;
          
        case 'morning_completion':
          // FIXED: Filter berdasarkan user_id
          final completions = await _supabase
              .from('daily_logs')
              .select('''
                created_at,
                habits!inner(user_id)
              ''')
              .eq('status', 'success')
              .eq('habits.user_id', userId);  // Filter user_id
          int morningCount = 0;
          for (final completion in completions) {
            final createdAt = DateTime.parse(completion['created_at'] as String);
            if (createdAt.hour < 8) morningCount++;
          }
          currentProgress = morningCount;
          break;
          
        case 'category_variety':
          final categories = await _supabase
              .from('habits')
              .select('category_id')
              .eq('user_id', userId)
              .eq('is_active', true);
          final uniqueCategories = categories
              .where((c) => c['category_id'] != null)
              .map((c) => c['category_id'])
              .toSet();
          currentProgress = uniqueCategories.length;
          break;
          
        default:
          currentProgress = 0;
      }

      final percentage = triggerValue > 0 
          ? (currentProgress / triggerValue * 100).toInt() 
          : 0;

      return {
        'badge': badgeDetails,
        'progress': {'current': currentProgress, 'target': triggerValue},
        'percentage': percentage,
      };
    } catch (e, stack) {
      // debugPrint('❌ Error getting badge progress: $e');
      // debugPrint('Stack trace: $stack');
      return {
        'badge': null, 
        'progress': {'current': 0, 'target': 1}, 
        'percentage': 0
      };
    }
  }

  // Helper method untuk menghitung streak habit
  Future<int> _calculateHabitStreak(int habitId) async {
    try {
      final completedLogs = await _supabase
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
        
        if (difference == streak) {
          streak++;
        } else {
          break;
        }
      }
      
      return streak;
    } catch (e) {
      // debugPrint('Error calculating habit streak: $e');
      return 0;
    }
  }

  // Reset semua badge user (dibuat method baru di BadgeService)
  Future<void> resetUserBadges(String userId) async {
    try {
      await _resetUserBadgesInSupabase(userId);
      // debugPrint('🔄 Reset all badges for user: $userId');
    } catch (e, stack) {
      // debugPrint('❌ Error resetting badges: $e');
      // debugPrint('Stack trace: $stack');
    }
  }

  // Helper method untuk reset badges
  Future<void> _resetUserBadgesInSupabase(String userId) async {
    try {
      final profileResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();
      
      final profileId = profileResponse['id'] as int;

      await _supabase
          .from('user_badges')
          .delete()
          .eq('profile_id', profileId);

      // debugPrint('✅ User badges reset for profile $profileId');
    } catch (e, stack) {
      // debugPrint('❌ Error resetting user badges in Supabase: $e');
      // debugPrint('Stack trace: $stack');
    }
  }
}