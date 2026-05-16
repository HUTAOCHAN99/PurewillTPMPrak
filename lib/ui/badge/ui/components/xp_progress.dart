// lib\ui\badge\ui\components\xp_progress.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/ui/badge/providers/badge_profile_provider.dart';

class XpProgress extends ConsumerWidget {
  const XpProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return userProfileAsync.when(
      loading: () => _buildLoading(),
      error: (error, stack) => _buildError(),
      data: (profile) => _buildContent(profile),
    );
  }

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Center(
        child: Text(
          'Failed to load XP data',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildContent(UserProfile profile) {
    final xpNeeded = profile.xpNeeded;
    final level = profile.level;
    final currentXP = profile.currentXP;
    final xpToNextLevel = profile.xpToNextLevel;
    final progressPercentage = (profile.progressPercentage * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$xpNeeded XP needed for level ${level + 1}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildXpStat(level.toString(), 'Level', Colors.purple),
              const SizedBox(width: 16),
              _buildXpStat('$currentXP', 'Current XP', Colors.green),
              const SizedBox(width: 16),
              _buildXpStat('$xpToNextLevel', 'Next Level', Colors.blue),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${profile.xpDisplay} ($progressPercentage%)',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}