import 'package:flutter/material.dart';
import 'package:purewill/domain/model/badge_model.dart' as models; // Use alias
import 'package:purewill/ui/badge/utils/badge_utils.dart';

class BadgeCard extends StatelessWidget {
  final models.Badge badge;
  final bool isUnlocked;

  const BadgeCard({super.key, required this.badge, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    return isUnlocked ? _buildUnlockedCard() : _buildLockedCard();
  }

  Widget _buildUnlockedCard() {
    final color = BadgeUtils.getBadgeColor(badge.triggerType);
    final icon = BadgeUtils.getBadgeIcon(badge.triggerType);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 9),
          Text(
            badge.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (badge.earnedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Earned: ${BadgeUtils.formatDate(badge.earnedAt!)}',
              style: const TextStyle(fontSize: 8, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLockedCard() {
    final progressText = BadgeUtils.getProgressText(badge);
    final progressPercentage = BadgeUtils.getProgressPercentage(badge);
    final color = BadgeUtils.getBadgeColor(badge.triggerType);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                BadgeUtils.getBadgeIcon(badge.triggerType),
                color: Colors.grey[400],
                size: 32,
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const Icon(Icons.lock, color: Colors.white, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Progress bar untuk badge yang belum unlocked
          if (badge.triggerType != 'first_habit_completion')
            LinearProgressIndicator(
              value: progressPercentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              progressText,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
