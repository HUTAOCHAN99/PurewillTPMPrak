import 'package:flutter/material.dart';

class HabitWelcomeMessage extends StatelessWidget {
  final String? name;
  const HabitWelcomeMessage({
    super.key,
    required this.name
  });

  @override
  Widget build(BuildContext context) {
   return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        'Hello, $name!',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.black54,
        ),
      ),
    );
  }
}