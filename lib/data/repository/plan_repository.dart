// lib\data\repository\plan_repository.dart
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/domain/model/plan_model.dart';
import 'package:purewill/domain/model/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository();
});

class PlanRepository {
  final supabase = Supabase.instance.client;

  Future<List<PlanModel>> getPlans() async {
    try {
      final response = await supabase
          .from('plans')
          .select()
          .eq('is_active', true)
          .order('price', ascending: true);

      // if (response == null) return [];

      return (response as List)
          .map((json) => PlanModel.fromJson(json))
          .toList();
    } catch (e) {
      // print('Error getting plans: $e');
      return _getDefaultPlans();
    }
  }

  Future<PlanModel?> getPlanById(int planId) async {
    try {
      final response = await supabase
          .from('plans')
          .select()
          .eq('id', planId)
          .single();

      // if (response == null) return null;
      return PlanModel.fromJson(response);
    } catch (e) {
      // print('Error getting plan: $e');
      return null;
    }
  }

  // Metode baru: Cek apakah user premium
  Future<bool> isUserPremium(String userId) async {
    try {
      // print('🔍 Checking premium status for user: $userId');

      // Query langsung dari profiles
      final response = await supabase
          .from('profiles')
          .select('is_premium_user, current_plan_id')
          .eq('user_id', userId)
          .single();

      final isPremium = response['is_premium_user'] ?? false;
      final planId = response['current_plan_id'];

      // print(
        // '📊 Premium check - is_premium_user: $isPremium, current_plan_id: $planId',
      // );

      return isPremium;
    } catch (e) {
      // print('❌ Error checking premium status: $e');
      return false;
    }
  }

  // Metode baru: Get user profile dengan status premium
  Future<ProfileModel?> getUserProfileWithPremiumStatus() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      // Join profiles dengan user_subscriptions
      final response = await supabase
          .from('profiles')
          .select('*, user_subscriptions!inner(*)')
          .eq('user_id', user.id)
          .eq('user_subscriptions.status', 'active')
          .maybeSingle();

      if (response == null) {
        // Cek hanya profile jika tidak ada subscription
        final profileResponse = await supabase
            .from('profiles')
            .select()
            .eq('user_id', user.id)
            .single();

        return ProfileModel.fromJson(profileResponse);
      }

      return ProfileModel.fromJson(response);
    } catch (e) {
      // print('Error getting user profile with premium: $e');
      return null;
    }
  }

  Future<PlanModel?> getCurrentUserPlan() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        // print('❌ No user logged in');
        return null;
      }

      // print('🔍 Getting current plan for user: ${user.id}');

      // Query 1: Coba dengan join langsung
      final response = await supabase
          .from('user_subscriptions')
          .select('''
          *,
          plans!inner(*)
        ''')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .maybeSingle();

      // print('📊 Query 1 result: $response');

      if (response != null && response['plans'] != null) {
        final planData = response['plans'] as Map<String, dynamic>;
        // print('✅ Found plan: ${planData['name']}');
        return PlanModel.fromJson(planData);
      }

      // Query 2: Coba dengan profiles.current_plan_id
      // print('🔄 Trying fallback query...');
      final profileResponse = await supabase
          .from('profiles')
          .select('current_plan_id')
          .eq('user_id', user.id)
          .single();

      final planId = profileResponse['current_plan_id'];
      // print('📊 Profile current_plan_id: $planId');

      if (planId != null) {
        final plan = await getPlanById(planId as int);
        // print('✅ Found plan via profile: ${plan?.name}');
        return plan;
      }

      // print('⚠️ No active plan found');
      return null;
    } catch (e) {
      // print('❌ Error in getCurrentUserPlan: $e');
      // print('Stack trace: ${e.toString()}');
      return null;
    }
  }

  Future<void> subscribeToPlan(int planId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Dapatkan data plan
      final plan = await getPlanById(planId);
      if (plan == null) throw Exception('Plan not found');

      final isPremium = plan.type != 'free';

      // Check if user already has active subscription
      final existingSub = await supabase
          .from('user_subscriptions')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'active')
          .maybeSingle();

      if (existingSub != null) {
        // Update existing subscription
        await supabase
            .from('user_subscriptions')
            .update({
              'plan_id': planId,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingSub['id']);
      } else {
        // Create new subscription
        await supabase.from('user_subscriptions').insert({
          'user_id': user.id,
          'plan_id': planId,
          'status': 'active',
          'start_date': DateTime.now().toIso8601String(),
          'end_date': plan.type == 'yearly'
              ? DateTime.now().add(Duration(days: 365)).toIso8601String()
              : DateTime.now().add(Duration(days: 30)).toIso8601String(),
        });
      }

      // Update user profile dengan status premium
      await supabase
          .from('profiles')
          .update({
            'is_premium_user': isPremium,
            'current_plan_id': planId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id);

      // print(
        // '✅ User ${user.id} upgraded to ${isPremium ? 'PREMIUM' : 'FREE'} plan',
      // );
    } catch (e) {
      // print('Error subscribing to plan: $e');
      rethrow;
    }
  }

  Future<void> cancelSubscription() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await supabase
          .from('user_subscriptions')
          .update({
            'status': 'cancelled',
            'end_date': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id)
          .eq('status', 'active');

      // Update user profile ke non-premium
      await supabase
          .from('profiles')
          .update({
            'is_premium_user': false,
            'current_plan_id': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id);

      // print('❌ User ${user.id} subscription cancelled, set to FREE plan');
    } catch (e) {
      // print('Error cancelling subscription: $e');
      rethrow;
    }
  }

  // Helper: Cek apakah subscription masih aktif
  Future<bool> isSubscriptionActive(String userId) async {
    try {
      final response = await supabase
          .from('user_subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .maybeSingle();

      if (response == null) return false;

      // Cek tanggal berakhir
      final endDateStr = response['end_date'];
      if (endDateStr != null) {
        final endDate = DateTime.parse(endDateStr);
        return DateTime.now().isBefore(endDate);
      }

      return true; // Lifetime subscription
    } catch (e) {
      // print('Error checking subscription active: $e');
      return false;
    }
  }

  // Helper: Sync premium status berdasarkan subscription
  Future<void> syncPremiumStatus() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final isActive = await isSubscriptionActive(user.id);

      await supabase
          .from('profiles')
          .update({
            'is_premium_user': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id);

      // print('🔄 Synced premium status for user ${user.id}: $isActive');
    } catch (e) {
      // print('Error syncing premium status: $e');
    }
  }

  // Method untuk simulasi proses pembayaran
  Future<bool> processPayment(int planId, String paymentMethod) async {
    try {
      // Simulasi proses pembayaran
      // print('💰 Processing payment for plan $planId with $paymentMethod');
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulasi 95% success rate
      final random = Random().nextDouble();
      if (random < 0.95) {
        // print('✅ Payment successful');
        return true;
      } else {
        // print('❌ Payment failed');
        throw Exception('Payment failed. Please try again.');
      }
    } catch (e) {
      // print('Error processing payment: $e');
      rethrow;
    }
  }

  List<PlanModel> _getDefaultPlans() {
    return [
      PlanModel(
        id: 1,
        name: 'Free',
        type: 'free',
        price: 0,
        currency: 'IDR',
        features: [
          'Akses Fitur Habits Tracker',
          'Akses Fitur Komunitas',
          'Akses Fitur Artikel Gratis',
          'Reminder & Notifikasi (Basic reminder)',
        ],
        isActive: true,
      ),
      PlanModel(
        id: 2,
        name: 'Sheet Monthly',
        type: 'monthly',
        price: 49000,
        originalPrice: 59000,
        currency: 'IDR',
        features: [
          'Fitur Habits Tracker Premium (grafik, report)',
          'Konsultasi Psikologi (2 sesi) (online, chat)',
          'Riwayat & Catatan Konsultasi (save 30 hari)',
          'Smart reminder (otomatis sesuai pola kebiasaan)',
          'Komunitas Eksklusif & Forum Dukungan untuk Sharing',
        ],
        isPopular: true,
        isActive: true,
        badgeText: 'POPULAR',
        consultationSessions: 2,
        consultationHistoryDays: 30,
      ),
      PlanModel(
        id: 3,
        name: 'Sheet Yearly',
        type: 'yearly',
        price: 499000,
        originalPrice: 588000,
        currency: 'IDR',
        features: [
          'Fitur Habits Tracker Premium (grafik, report)',
          'Konsultasi Psikologi (24 sesi) (online, chat)',
          'Riwayat & Catatan Konsultasi (save 365 hari)',
          'Smart reminder (otomatis sesuai pola kebiasaan)',
          'Komunitas Eksklusif & Forum Dukungan untuk Sharing',
          'Diskon 40% dari harga bulanan',
          'Prioritas dukungan customer',
        ],
        isBestValue: true,
        isActive: true,
        badgeText: 'BEST VALUE',
        consultationSessions: 24,
        consultationHistoryDays: 365,
      ),
    ];
  }
}