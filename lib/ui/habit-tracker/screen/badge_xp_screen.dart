import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/domain/model/badge_model.dart' as models;
import 'package:purewill/ui/badge/providers/badge_provider.dart';
import 'package:purewill/ui/badge/providers/badge_profile_provider.dart';
import 'package:purewill/ui/badge/ui/components/badge_card.dart';
import 'package:purewill/ui/badge/ui/components/level_progress.dart';
import 'package:purewill/ui/badge/ui/components/streak_alert.dart';
import 'package:purewill/ui/badge/ui/components/xp_progress.dart';

class BadgeXpScreen extends ConsumerWidget {
  const BadgeXpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(badgesProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, userProfileAsync),
      body: badgesAsync.when(
        loading: () => const _LoadingState(),
        error: (error, stack) => _ErrorState(error: error, ref: ref),
        data: (badges) =>
            _ContentState(badges: badges, userProfileAsync: userProfileAsync),
      ),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    AsyncValue<UserProfile> userProfileAsync,
  ) {
    return AppBar(
      title: const Text(
        'Badge & XP',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Display level badge dengan data real
        userProfileAsync.when(
          data: (profile) => _buildLevelBadge(profile.level),
          loading: () => _buildLoadingBadge(),
          error: (error, stack) => Container(),
        ),
      ],
    );
  }

  Widget _buildLevelBadge(int level) {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'Lvl $level',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBadge() {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      child: const SizedBox(
        width: 40,
        child: Center(
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final WidgetRef ref;

  const _ErrorState({required this.error, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Failed to load badges',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // ref.refresh(badgesProvider);
                ref.invalidate(userProfileProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentState extends ConsumerWidget {
  final List<models.Badge> badges;
  final AsyncValue<UserProfile> userProfileAsync;

  const _ContentState({required this.badges, required this.userProfileAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedBadges = badges.where((b) => b.isUnlocked).toList();
    final lockedBadges = badges.where((b) => !b.isUnlocked).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak Alert (hanya muncul jika ada streak)
          const StreakAlert(),
          const SizedBox(height: 24),

          // Level Progress dengan data user
          const LevelProgress(),
          const SizedBox(height: 24),

          // XP Progress
          const XpProgress(),
          const SizedBox(height: 24),

          // User Stats Summary
          _buildUserStatsSummary(unlockedBadges.length),
          const SizedBox(height: 24),

          // Earned Badges Section
          if (unlockedBadges.isNotEmpty) ...[
            _BadgeSection(
              title: '🏆 Earned Badges',
              subtitle: '${unlockedBadges.length} Badges Earned',
              badges: unlockedBadges,
              isUnlocked: true,
            ),
            const SizedBox(height: 24),
          ],

          // Locked Badges Section
          if (lockedBadges.isNotEmpty) ...[
            _BadgeSection(
              title: '🔒 Locked Badges',
              subtitle: '${lockedBadges.length} Badges to Earn',
              badges: lockedBadges,
              isUnlocked: false,
            ),
            const SizedBox(height: 24),
          ],

          // Progress Tips
          _buildProgressTips(),
        ],
      ),
    );
  }

  Widget _buildUserStatsSummary(int unlockedBadgesCount) {
    return userProfileAsync.when(
      data: (profile) {
        final totalBadges = badges.length;
        final progressPercentage = totalBadges > 0
            ? (unlockedBadgesCount / totalBadges * 100).toInt()
            : 0;

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
              const Text(
                'Achievement Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              // Progress Bar untuk Badges
              LinearProgressIndicator(
                value: totalBadges > 0 ? unlockedBadgesCount / totalBadges : 0,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$unlockedBadgesCount/$totalBadges badges',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '$progressPercentage% complete',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.6, // ⬅️ sebelumnya 3
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildStatCard(
                    'Level',
                    '${profile.level}',
                    Icons.star,
                    Colors.amber,
                  ),
                  _buildStatCard(
                    'Current XP',
                    '${profile.currentXP}',
                    Icons.bolt,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Next Level',
                    '${profile.xpToNextLevel} XP',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Streak',
                    '${profile.streak} days',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => _buildLoadingStats(),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: Text(
            'Unable to load stats',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF7C3AED),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTips() {
    final lockedBadges = badges.where((b) => !b.isUnlocked).toList();

    if (lockedBadges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withAlpha(60)),
        ),
        child: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.green),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '🎉 Congratulations! You\'ve earned all badges!',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // PERBAIKAN: Ambil 3 badge terdekat untuk didapatkan TANPA cascade operator
    List<models.Badge> getNearestBadges() {
      final filtered = lockedBadges
          .where((badge) => badge.progress > 0)
          .toList();

      // Sort berdasarkan progress tertinggi
      filtered.sort((a, b) {
        final progressA = a.progress / a.triggerValue;
        final progressB = b.progress / b.triggerValue;
        return progressB.compareTo(progressA);
      });

      // Ambil maksimal 3
      return filtered.take(3).toList();
    }

    final nearestBadges = getNearestBadges();

    if (nearestBadges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withAlpha(60)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Quick Start Tips',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '• Complete your first habit to earn "First Steps" badge\n'
              '• Create 3 active habits to earn "Habit Collector"\n'
              '• Complete a habit before 8 AM for "Early Bird"',
              style: TextStyle(color: Colors.blue, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Almost There!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Gunakan List.generate untuk menghindari error spread
          ...List.generate(nearestBadges.length, (index) {
            final badge = nearestBadges[index];
            final percentage = (badge.progress / badge.triggerValue * 100)
                .toInt();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badge.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: badge.progress / badge.triggerValue,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getBadgeColor(badge.triggerType),
                          ),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${badge.progress}/${badge.triggerValue} ($percentage%)',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getBadgeColor(String triggerType) {
    switch (triggerType) {
      case 'STREAK':
      case 'streak':
        return Colors.amber;
      case 'TOTAL':
      case 'habit_count':
        return Colors.blue;
      case 'perfect_week':
        return Colors.green;
      case 'category_variety':
        return Colors.purple;
      case 'morning_completion':
        return Colors.orange;
      case 'first_habit_completion':
        return Colors.red;
      default:
        return const Color(0xFF7C3AED);
    }
  }
}

class _BadgeSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<models.Badge> badges;
  final bool isUnlocked;

  const _BadgeSection({
    required this.title,
    required this.subtitle,
    required this.badges,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) =>
              BadgeCard(badge: badges[index], isUnlocked: isUnlocked),
        ),
      ],
    );
  }
}
