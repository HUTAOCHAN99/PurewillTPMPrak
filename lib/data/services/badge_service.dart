import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purewill/data/services/badge_notification_service.dart';

class BadgeService {
  final SupabaseClient _supabase;
  final BadgeNotificationService _badgeNotificationService;

  BadgeService(this._supabase, this._badgeNotificationService);

  // Initialize badge notification service
  Future<void> initializeNotificationService({Function(String?)? onBadgeTap}) async {
    await _badgeNotificationService.initialize(onBadgeNotificationTap: onBadgeTap);
  }

  // Check all badges periodically atau manual trigger - REAL WORKING VERSION
  Future<void> checkAllBadges(String userId) async {
    try {
      // debugPrint('🎯 === REAL BADGE CHECK STARTED ===');
      // debugPrint('👤 User ID: $userId');

      // Get user's profile ID
      final profileResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();
      
      final profileId = profileResponse['id'] as int;
      // debugPrint('📋 Profile ID: $profileId');

      // SAFETY CHECK: Pastikan user punya habits dulu
      final userHabits = await _supabase
          .from('habits')
          .select('id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();
      
      if (userHabits == null) {
        // debugPrint('⚠️ User has no habits, skipping badge check');
        return;
      }

      List<Map<String, dynamic>> newlyEarnedBadges = [];

      // Check different badge types dengan logging detail
      // debugPrint('🔍 Checking first habit completion...');
      final firstHabitBadge = await _checkFirstHabitCompletion(profileId, userId);
      if (firstHabitBadge != null) {
        newlyEarnedBadges.add(firstHabitBadge);
        // debugPrint('✅ First habit badge qualified');
      }

      // debugPrint('🔍 Checking habit count badges...');
      final habitCountBadges = await _checkHabitCountBadges(profileId, userId);
      newlyEarnedBadges.addAll(habitCountBadges);
      // debugPrint('✅ Habit count badges found: ${habitCountBadges.length}');

      // debugPrint('🔍 Checking streak badges...');
      final streakBadges = await _checkStreakBadges(profileId, userId);
      newlyEarnedBadges.addAll(streakBadges);
      // debugPrint('✅ Streak badges found: ${streakBadges.length}');

      // debugPrint('🔍 Checking morning completion badges...');
      final morningBadges = await _checkMorningCompletionBadges(profileId, userId);
      newlyEarnedBadges.addAll(morningBadges);
      // debugPrint('✅ Morning badges found: ${morningBadges.length}');

      // debugPrint('🔍 Checking category variety badges...');
      final categoryBadges = await _checkCategoryVarietyBadges(profileId, userId);
      newlyEarnedBadges.addAll(categoryBadges);
      // debugPrint('✅ Category badges found: ${categoryBadges.length}');

      // debugPrint('🔍 Checking perfect week badges...');
      final perfectWeekBadges = await _checkPerfectWeekBadges(profileId, userId);
      newlyEarnedBadges.addAll(perfectWeekBadges);
      // debugPrint('✅ Perfect week badges found: ${perfectWeekBadges.length}');

      // debugPrint('🔍 Checking consistency badges...');
      final consistencyBadges = await _checkConsistencyBadges(profileId, userId);
      newlyEarnedBadges.addAll(consistencyBadges);
      // debugPrint('✅ Consistency badges found: ${consistencyBadges.length}');

      // debugPrint('🔍 Checking time of day badges...');
      final timeOfDayBadges = await _checkTimeOfDayBadges(profileId, userId);
      newlyEarnedBadges.addAll(timeOfDayBadges);
      // debugPrint('✅ Time of day badges found: ${timeOfDayBadges.length}');

      // Show notifications for newly earned badges
      if (newlyEarnedBadges.isNotEmpty) {
        // debugPrint('🎉 ${newlyEarnedBadges.length} new badges earned!');
        
        for (final badge in newlyEarnedBadges) {
          // debugPrint('📢 Showing notification for: ${badge['name']}');
          await _badgeNotificationService.showFloatingBadge(
            badgeName: badge['name'] as String,
            badgeDescription: badge['description'] as String,
            badgeId: badge['id'] as int,
          );
          
          // Tunggu 1 detik antara notifications
          await Future.delayed(Duration(seconds: 1));
        }
        
        await _updateUserXP(userId, newlyEarnedBadges.length * 10);
      } else {
        // debugPrint('ℹ️ No new badges earned this time');
      }

      // debugPrint('✅ === REAL BADGE CHECK COMPLETED ===');

    } catch (e, stack) {
      // debugPrint('❌ Error checking badges: $e');
      // debugPrint('Stack trace: $stack');
    }
  }

  // Check first habit completion badge - FIXED: Filter user_id
  Future<Map<String, dynamic>?> _checkFirstHabitCompletion(int profileId, String userId) async {
    try {
      // Check if user already has this badge
      final existingBadge = await _supabase
          .from('user_badges')
          .select('id')
          .eq('profile_id', profileId)
          .eq('badge_id', 21)
          .maybeSingle();

      if (existingBadge != null) {
        // debugPrint('ℹ️ First habit badge already earned');
        return null;
      }

      // FIXED: Filter berdasarkan user_id melalui JOIN ke habits
      final completedHabits = await _supabase
          .from('daily_logs')
          .select('''
            id,
            habits!inner(user_id)
          ''')
          .eq('status', 'success')
          .eq('habits.user_id', userId)  // Filter user_id
          .limit(1);

      if (completedHabits.isNotEmpty) {
        await _awardBadge(profileId, 21);
        
        final badgeDetails = await _supabase
            .from('badges')
            .select('*')
            .eq('id', 21)
            .single();
        
        // debugPrint('🎯 First habit completion badge earned!');
        return badgeDetails;
      } else {
        // debugPrint('ℹ️ No completed habits found for first badge');
      }
      return null;
    } catch (e, stack) {
      // debugPrint('❌ Error checking first habit completion: $e');
      // debugPrint('Stack trace: $stack');
      return null;
    }
  }

  // Check streak badges - FIXED
  Future<List<Map<String, dynamic>>> _checkStreakBadges(int profileId, String userId) async {
    final List<Map<String, dynamic>> earnedBadges = [];
    
    try {
      final currentStreak = await _calculateCurrentStreak(userId);
      // debugPrint('📊 Current streak: $currentStreak days');

      // Get all badges dan filter manual
      final allBadges = await _supabase
          .from('badges')
          .select('id, trigger_value, name, description, image_url, trigger_type')
          .order('trigger_value', ascending: true);

      // Filter streak badges manually
      final streakBadges = allBadges.where((badge) {
        final triggerType = badge['trigger_type'] as String;
        return triggerType == 'STREAK' || triggerType == 'streak';
      }).toList();

      // debugPrint('📋 Found ${streakBadges.length} streak badges to check');

      for (final badge in streakBadges) {
        final badgeId = badge['id'] as int;
        final triggerValue = _parseToInt(badge['trigger_value']);
        
        // Check if user already has this badge
        final hasBadge = await _supabase
            .from('user_badges')
            .select('id')
            .eq('profile_id', profileId)
            .eq('badge_id', badgeId)
            .maybeSingle();

        if (hasBadge == null && currentStreak >= triggerValue) {
          await _awardBadge(profileId, badgeId);
          earnedBadges.add(badge);
          // debugPrint('🏆 Streak badge $badgeId earned for $currentStreak days!');
        } else if (hasBadge != null) {
          // debugPrint('ℹ️ Streak badge $badgeId already earned');
        } else {
          // debugPrint('ℹ️ Streak badge $badgeId not qualified (need $triggerValue, have $currentStreak)');
        }
      }
    } catch (e, stack) {
      // debugPrint('❌ Error checking streak badges: $e');
      // debugPrint('Stack trace: $stack');
    }
    
    return earnedBadges;
  }

  // Check habit count badges - FIXED
  Future<List<Map<String, dynamic>>> _checkHabitCountBadges(int profileId, String userId) async {
    final List<Map<String, dynamic>> earnedBadges = [];
    
    try {
      final habitCount = await _supabase
          .from('habits')
          .select('id')
          .eq('user_id', userId)
          .eq('is_active', true);

      final currentCount = habitCount.length;
      // debugPrint('📊 Current active habits: $currentCount');
      
      // Get all badges dan filter manual
      final allBadges = await _supabase
          .from('badges')
          .select('id, trigger_value, name, description, image_url, trigger_type')
          .order('trigger_value', ascending: true);

      final countBadges = allBadges.where((badge) {
        final triggerType = badge['trigger_type'] as String;
        return triggerType == 'habit_count' || triggerType == 'META_HABITS';
      }).toList();

      // debugPrint('📋 Found ${countBadges.length} habit count badges to check');

      for (final badge in countBadges) {
        final badgeId = badge['id'] as int;
        final triggerValue = _parseToInt(badge['trigger_value']);
        
        final hasBadge = await _supabase
            .from('user_badges')
            .select('id')
            .eq('profile_id', profileId)
            .eq('badge_id', badgeId)
            .maybeSingle();

        if (hasBadge == null && currentCount >= triggerValue) {
          await _awardBadge(profileId, badgeId);
          earnedBadges.add(badge);
          // debugPrint('📊 Habit count badge $badgeId earned for $currentCount habits!');
        } else if (hasBadge != null) {
          // debugPrint('ℹ️ Habit count badge $badgeId already earned');
        } else {
          // debugPrint('ℹ️ Habit count badge $badgeId not qualified (need $triggerValue, have $currentCount)');
        }
      }
    } catch (e, stack) {
      // debugPrint('❌ Error checking habit count badges: $e');
      // debugPrint('Stack trace: $stack');
    }
    
    return earnedBadges;
  }

  // Check morning completion badges - FIXED: Filter user_id
  Future<List<Map<String, dynamic>>> _checkMorningCompletionBadges(int profileId, String userId) async {
    final List<Map<String, dynamic>> earnedBadges = [];
    
    try {
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
        if (createdAt.hour < 8) {
          morningCount++;
        }
      }

      // debugPrint('🌅 Morning completions (before 8 AM): $morningCount');

      // Query badges dengan trigger_type morning_completion
      final morningBadges = await _supabase
          .from('badges')
          .select('id, trigger_value, name, description, image_url')
          .eq('trigger_type', 'morning_completion')
          .order('trigger_value', ascending: true);

      // debugPrint('📋 Found ${morningBadges.length} morning completion badges to check');

      for (final badge in morningBadges) {
        final badgeId = badge['id'] as int;
        final triggerValue = _parseToInt(badge['trigger_value']);
        
        final hasBadge = await _supabase
            .from('user_badges')
            .select('id')
            .eq('profile_id', profileId)
            .eq('badge_id', badgeId)
            .maybeSingle();

        if (hasBadge == null && morningCount >= triggerValue) {
          await _awardBadge(profileId, badgeId);
          earnedBadges.add(badge);
          // debugPrint('🌅 Morning completion badge $badgeId earned for $morningCount completions!');
        } else if (hasBadge != null) {
          // debugPrint('ℹ️ Morning badge $badgeId already earned');
        } else {
          // debugPrint('ℹ️ Morning badge $badgeId not qualified (need $triggerValue, have $morningCount)');
        }
      }
    } catch (e, stack) {
      // debugPrint('❌ Error checking morning completion badges: $e');
      // debugPrint('Stack trace: $stack');
    }
    
    return earnedBadges;
  }

  // Check category variety badges - FIXED
  Future<List<Map<String, dynamic>>> _checkCategoryVarietyBadges(int profileId, String userId) async {
    final List<Map<String, dynamic>> earnedBadges = [];
    
    try {
      final categories = await _supabase
          .from('habits')
          .select('category_id')
          .eq('user_id', userId)
          .eq('is_active', true);

      final uniqueCategories = categories
          .where((c) => c['category_id'] != null)
          .map((c) => c['category_id'])
          .toSet();

      final categoryCount = uniqueCategories.length;
      // debugPrint('🏷️ Unique categories used: $categoryCount');

      // Get all badges dan filter manual
      final allBadges = await _supabase
          .from('badges')
          .select('id, trigger_value, name, description, image_url, trigger_type')
          .order('trigger_value', ascending: true);

      final categoryBadges = allBadges.where((badge) {
        final triggerType = badge['trigger_type'] as String;
        return triggerType == 'category_variety' || triggerType == 'META_HABITS';
      }).toList();

      // debugPrint('📋 Found ${categoryBadges.length} category badges to check');

      for (final badge in categoryBadges) {
        final badgeId = badge['id'] as int;
        final triggerValue = _parseToInt(badge['trigger_value']);
        
        final hasBadge = await _supabase
            .from('user_badges')
            .select('id')
            .eq('profile_id', profileId)
            .eq('badge_id', badgeId)
            .maybeSingle();

        if (hasBadge == null && categoryCount >= triggerValue) {
          await _awardBadge(profileId, badgeId);
          earnedBadges.add(badge);
          // debugPrint('🏷️ Category variety badge $badgeId earned for $categoryCount categories!');
        } else if (hasBadge != null) {
          // debugPrint('ℹ️ Category badge $badgeId already earned');
        } else {
          // debugPrint('ℹ️ Category badge $badgeId not qualified (need $triggerValue, have $categoryCount)');
        }
      }
    } catch (e, stack) {
      // debugPrint('❌ Error checking category variety badges: $e');
      // debugPrint('Stack trace: $stack');
    }
    
    return earnedBadges;
  }

  // Check perfect week badges - FIXED
  Future<List<Map<String, dynamic>>> _checkPerfectWeekBadges(int profileId, String userId) async {
    final List<Map<String, dynamic>> earnedBadges = [];
    
    try {
      final perfectWeeks = await _getPerfectWeeksCount(userId);
      // debugPrint('⭐ Perfect weeks completed: $perfectWeeks');

      // Get all badges dan filter manual
      final allBadges = await _supabase
          .from('badges')
          .select('id, trigger_value, name, description, image_url, trigger_type')
          .order('trigger_value', ascending: true);

      final perfectWeekBadges = allBadges.where((badge) {
        final triggerType = badge['trigger_type'] as String;
        return triggerType == 'perfect_week' || triggerType == 'CONSISTENCY';
      }).toList();

      // debugPrint('📋 Found ${perfectWeekBadges.length} perfect week badges to check');

      for (final badge in perfectWeekBadges) {
        final badgeId = badge['id'] as int;
        final triggerValue = _parseToInt(badge['trigger_value']);
        
        final hasBadge = await _supabase
            .from('user_badges')
            .select('id')
            .eq('profile_id', profileId)
            .eq('badge_id', badgeId)
            .maybeSingle();

        if (hasBadge == null && perfectWeeks >= triggerValue) {
          await _awardBadge(profileId, badgeId);
          earnedBadges.add(badge);
          // debugPrint('⭐ Perfect week badge $badgeId earned for $perfectWeeks weeks!');
        } else if (hasBadge != null) {
          // debugPrint('ℹ️ Perfect week badge $badgeId already earned');
        } else {
          // debugPrint('ℹ️ Perfect week badge $badgeId not qualified (need $triggerValue, have $perfectWeeks)');
        }
      }
    } catch (e, stack) {
      // debugPrint('❌ Error checking perfect week badges: $e');
      // debugPrint('Stack trace: $stack');
    }
    
    return earnedBadges;
  }

  // Check consistency badges - FIXED: Filter user_id
  Future<List<Map<String, dynamic>>> _checkConsistencyBadges(int profileId, String userId) async {
    final List<Map<String, dynamic>> earnedBadges = [];
    
    try {
      // FIXED: Filter berdasarkan user_id
      final totalCompletions = await _supabase
          .from('daily_logs')
          .select('''
            id,
            habits!inner(user_id)
          ''')
          .eq('status', 'success')
          .eq('habits.user_id', userId);  // Filter user_id

      final completionCount = totalCompletions.length;
      // debugPrint('📈 Total habit completions: $completionCount');

      final consistencyBadges = await _supabase
          .from('badges')
          .select('id, trigger_value, name, description, image_url')
          .eq('trigger_type', 'TOTAL')
          .order('trigger_value', ascending: true);

      // debugPrint('📋 Found ${consistencyBadges.length} consistency badges to check');

      for (final badge in consistencyBadges) {
        final badgeId = badge['id'] as int;
        final triggerValue = _parseToInt(badge['trigger_value']);
        
        final hasBadge = await _supabase
            .from('user_badges')
            .select('id')
            .eq('profile_id', profileId)
            .eq('badge_id', badgeId)
            .maybeSingle();

        if (hasBadge == null && completionCount >= triggerValue) {
          await _awardBadge(profileId, badgeId);
          earnedBadges.add(badge);
          // debugPrint('📈 Consistency badge $badgeId earned for $completionCount completions!');
        } else if (hasBadge != null) {
          // debugPrint('ℹ️ Consistency badge $badgeId already earned');
        } else {
          // debugPrint('ℹ️ Consistency badge $badgeId not qualified (need $triggerValue, have $completionCount)');
        }
      }
    } catch (e, stack) {
      // debugPrint('❌ Error checking consistency badges: $e');
      // debugPrint('Stack trace: $stack');
    }
    
    return earnedBadges;
  }

  // Check time of day badges - FIXED: Filter user_id
  Future<List<Map<String, dynamic>>> _checkTimeOfDayBadges(int profileId, String userId) async {
    final List<Map<String, dynamic>> earnedBadges = [];
    
    try {
      // FIXED: Filter berdasarkan user_id
      final completions = await _supabase
          .from('daily_logs')
          .select('''
            created_at,
            habits!inner(user_id)
          ''')
          .eq('status', 'success')
          .eq('habits.user_id', userId);  // Filter user_id

      int earlyBirdCount = 0;
      int nightOwlCount = 0;

      for (final completion in completions) {
        final createdAt = DateTime.parse(completion['created_at'] as String);
        if (createdAt.hour < 8) {
          earlyBirdCount++;
        }
        if (createdAt.hour >= 21) {
          nightOwlCount++;
        }
      }

      // debugPrint('🐦 Early bird completions: $earlyBirdCount');
      // debugPrint('🦉 Night owl completions: $nightOwlCount');

      // Early Bird badge (ID 13)
      final hasEarlyBird = await _supabase
          .from('user_badges')
          .select('id')
          .eq('profile_id', profileId)
          .eq('badge_id', 13)
          .maybeSingle();

      if (hasEarlyBird == null && earlyBirdCount >= 1) {
        await _awardBadge(profileId, 13);
        final badgeDetails = await _supabase
            .from('badges')
            .select('*')
            .eq('id', 13)
            .single();
        earnedBadges.add(badgeDetails);
        // debugPrint('🐦 Early Bird badge earned!');
      } else if (hasEarlyBird != null) {
        // debugPrint('ℹ️ Early Bird badge already earned');
      } else {
        // debugPrint('ℹ️ Early Bird badge not qualified (need 1, have $earlyBirdCount)');
      }

      // Night Owl badge (ID 14)
      final hasNightOwl = await _supabase
          .from('user_badges')
          .select('id')
          .eq('profile_id', profileId)
          .eq('badge_id', 14)
          .maybeSingle();

      if (hasNightOwl == null && nightOwlCount >= 1) {
        await _awardBadge(profileId, 14);
        final badgeDetails = await _supabase
            .from('badges')
            .select('*')
            .eq('id', 14)
            .single();
        earnedBadges.add(badgeDetails);
        // debugPrint('🦉 Night Owl badge earned!');
      } else if (hasNightOwl != null) {
        // debugPrint('ℹ️ Night Owl badge already earned');
      } else {
        // debugPrint('ℹ️ Night Owl badge not qualified (need 1, have $nightOwlCount)');
      }
    } catch (e, stack) {
      // debugPrint('❌ Error checking time of day badges: $e');
      // debugPrint('Stack trace: $stack');
    }
    
    return earnedBadges;
  }

  // Update user XP when earning badges
  Future<void> _updateUserXP(String userId, int xpEarned) async {
    try {
      // Get current user profile
      final profileResponse = await _supabase
          .from('profiles')
          .select('current_xp, level, xp_to_next_level')
          .eq('user_id', userId)
          .single();

      int currentXP = profileResponse['current_xp'] as int;
      int currentLevel = profileResponse['level'] as int;
      int xpToNextLevel = profileResponse['xp_to_next_level'] as int;

      // Calculate new XP and check for level up
      int newXP = currentXP + xpEarned;
      int newLevel = currentLevel;
      int newXPToNextLevel = xpToNextLevel;

      // Level up logic
      while (newXP >= newXPToNextLevel) {
        newXP -= newXPToNextLevel;
        newLevel++;
        newXPToNextLevel = (newXPToNextLevel * 1.2).round(); // Increase required XP by 20%
      }

      // Update profile
      await _supabase
          .from('profiles')
          .update({
            'current_xp': newXP,
            'level': newLevel,
            'xp_to_next_level': newXPToNextLevel,
          })
          .eq('user_id', userId);

      // debugPrint('📈 User XP updated: +$xpEarned XP, Level $newLevel ($newXP/$newXPToNextLevel XP)');
    } catch (e, stack) {
      // debugPrint('❌ Error updating user XP: $e');
      // debugPrint('Stack trace: $stack');
    }
  }

  // Manual trigger untuk badge tertentu
  Future<void> manuallyAwardBadge(String userId, int badgeId) async {
    try {
      // debugPrint('🎯 Manually awarding badge $badgeId to user $userId');
      
      final profileResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();
      
      final profileId = profileResponse['id'] as int;

      // Check if badge exists
      final badgeExists = await _supabase
          .from('badges')
          .select('id')
          .eq('id', badgeId)
          .maybeSingle();

      if (badgeExists == null) {
        // debugPrint('❌ Badge $badgeId does not exist');
        return;
      }

      await _awardBadge(profileId, badgeId);
      
      // Get badge details for notification
      final badgeDetails = await _supabase
          .from('badges')
          .select('*')
          .eq('id', badgeId)
          .single();
      
      await _badgeNotificationService.showFloatingBadge(
        badgeName: badgeDetails['name'] as String,
        badgeDescription: badgeDetails['description'] as String,
        badgeId: badgeId,
      );
      
      // Update XP
      await _updateUserXP(userId, 10);
      
      // debugPrint('✅ Badge $badgeId manually awarded!');
    } catch (e, stack) {
      // debugPrint('❌ Error manually awarding badge: $e');
      // debugPrint('Stack trace: $stack');
    }
  }

  // Award badge to user - DENGAN LOGGING DETAIL
  Future<void> _awardBadge(int profileId, int badgeId) async {
    try {
      // First, check if badge already exists to avoid duplicates
      final existingBadge = await _supabase
          .from('user_badges')
          .select('id')
          .eq('profile_id', profileId)
          .eq('badge_id', badgeId)
          .maybeSingle();

      if (existingBadge != null) {
        // debugPrint('ℹ️ Badge $badgeId already awarded to profile $profileId');
        return;
      }

      // debugPrint('🏆 Awarding badge $badgeId to profile $profileId...');

      // Insert new badge
      final response = await _supabase
          .from('user_badges')
          .insert({
            'profile_id': profileId,
            'badge_id': badgeId,
            'earned_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select();
      
      // debugPrint('✅ Badge $badgeId awarded to profile $profileId');
      // debugPrint('📝 Insert response: $response');
    } catch (e, stack) {
      // debugPrint('❌ Error awarding badge: $e');
      // debugPrint('Stack trace: $stack');
    }
  }

  // Calculate current streak
  Future<int> _calculateCurrentStreak(String userId) async {
    try {
      // Get user's active habits
      final activeHabits = await _supabase
          .from('habits')
          .select('id')
          .eq('user_id', userId)
          .eq('is_active', true);

      if (activeHabits.isEmpty) return 0;

      int maxStreak = 0;
      
      // Calculate streak for each habit and take the maximum
      for (final habit in activeHabits) {
        final habitId = habit['id'] as int;
        final habitStreak = await _calculateHabitStreak(habitId);
        if (habitStreak > maxStreak) {
          maxStreak = habitStreak;
        }
      }
      
      // debugPrint('📈 Max streak across all habits: $maxStreak days');
      return maxStreak;
    } catch (e, stack) {
      // debugPrint('❌ Error calculating current streak: $e');
      // debugPrint('Stack trace: $stack');
      return 0;
    }
  }

  // Calculate habit streak
  Future<int> _calculateHabitStreak(int habitId) async {
    try {
      // Get completed logs ordered by date descending
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
        
        // If it's today or consecutive days, continue streak
        if (difference == streak) {
          streak++;
        } else {
          break;
        }
      }
      
      return streak;
    } catch (e, stack) {
      // debugPrint('❌ Error calculating habit streak: $e');
      // debugPrint('Stack trace: $stack');
      return 0;
    }
  }

  // Get perfect weeks count - FIXED: Filter user_id
  Future<int> _getPerfectWeeksCount(String userId) async {
    try {
      // FIXED: Filter berdasarkan user_id
      final completedLogs = await _supabase
          .from('daily_logs')
          .select('''
            log_date,
            habits!inner(user_id)
          ''')
          .eq('status', 'success')
          .eq('habits.user_id', userId);  // Filter user_id
      
      // Group by week
      final weeks = <String, Set<String>>{};
      
      for (final log in completedLogs) {
        final date = DateTime.parse(log['log_date'] as String);
        final weekKey = '${date.year}-W${_getWeekNumber(date)}';
        final dateKey = '${date.year}-${date.month}-${date.day}';
        
        if (!weeks.containsKey(weekKey)) {
          weeks[weekKey] = <String>{};
        }
        weeks[weekKey]!.add(dateKey);
      }
      
      // Consider a week perfect if at least 7 unique days
      int perfectWeeks = 0;
      for (final weekDays in weeks.values) {
        if (weekDays.length >= 7) {
          perfectWeeks++;
        }
      }
      
      return perfectWeeks;
    } catch (e, stack) {
      // debugPrint('❌ Error calculating perfect weeks: $e');
      // debugPrint('Stack trace: $stack');
      return 0;
    }
  }

  // Get week number
  int _getWeekNumber(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    final diff = date.difference(firstDay).inDays;
    return (diff / 7).ceil();
  }

  // Show progress notification untuk badge yang hampir didapat
  Future<void> showBadgeProgress(String userId, int badgeId) async {
    try {
      final badgeDetails = await _supabase
          .from('badges')
          .select('*')
          .eq('id', badgeId)
          .single();

      final progress = await _getBadgeProgress(userId, badgeDetails);
      
      await _badgeNotificationService.showProgressNotification(
        badgeName: badgeDetails['name'] as String,
        currentProgress: progress['current'] ?? 0,
        targetProgress: progress['target'] ?? 1,
        progressType: badgeDetails['trigger_type'] as String,
      );
    } catch (e, stack) {
      // debugPrint('❌ Error showing badge progress: $e');
      // debugPrint('Stack trace: $stack');
    }
  }

  // Helper method untuk parse dynamic ke int
  int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return 0;
  }

  // Helper method untuk progress calculation - FIXED: Filter user_id
  Future<Map<String, int>> _getBadgeProgress(String userId, Map<String, dynamic> badge) async {
    final triggerType = badge['trigger_type'] as String;
    final int triggerValue = _parseToInt(badge['trigger_value']);
    
    int currentProgress = 0;

    switch (triggerType) {
      case 'STREAK':
      case 'streak':
        currentProgress = await _calculateCurrentStreak(userId);
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
      case 'morning_completion':
        // FIXED: Filter berdasarkan user_id
        final completions = await _supabase
            .from('daily_logs')
            .select('''
              *,
              habits!inner(user_id)
            ''')
            .eq('status', 'success')
            .eq('habits.user_id', userId);  // Filter user_id
        int morningCount = 0;
        for (final completion in completions) {
          final createdAt = DateTime.parse(completion['created_at'] as String);
          if (createdAt.hour < 8) {
            morningCount++;
          }
        }
        currentProgress = morningCount;
        break;
      case 'META_HABITS':
      case 'category_variety':
        final categories = await _supabase
            .from('habits')
            .select('category_id')
            .eq('user_id', userId)
            .eq('is_active', true);
        final uniqueCategories = categories
            .where((c) => c['category_id'] != null)
            .map((c) => c['category_id'] as int)
            .toSet();
        currentProgress = uniqueCategories.length;
        break;
      case 'CONSISTENCY':
      case 'perfect_week':
        currentProgress = await _getPerfectWeeksCount(userId);
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
      default:
        currentProgress = 0;
    }

    return {
      'current': currentProgress,
      'target': triggerValue,
    };
  }

  // Get user profile with XP and level
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select('*')
          .eq('user_id', userId)
          .single();
      
      return profile;
    } catch (e, stack) {
      // debugPrint('❌ Error getting user profile: $e');
      // debugPrint('Stack trace: $stack');
      return null;
    }
  }

  // Get all user badges with details
  Future<List<Map<String, dynamic>>> getUserBadges(String userId) async {
    try {
      final profileResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();
      
      final profileId = profileResponse['id'] as int;

      final userBadges = await _supabase
          .from('user_badges')
          .select('''
            *,
            badges(*)
          ''')
          .eq('profile_id', profileId)
          .order('earned_at', ascending: false);

      return userBadges;
    } catch (e, stack) {
      // debugPrint('❌ Error getting user badges: $e');
      // debugPrint('Stack trace: $stack');
      return [];
    }
  }

  // Get all available badges
  Future<List<Map<String, dynamic>>> getAllBadges() async {
    try {
      final badges = await _supabase
          .from('badges')
          .select('*')
          .order('trigger_value', ascending: true);

      return badges;
    } catch (e, stack) {
      // debugPrint('❌ Error getting all badges: $e');
      // debugPrint('Stack trace: $stack');
      return [];
    }
  }

  // Get user badge count
  Future<int> getUserBadgeCount(String userId) async {
    try {
      final badges = await getUserBadges(userId);
      return badges.length;
    } catch (e) {
      // debugPrint('❌ Error getting badge count: $e');
      return 0;
    }
  }
}