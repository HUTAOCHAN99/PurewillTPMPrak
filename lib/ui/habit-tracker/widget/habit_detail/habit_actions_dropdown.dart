import 'package:flutter/material.dart';
import 'package:purewill/domain/model/habit_model.dart';
import 'package:purewill/ui/habit-tracker/screen/edit_habit_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/reminder_setting_screen.dart';

class HabitActionsDropdown extends StatelessWidget {
  final Function(String) onActionSelected;
  final String habitName;
  final HabitModel habit;

  const HabitActionsDropdown({
    super.key,
    required this.onActionSelected,
    required this.habitName,
    required this.habit,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: onActionSelected,
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('Edit Habit'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'reminder',
          child: Row(
            children: [
              Icon(Icons.notifications, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('Reminder Settings'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Delete Habit'),
            ],
          ),
        ),
      ],
    );
  }

  static void showDeleteConfirmationDialog({
    required BuildContext context,
    required String habitName,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "$habitName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  static void handleMenuAction({
    required String value,
    required BuildContext context,
    required String habitName,
    required HabitModel habit,
    VoidCallback? onEdit,
    VoidCallback? onReminder,
    VoidCallback? onDelete,
  }) {
    switch (value) {
      case 'edit':
        if (onEdit != null) {
          onEdit();
        } else {
          _navigateToEditScreen(context, habit);
        }
        break;
      case 'reminder':
        if (onReminder != null) {
          onReminder();
        } else {
          _navigateToReminderSettings(context, habit);
        }
        break;
      case 'delete':
        if (onDelete != null) {
          onDelete();
        } else {
          showDeleteConfirmationDialog(
            context: context,
            habitName: habitName,
            onConfirm: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"$habitName" deleted')),
              );
              Navigator.pop(context); // Kembali ke home setelah delete
            },
          );
        }
        break;
    }
  }

  static void _navigateToEditScreen(BuildContext context, HabitModel habit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditHabitScreen(habit: habit),
      ),
    );
  }

  static void _navigateToReminderSettings(BuildContext context, HabitModel habit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderSettingScreen(habit: habit),
      ),
    );
  }

  // static void _showComingSoonSnackBar(BuildContext context, String feature) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text('$feature - Coming Soon')),
  //   );
  // }
}