// lib\ui\habit-tracker\widget\habit_detail\performance_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PerformanceChartWidget extends ConsumerStatefulWidget {
  final List<double> weeklyPerformance;

  const PerformanceChartWidget({super.key, required this.weeklyPerformance});

  @override
  ConsumerState<PerformanceChartWidget> createState() =>
      _PerformanceChartWidgetState();
}

class _PerformanceChartWidgetState
    extends ConsumerState<PerformanceChartWidget> {

  @override
  Widget build(BuildContext context) {
    // Generate actual dates for this week (Monday to Sunday)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    
    final weekDates = List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      return {
        'date': date,
        'dayName': _getShortDayName(date.weekday),
        'dayNumber': date.day.toString(),
        'isToday': date.isAtSameMomentAs(today),
      };
    });
    
    // Safe handling untuk weeklyPerformance dengan default values
    final safeWeeklyPerformance = _ensureValidPerformanceData(widget.weeklyPerformance);
    
    final maxPerformance = safeWeeklyPerformance.isNotEmpty
        ? safeWeeklyPerformance.reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Weekly Performance",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                _getWeekRange(startOfWeek),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart dengan tanggal aktual
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final dayInfo = weekDates[index];
                final percentage = index < safeWeeklyPerformance.length 
                    ? safeWeeklyPerformance[index] / 100 
                    : 0.0;
                return _buildBarChartItem(
                  dayInfo['dayName'] as String,
                  dayInfo['dayNumber'] as String,
                  percentage,
                  maxPerformance,
                  dayInfo['isToday'] as bool,
                );
              }),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          _buildPerformanceLegend(),
        ],
      ),
    );
  }

  // Helper method untuk memastikan data valid
  List<double> _ensureValidPerformanceData(List<double> data) {
    // Jika data kosong atau kurang dari 7, isi dengan 0.0
    if (data.isEmpty) {
      return List.filled(7, 0.0);
    }
    
    // Jika data kurang dari 7, tambahkan 0.0 hingga 7 elemen
    if (data.length < 7) {
      final List<double> result = List.from(data);
      while (result.length < 7) {
        result.add(0.0);
      }
      return result;
    }
    
    // Jika data lebih dari 7, ambil 7 pertama
    if (data.length > 7) {
      return data.take(7).toList();
    }
    
    // Data sudah tepat 7 elemen
    return data;
  }

  String _getShortDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return 'Unknown';
    }
  }

  String _getWeekRange(DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final startMonth = startOfWeek.month;
    final endMonth = endOfWeek.month;
    
    if (startMonth == endMonth) {
      return '${startOfWeek.day}-${endOfWeek.day} ${_getMonthName(startMonth)}';
    } else {
      return '${startOfWeek.day} ${_getMonthName(startMonth)} - ${endOfWeek.day} ${_getMonthName(endMonth)}';
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildBarChartItem(
    String dayName,
    String dayNumber,
    double percentage,
    double maxPerformance,
    bool isToday,
  ) {
    final height = percentage * 80;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 20,
          height: height.clamp(2.0, 80.0), // Minimum height 2px untuk visibility
          decoration: BoxDecoration(
            color: _getPerformanceColor(percentage),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(percentage * 100).toInt()}%',
          style: TextStyle(
            fontSize: 10, 
            color: isToday ? Colors.blue[700] : Colors.grey[600],
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dayName,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday ? Colors.blue[700] : Colors.grey[600],
          ),
        ),
        Text(
          dayNumber,
          style: TextStyle(
            fontSize: 10,
            color: isToday ? Colors.blue[700] : Colors.grey[500],
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceLegend() {
    return Wrap(
      spacing: 6,
      runSpacing: 2,
      alignment: WrapAlignment.spaceAround,
      children: [
        _buildLegendItem(const Color(0xFF4CAF50), "Excellent (80-100%)"),
        _buildLegendItem(const Color(0xFFFFC107), "Good (60-79%)"),
        _buildLegendItem(const Color(0xFFF44336), "Needs Improvement (<60%)"),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 2),
        Text(
          text,
          style: const TextStyle(
            fontSize: 8,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 0.8) return const Color(0xFF4CAF50);
    if (percentage >= 0.6) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }
}
