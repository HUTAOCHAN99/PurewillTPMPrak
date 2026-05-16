import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/domain/model/daily_log_model.dart';
import 'package:purewill/domain/model/habit_model.dart';
import 'package:purewill/domain/model/reminder_setting_model.dart';
import 'package:purewill/ui/habit-tracker/habit_provider.dart';
import 'package:purewill/ui/habit-tracker/screen/edit_habit_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/reminder_setting_screen.dart';
import 'package:purewill/ui/habit-tracker/widget/habit_detail/calendar_tracker_widget.dart';
import 'package:purewill/ui/habit-tracker/widget/habit_detail/habit_actions_dropdown.dart';
import 'package:purewill/ui/habit-tracker/widget/habit_detail/motivational_quote_widget.dart';
import 'package:purewill/ui/habit-tracker/widget/habit_detail/performance_chart_widget.dart';
import 'package:purewill/ui/habit-tracker/widget/habit_detail/progress_widget.dart';
import 'package:purewill/ui/habit-tracker/widget/habit_detail/weekly_streak_widget.dart';
import 'package:purewill/utils/habit_icon_helper.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  final HabitModel habit;
  final Map<int, LogStatus> completionStatus;
  const HabitDetailScreen({
    super.key,
    required this.habit,
    required this.completionStatus,
  });

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  late bool _isCompleted;
  int _completedDays = 0;
  int _habitLogStreak = 0;
  int _possibleDays = 0;
  List<DailyLogModel>? _habitLogForThisMonth;
  List<double> _weeklyPerformance = [];
  bool _isLoading = true;
  ReminderSettingModel? _reminderSetting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      int habitId = widget.habit.id;
      _isCompleted =
          widget.completionStatus[widget.habit.id] == LogStatus.success;
      _loadHabitLogForThisMonth(habitId);
      _loadReminderSetting(habitId);
      _countPossibleDays(widget.habit.startDate, widget.habit.endDate);
    });
  }

  Future<void> _loadReminderSetting(int habitId) async {
    try {
      final reminderSetting = await ref
          .read(habitNotifierProvider.notifier)
          .loadCurrentReminderSetting(habitId);
      if (mounted) {
        setState(() {
          _reminderSetting = reminderSetting;
        });
      }
    } catch (e) {
      print('Error loading reminder setting: $e');
      if (mounted) {
        setState(() {
          _reminderSetting = null;
        });
      }
    }
  }

  void _countPossibleDays(DateTime habitStartDate, DateTime? habitEndDate) {

    final localHabitStart = habitStartDate;

    final effectiveHabitStartDate = DateTime(
      localHabitStart.year,
      localHabitStart.month,
      localHabitStart.day,
    );

    DateTime? effectiveHabitEndDate;
    if (habitEndDate != null) {
      final localHabitEnd = habitEndDate;
      effectiveHabitEndDate = DateTime(
        localHabitEnd.year,
        localHabitEnd.month,
        localHabitEnd.day,
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    // print("start of week: $startOfWeek");
    final endOfWeekExclusive = startOfWeek.add(const Duration(days: 7));
    // print("end of week exclusive: $endOfWeekExclusive");

    DateTime effectiveEndExclusive;

    if (effectiveHabitEndDate == null) {
      effectiveEndExclusive = endOfWeekExclusive;
    } else {
      final habitEndDateExclusive = effectiveHabitEndDate.add(
        const Duration(days: 1),
      );

      // print("habit end date exclusive: $habitEndDateExclusive");

      effectiveEndExclusive = habitEndDateExclusive.isBefore(endOfWeekExclusive)
          ? habitEndDateExclusive
          : endOfWeekExclusive;
    }

    final effectiveStartForTarget = effectiveHabitStartDate.isAfter(startOfWeek)
        ? effectiveHabitStartDate
        : startOfWeek;

    // print("effective start for target: $effectiveStartForTarget");
    // print("effective end exclusive: $effectiveEndExclusive");

    final difference = effectiveEndExclusive.difference(
      effectiveStartForTarget,
    );

    // print("difference: $difference");

    final possibleDaysTarget = difference.inDays;

    // print("possible days target: $possibleDaysTarget");

    setState(() {
      _possibleDays = possibleDaysTarget;
    });
  }

  Future<void> _loadHabitLogForThisMonth(int habitId) async {
    try {
      // Untuk monthly calendar data
      DateTime now = DateTime.now();
      DateTime monthStartDate = DateTime(now.year, now.month, 1);
      DateTime monthEndDate = DateTime(now.year, now.month + 1, 0);

      final habitLogForThisMonth = await ref
          .read(habitNotifierProvider.notifier)
          .fetchLogsForCalendar(
            startDate: monthStartDate,
            endDate: monthEndDate,
            habitId: habitId,
          );

      // Untuk weekly performance, ambil data minggu ini (bisa lintas bulan)
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1)); // Senin
      final endOfWeek = startOfWeek.add(const Duration(days: 6)); // Minggu

      final habitLogForThisWeek = await ref
          .read(habitNotifierProvider.notifier)
          .fetchLogsForCalendar(
            startDate: startOfWeek,
            endDate: endOfWeek,
            habitId: habitId,
          );

      final streak = await ref
          .read(habitNotifierProvider.notifier)
          .fetchHabitLogStreak(habitId: habitId);

      // Safe handling untuk empty list tanpa null check yang unnecessary
      final List<DateTime> localCompletionDates = habitLogForThisMonth
          .map((dailyLog) => dailyLog.logDate)
          .toList();

      final completeDays = localCompletionDates.length;

      // Hitung weekly performance dari data log minggu ini
      final weeklyPerformanceData = _calculateWeeklyPerformance(habitLogForThisWeek);

      print('Weekly dates range: ${startOfWeek.toString().split(' ')[0]} to ${endOfWeek.toString().split(' ')[0]}');
      print('Weekly performance data: $weeklyPerformanceData');

      if (mounted) {
        setState(() {
          _habitLogForThisMonth = habitLogForThisMonth;
          _completedDays = completeDays;
          _weeklyPerformance = weeklyPerformanceData; // Set data yang benar
          _isLoading = false;
          _habitLogStreak = streak;
        });
      }
    } catch (e) {
      print('Error loading completion status: $e');
      
      // Set default values jika terjadi error
      if (mounted) {
        setState(() {
          _habitLogForThisMonth = [];
          _completedDays = 0;
          _weeklyPerformance = List.filled(7, 0.0); // Default weekly performance
          _isLoading = false;
          _habitLogStreak = 0;
        });
      }
    }
  }

  // Method untuk menghitung weekly performance berdasarkan data log minggu ini
  List<double> _calculateWeeklyPerformance(List<DailyLogModel> weeklyLogs) {
    try {
      // Get start of current week (Monday)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      
      // Initialize performance array untuk 7 hari (Monday to Sunday)
      List<double> weeklyPerformance = List.filled(7, 0.0);
      
      // Debug info
      print('Calculating weekly performance for week: ${startOfWeek.toString().split(' ')[0]} to ${startOfWeek.add(Duration(days: 6)).toString().split(' ')[0]}');
      print('Today is: ${today.toString().split(' ')[0]} (${_getDayName(today.weekday)})');
      
      // Hitung performa untuk setiap hari dalam seminggu
      for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
        final targetDate = startOfWeek.add(Duration(days: dayIndex));
        final dayName = _getDayName(targetDate.weekday);
        
        // Cari log untuk tanggal tersebut
        final logForDay = weeklyLogs.where((log) {
          final logDate = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
          final targetDateNormalized = DateTime(targetDate.year, targetDate.month, targetDate.day);
          return logDate.isAtSameMomentAs(targetDateNormalized);
        }).toList();
        
        if (logForDay.isNotEmpty) {
          // Hitung persentase berdasarkan status log
          final log = logForDay.first;
          switch (log.status) {
            case LogStatus.success:
              weeklyPerformance[dayIndex] = 100.0; // 100% jika berhasil
              print('  $dayName (${targetDate.toString().split(' ')[0]}): 100% - SUCCESS');
              break;
            case LogStatus.failed:
              weeklyPerformance[dayIndex] = 0.0;   // 0% jika gagal
              print('  $dayName (${targetDate.toString().split(' ')[0]}): 0% - FAILED');
              break;
            case LogStatus.neutral:
              weeklyPerformance[dayIndex] = 50.0;  // 50% jika neutral
              print('  $dayName (${targetDate.toString().split(' ')[0]}): 50% - NEUTRAL');
              break;
          }
        } else {
          // Tidak ada log untuk hari ini
          if (targetDate.isAfter(today)) {
            // Hari yang belum terjadi
            weeklyPerformance[dayIndex] = 0.0;
            print('  $dayName (${targetDate.toString().split(' ')[0]}): 0% - FUTURE DAY');
          } else {
            // Hari yang sudah lewat tapi tidak ada log (dianggap missed)
            weeklyPerformance[dayIndex] = 0.0;
            print('  $dayName (${targetDate.toString().split(' ')[0]}): 0% - NO LOG (MISSED)');
          }
        }
      }
      
      return weeklyPerformance;
    } catch (e) {
      print('Error calculating weekly performance: $e');
      // Return default jika terjadi error
      return List.filled(7, 0.0);
    }
  }

  // Helper method untuk mendapatkan nama hari
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconData = HabitIconHelper.getHabitIcon(widget.habit.name);
    final iconColor = HabitIconHelper.getHabitColor(widget.habit.name);
    final category = HabitIconHelper.getHabitCategory(widget.habit.name);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color.fromRGBO(184, 230, 230, 1),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeaderBackground(iconData, iconColor, category),
              titlePadding: const EdgeInsets.only(left: 0, right: 0, bottom: 0),
              collapseMode: CollapseMode.pin,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Habit detail",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              HabitActionsDropdown(
                onActionSelected: _handleMenuAction,
                habitName: widget.habit.name,
                habit: widget.habit,
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProgressWidget(
                    isCompleted: _isCompleted,
                    habitColor: iconColor,
                    habitName: widget.habit.name,
                    completedDays: _completedDays,
                    totalDays: _possibleDays,
                  ),
                  const SizedBox(height: 24),

                  WeeklyStreakWidget(streak: _habitLogStreak),
                  const SizedBox(height: 24),

                  PerformanceChartWidget(weeklyPerformance: _weeklyPerformance),
                  const SizedBox(height: 24),

                  // Safe access dengan null check untuk CalendarTrackerWidget
                  if (_habitLogForThisMonth != null)
                    CalendarTrackerWidget(
                      habitLogForThisMonth: _habitLogForThisMonth!,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'No habit log data available',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  MotivationalQuotesWidget(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String value) {
    HabitActionsDropdown.handleMenuAction(
      value: value,
      context: context,
      habitName: widget.habit.name,
      habit: widget.habit,
      onEdit: _editHabit,
      onReminder: _setReminder,
      onDelete: _deleteHabit,
    );
  }

  void _editHabit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditHabitScreen(habit: widget.habit),
      ),
    );
  }

  void _setReminder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderSettingScreen(
          habit: widget.habit,
          reminderSetting: _reminderSetting,
        ),
      ),
    );
  }

  void _deleteHabit() {
    HabitActionsDropdown.showDeleteConfirmationDialog(
      context: context,
      habitName: widget.habit.name,
      onConfirm: () {
        _performDeleteHabit();
      },
    );
  }

  Future<void> _performDeleteHabit() async {
    try {
      final viewModel = ref.read(habitNotifierProvider.notifier);
      if (widget.habit.isDefault) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"${widget.habit.name}" adalah habit default dan tidak dapat dihapus',
            ),
          ),
        );
        return;
      }
      await viewModel.deleteHabit(habitId: widget.habit.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${widget.habit.name}" berhasil dihapus')),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus habit: $e')));
    }
  }

  Widget _buildHeaderBackground(
    IconData iconData,
    Color iconColor,
    String category,
  ) {
    return Container(
      color: const Color.fromRGBO(184, 230, 230, 1),
      padding: const EdgeInsets.only(
        top: kToolbarHeight + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(iconData, size: 25, color: iconColor),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    widget.habit.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
