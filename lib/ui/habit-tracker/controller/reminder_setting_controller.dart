// lib/ui/habit-tracker/controller/reminder_setting_controller.dart
import 'package:flutter/material.dart';
import 'package:purewill/data/services/local_notification_service.dart';
import 'package:purewill/domain/model/habit_model.dart';
import 'package:purewill/domain/model/reminder_setting_model.dart';
import 'package:purewill/data/repository/reminder_setting_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;

class ReminderSettingController with ChangeNotifier {
  final HabitModel habit;
  final ReminderSettingRepository _repository;
  final LocalNotificationService _notificationService;

  ReminderSettingModel? _reminderSetting;
  bool _isLoading = true;
  bool _hasChanges = false;
  String? _lastErrorMessage;
  String? _lastDebugMessage;

  // Form state
  final List<int> _snoozeOptions = [5, 10, 15, 30, 60];
  int _selectedSnoozeIndex = 1;
  int _customSnoozeMinutes = 5;
  bool _useCustomSnooze = false;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _pushNotification = true;
  bool _repeatDaily = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  ReminderSettingController({
    required this.habit,
    required ReminderSettingRepository repository,
    required LocalNotificationService notificationService,
  }) : _repository = repository,
       _notificationService = notificationService {
    _initialize();
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get hasChanges => _hasChanges;
  List<int> get snoozeOptions => _snoozeOptions;
  int get selectedSnoozeIndex => _selectedSnoozeIndex;
  int get customSnoozeMinutes => _customSnoozeMinutes;
  bool get useCustomSnooze => _useCustomSnooze;
  TimeOfDay get selectedTime => _selectedTime;
  bool get pushNotification => _pushNotification;
  bool get repeatDaily => _repeatDaily;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  ReminderSettingModel? get reminderSetting => _reminderSetting;
  String? get lastErrorMessage => _lastErrorMessage;
  String? get lastDebugMessage => _lastDebugMessage;

  Future<void> _initialize() async {
    await _loadReminderSettings();
  }

  Future<void> _loadReminderSettings() async {
    try {
      _addDebugLog('🔄 Loading reminder settings for habit: ${habit.id}');

      final settings = await _repository.fetchReminderSettingsByHabit(habit.id);

      if (settings.isEmpty == false) {
        _reminderSetting = settings;
        _initializeFormFromModel(_reminderSetting!);
        _addDebugLog('✅ Loaded existing reminder: ${_reminderSetting!.formattedTime}');
      } else {
        _reminderSetting = ReminderSettingModel.empty(habitId: habit.id);
        _initializeFormFromModel(_reminderSetting!);
        _addDebugLog('✅ Created new reminder model');
      }
      _lastErrorMessage = null;
    } catch (e) {
      _lastErrorMessage = e.toString();
      _addDebugLog('❌ Error loading reminder settings: $e', isError: true);
      _reminderSetting = ReminderSettingModel.empty(habitId: habit.id);
      _initializeFormFromModel(_reminderSetting!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _initializeFormFromModel(ReminderSettingModel model) {
    _pushNotification = model.isEnabled;
    _selectedTime = model.time;

    final snoozeIndex = _snoozeOptions.indexOf(model.snoozeDuration);
    if (snoozeIndex != -1) {
      _selectedSnoozeIndex = snoozeIndex;
      _useCustomSnooze = false;
    } else {
      _useCustomSnooze = true;
      _customSnoozeMinutes = model.snoozeDuration;
    }

    _repeatDaily = model.repeatDaily;
    _soundEnabled = model.isSoundEnabled;
    _vibrationEnabled = model.isVibrationEnabled;

    _addDebugLog('✅ Form initialized with time: ${_selectedTime.hour}:${_selectedTime.minute}');
  }

  void _addDebugLog(String message, {bool isError = false}) {
    _lastDebugMessage = message;
    if (isError) {
      debugPrint('❌ [CONTROLLER] $message');
    } else {
      debugPrint('✅ [CONTROLLER] $message');
    }
  }

  // Setters
  void setSelectedTime(TimeOfDay time) {
    _selectedTime = time;
    _hasChanges = true;
    _addDebugLog('Time changed to: ${time.hour}:${time.minute}');
    notifyListeners();
  }

  void setPushNotification(bool value) {
    _pushNotification = value;
    _hasChanges = true;
    _addDebugLog('Push notification: $value');
    notifyListeners();
  }

  void setRepeatDaily(bool value) {
    _repeatDaily = value;
    _hasChanges = true;
    _addDebugLog('Repeat daily: $value');
    notifyListeners();
  }

  void setSoundEnabled(bool value) {
    _soundEnabled = value;
    _hasChanges = true;
    _addDebugLog('Sound enabled: $value');
    notifyListeners();
  }

  void setVibrationEnabled(bool value) {
    _vibrationEnabled = value;
    _hasChanges = true;
    _addDebugLog('Vibration enabled: $value');
    notifyListeners();
  }

  void setSnoozeOption(int index) {
    _selectedSnoozeIndex = index;
    _useCustomSnooze = false;
    _hasChanges = true;
    _addDebugLog('Snooze option: ${_snoozeOptions[index]} minutes');
    notifyListeners();
  }

  void setCustomSnooze(int minutes) {
    _customSnoozeMinutes = minutes.clamp(1, 120);
    _useCustomSnooze = true;
    _hasChanges = true;
    _addDebugLog('Custom snooze: $minutes minutes');
    notifyListeners();
  }

  void setUseCustomSnooze(bool value) {
    _useCustomSnooze = value;
    _hasChanges = true;
    notifyListeners();
  }

  int _generateNotificationId() {
    return habit.id;
  }

  // Main save method with full debug
  Future<Map<String, dynamic>> saveSettings() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'error': null,
    };

    if (habit.id <= 0) {
      result['message'] = 'Invalid habit ID: ${habit.id}';
      result['error'] = 'INVALID_HABIT_ID';
      _addDebugLog(result['message'], isError: true);
      return result;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final snoozeDuration = _useCustomSnooze
          ? _customSnoozeMinutes
          : _snoozeOptions[_selectedSnoozeIndex];

      _addDebugLog('💾 SAVING REMINDER SETTINGS...');
      _addDebugLog('   - Selected Time: ${_selectedTime.hour}:${_selectedTime.minute}');
      _addDebugLog('   - Enabled: $_pushNotification');
      _addDebugLog('   - Repeat Daily: $_repeatDaily');
      _addDebugLog('   - Sound Enabled: $_soundEnabled');
      _addDebugLog('   - Vibration Enabled: $_vibrationEnabled');
      _addDebugLog('   - Snooze Duration: $snoozeDuration');

      // Delete old reminder if exists
      if (_reminderSetting != null && _reminderSetting!.id.isNotEmpty) {
        await _repository.deleteReminderSetting(_reminderSetting!.habitId);
        _addDebugLog('🗑️ Deleted old reminder');
      }

      // Update habit table
      await _updateHabitReminderSettings(_pushNotification);
      _addDebugLog('✅ Habit table updated');

      // Create new reminder
      final newReminder = ReminderSettingModel(
        id: '',
        habitId: habit.id,
        isEnabled: _pushNotification,
        time: _selectedTime,
        snoozeDuration: snoozeDuration,
        repeatDaily: _repeatDaily,
        isSoundEnabled: _soundEnabled,
        isVibrationEnabled: _vibrationEnabled,
        createdAt: DateTime.now(),
      );

      _reminderSetting = await _repository.createReminderSetting(newReminder);
      _addDebugLog('✅ Reminder saved to database (ID: ${_reminderSetting!.id})');

      // Schedule notification
      if (_pushNotification) {
        final scheduleResult = await _scheduleNotificationWithDebug();
        if (scheduleResult['success'] == true) {
          _addDebugLog('✅ ${scheduleResult['message']}');
          result['message'] = 'Reminder settings saved and notification scheduled';
        } else {
          _addDebugLog('⚠️ ${scheduleResult['message']}', isError: true);
          result['message'] = 'Settings saved but notification scheduling had issues';
          result['error'] = scheduleResult['error'];
        }
      } else {
        await _notificationService.cancelNotification(habit.id);
        await _notificationService.cancelHabitNotifications(habit.id);
        _addDebugLog('🔕 Notifications disabled');
        result['message'] = 'Reminder settings saved (notifications disabled)';
      }

      _hasChanges = false;
      _lastErrorMessage = null;
      result['success'] = true;
      
      _addDebugLog('✅ ALL DONE! Reminder settings saved successfully');
      
    } catch (e, stackTrace) {
      _lastErrorMessage = e.toString();
      result['success'] = false;
      result['message'] = 'Failed to save settings';
      result['error'] = e.toString();
      _addDebugLog('❌ Error saving settings: $e', isError: true);
      _addDebugLog('Stack trace: $stackTrace', isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    
    return result;
  }

  Future<void> _updateHabitReminderSettings(bool reminderEnabled) async {
    final timeString = '${_selectedTime.hour.toString().padLeft(2, '0')}:'
                       '${_selectedTime.minute.toString().padLeft(2, '0')}:00';

    _addDebugLog('🔄 Updating habit settings:');
    _addDebugLog('   - Reminder Enabled: $reminderEnabled');
    _addDebugLog('   - Reminder Time: $timeString');

    try {
      await Supabase.instance.client
          .from('habits')
          .update({
            'reminder_enabled': reminderEnabled,
            'reminder_time': timeString,
          })
          .eq('id', habit.id);
      _addDebugLog('✅ Habit update completed');
    } catch (e) {
      _addDebugLog('❌ Error updating habit: $e', isError: true);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _scheduleNotificationWithDebug() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'error': null,
    };
    
    try {
      _addDebugLog('🔔 SCHEDULING NOTIFICATION...');
      
      // Cancel existing notifications first
      await _notificationService.cancelNotification(habit.id);
      await _notificationService.cancelHabitNotifications(habit.id);
      _addDebugLog('🔕 Cancelled existing notifications');

      // Check permissions
      final hasPermission = await _notificationService.checkPermissions();
      if (!hasPermission) {
        _addDebugLog('⚠️ Notification permission not granted, requesting...');
        await _notificationService.requestPermissions();
        // Check again
        final newPermission = await _notificationService.checkPermissions();
        if (!newPermission) {
          result['message'] = 'Notification permission denied';
          result['error'] = 'PERMISSION_DENIED';
          _addDebugLog(result['message'], isError: true);
          return result;
        }
      }
      _addDebugLog('✅ Notification permission granted');

      final notificationId = _generateNotificationId();

      _addDebugLog('📝 Notification details:');
      _addDebugLog('   - ID: $notificationId');
      _addDebugLog('   - Habit: ${habit.name}');
      _addDebugLog('   - Time: ${_selectedTime.hour}:${_selectedTime.minute}');
      _addDebugLog('   - Repeat daily: $_repeatDaily');
      _addDebugLog('   - Sound: $_soundEnabled');
      _addDebugLog('   - Vibration: $_vibrationEnabled');

      // Schedule the reminder
      final scheduleResult = await _notificationService.scheduleHabitReminder(
        id: notificationId,
        title: 'Habit Reminder: ${habit.name}',
        body: 'Time to complete your habit: ${habit.name}',
        time: _selectedTime,
        habitId: habit.id.toString(),
        repeatDaily: _repeatDaily,
        enableSound: _soundEnabled,
        enableVibration: _vibrationEnabled,
      );

      if (scheduleResult['success'] == true) {
        result['success'] = true;
        result['message'] = scheduleResult['message'];
        if (scheduleResult['scheduledDate'] != null) {
          final scheduled = scheduleResult['scheduledDate'] as DateTime;
          final minutesFromNow = scheduled.difference(DateTime.now()).inMinutes;
          _addDebugLog('📅 Will fire at: ${scheduled.hour}:${scheduled.minute}');
          _addDebugLog('⏱️ Minutes from now: $minutesFromNow');
        }
      } else {
        result['message'] = scheduleResult['message'];
        result['error'] = scheduleResult['error'];
      }
      
      // Verify notification was scheduled
      await _verifyNotificationScheduled();
      
    } catch (e, stackTrace) {
      result['success'] = false;
      result['message'] = 'Error scheduling notification';
      result['error'] = e.toString();
      _addDebugLog('❌ ERROR in scheduling: $e', isError: true);
      _addDebugLog('Stack trace: $stackTrace', isError: true);
    }
    
    return result;
  }

  Future<void> _verifyNotificationScheduled() async {
    try {
      final pending = await _notificationService.getPendingNotifications();
      final isScheduled = pending.any((n) => n.id == habit.id);
      if (isScheduled) {
        _addDebugLog('✅ Verified: Notification ${habit.id} is scheduled');
        final ourNotification = pending.firstWhere((n) => n.id == habit.id);
        _addDebugLog('   Title: ${ourNotification.title}');
      } else {
        _addDebugLog('⚠️ WARNING: Notification ${habit.id} not found in pending list!', isError: true);
        _addDebugLog('   Pending IDs: ${pending.map((n) => n.id).toList()}');
      }
    } catch (e) {
      _addDebugLog('❌ Error verifying notification: $e', isError: true);
    }
  }

  // Test methods
  Future<Map<String, dynamic>> testNotification() async {
    _addDebugLog('🔔 Testing notification for habit: ${habit.name}');
    final result = await _notificationService.showTestNotification(habit.name);
    if (result['success'] == true) {
      _addDebugLog('✅ Test notification sent successfully');
    } else {
      _addDebugLog('❌ Test notification failed: ${result['message']}', isError: true);
    }
    return result;
  }

  // FIXED: Using showTestNotification instead of showNotification
  Future<Map<String, dynamic>> testForegroundNotification() async {
    _addDebugLog('🔔 Testing foreground notification');
    try {
      // Use showTestNotification which already exists
      final result = await _notificationService.showTestNotification(habit.name);
      if (result['success'] == true) {
        _addDebugLog('✅ Foreground test notification sent');
        return {'success': true, 'message': 'Foreground test notification sent'};
      } else {
        return {'success': false, 'message': result['message']};
      }
    } catch (e) {
      _addDebugLog('❌ Foreground test failed: $e', isError: true);
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> checkPendingNotifications() async {
    _addDebugLog('📋 ========== CHECKING PENDING NOTIFICATIONS ==========');
    
    final pending = await _notificationService.getPendingNotifications();
    _addDebugLog('   - Total pending: ${pending.length}');

    int ourNotifications = 0;
    for (final notification in pending) {
      if (notification.id == habit.id || 
          notification.payload?.contains('habit_${habit.id}') == true) {
        ourNotifications++;
        _addDebugLog('   ✅ OUR NOTIFICATION:');
        _addDebugLog('      ID: ${notification.id}');
        _addDebugLog('      Title: ${notification.title}');
        _addDebugLog('      Payload: ${notification.payload}');
      }
    }

    if (ourNotifications == 0) {
      _addDebugLog('   ❌ NO NOTIFICATIONS FOUND FOR HABIT ${habit.id}', isError: true);
    } else {
      _addDebugLog('   📊 Found $ourNotifications notification(s) for this habit');
    }
  }

  Future<Map<String, dynamic>> checkPermissions() async {
    _addDebugLog('📱 ========== PERMISSION CHECK ==========');
    
    final hasPermission = await _notificationService.checkPermissions();
    _addDebugLog('   - Basic permission granted: $hasPermission');
    
    if (Platform.isAndroid) {
      final android = _notificationService.getAndroidPlugin();
      if (android != null) {
        final notificationsEnabled = await android.areNotificationsEnabled();
        _addDebugLog('   - Notifications enabled (Android): $notificationsEnabled');
      }
    }
    
    if (!hasPermission) {
      _addDebugLog('   ⚠️ Please enable notification permissions in device settings', isError: true);
      final requested = await _notificationService.requestPermissions();
      _addDebugLog('   - Permission requested result: $requested');
      return {'success': requested, 'message': requested ? 'Permission granted' : 'Permission denied'};
    }
    
    return {'success': true, 'message': 'Permission OK'};
  }

  Future<void> resetReminderData() async {
    _addDebugLog('🔄 Resetting reminder data for habit ${habit.id}');
    
    try {
      await _repository.deleteAllReminderSettingsForHabit(habit.id);
      _addDebugLog('✅ Deleted from database');
      
      await Supabase.instance.client
          .from('habits')
          .update({'reminder_enabled': false, 'reminder_time': null})
          .eq('id', habit.id);
      _addDebugLog('✅ Reset habit table');
      
      await _notificationService.cancelNotification(habit.id);
      await _notificationService.cancelHabitNotifications(habit.id);
      _addDebugLog('✅ Cancelled notifications');

      _reminderSetting = ReminderSettingModel.empty(habitId: habit.id);
      _initializeFormFromModel(_reminderSetting!);
      _hasChanges = true;

      _addDebugLog('✅ Reminder data reset successfully');
      notifyListeners();
    } catch (e) {
      _addDebugLog('❌ Error resetting reminder data: $e', isError: true);
      rethrow;
    }
  }

  String getTimeString(TimeOfDay time) {
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final displayHour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    return '$displayHour:$minute $period';
  }

  void debugCurrentState() {
    _addDebugLog('🎯 ========== CURRENT STATE ==========');
    _addDebugLog('   Habit: ${habit.name} (ID: ${habit.id})');
    _addDebugLog('   Selected Time: ${getTimeString(_selectedTime)} (${_selectedTime.hour}:${_selectedTime.minute})');
    _addDebugLog('   Enabled: $_pushNotification');
    _addDebugLog('   Repeat: $_repeatDaily');
    _addDebugLog('   Sound: $_soundEnabled');
    _addDebugLog('   Vibration: $_vibrationEnabled');
    _addDebugLog('   Snooze: ${_useCustomSnooze ? "Custom $_customSnoozeMinutes" : "${_snoozeOptions[_selectedSnoozeIndex]} minutes"}');
    _addDebugLog('   Has Changes: $_hasChanges');
    
    if (_reminderSetting != null) {
      _addDebugLog('   Saved Reminder: ${_reminderSetting!.formattedTime}');
      _addDebugLog('   Reminder Enabled: ${_reminderSetting!.isEnabled}');
      _addDebugLog('   Reminder Sound: ${_reminderSetting!.isSoundEnabled}');
      _addDebugLog('   Reminder Vibration: ${_reminderSetting!.isVibrationEnabled}');
    }
    _addDebugLog('   ===================================');
  }

  void clearDebugLog() {
    _lastErrorMessage = null;
    _lastDebugMessage = null;
    _addDebugLog('Debug log cleared');
  }
}