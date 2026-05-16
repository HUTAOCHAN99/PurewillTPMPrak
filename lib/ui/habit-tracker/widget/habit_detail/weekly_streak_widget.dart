import 'package:flutter/material.dart';

class WeeklyStreakWidget extends StatelessWidget {
  final int streak;

  const WeeklyStreakWidget({
    super.key,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final currentStreak = streak;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFED7AA), // rgb(254 215 170)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Fire Animation dan Streak Number di center
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // GIF Fire Icon
              _buildFireGif(),
              const SizedBox(width: 8),
              Text(
                currentStreak.toString(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFEA580C), // rgb(234 88 12)
                ),
              ),
            ],
          ),
          
          // "Days Streak" text di center
          const Text(
            "Days Streak",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700, // Bold
              color: Color(0xFFEA580C), // rgb(234 88 12)
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Motivational Text di center
          const Text(
            "Keep it up! You're on fire!",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFEA580C), // rgb(234 88 12)
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFireGif() {
    return SizedBox(
      width: 40,
      height: 40,
      child: Image.asset(
        'assets/images/home/habit_detail/fire-flame.gif',
        fit: BoxFit.contain,
      ),
    );
  }
}