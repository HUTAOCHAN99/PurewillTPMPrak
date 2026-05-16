// lib/ui/membership/premium_status/models/subscription_data.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionData {
  DateTime? startDate;
  DateTime? endDate;
  String status = 'active';

  Future<void> loadSubscriptionData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final subscriptionResponse = await Supabase.instance.client
          .from('user_subscriptions')
          .select('start_date, end_date, status')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .maybeSingle();

      if (subscriptionResponse != null) {
        if (subscriptionResponse['start_date'] != null) {
          startDate = DateTime.parse(subscriptionResponse['start_date'] as String);
        }
        if (subscriptionResponse['end_date'] != null) {
          endDate = DateTime.parse(subscriptionResponse['end_date'] as String);
        }
        status = subscriptionResponse['status'] ?? 'active';
      } else {
        // Jika tidak ada subscription aktif, set default values
        startDate = DateTime.now().subtract(const Duration(days: 30));
        endDate = DateTime.now().add(const Duration(days: 335));
      }
    } catch (e) {
      print('Error loading subscription details: $e');
      // Fallback ke default values
      startDate = DateTime.now().subtract(const Duration(days: 30));
      endDate = DateTime.now().add(const Duration(days: 335));
    }
  }

  String formatDate(DateTime date) {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }
}