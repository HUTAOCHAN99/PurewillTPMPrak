// lib\domain\model\profile_model.dart
import 'package:flutter/material.dart';

class ProfileModel {
  final String id;
  final String userId;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final int level;
  final int currentXP;
  final int xpToNextLevel;
  final bool isPremiumUser;
  final int? currentPlanId; 
  final String? currentPlanName; 
  final String? subscriptionStatus; 

  ProfileModel({
    required this.id,
    required this.userId,
    required this.email,
    this.fullName,
    this.avatarUrl,
    required this.level,
    required this.currentXP,
    required this.xpToNextLevel,
    this.isPremiumUser = false,
    this.currentPlanId,
    this.currentPlanName,
    this.subscriptionStatus,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id']?.toString() ?? '', 
      userId: json["user_id"]?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      level: (json['level'] as int?) ?? 1,
      currentXP: (json['current_xp'] as int?) ?? 0,
      xpToNextLevel: (json['xp_to_next_level'] as int?) ?? 100,
      isPremiumUser: json['is_premium_user'] ?? false,
      currentPlanId: json['current_plan_id'] as int?,
      currentPlanName: json['current_plan_name'] as String?,
      subscriptionStatus: json['subscription_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'level': level,
      'current_xp': currentXP,
      'xp_to_next_level': xpToNextLevel,
      'is_premium_user': isPremiumUser,
    };
  }

  // Helper method untuk progress percentage
  double get progressPercentage {
    if (xpToNextLevel == 0) return 0.0;
    return currentXP / xpToNextLevel;
  }

  // Helper untuk menampilkan XP
  String get xpDisplay => '$currentXP/$xpToNextLevel XP';

  // Helper untuk menampilkan status membership
  String get membershipStatus {
    if (isPremiumUser) {
      return currentPlanName ?? 'Premium Member';
    }
    return 'Free Member';
  }

  // Helper untuk warna badge membership
  Color get membershipColor {
    return isPremiumUser ? Colors.deepPurple : Colors.grey;
  }

  // Helper untuk icon membership
  IconData get membershipIcon {
    return isPremiumUser ? Icons.star : Icons.star_border;
  }
}