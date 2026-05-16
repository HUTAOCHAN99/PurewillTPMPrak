import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/domain/model/habit_model.dart';
import 'package:purewill/domain/model/profile_model.dart';
import 'package:purewill/ui/auth/auth_provider.dart';
import 'package:purewill/ui/auth/screen/login_screen.dart';
import 'package:purewill/ui/habit-tracker/habit_provider.dart';
import 'package:purewill/ui/habit-tracker/screen/community_selection_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/membership_screen.dart';
import 'package:purewill/ui/habit-tracker/view_model/habit_view_model.dart';
import 'package:purewill/ui/membership/plan_provider.dart';
import 'package:purewill/ui/habit-tracker/widget/clean_bottom_navigation_bar.dart';
import 'package:purewill/ui/habit-tracker/widget/habit_cards_list.dart';
import 'package:purewill/ui/habit-tracker/widget/habit_header.dart';
import 'package:purewill/ui/habit-tracker/widget/habit_welcome_message.dart';
import 'package:purewill/ui/habit-tracker/widget/progress_card.dart';
import 'package:purewill/ui/habit-tracker/widget/premium_card_button.dart';
import 'package:purewill/ui/habit-tracker/screen/habit_detail_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/add_habit_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/habit_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/consultation_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/nofap_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purewill/data/services/badge_service.dart';
import 'package:purewill/data/services/badge_notification_service.dart';
import 'package:purewill/data/services/reminder_sync_service.dart';
import 'package:purewill/domain/model/daily_log_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  Map<int, LogStatus> _todayCompletionStatus = {};
  String _userRole = 'user'; // Default role
  bool _isLoadingRole = true;

  final badgeNotificationService = BadgeNotificationService();
  late BadgeService badgeService;

  @override
  void initState() {
    super.initState();

    badgeService = BadgeService(
      Supabase.instance.client,
      badgeNotificationService,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(habitNotifierProvider.notifier).loadTodayUserHabits();
      _loadTodayCompletionStatus();
      ref.read(habitNotifierProvider.notifier).getCurrentUser();
      ref.read(planProvider.notifier).loadPlans();
      _loadUserRole();
      _refreshData();

      // Schedule reminders setelah login
      _scheduleReminders();
    });
  }

  Future<void> _loadTodayCompletionStatus() async {
    try {
      final completionStatus = await ref
          .read(habitNotifierProvider.notifier)
          .getTodayCompletionStatus();
      if (mounted) {
        setState(() {
          _todayCompletionStatus = completionStatus;
        });
      }
    } catch (e) {
      print('Error loading completion status: $e');
    }
  }

  Future<void> _loadUserRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('user_id', user.id)
            .single();

        if (mounted) {
          setState(() {
            _userRole = response['role'] as String? ?? 'user';
            _isLoadingRole = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _userRole = 'user';
            _isLoadingRole = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user role: $e');
      if (mounted) {
        setState(() {
          _userRole = 'user';
          _isLoadingRole = false;
        });
      }
    }
  }

  Future<void> _scheduleReminders() async {
    try {
      // debugPrint('🔄 Scheduling reminders for current user...');
      final reminderService = ReminderSyncService();
      await reminderService.rescheduleAllReminders();
      // debugPrint('✅ Reminders scheduled successfully');
    } catch (e) {
      // debugPrint('❌ Error scheduling reminders: $e');
    }
  }

  void _onNavBarTap(int index) {
    print('NavBar tapped: index $index');

    if (index == 1) {
      // Navigate to Habit Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HabitScreen()),
      );
    } else if (index == 2) {
      // Navigate to NoFap Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const NoFapScreen()),
      );
    } else if (index == 3) {
      // Navigate to Community Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const CommunitySelectionScreen(),
        ),
      );
    } else if (index == 4) {
      // Navigate to Consultation Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ConsultationScreen()),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _navigateToMembership() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const MembershipScreen()));
  }

  void _refreshData() async {
    await ref.read(habitNotifierProvider.notifier).loadTodayUserHabits();
    await ref.read(planProvider.notifier).loadPlans();
    await _loadTodayCompletionStatus();
    await _loadUserRole();
  }

  @override
  Widget build(BuildContext context) {
    final habitsState = ref.watch(habitNotifierProvider);
    final planState = ref.watch(planProvider);

    if (_isLoadingRole || habitsState.status == HabitStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<HabitModel> userHabits = habitsState.todayHabit;
    final ProfileModel? currentUser = habitsState.currentUser;
    final String userName = currentUser?.fullName ?? "User";
    final String userEmail = currentUser?.email ?? "email@example.com";

    final completedToday = userHabits.where((habit) {
      return _todayCompletionStatus[habit.id] == LogStatus.success;
    }).length;

    final totalHabits = userHabits.length;
    final progress = totalHabits > 0 ? completedToday / totalHabits : 0.0;

    final bool isPremiumUser = planState.isUserPremium ?? false;
    final currentPlan = planState.currentPlan;

    if (planState.isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/home/bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (planState.error != null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/home/bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 50),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    planState.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(planProvider.notifier).loadPlans(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(authNotifierProvider.notifier).logout();
        },
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/home/bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                HabitHeader(
                  userEmail: userEmail,
                  userName: userName,
                  userRole: _userRole,
                  onLogout: _performLogout,
                  isPremiumUser: isPremiumUser,
                  currentPlan: currentPlan,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HabitWelcomeMessage(name: userName),

                        // Role info badge (jika doctor atau admin)
                        if (_userRole == 'doctor' || _userRole == 'admin')
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _userRole == 'doctor'
                                  ? const Color(0xFF10B981).withOpacity(0.1)
                                  : const Color(0xFFEF4444).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _userRole == 'doctor'
                                    ? const Color(0xFF10B981).withOpacity(0.3)
                                    : const Color(0xFFEF4444).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _userRole == 'doctor'
                                      ? Icons.medical_services
                                      : Icons.admin_panel_settings,
                                  color: _userRole == 'doctor'
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _userRole == 'doctor'
                                        ? 'Akun dokter Anda sudah aktif'
                                        : 'Anda memiliki akses admin',
                                    style: TextStyle(
                                      color: _userRole == 'doctor'
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        ProgressCard(
                          progress: progress,
                          completed: completedToday,
                          total: totalHabits,
                        ),

                        const SizedBox(height: 16),
                        PremiumCardButton(
                          isPremiumUser: isPremiumUser,
                          currentPlan: currentPlan,
                          onTap: _navigateToMembership,
                        ),

                        const SizedBox(height: 24),
                        const Text(
                          "Your Habits",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        HabitCardsList(
                          habitsState: habitsState,
                          todayCompletionStatus: _todayCompletionStatus,
                          habits: userHabits,
                          onHabitTap: _handleHabitTap,
                          onCheckboxTap: _handleCheckboxTap,
                          isPremiumUser: isPremiumUser,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CleanBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        child: const Icon(Icons.add),
        heroTag: "add_habit_fab",
      ),
    );
  }

  void _addHabit() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddHabitScreen()));
  }

  void _handleHabitTap(HabitModel habit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitDetailScreen(
          habit: habit,
          completionStatus: _todayCompletionStatus,
        ),
      ),
    );
  }

  void _handleCheckboxTap(HabitModel habit) async {
    try {
      final currentStatus = _todayCompletionStatus[habit.id];

      setState(() {
        _todayCompletionStatus[habit.id] = currentStatus == LogStatus.success
            ? LogStatus.failed
            : currentStatus == LogStatus.failed
            ? LogStatus.neutral
            : LogStatus.success;
      });

      await ref
          .read(habitNotifierProvider.notifier)
          .toggleHabitCompletion(habit);

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final newStatus = _todayCompletionStatus[habit.id];

        if (newStatus == LogStatus.success) {
          _showSnackBar('Habit completed successfully!');
          await badgeService.checkAllBadges(user.id);
        } else if (newStatus == LogStatus.failed) {
          _showSnackBar('Habit marked as failed.');
        } else if (newStatus == LogStatus.neutral) {
          _showSnackBar('Habit reset to neutral.');
        }
      }
    } catch (e) {
      final previousStatus =
          _todayCompletionStatus[habit.id] == LogStatus.success;
      setState(() {
        _todayCompletionStatus[habit.id] = previousStatus
            ? LogStatus.neutral
            : LogStatus.success;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update habit: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _performLogout() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      ref.read(authNotifierProvider.notifier).logout();

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
