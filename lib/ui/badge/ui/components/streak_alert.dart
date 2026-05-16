// lib\ui\badge\ui\components\streak_alert.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/ui/badge/providers/badge_profile_provider.dart';

class StreakAlert extends ConsumerWidget {
  const StreakAlert({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return userProfileAsync.when(
      loading: () => Container(),
      error: (error, stack) => Container(),
      data: (profile) {
        final streak = profile.streak;
        
        // Hanya tampilkan jika ada streak
        if (streak <= 0) return Container();
        
        return _buildStreakAlert(streak);
      },
    );
  }

  Widget _buildStreakAlert(int streak) {
    final daysText = streak == 1 ? 'day' : 'days';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$streak $daysText streak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getStreakMessage(streak),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getStreakDescription(streak),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getStreakMessage(int streak) {
    if (streak >= 7) return '🔥 Amazing! $streak Day Streak!';
    if (streak >= 3) return '⚡ Great $streak Day Streak!';
    return '📈 $streak Day Streak - Keep Going!';
  }

  String _getStreakDescription(int streak) {
    if (streak >= 7) return 'You\'re on fire! Maintain this incredible consistency!';
    if (streak >= 3) return 'You\'re building great habits. Just a few more days for the next achievement!';
    return 'Start your journey strong. Complete your habit tomorrow to continue your streak!';
  }
}