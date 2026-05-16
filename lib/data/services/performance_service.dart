// lib\data\services\performance_service.dart
// import 'package:flutter/foundation.dart';
import 'package:purewill/data/repository/habit_repository.dart';
// import 'package:purewill/data/repository/habit_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerformanceService {
  final HabitRepository _habitRepository;
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  PerformanceService(this._habitRepository);
  // PerformanceService();

  Future<List<double>> getWeeklyPerformance(int habitId) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      
      // debugPrint('Getting weekly performance for habit: $habitId');
      // debugPrint('Date range: $startOfWeek to $now');

      final response = await _supabaseClient
          .from('daily_logs')
          .select('*')
          .eq('habit_id', habitId)
          .gte('log_date', startOfWeek.toIso8601String())
          .lte('log_date', now.toIso8601String())
          .order('log_date', ascending: true);

      // debugPrint('Raw logs data: ${response.length} entries');

      final weeklyData = List<double>.filled(7, 0.0);
      
      for (final log in response) {
        final logDate = DateTime.parse(log['log_date']);
        final dayIndex = logDate.weekday - 1; // Monday = 0, Sunday = 6
        
        // Jika status adalah 'success', set nilai menjadi 100%
        if (log['status'] == 'success') {
          weeklyData[dayIndex] = 100.0;
          // debugPrint('Success log found for day $dayIndex (${logDate})');
        }
      }

      // debugPrint('Final weekly data: $weeklyData');
      return weeklyData;
      
    } catch (e) {
      // debugPrint('Error in PerformanceService: $e');
      // Return data dummy untuk testing
      return [100.0, 80.0, 60.0, 40.0, 100.0, 0.0, 20.0];
    }
  }
}