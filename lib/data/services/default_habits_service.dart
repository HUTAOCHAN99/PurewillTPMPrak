import 'package:flutter/material.dart';
import 'package:purewill/domain/model/habit_model.dart';

class DefaultHabitsService {
  static List<HabitModel> getDefaultHabits() {
    return [
      HabitModel(
        id: -1,
        userId: 'default',
        name: 'NoFap',
        frequency: 'daily',
        startDate: DateTime.now(),
        isActive: false,
        status: 'neutral',
        isDefault: true,
      ),
      // HabitModel(
      //   id: -2,
      //   userId: 'default',
      //   name: 'Read Books',
      //   frequency: 'daily',
      //   startDate: DateTime.now(),
      //   targetValue: 20,
      //   unit: 'pages',
      //   isActive: true,
      //   status: 'neutral',
      //   isDefault: true,
      // ),
      // HabitModel(
      //   id: -3,
      //   userId: 'default',
      //   name: 'Drink Water',
      //   frequency: 'daily',
      //   startDate: DateTime.now(),
      //   targetValue: 8,
      //   unit: 'glasses',
      //   isActive: true,
      //   status: 'neutral',
      //   isDefault: true,
      // ),
      // HabitModel(
      //   id: -4,
      //   userId: 'default',
      //   name: 'Sleep Early',
      //   frequency: 'daily',
      //   startDate: DateTime.now(),
      //   targetValue: 1,
      //   unit: 'hours',
      //   isActive: true,
      //   status: 'neutral',
      //   isDefault: true,
      // ),
    ];
  }

  static Map<String, IconData> getDefaultHabitIcons() {
    return {
      'Morning Workout': Icons.fitness_center,
      'Read Books': Icons.menu_book_rounded,
      'Drink Water': Icons.water_drop,
      'Sleep Early': Icons.nightlight_round,
    };
  }

  static Map<String, Color> getDefaultHabitColors() {
    return {
      'Morning Workout': Colors.green,
      'Read Books': Colors.green,
      'Drink Water': Colors.amber,
      'Sleep Early': Colors.blue,
    };
  }

  static String? getDefaultHabitUnit(String habitName) {
    final habits = getDefaultHabits();
    final habit = habits.firstWhere(
      (h) => h.name == habitName,
      orElse: () => HabitModel(
        id: 0,
        userId: '',
        name: '',
        frequency: 'daily',
        startDate: DateTime.now(),
      ),
    );
    return habit.unit;
  }
}
