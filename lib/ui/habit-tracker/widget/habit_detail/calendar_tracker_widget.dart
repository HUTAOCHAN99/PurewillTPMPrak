import 'package:flutter/material.dart';
import 'package:purewill/domain/model/daily_log_model.dart';

class CalendarTrackerWidget extends StatelessWidget {
  final List<DailyLogModel> habitLogForThisMonth;

  const CalendarTrackerWidget({super.key, required this.habitLogForThisMonth});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE9ECEF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                _getMonthName(now.month),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              _buildWeekDaysHeader(),
              const SizedBox(height: 8),

              _buildFullMonthCalendar(firstDayOfMonth, lastDayOfMonth),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFullMonthCalendar(DateTime firstDay, DateTime lastDay) {
    List<Widget> weeks = [];

    DateTime startDate = firstDay.subtract(
      Duration(days: (firstDay.weekday - 1) % 7),
    );

    DateTime currentDate = startDate;
    while (currentDate.isBefore(lastDay) || currentDate.day == lastDay.day) {
      weeks.add(_buildWeekRow(currentDate, firstDay, lastDay));
      weeks.add(const SizedBox(height: 8));
      currentDate = currentDate.add(const Duration(days: 7));
    }

    return Column(children: weeks);
  }

  Widget _buildWeekDaysHeader() {
    return Row(
      children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
          .map(
            (day) => Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildWeekRow(
    DateTime weekStart,
    DateTime firstDay,
    DateTime lastDay,
  ) {
    return Row(
      children: List.generate(7, (index) {
        final currentDate = weekStart.add(Duration(days: index));
        final isInCurrentMonth =
            currentDate.isAfter(firstDay.subtract(const Duration(days: 1))) &&
            currentDate.isBefore(lastDay.add(const Duration(days: 1)));

        if (!isInCurrentMonth) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Text(
                  currentDate.day.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
          );
        }

        final dayStatus = _getDayStatus(currentDate);

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getDayColor(dayStatus),
              shape: BoxShape.circle,
              border: _isToday(currentDate)
                  ? Border.all(color: Colors.blue, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                currentDate.day.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(dayStatus),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  String _getDayStatus(DateTime date) {
    // Find log for this specific date
    final logForDate = habitLogForThisMonth
        .where(
          (log) =>
              log.logDate.year == date.year &&
              log.logDate.month == date.month &&
              log.logDate.day == date.day,
        )
        .toList();

    if (logForDate.isEmpty) {
      return 'default'; // No log entry for this date
    }

    // Check the status of the log
    final log = logForDate.first;
    switch (log.status) {
      case LogStatus.success:
        return 'success';
      case LogStatus.failed:
        return 'missed';
      case LogStatus.neutral:
        return 'default';
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Color _getDayColor(String status) {
    switch (status) {
      case 'success':
        return const Color(0xFF4CAF50); // Green for success
      case 'missed':
        return const Color(0xFFF44336); // Red for failed/missed
      case 'default':
        return Colors.grey[300]!; // Default grey for no log
      default:
        return Colors.transparent;
    }
  }

  Color _getTextColor(String status) {
    switch (status) {
      case 'success':
        return Colors.white;
      case 'missed':
        return Colors.white;
      case 'default':
        return Colors.grey[600]!;
      default:
        return Colors.black87;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
