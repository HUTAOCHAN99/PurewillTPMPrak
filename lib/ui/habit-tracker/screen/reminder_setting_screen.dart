// lib/ui/habit-tracker/screen/reminder_setting_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/data/services/local_notification_service.dart';
import 'package:purewill/data/services/reminder_sync_service.dart';
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
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

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    
    Color backgroundColor;
    IconData icon;
    
    if (isError) {
      backgroundColor = Colors.red.shade700;
      icon = Icons.error_outline;
    } else if (isSuccess) {
      backgroundColor = Colors.green.shade700;
      icon = Icons.check_circle_outline;
    } else {
      backgroundColor = Colors.blue.shade700;
      icon = Icons.info_outline;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });
    
    _showSnackBar('Saving reminder settings...');
    
    try {
      final result = await _controller.saveSettings();
      
      if (mounted) {
        if (result['success'] == true) {
          _showSnackBar(result['message'], isSuccess: true);
          await Future.delayed(const Duration(seconds: 1));
          await _checkPendingNotifications();
        } else {
          _showSnackBar(result['message'] ?? 'Failed to save settings', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _testNotification() async {
    _showSnackBar('Sending test notification...');
    
    final result = await _controller.testNotification();
    
    if (mounted) {
      if (result['success'] == true) {
        _showSnackBar('Test notification sent! Check your notification panel.', isSuccess: true);
      } else {
        _showSnackBar('Test failed: ${result['message']}', isError: true);
      }
    }
  }

  Future<void> _testImmediateNotification() async {
    _showSnackBar('Sending immediate test notification...');
    
    try {
      final notificationService = LocalNotificationService();
      final result = await notificationService.showImmediateTestNotification(
        title: 'Test: ${widget.habit.name}',
        body: 'This is an immediate test notification',
        id: DateTime.now().millisecondsSinceEpoch % 100000,
      );
      
      if (mounted) {
        if (result['success'] == true) {
          _showSnackBar('Immediate test notification sent!', isSuccess: true);
        } else {
          _showSnackBar('Immediate test failed: ${result['message']}', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  Future<void> _testOneMinuteNotification() async {
    _showSnackBar('Scheduling test notification in 1 minute...');
    
    try {
      final notificationService = LocalNotificationService();
      final now = DateTime.now();
      final oneMinuteLater = TimeOfDay(
        hour: now.add(const Duration(minutes: 1)).hour,
        minute: now.add(const Duration(minutes: 1)).minute,
      );
      
      final result = await notificationService.scheduleHabitReminder(
        id: 8888,
        title: '1-Minute Test: ${widget.habit.name}',
        body: 'This notification should appear in 1 minute',
        time: oneMinuteLater,
        habitId: widget.habit.id.toString(),
        repeatDaily: false,
        enableSound: true,
        enableVibration: true,
      );
      
      if (mounted) {
        if (result['success'] == true) {
          _showSnackBar('Test notification scheduled for ${_formatTimeOfDay(oneMinuteLater)}', isSuccess: true);
        } else {
          _showSnackBar('Test scheduling failed: ${result['message']}', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  Future<void> _testForegroundNotification() async {
    _showSnackBar('Sending foreground test...');
    
    final result = await _controller.testForegroundNotification();
    
    if (mounted) {
      if (result['success'] == true) {
        _showSnackBar('Foreground test notification sent!', isSuccess: true);
      } else {
        _showSnackBar('Foreground test failed: ${result['message']}', isError: true);
      }
    }
  }

  Future<void> _checkPendingNotifications() async {
    _showSnackBar('Checking pending notifications...');
    await _controller.checkPendingNotifications();
    if (mounted) {
      _showSnackBar('Check completed. See console for details.', isSuccess: true);
    }
  }

  Future<void> _forceRescheduleReminders() async {
    _showSnackBar('Force rescheduling all reminders...');
    
    try {
      final reminderSyncService = ReminderSyncService();
      await reminderSyncService.rescheduleAllReminders();
      if (mounted) {
        _showSnackBar('All reminders rescheduled successfully!', isSuccess: true);
        await _checkPendingNotifications();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Reschedule failed: $e', isError: true);
      }
    }
  }

  Future<void> _checkPermissions() async {
    _showSnackBar('Checking permissions...');
    
    final result = await _controller.checkPermissions();
    
    if (mounted) {
      if (result['success'] == true) {
        _showSnackBar(result['message'], isSuccess: true);
      } else {
        _showSnackBar(result['message'], isError: true);
      }
    }
  }

  Future<void> _resetReminderData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Reminder Data'),
        content: const Text(
          'Are you sure you want to reset all reminder data for this habit? '
          'This will delete all saved reminder settings and cancel scheduled notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      _showSnackBar('Resetting reminder data...');
      try {
        await _controller.resetReminderData();
        if (mounted) {
          _showSnackBar('Reminder data reset successfully', isSuccess: true);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Reset failed: $e', isError: true);
        }
      }
    }
  }

  void _showDebugInfo() {
    _controller.debugCurrentState();
    _showSnackBar('Debug info printed to console', isSuccess: true);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
          if (_controller.hasChanges && !_controller.isLoading && !_isSaving)
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.blue),
            onSelected: (value) {
              switch (value) {
                case 'debug':
                  _showDebugInfo();
                  break;
                case 'reset':
                  _resetReminderData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'debug',
                child: Row(
                  children: [
                    Icon(Icons.bug_report, size: 20),
                    SizedBox(width: 12),
                    Text('Debug Info'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Reset Data', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
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
          _buildHeaderSection(),
          const SizedBox(height: 24),
          _buildMainSettingsSection(),
          const SizedBox(height: 24),
          _buildAdvancedSettingsSection(),
          const SizedBox(height: 24),
          _buildTestingToolsSection(),
          const SizedBox(height: 24),
          _buildDebugSection(),
          const SizedBox(height: 32),
          _buildSaveButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Colors.blue[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    IconData statusIcon;

    if (hasReminder) {
      statusText = 'Reminder at ${_controller.reminderSetting!.formattedTime}';
      statusColor = Colors.green;
      statusIcon = Icons.notifications_active;
    } else {
      statusText = 'No active reminder set';
      statusColor = Colors.grey;
      statusIcon = Icons.notifications_off;
    }

    return Card(
      color: hasReminder ? Colors.green[50] : Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(statusIcon, color: hasReminder ? statusColor : Colors.grey, size: 20),
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
            _buildEnableToggle(),
            const SizedBox(height: 16),
            _buildTimePicker(),
            const SizedBox(height: 16),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SwitchListTile(
        title: const Text(
          'Enable Reminder',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: const Text('Receive notifications for this habit'),
        value: _controller.pushNotification,
        onChanged: (value) => _controller.setPushNotification(value),
        activeTrackColor: Colors.blue,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            _buildAdvancedOption(
              title: 'Repeat Daily',
              subtitle: 'Send reminder every day at the same time',
              value: _controller.repeatDaily,
              onChanged: _controller.setRepeatDaily,
              icon: Icons.repeat,
            ),
            const Divider(height: 1),
            _buildAdvancedOption(
              title: 'Sound',
              subtitle: 'Play sound with notification',
              value: _controller.soundEnabled,
              onChanged: _controller.setSoundEnabled,
              icon: Icons.volume_up,
            ),
            const Divider(height: 1),
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
        activeTrackColor: Colors.purple,
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
            Column(
              children: [
                _buildTestButton(
                  icon: Icons.notifications_active,
                  label: 'Test Immediate Notification',
                  color: Colors.red,
                  onPressed: _testImmediateNotification,
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  icon: Icons.timer,
                  label: 'Test 1-Minute Notification',
                  color: Colors.orange,
                  onPressed: _testOneMinuteNotification,
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  icon: Icons.notifications_active,
                  label: 'Test Scheduled Notification',
                  color: Colors.green,
                  onPressed: _testNotification,
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  icon: Icons.notifications_active,
                  label: 'Test Foreground Notification',
                  color: Colors.teal,
                  onPressed: _testForegroundNotification,
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
                  icon: Icons.refresh,
                  label: 'Force Reschedule All Reminders',
                  color: Colors.purple,
                  onPressed: _forceRescheduleReminders,
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  icon: Icons.security,
                  label: 'Check Permissions',
                  color: Colors.indigo,
                  onPressed: _checkPermissions,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugSection() {
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
                Icon(Icons.bug_report, size: 20, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Debug Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_controller.lastErrorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last Error:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _controller.lastErrorMessage!,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ],
                ),
              ),
            if (_controller.lastDebugMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last Debug:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _controller.lastDebugMessage!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildTestButton(
              icon: Icons.bug_report,
              label: 'Show Debug Info (Console)',
              color: Colors.deepPurple,
              onPressed: _showDebugInfo,
            ),
            const SizedBox(height: 8),
            _buildTestButton(
              icon: Icons.restart_alt,
              label: 'Reset All Reminder Data',
              color: Colors.red,
              onPressed: _resetReminderData,
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You have unsaved changes',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _saveSettings,
                    child: const Text('SAVE NOW'),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_controller.isLoading || _isSaving) ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: (_controller.isLoading || _isSaving)
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
      if (mounted) {
        _showSnackBar('Time set to ${_controller.getTimeString(pickedTime)}', isSuccess: true);
      }
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