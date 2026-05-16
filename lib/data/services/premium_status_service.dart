// lib\data\services\premium_status_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purewill/data/repository/plan_repository.dart';

class PremiumStatusService {
  final SupabaseClient _supabase;
  final PlanRepository _planRepository;

  PremiumStatusService()
      : _supabase = Supabase.instance.client,
        _planRepository = PlanRepository();

  // Cek dan update status premium secara berkala
  Future<void> checkAndUpdatePremiumStatus() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Cek apakah subscription masih aktif
      final isActive = await _planRepository.isSubscriptionActive(user.id);
      
      // Update profile jika status berubah
      final currentProfile = await _planRepository.getUserProfileWithPremiumStatus();
      final currentIsPremium = currentProfile?.isPremiumUser ?? false;

      if (isActive != currentIsPremium) {
        await _planRepository.syncPremiumStatus();
        // print('🔄 Premium status updated: $currentIsPremium -> $isActive');
      }

    } catch (e) {
      print('Error checking premium status: $e');
    }
  }

  void startPeriodicCheck() {
    // Cek setiap 24 jam
    Future.delayed(const Duration(hours: 24), () async {
      await checkAndUpdatePremiumStatus();
      startPeriodicCheck(); // Recursive call
    });
  }

  // Cek premium status untuk fitur tertentu
  Future<bool> canAccessFeature(String feature) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final isPremium = await _planRepository.isUserPremium(user.id);
    
    // Map fitur-fitur yang membutuhkan premium
    final premiumFeatures = {
      'habit_tracker_premium': true,
      'smart_reminder': true,
      'psychology_consultation': true,
      'exclusive_community': true,
      'extended_history': true,
    };

    // Jika fitur ada di daftar premium, cek status user
    if (premiumFeatures.containsKey(feature)) {
      return isPremium;
    }

    return true; // Fitur non-premium bisa diakses semua
  }
}