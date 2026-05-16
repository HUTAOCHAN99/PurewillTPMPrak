import 'package:flutter/material.dart';
import 'package:purewill/ui/habit-tracker/controller/reminder_setting_controller.dart';
import 'package:purewill/domain/model/habit_model.dart'; // ADD IMPORT

class ReminderSettingComponents {
  static Widget buildHabitInfoCard(HabitModel habit) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Colors.blue, size: 16),
                SizedBox(width: 4),
                Text(
                  'Current Habit:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('ID: ${habit.id}'),
            Text('Name: "${habit.name}"'),
          ],
        ),
      ),
    );
  }

  static Widget buildRemindersSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminders',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Get notified about important updates',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  static Widget buildNotificationTimeSection(
    ReminderSettingController controller,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notification Time',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildTimePickerCard(controller, context),
        const SizedBox(height: 16),
        _buildSnoozeSection(controller),
      ],
    );
  }

  static Widget _buildTimePickerCard(
    ReminderSettingController controller,
    BuildContext context,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.access_time, color: Colors.blue),
        title: const Text(
          'Reminder Time',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          controller.getTimeString(controller.selectedTime),
          style: const TextStyle(fontSize: 16),
        ),
        onTap: () => _selectTime(context, controller),
        trailing: const Icon(Icons.arrow_drop_down, color: Colors.grey),
      ),
    );
  }

  static Future<void> _selectTime(
    BuildContext context,
    ReminderSettingController controller,
  ) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: controller.selectedTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            // FIXED: menggunakan ThemeData.light() yang sudah include dialog theme
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      controller.setSelectedTime(pickedTime);
    }
  }

  static Widget _buildSnoozeSection(ReminderSettingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Snooze Duration',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        // FIXED: Menggunakan Column dengan RadioListTile untuk menghindari deprecation
        _buildSnoozeOptions(controller),
      ],
    );
  }

  static Widget _buildSnoozeOptions(ReminderSettingController controller) {
    return Column(
      children: [
        for (int i = 0; i < controller.snoozeOptions.length; i++)
          _buildSnoozeListTile(
            '${controller.snoozeOptions[i]} minutes',
            i,
            controller,
          ),
        _buildCustomSnoozeListTile(controller),
      ],
    );
  }

  // FIXED: Menggunakan RadioListTile yang tidak deprecated
  static Widget _buildSnoozeListTile(
    String text,
    int index,
    ReminderSettingController controller,
  ) {
    final isSelected = controller.selectedSnoozeIndex == index &&
        !controller.useCustomSnooze;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 1,
        color: isSelected ? Colors.blue[50] : Colors.white,
        child: RadioListTile<int>(
          value: index,
          groupValue: controller.useCustomSnooze ? null : controller.selectedSnoozeIndex,
          onChanged: (value) {
            if (value != null) {
              controller.setSnoozeOption(value);
            }
          },
          activeColor: Colors.blue,
          title: Text(
            text,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // FIXED: Menggunakan RadioListTile yang tidak deprecated
  static Widget _buildCustomSnoozeListTile(
    ReminderSettingController controller,
  ) {
    final isSelected = controller.useCustomSnooze;

    return Card(
      elevation: 1,
      color: isSelected ? Colors.blue[50] : Colors.white,
      child: RadioListTile<int>(
        value: -1,
        groupValue: isSelected ? -1 : null,
        onChanged: (value) {
          if (value != null) {
            controller.setUseCustomSnooze(true);
          }
        },
        activeColor: Colors.blue,
        title: Row(
          children: [
            const Text('Custom', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 16),
            SizedBox(
              width: 100,
              child: TextField(
                controller: TextEditingController(
                  text: controller.customSnoozeMinutes.toString(),
                ),
                onChanged: (value) {
                  final minutes = int.tryParse(value) ?? 5;
                  controller.setCustomSnooze(minutes);
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Minutes',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildNotificationChannelSection(
    ReminderSettingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notification Channel',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: CheckboxListTile(
            title: const Text(
              'Push Notification',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: const Text('Receive notifications on your device'),
            value: controller.pushNotification,
            onChanged: (value) => controller.setPushNotification(value ?? false),
            activeColor: Colors.blue,
          ),
        ),
      ],
    );
  }

  static Widget buildAdvancedSettingsSection(
    ReminderSettingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Advanced Settings',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Column(
            children: [
              CheckboxListTile(
                title: const Text(
                  'Repeat Daily',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Send reminder every day at the same time'),
                value: controller.repeatDaily,
                onChanged: (value) => controller.setRepeatDaily(value ?? true),
                activeColor: Colors.blue,
              ),
              CheckboxListTile(
                title: const Text(
                  'Sound',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Play sound with notification'),
                value: controller.soundEnabled,
                onChanged: (value) => controller.setSoundEnabled(value ?? true),
                activeColor: Colors.blue,
              ),
              CheckboxListTile(
                title: const Text(
                  'Vibration',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Vibrate device with notification'),
                value: controller.vibrationEnabled,
                onChanged: (value) =>
                    controller.setVibrationEnabled(value ?? false),
                activeColor: Colors.blue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget buildActionButtonsSection(
    ReminderSettingController controller,
  ) {
    return Column(
      children: [
        _buildActionButton(
          onPressed: controller.testNotification,
          icon: Icons.notifications_active,
          label: 'Test Notification',
          color: Colors.blue,
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          onPressed: controller.checkPendingNotifications,
          icon: Icons.list_alt,
          label: 'Check Pending Notifications',
          color: Colors.orange,
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          onPressed: controller.checkPermissions,
          icon: Icons.security,
          label: 'Check Permissions',
          color: Colors.green,
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          onPressed: controller.debugCurrentState,
          icon: Icons.bug_report,
          label: 'Debug Current State',
          color: Colors.purple,
        ),
      ],
    );
  }

  static Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: color),
        ),
      ),
    );
  }

  static Widget buildSaveButton(ReminderSettingController controller) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.isLoading ? null : () => controller.saveSettings(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: controller.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Save Reminder Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}