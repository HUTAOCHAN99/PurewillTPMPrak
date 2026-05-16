import 'package:flutter/material.dart' hide Badge;
import 'package:purewill/domain/model/badge_model.dart';

class BadgeUtils {
  static Color getBadgeColor(String triggerType) {
    const colorMap = <String, Color>{
      'STREAK': Colors.amber,
      'TOTAL': Colors.blue,
      'CONSISTENCY': Colors.green,
      'TIME_OF_DAY': Colors.orange,
      'META_HABITS': Colors.purple,
      'streak': Colors.amber,
      'habit_count': Colors.blue,
      'perfect_week': Colors.green,
      'category_variety': Colors.purple,
      'morning_completion': Colors.orange,
      'first_habit_completion': Colors.red, // New color for first completion
    };
    return colorMap[triggerType] ?? const Color(0xFF7C3AED);
  }

  static IconData getBadgeIcon(String triggerType) {
    const iconMap = <String, IconData>{
      'STREAK': Icons.auto_awesome,
      'streak': Icons.auto_awesome,
      'TOTAL': Icons.emoji_events,
      'habit_count': Icons.emoji_events,
      'CONSISTENCY': Icons.check_circle,
      'perfect_week': Icons.check_circle,
      'TIME_OF_DAY': Icons.access_time,
      'morning_completion': Icons.access_time,
      'META_HABITS': Icons.explore,
      'category_variety': Icons.explore,
      'first_habit_completion': Icons.celebration, // New icon for first completion
    };
    return iconMap[triggerType] ?? Icons.star;
  }

  static String getProgressText(Badge badge) {
    const textMap = <String, String>{
      'STREAK': 'days needed',
      'streak': 'days needed',
      'TOTAL': 'habits needed',
      'habit_count': 'habits needed',
      'CONSISTENCY': 'days perfect',
      'perfect_week': 'days perfect',
      'TIME_OF_DAY': 'days before 8 AM',
      'morning_completion': 'days before 8 AM',
      'META_HABITS': 'categories needed',
      'category_variety': 'categories needed',
      'first_habit_completion': 'complete first habit',
    };

    final template = textMap[badge.triggerType] ?? 'Complete to unlock';
    
    if (badge.triggerType == 'first_habit_completion') {
      return badge.isUnlocked ? 'Completed!' : template;
    }
    
    return '${badge.progress}/${badge.triggerValue} $template';
  }

  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Calculate progress percentage for progress bars
  static double getProgressPercentage(Badge badge) {
    if (badge.isUnlocked) return 1.0;
    if (badge.triggerValue == 0) return 0.0;
    return (badge.progress / badge.triggerValue).clamp(0.0, 1.0);
  }
}