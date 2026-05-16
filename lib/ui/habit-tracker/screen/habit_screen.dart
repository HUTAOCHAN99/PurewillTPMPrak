import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:purewill/domain/model/habit_model.dart';
import 'package:purewill/domain/model/daily_log_model.dart';
import 'package:purewill/ui/habit-tracker/habit_provider.dart';
import 'package:purewill/ui/habit-tracker/screen/community_selection_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/consultation_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/home_screen.dart';
import 'package:purewill/ui/habit-tracker/view_model/habit_view_model.dart';
import 'package:purewill/ui/habit-tracker/widget/habit_screen_card.dart';
import 'package:purewill/ui/habit-tracker/widget/clean_bottom_navigation_bar.dart';
import 'package:purewill/ui/habit-tracker/screen/habit_detail_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/add_habit_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/nofap_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purewill/data/services/badge_service.dart';
import 'package:purewill/data/services/badge_notification_service.dart';
import 'package:purewill/utils/habit_icon_helper.dart';

class HabitScreen extends ConsumerStatefulWidget {
  const HabitScreen({super.key});
  @override
  ConsumerState<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends ConsumerState<HabitScreen> {
  final _currentIndex = 1;
  Map<int, LogStatus> _todayCompletionStatus = {};

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
      ref.read(habitNotifierProvider.notifier).loadUserHabits();
      _loadTodayCompletionStatus();
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _onNavBarTap(int index) {
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (index == 1) {
      // Already on Habit Screen, do nothing
      return;
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitsState = ref.watch(habitNotifierProvider);
    final List<HabitModel> userHabits = habitsState.habits;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(176, 230, 216, 1),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        title: const Text(
          'My Habits',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black87),
            onPressed: _addHabit,
          ),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/home/bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // Blur effect overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
          ),
          // Content
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                print('🔄 HabitScreen: Pull to refresh triggered');
                await ref.read(habitNotifierProvider.notifier).loadUserHabits();
                await _loadTodayCompletionStatus();
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Habit Overview Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Habit Overview',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard(
                              'Total Habits',
                              userHabits.length.toString(),
                              Icons.list_alt,
                              Colors.blue,
                            ),
                            _buildStatCard(
                              'Completed Today',
                              _getCompletedTodayCount().toString(),
                              Icons.check_circle,
                              Colors.green,
                            ),
                            _buildStatCard(
                              'Active Habits',
                              userHabits
                                  .where((h) => h.isActive)
                                  .length
                                  .toString(),
                              Icons.play_circle,
                              Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // All Habits Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "All Habits",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildHabitsList(userHabits),
                      ],
                    ),
                  ),

                  // Bottom padding
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CleanBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.psychology_outlined,
            color: Colors.grey.shade400,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No habits yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start building positive habits today!\nTap the + button to add your first habit.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addHabit,
            icon: const Icon(Icons.add),
            label: const Text('Add Habit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(176, 230, 216, 1),
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomErrorState(String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Failed to load habits',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await ref.read(habitNotifierProvider.notifier).loadUserHabits();
              await _loadTodayCompletionStatus();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getCompletedTodayCount() {
    return _todayCompletionStatus.values
        .where((status) => status == LogStatus.success)
        .length;
  }

  void _addHabit() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddHabitScreen()),
    );
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
      final currentStatus =
          _todayCompletionStatus[habit.id] == LogStatus.success;
      final newStatus = !currentStatus;

      setState(() {
        _todayCompletionStatus[habit.id] = newStatus
            ? LogStatus.success
            : LogStatus.neutral;
      });

      await ref
          .read(habitNotifierProvider.notifier)
          .toggleHabitCompletion(habit);

      if (newStatus) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await Future.delayed(const Duration(milliseconds: 500));
          await badgeService.checkAllBadges(user.id);
          _showSnackBar('Habit completed!');
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

  Widget _buildHabitsList(List<HabitModel> userHabits) {
    final habitsState = ref.watch(habitNotifierProvider);

    switch (habitsState.status) {
      case HabitStatus.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        );

      case HabitStatus.failure:
        return _buildCustomErrorState(
          habitsState.errorMessage ?? 'Unknown error',
        );

      case HabitStatus.success:
        if (userHabits.isEmpty) {
          return _buildCustomEmptyState();
        }

        final defaultHabits = userHabits.where((h) => h.isDefault).toList();
        final userCustomHabits = userHabits.where((h) => !h.isDefault).toList();
        final sortedHabits = [...defaultHabits, ...userCustomHabits];

        return Column(
          children: sortedHabits.map((habit) {
            // Tentukan kategori berdasarkan categoryId
            final categoryName = _determineCategory(habit);

            // Dapatkan icon dan warna dari habit_icon_helper berdasarkan kategori
            final iconData = HabitIconHelper.getHabitIcon(categoryName);
            final color = HabitIconHelper.getHabitColor(categoryName);

            // Hitung persentase progress (dummy calculation - bisa disesuaikan dengan logika real)
            final todayStatus =
                _todayCompletionStatus[habit.id] ?? LogStatus.neutral;
            final progressPercentage = todayStatus == LogStatus.success
                ? 1.0
                : 0.0;

            return HabitScreenCard(
              icon: iconData,
              title: habit.name,
              subtitle: _buildHabitSubtitle(habit),
              color: color,
              progressPercentage: progressPercentage,
              category: categoryName,
              onTap: () => _handleHabitTap(habit),
            );
          }).toList(),
        );

      case HabitStatus.initial:
        return const SizedBox.shrink();
    }
  }

  // Method untuk menentukan kategori habit
  String _determineCategory(HabitModel habit) {
    // Prioritas 1: Jika habit punya categoryId, mapping ke nama kategori
    if (habit.categoryId != null) {
      final categoryName = _mapCategoryIdToName(habit.categoryId!);
      return categoryName;
    }

    // Prioritas 2: Gunakan habit_icon_helper untuk menentukan kategori dari nama habit
    final categoryFromName = HabitIconHelper.getHabitCategory(habit.name);
    return categoryFromName;
  }

  // Mapping categoryId ke nama kategori
  String _mapCategoryIdToName(int categoryId) {
    switch (categoryId) {
      case 1:
        return "Health & Fitness";
      case 2:
        return "Learning & Education";
      case 3:
        return "Productivity";
      case 4:
        return "Mindfulness & Mental Health";
      case 5:
        return "Personal Care";
      case 6:
        return "Social & Relationships";
      case 7:
        return "Finance";
      case 8:
        return "Hobbies & Creativity";
      case 9:
        return "Work & Career";
      case 10:
        return "Other";
      default:
        return "Other";
    }
  }

  String _buildHabitSubtitle(HabitModel habit) {
    if (habit.targetValue != null) {
      if (habit.unit != null && habit.unit!.isNotEmpty) {
        return '${habit.targetValue} ${habit.unit}';
      }
      return '${habit.targetValue}';
    }
    return 'Daily habit';
  }
}