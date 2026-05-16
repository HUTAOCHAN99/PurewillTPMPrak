import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class ProgressCard extends StatelessWidget {
  final double progress;
  final int completed;
  final int total;

  const ProgressCard({
    super.key,
    required this.progress,
    required this.completed,
    required this.total,
  });

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.5) return Colors.blue;
    if (progress >= 0.3) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Progress",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 8,
            percent: progress,
            progressColor: _getProgressColor(progress),
            backgroundColor: Colors.grey[200]!,
            barRadius: const Radius.circular(8),
          ),
          const SizedBox(height: 8),
          Text(
            "$completed of $total habits completed",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
