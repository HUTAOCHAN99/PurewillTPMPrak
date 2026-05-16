import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/data/services/local_notification_service.dart';
import 'package:purewill/domain/model/habit_model.dart';
import 'package:purewill/data/repository/reminder_setting_repository.dart';
import 'package:purewill/domain/model/reminder_setting_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controller/reminder_setting_controller.dart';

class ReminderSettingScreen extends ConsumerStatefulWidget {
  final HabitModel habit;
  final ReminderSettingModel? reminderSetting;
  const ReminderSettingScreen({
    super.key,
    required this.habit,
    this.reminderSetting,
  });
  @override
  ConsumerState<ReminderSettingScreen> createState() =>
      _ReminderSettingScreenState();
}

class _ReminderSettingScreenState extends ConsumerState<ReminderSettingScreen> {
  late ReminderSettingController _controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Variabel untuk live clock
  DateTime _currentTime = DateTime.now();
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _startLiveClock();
  }

  void _initializeController() {
    _controller = ReminderSettingController(
      habit: widget.habit,
      repository: ReminderSettingRepository(Supabase.instance.client),
      notificationService: LocalNotificationService(),
    )..addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _startLiveClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _timer.cancel();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveSettings() async {
    try {
      await _controller.saveSettings();
      _showSnackBar('Reminder settings saved successfully!');
    } catch (e) {
      _showSnackBar('Failed to save settings: $e', isError: true);
    }
  }

  Future<void> _testNotification() async {
    try {
      await _controller.testNotification();
      _showSnackBar('Test notification sent!');
    } catch (e) {
      _showSnackBar('Failed to send test notification: $e', isError: true);
    }
  }

  Future<void> _checkPendingNotifications() async {
    try {
      await _controller.checkPendingNotifications();
      _showSnackBar('Pending notifications checked - see console for details');
    } catch (e) {
      _showSnackBar('Failed to check notifications: $e', isError: true);
    }
  }

  Future<void> _checkPermissions() async {
    try {
      await _controller.checkPermissions();
      _showSnackBar('Permission check completed - see console for details');
    } catch (e) {
      _showSnackBar('Failed to check permissions: $e', isError: true);
    }
  }

  Future<void> _resetReminderData() async {
    try {
      await _controller.resetReminderData();
      _showSnackBar('Reminder data reset successfully');
    } catch (e) {
      _showSnackBar('Failed to reset data: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(
          'Reminder Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.blue[50],
        foregroundColor: Colors.blue[800],
        elevation: 0,
        actions: [
          // Debug button
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: _controller.debugCurrentState,
            tooltip: 'Debug Current State',
          ),
          // Save button di appbar jika ada perubahan
          if (_controller.hasChanges && !_controller.isLoading)
            TextButton(
              onPressed: _saveSettings,
              child: const Text(
                'SAVE',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _controller.isLoading ? const _LoadingState() : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Clock Debug Section - DITAMBAHKAN
          _buildLiveClockSection(),

          const SizedBox(height: 16),

          // Header Info
          _buildHeaderSection(),

          const SizedBox(height: 24),

          // Main Reminder Settings
          _buildMainSettingsSection(),

          const SizedBox(height: 24),

          // Advanced Settings
          _buildAdvancedSettingsSection(),

          const SizedBox(height: 24),

          // Testing Tools
          _buildTestingToolsSection(),

          const SizedBox(height: 32),

          // Save Button
          _buildSaveButton(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // WIDGET BARU: Live Clock Section
  Widget _buildLiveClockSection() {
    return Card(
      elevation: 2,
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange[300]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            const Row(
              children: [
                Icon(Icons.access_time, size: 20, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Device Time Debug',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Current Time Display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Device Time:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(_currentTime),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Date:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(_currentTime),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Timezone Info
            FutureBuilder<String>(
              future: _getTimezoneInfo(),
              builder: (context, snapshot) {
                return Text(
                  snapshot.data ?? 'Loading timezone info...',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            // Selected Time Comparison
            _buildTimeComparison(),
          ],
        ),
      ),
    );
  }

  // Method untuk mendapatkan info timezone
  Future<String> _getTimezoneInfo() async {
    try {
      final timezoneOffset = _currentTime.timeZoneOffset;
      final isDST = _currentTime.timeZoneName.contains('DT');
      final hours = timezoneOffset.inHours;
      final minutes = timezoneOffset.inMinutes.remainder(60);
      final sign = hours >= 0 ? '+' : '-';

      return 'Timezone: UTC${sign}${hours.abs().toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} • ${_currentTime.timeZoneName} ${isDST ? '(Daylight Saving)' : ''}';
    } catch (e) {
      return 'Timezone: Unable to determine';
    }
  }

  // Widget untuk perbandingan waktu yang dipilih dengan waktu sekarang
  Widget _buildTimeComparison() {
    final selectedTime = _controller.selectedTime;
    final now = _currentTime;

    // Buat DateTime dengan waktu yang dipilih untuk hari ini
    final selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
      0,
    );

    final difference = selectedDateTime.difference(now);
    final isPast = difference.isNegative;
    final absoluteDifference = difference.abs();

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isPast) {
      statusText =
          'Selected time was ${_formatDuration(absoluteDifference)} ago';
      statusColor = Colors.red;
      statusIcon = Icons.schedule;
    } else {
      statusText = 'Selected time is in ${_formatDuration(absoluteDifference)}';
      statusColor = Colors.green;
      statusIcon = Icons.timer;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 16),
              const SizedBox(width: 8),
              Text(
                'Time Comparison',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Selected: ${_controller.getTimeString(selectedTime)}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Text(
            'Current: ${_formatTime(now)}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Habit Info Card
        Card(
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
                Text('ID: ${widget.habit.id}'),
                Text('Name: "${widget.habit.name}"'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Status Info
        _buildStatusInfo(),
      ],
    );
  }

  Widget _buildStatusInfo() {
    final hasReminder =
        _controller.reminderSetting != null &&
        _controller.reminderSetting!.isEnabled;

    String statusText;
    Color statusColor;

    if (hasReminder) {
      statusText = _controller.reminderSetting!.dynamicTimeDisplay;
      statusColor = Colors.green;
    } else {
      statusText = 'No active reminder set';
      statusColor = Colors.grey;
    }

    return Card(
      color: hasReminder ? Colors.green[50] : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              hasReminder
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: hasReminder ? statusColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                statusText,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: hasReminder ? statusColor : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainSettingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            const Row(
              children: [
                Icon(Icons.settings, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Reminder Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Enable/Disable Toggle
            _buildEnableToggle(),

            const SizedBox(height: 16),

            // Time Picker
            _buildTimePicker(),

            const SizedBox(height: 16),

            // Snooze Settings
            _buildSnoozeSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnableToggle() {
    return Card(
      elevation: 1,
      color: Colors.grey[50],
      child: SwitchListTile(
        title: const Text(
          'Enable Reminder',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: const Text('Receive notifications for this habit'),
        value: _controller.pushNotification,
        onChanged: (value) => _controller.setPushNotification(value),
        activeColor: Colors.blue,
        secondary: const Icon(Icons.notifications, color: Colors.blue),
      ),
    );
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reminder Time',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.access_time, color: Colors.blue),
            title: const Text(
              'Set Time',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              _controller.getTimeString(_controller.selectedTime),
              style: const TextStyle(fontSize: 16),
            ),
            trailing: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            onTap: () => _showTimePicker(),
          ),
        ),
      ],
    );
  }

  Widget _buildSnoozeSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Snooze Duration',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'How long to wait before reminding again',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 12),

        // Snooze Options
        Column(
          children: [
            for (int i = 0; i < _controller.snoozeOptions.length; i++)
              _buildSnoozeOption(i),
            _buildCustomSnoozeOption(),
          ],
        ),
      ],
    );
  }

  Widget _buildSnoozeOption(int index) {
    final isSelected =
        _controller.selectedSnoozeIndex == index &&
        !_controller.useCustomSnooze;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 1,
        color: isSelected ? Colors.blue[50] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: RadioListTile<int>(
          value: index,
          groupValue: _controller.useCustomSnooze
              ? null
              : _controller.selectedSnoozeIndex,
          onChanged: (value) {
            if (value != null) {
              _controller.setSnoozeOption(value);
            }
          },
          activeColor: Colors.blue,
          title: Text(
            '${_controller.snoozeOptions[index]} minutes',
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.blue[800] : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomSnoozeOption() {
    final isSelected = _controller.useCustomSnooze;

    return Card(
      elevation: 1,
      color: isSelected ? Colors.blue[50] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<int>(
        value: -1,
        groupValue: isSelected ? -1 : null,
        onChanged: (value) {
          if (value != null) {
            _controller.setUseCustomSnooze(true);
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
                  text: _controller.customSnoozeMinutes.toString(),
                ),
                onChanged: (value) {
                  final minutes = int.tryParse(value) ?? 5;
                  _controller.setCustomSnooze(minutes);
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

  Widget _buildAdvancedSettingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            const Row(
              children: [
                Icon(Icons.tune, size: 20, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Advanced Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Repeat Daily
            _buildAdvancedOption(
              title: 'Repeat Daily',
              subtitle: 'Send reminder every day at the same time',
              value: _controller.repeatDaily,
              onChanged: _controller.setRepeatDaily,
              icon: Icons.repeat,
            ),

            const Divider(height: 1),

            // Sound
            _buildAdvancedOption(
              title: 'Sound',
              subtitle: 'Play sound with notification',
              value: _controller.soundEnabled,
              onChanged: _controller.setSoundEnabled,
              icon: Icons.volume_up,
            ),

            const Divider(height: 1),

            // Vibration
            _buildAdvancedOption(
              title: 'Vibration',
              subtitle: 'Vibrate device with notification',
              value: _controller.vibrationEnabled,
              onChanged: _controller.setVibrationEnabled,
              icon: Icons.vibration,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOption({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.purple),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.purple,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildTestingToolsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.build, size: 20, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Testing Tools',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Text(
              'Use these tools to test and debug notifications',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 16),

            // Test Buttons
            Column(
              children: [
                _buildTestButton(
                  icon: Icons.notifications_active,
                  label: 'Test Immediate Notification',
                  color: Colors.green,
                  onPressed: _testNotification,
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  icon: Icons.list_alt,
                  label: 'Check Pending Notifications',
                  color: Colors.blue,
                  onPressed: _checkPendingNotifications,
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  icon: Icons.security,
                  label: 'Check Permissions',
                  color: Colors.purple,
                  onPressed: _checkPermissions,
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  icon: Icons.restart_alt,
                  label: 'Reset Reminder Data',
                  color: Colors.red,
                  onPressed: _resetReminderData,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w500, color: color),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Column(
      children: [
        if (_controller.hasChanges)
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have unsaved changes',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _controller.isLoading ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _controller.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Save Reminder Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _showTimePicker() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _controller.selectedTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            timePickerTheme: const TimePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null && pickedTime != _controller.selectedTime) {
      _controller.setSelectedTime(pickedTime);
      _showSnackBar('Time set to ${_controller.getTimeString(pickedTime)}');
    }
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading reminder settings...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
