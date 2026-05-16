// <<<<<<< HEAD
// import 'package:flutter/material.dart';

// class HabitIconHelper {
//   static IconData getHabitIcon(String habitName) {
//     final name = habitName.toLowerCase();

//     if (name.contains('read') || name.contains('book')) {
//       return Icons.menu_book;
//     } else if (name.contains('meditation') ||
//         name.contains('yoga') ||
//         name.contains('mindfulness')) {
//       return Icons.self_improvement;
//     } else if (name.contains('water') ||
//         name.contains('drink') ||
//         name.contains('hydration')) {
//       return Icons.local_drink;
//     } else if (name.contains('exercise') ||
//         name.contains('workout') ||
//         name.contains('gym') ||
//         name.contains('fitness')) {
//       return Icons.fitness_center;
//     } else if (name.contains('study') ||
//         name.contains('learn') ||
//         name.contains('bus')) {
//       return Icons.school;
//     } else if (name.contains('morning') ||
//         name.contains('wake') ||
//         name.contains('worsnet')) {
//       return Icons.wb_sunny;
//     } else if (name.contains('gazebo') ||
//         name.contains('garden') ||
//         name.contains('plant')) {
//       return Icons.nature;
//     } else if (name.contains('crime') ||
//         name.contains('security') ||
//         name.contains('safety')) {
//       return Icons.security;
//     } else if (name.contains('money') ||
//         name.contains('finance') ||
//         name.contains('budget')) {
//       return Icons.attach_money;
//     } else if (name.contains('exhaust') ||
//         name.contains('energy') ||
//         name.contains('tired')) {
//       return Icons.energy_savings_leaf;
//     } else {
//       return Icons.check_circle;
//     }
//   }

//   static Color getHabitColor(String habitName) {
//     final name = habitName.toLowerCase();

//     if (name.contains('read') || name.contains('book')) {
//       return const Color(0xFF2196F3);
//     } else if (name.contains('meditation') ||
//         name.contains('yoga') ||
//         name.contains('mindfulness')) {
//       return const Color(0xFF9C27B0);
//     } else if (name.contains('water') ||
//         name.contains('drink') ||
//         name.contains('hydration')) {
//       return const Color(0xFF00BCD4);
//     } else if (name.contains('exercise') ||
//         name.contains('workout') ||
//         name.contains('gym') ||
//         name.contains('fitness')) {
//       return const Color(0xFFFF5722);
//     } else if (name.contains('study') ||
//         name.contains('learn') ||
//         name.contains('bus')) {
//       return const Color(0xFF673AB7);
//     } else if (name.contains('morning') ||
//         name.contains('wake') ||
//         name.contains('worsnet')) {
//       return const Color(0xFFFF9800);
//     } else if (name.contains('gazebo') ||
//         name.contains('garden') ||
//         name.contains('plant')) {
//       return const Color(0xFF4CAF50);
//     } else if (name.contains('crime') ||
//         name.contains('security') ||
//         name.contains('safety')) {
//       return const Color(0xFFF44336);
//     } else if (name.contains('money') ||
//         name.contains('finance') ||
//         name.contains('budget')) {
//       return const Color(0xFFFFC107);
//     } else if (name.contains('exhaust') ||
//         name.contains('energy') ||
//         name.contains('tired')) {
//       return const Color(0xFF795548);
//     } else {
//       return const Color(0xFF607D8B);
// =======
// lib\utils\habit_icon_helper.dart
import 'package:flutter/material.dart';

class HabitIconHelper {
  // Method untuk mendapatkan icon berdasarkan nama habit ATAU kategori
  static IconData getHabitIcon(String habitNameOrCategory) {
    final name = habitNameOrCategory.toLowerCase();
    
    // Cek berdasarkan kategori dari tabel (exact match dulu)
    if (name == 'health & fitness' || name.contains('health') || name.contains('fitness')) {
      return Icons.favorite;
    } else if (name == 'learning & education' || name.contains('learning') || name.contains('education')) {
      return Icons.school;
    } else if (name == 'productivity') {
      return Icons.timer;
    } else if (name == 'mindfulness & mental health' || name.contains('mindfulness') || name.contains('mental')) {
      return Icons.self_improvement;
    } else if (name == 'personal care') {
      return Icons.person;
    } else if (name == 'social & relationships' || name.contains('social') || name.contains('relationship')) {
      return Icons.people;
    } else if (name == 'finance') {
      return Icons.attach_money;
    } else if (name == 'hobbies & creativity' || name.contains('hobbies') || name.contains('creativity')) {
      return Icons.palette;
    } else if (name == 'work & career' || name.contains('work') || name.contains('career')) {
      return Icons.work;
    } else if (name == 'other') {
      return Icons.category;
    }
    
    // Jika bukan kategori, coba mapping dari nama habit
    final habitName = habitNameOrCategory.toLowerCase();
    
    // Mapping spesifik untuk habit-habit Anda
    if (habitName.contains('main') || habitName.contains('genshin') || habitName.contains('uma musume') || habitName.contains('game')) {
      return Icons.videogame_asset;
    } else if (habitName.contains('sleep') || habitName.contains('turu') || habitName.contains('early')) {
      return Icons.bedtime;
    } else if (habitName.contains('nabung') || habitName.contains('uang') || habitName.contains('money')) {
      return Icons.savings;
    } else if (habitName.contains('ngising') || habitName.contains('toilet')) {
      return Icons.wc;
    } else if (habitName.contains('mandi') || habitName.contains('bath')) {
      return Icons.shower;
    } else if (habitName.contains('belajar') || habitName.contains('javascript') || habitName.contains('koding') || habitName.contains('java')) {
      return Icons.code;
    } else if (habitName.contains('oke') || habitName.contains('haooo')) {
      return Icons.check_circle;
    }
    
    // Fallback berdasarkan kata kunci umum
    if (habitName.contains('read') || habitName.contains('book')) {
      return Icons.menu_book;
    } else if (habitName.contains('meditation') || habitName.contains('yoga')) {
      return Icons.self_improvement;
    } else if (habitName.contains('water') || habitName.contains('drink') || habitName.contains('hydration')) {
      return Icons.local_drink;
    } else if (habitName.contains('exercise') || habitName.contains('workout') || habitName.contains('gym') || habitName.contains('run')) {
      return Icons.fitness_center;
    } else if (habitName.contains('study') || habitName.contains('learn')) {
      return Icons.school;
    } else if (habitName.contains('morning') || habitName.contains('wake')) {
      return Icons.wb_sunny;
    } else if (habitName.contains('garden') || habitName.contains('plant')) {
      return Icons.nature;
    } else if (habitName.contains('security') || habitName.contains('safety')) {
      return Icons.security;
    } else if (habitName.contains('money') || habitName.contains('finance') || habitName.contains('budget')) {
      return Icons.attach_money;
// >>>>>>> f2d2932ae1d617906d117abaeeb90fd7045aea0c
    }
    
    // Default
    return Icons.check_circle;
  }

  static Color getHabitColor(String habitNameOrCategory) {
    final name = habitNameOrCategory.toLowerCase();
    
    // Cek berdasarkan kategori dari tabel
    if (name == 'health & fitness' || name.contains('health') || name.contains('fitness')) {
      return const Color(0xFFE91E63); // Pink
    } else if (name == 'learning & education' || name.contains('learning') || name.contains('education')) {
      return const Color(0xFF3F51B5); // Indigo
    } else if (name == 'productivity') {
      return const Color(0xFF009688); // Teal
    } else if (name == 'mindfulness & mental health' || name.contains('mindfulness') || name.contains('mental')) {
      return const Color(0xFF9C27B0); // Purple
    } else if (name == 'personal care') {
      return const Color(0xFF00BCD4); // Cyan
    } else if (name == 'social & relationships' || name.contains('social') || name.contains('relationship')) {
      return const Color(0xFFFF9800); // Orange
    } else if (name == 'finance') {
      return const Color(0xFFFFC107); // Amber
    } else if (name == 'hobbies & creativity' || name.contains('hobbies') || name.contains('creativity')) {
      return const Color(0xFF9C27B0); // Purple
    } else if (name == 'work & career' || name.contains('work') || name.contains('career')) {
      return const Color(0xFF607D8B); // Blue Grey
    } else if (name == 'other') {
      return const Color(0xFF795548); // Brown
    }
    
    // Jika bukan kategori, coba mapping dari nama habit
    final habitName = habitNameOrCategory.toLowerCase();
    
    // Mapping spesifik untuk habit-habit Anda
    if (habitName.contains('main') || habitName.contains('genshin') || habitName.contains('uma musume') || habitName.contains('game')) {
      return const Color(0xFF9C27B0); // Purple untuk game
    } else if (habitName.contains('sleep') || habitName.contains('turu') || habitName.contains('early')) {
      return const Color(0xFF2196F3); // Blue untuk tidur
    } else if (habitName.contains('nabung') || habitName.contains('uang') || habitName.contains('money')) {
      return const Color(0xFFFFC107); // Amber untuk keuangan
    } else if (habitName.contains('ngising') || habitName.contains('toilet')) {
      return const Color(0xFF795548); // Brown
    } else if (habitName.contains('mandi') || habitName.contains('bath')) {
      return const Color(0xFF00BCD4); // Cyan untuk mandi
    } else if (habitName.contains('belajar') || habitName.contains('javascript') || habitName.contains('koding') || habitName.contains('java')) {
      return const Color(0xFF3F51B5); // Indigo untuk belajar
    } else if (habitName.contains('oke') || habitName.contains('haooo')) {
      return const Color(0xFF4CAF50); // Green untuk general
    }
    
    // Fallback berdasarkan kata kunci umum
    if (habitName.contains('read') || habitName.contains('book')) {
      return const Color(0xFF2196F3); // Blue
    } else if (habitName.contains('meditation') || habitName.contains('yoga')) {
      return const Color(0xFF9C27B0); // Purple
    } else if (habitName.contains('water') || habitName.contains('drink') || habitName.contains('hydration')) {
      return const Color(0xFF00BCD4); // Cyan
    } else if (habitName.contains('exercise') || habitName.contains('workout') || habitName.contains('gym') || habitName.contains('run')) {
      return const Color(0xFFFF5722); // Deep Orange
    }
    
    // Default
    return const Color(0xFF607D8B); // Blue Grey
  }

  // Method untuk menentukan kategori dari habit name (untuk habit yang categoryId = null)
  static String getHabitCategory(String habitName) {
    final name = habitName.toLowerCase();
// <<<<<<< HEAD

//     if (name.contains('read') ||
//         name.contains('book') ||
//         name.contains('study') ||
//         name.contains('learn')) {
//       return "Education";
//     } else if (name.contains('meditation') ||
//         name.contains('yoga') ||
//         name.contains('mindfulness')) {
//       return "Wellness";
//     } else if (name.contains('water') ||
//         name.contains('drink') ||
//         name.contains('hydration')) {
//       return "Health";
//     } else if (name.contains('exercise') ||
//         name.contains('workout') ||
//         name.contains('gym') ||
//         name.contains('fitness')) {
//       return "Fitness";
//     } else if (name.contains('morning') ||
//         name.contains('wake') ||
//         name.contains('worsnet')) {
//       return "Routine";
//     } else if (name.contains('gazebo') ||
//         name.contains('garden') ||
//         name.contains('plant')) {
//       return "Home";
//     } else if (name.contains('crime') ||
//         name.contains('security') ||
//         name.contains('safety')) {
//       return "Safety";
//     } else if (name.contains('money') ||
//         name.contains('finance') ||
//         name.contains('budget')) {
//       return "Finance";
//     } else if (name.contains('exhaust') ||
//         name.contains('energy') ||
//         name.contains('tired')) {
//       return "Energy";
// =======
    
    // Mapping spesifik untuk habit-habit Anda
    if (name.contains('main genshin') || name.contains('main uma musume') || name.contains('game')) {
      return "Hobbies & Creativity";
    } else if (name.contains('sleep early') || name.contains('turu')) {
      return "Health & Fitness";
    } else if (name.contains('nabung')) {
      return "Finance";
    } else if (name.contains('ngising')) {
      return "Personal Care";
    } else if (name.contains('mandi')) {
      return "Personal Care";
    } else if (name.contains('belajar javascript') || name.contains('koding java')) {
      return "Learning & Education";
    } else if (name.contains('oke') || name.contains('haooo')) {
      return "Other";
    }
    
    // Mapping umum berdasarkan kata kunci
    if (name.contains('exercise') || name.contains('workout') || name.contains('gym') || 
        name.contains('fitness') || name.contains('yoga') || name.contains('run') ||
        name.contains('sport') || name.contains('health') || name.contains('diet') ||
        name.contains('sleep') || name.contains('rest')) {
      return "Health & Fitness";
    } else if (name.contains('read') || name.contains('book') || name.contains('study') || 
               name.contains('learn') || name.contains('course') || name.contains('education') ||
               name.contains('school') || name.contains('javascript') || name.contains('java') ||
               name.contains('code') || name.contains('programming')) {
      return "Learning & Education";
    } else if (name.contains('meditation') || name.contains('mindfulness') || 
               name.contains('mental') || name.contains('therapy')) {
      return "Mindfulness & Mental Health";
    } else if (name.contains('money') || name.contains('finance') || name.contains('budget') ||
               name.contains('save') || name.contains('invest') || name.contains('spend') ||
               name.contains('nabung') || name.contains('uang')) {
      return "Finance";
    } else if (name.contains('work') || name.contains('career') || name.contains('job') ||
               name.contains('office') || name.contains('business') || name.contains('meeting')) {
      return "Work & Career";
    } else if (name.contains('social') || name.contains('friend') || name.contains('family') ||
               name.contains('relationship') || name.contains('date') || name.contains('people') ||
               name.contains('party') || name.contains('chat')) {
      return "Social & Relationships";
    } else if (name.contains('hobby') || name.contains('game') || name.contains('play') ||
               name.contains('music') || name.contains('guitar') || name.contains('art') ||
               name.contains('creative') || name.contains('craft') || name.contains('palette') ||
               name.contains('genshin') || name.contains('uma musume')) {
      return "Hobbies & Creativity";
    } else if (name.contains('productivity') || name.contains('task') || name.contains('todo') ||
               name.contains('schedule') || name.contains('plan') || name.contains('organize') ||
               name.contains('timer') || name.contains('focus')) {
      return "Productivity";
    } else if (name.contains('care') || name.contains('bath') || name.contains('shower') ||
               name.contains('groom') || name.contains('person') || name.contains('hygiene') ||
               name.contains('clean') || name.contains('mandi') || name.contains('ngising') ||
               name.contains('toilet')) {
      return "Personal Care";
// >>>>>>> f2d2932ae1d617906d117abaeeb90fd7045aea0c
    } else {
      return "Other";
    }
  }
}
