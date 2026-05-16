import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:purewill/data/repository/category_repository.dart';
import 'package:purewill/data/repository/daily_log_repository.dart';
import 'package:purewill/data/repository/habit_repository.dart';
import 'package:purewill/data/repository/reminder_setting_repository.dart';
import 'package:purewill/data/repository/target_unit_repository.dart';
import 'package:purewill/data/repository/user_repository.dart';
import 'package:purewill/data/services/performance_service.dart';
import 'package:purewill/ui/habit-tracker/view_model/habit_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repository/habit_session_repository.dart';
import '../auth/auth_provider.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return HabitRepository(client);
});

final targetUnitRepositoryProvider = Provider<TargetUnitRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TargetUnitRepository(client);
});

final dailyLogRepositoryProvider = Provider<DailyLogRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DailyLogRepository(client);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return UserRepository(client);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CategoryRepository(client);
});

final reminderSettingRepositoryProvider = Provider<ReminderSettingRepository>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return ReminderSettingRepository(client);
});

final habitSessionRepositoryProvider = Provider<HabitSessionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return HabitSessionRepository(client);
});

// Provider yang reactive terhadap perubahan auth state
final habitNotifierProvider =
    StateNotifierProvider<HabitsViewModel, HabitsState>((ref) {
      final habitRepository = ref.watch(habitRepositoryProvider);
      final dailyLogRepository = ref.watch(dailyLogRepositoryProvider);
      final reminderSettingRepository = ref.watch(
        reminderSettingRepositoryProvider,
      );
      final habitSessionRepository = ref.watch(habitSessionRepositoryProvider);
      final targetUnitRepository = ref.watch(targetUnitRepositoryProvider);
      final categoryRepository = ref.watch(categoryRepositoryProvider);
      final userRepository = ref.watch(userRepositoryProvider);

      // Watch auth state untuk mendapat current user
      final authState = ref.watch(authNotifierProvider);
      final userId = authState.user?.id ?? "";

      // Invalidate provider ini ketika auth state berubah
      ref.listen(authNotifierProvider, (previous, next) {
        // Jika user berubah atau logout, invalidate provider ini
        if (previous?.user?.id != next.user?.id) {
          ref.invalidateSelf();
        }
      });

      return HabitsViewModel(
        habitRepository,
        dailyLogRepository,
        reminderSettingRepository,
        habitSessionRepository,
        targetUnitRepository,
        categoryRepository,
        userRepository,
        userId,
      );
    });

final performanceServiceProvider = Provider<PerformanceService>((ref) {
  final habitRepository = ref.read(habitRepositoryProvider);
  return PerformanceService(habitRepository);
});
