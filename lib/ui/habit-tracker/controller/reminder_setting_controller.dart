import 'package:flutter/material.dart';
import 'package:purewill/data/services/local_notification_service.dart';
import 'package:purewill/domain/model/habit_model.dart';
import 'package:purewill/domain/model/reminder_setting_model.dart';
import 'package:purewill/data/repository/reminder_setting_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReminderSettingController with ChangeNotifier {
  final HabitModel habit;
  final ReminderSettingRepository _repository;
  final LocalNotificationService _notificationService;

  ReminderSettingModel? _reminderSetting;
  bool _isLoading = true;
  bool _hasChanges = false;

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

  Future<void> _initialize() async {
    await _loadReminderSettings();
  }

  Future<void> _loadReminderSettings() async {
    try {
      // debugPrint('🔄 Loading reminder settings for habit: ${habit.id}');

      final settings = await _repository.fetchReminderSettingsByHabit(habit.id);

      if (settings.isEmpty == false) {
        _reminderSetting = settings;
        _initializeFormFromModel(_reminderSetting!);
        // debugPrint('✅ Loaded existing reminder: ${_reminderSetting!.time}');
      } else {
        _reminderSetting = ReminderSettingModel.empty(habitId: habit.id);
        _initializeFormFromModel(_reminderSetting!);
        // debugPrint('✅ Created new reminder model');
      }
    } catch (e) {
      // debugPrint('❌ Error loading reminder settings: $e');
      _reminderSetting = ReminderSettingModel.empty(habitId: habit.id);
      _initializeFormFromModel(_reminderSetting!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _initializeFormFromModel(ReminderSettingModel model) {
    _pushNotification = model.isEnabled;

    final snoozeIndex = _snoozeOptions.indexOf(model.snoozeDuration);
    if (snoozeIndex != -1) {
      _selectedSnoozeIndex = snoozeIndex;
      _useCustomSnooze = false;
    } else {
      _useCustomSnooze = true;
      _customSnoozeMinutes = model.snoozeDuration;
    }

    _selectedTime = TimeOfDay.fromDateTime(model.time);
    _repeatDaily = model.repeatDaily;
    _soundEnabled = model.isSoundEnabled;
    _vibrationEnabled = model.isVibrationEnabled;

    // debugPrint(
      // '✅ Form initialized with time: ${_selectedTime.hour}:${_selectedTime.minute}',
    // );
  }

  // Setters
  void setSelectedTime(TimeOfDay time) {
    final now = TimeOfDay.now();

    // Check if selected time is in the past
    if (time.hour < now.hour ||
        (time.hour == now.hour && time.minute <= now.minute)) {
      // debugPrint(
        // '⚠️  WARNING: Selected time ($time) is in the past compared to current time ($now)',
      // );
      // debugPrint('💡 TIP: Set reminder for at least 1-2 minutes from now');
    }

    _selectedTime = time;
    _hasChanges = true;
    // debugPrint(
      // '🕐 Time changed to: ${getTimeString(time)} (Current: ${getTimeString(now)})',
    // );
    notifyListeners();
  }

  void setPushNotification(bool value) {
    _pushNotification = value;
    _hasChanges = true;
    notifyListeners();
  }

  void setRepeatDaily(bool value) {
    _repeatDaily = value;
    _hasChanges = true;
    notifyListeners();
  }

  void setSoundEnabled(bool value) {
    _soundEnabled = value;
    _hasChanges = true;
    notifyListeners();
  }

  void setVibrationEnabled(bool value) {
    _vibrationEnabled = value;
    _hasChanges = true;
    notifyListeners();
  }

  void setSnoozeOption(int index) {
    _selectedSnoozeIndex = index;
    _useCustomSnooze = false;
    _hasChanges = true;
    notifyListeners();
  }

  void setCustomSnooze(int minutes) {
    _customSnoozeMinutes = minutes.clamp(1, 120);
    _useCustomSnooze = true;
    _hasChanges = true;
    notifyListeners();
  }

  void setUseCustomSnooze(bool value) {
    _useCustomSnooze = value;
    _hasChanges = true;
    notifyListeners();
  }

  // SIMPLIFIED: Main save method
  Future<void> saveSettings() async {
    if (habit.id <= 0) {
      // debugPrint('❌ Invalid habit ID: ${habit.id}');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final snoozeDuration = _useCustomSnooze
          ? _customSnoozeMinutes
          : _snoozeOptions[_selectedSnoozeIndex];

      // FIX: Gunakan waktu yang tepat untuk reminder
      // Buat DateTime dengan waktu yang dipilih user, tapi tanggal tetap
      final now = DateTime.now();
      final scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // debugPrint('💾 SAVING REMINDER:');
      // debugPrint(
        // '   - Selected Time: ${_selectedTime.hour}:${_selectedTime.minute}',
      // );
      // debugPrint('   - Scheduled DateTime: $scheduledDateTime');
      // debugPrint('   - Device Now: $now');
      // debugPrint('   - Enabled: $_pushNotification');
      // debugPrint('   - Repeat Daily: $_repeatDaily');

      // Delete old reminder if exists
      if (_reminderSetting != null && _reminderSetting!.id.isNotEmpty) {

        await _repository.deleteReminderSetting(_reminderSetting!.id.hashCode);
      }

      // Update habit table
      await _updateHabitReminderSettings(_pushNotification);

      // Create new reminder dengan waktu yang benar
      final newReminder = ReminderSettingModel(
        id: '', // Force new creation
        habitId: habit.id,
        isEnabled: _pushNotification,
        time: scheduledDateTime, // Ini yang akan disimpan ke database
        snoozeDuration: snoozeDuration,
        repeatDaily: _repeatDaily,
        isSoundEnabled: _soundEnabled,
        isVibrationEnabled: _vibrationEnabled,
        createdAt: DateTime.now(),
      );

      _reminderSetting = await _repository.createReminderSetting(newReminder);

      // Schedule notification if enabled
      if (_pushNotification) {
        await _scheduleNotification();
      } else {
        await _notificationService.cancelHabitNotifications(habit.id);
        // debugPrint('🔕 Notifications disabled');
      }

      _hasChanges = false;
      // debugPrint('✅ Reminder settings saved successfully');
    } catch (e, stackTrace) {
      // debugPrint('❌ Error saving settings: $e');
      // debugPrint('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _updateHabitReminderSettings(bool reminderEnabled) async {
    final timeString =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00';

    // debugPrint('🔄 Updating habit settings:');
    // debugPrint('   - Reminder Enabled: $reminderEnabled');
    // debugPrint('   - Reminder Time: $timeString');

    try {
      await Supabase.instance.client
          .from('habits')
          .update({
            'reminder_enabled': reminderEnabled,
            'reminder_time': timeString,
          })
          .eq('id', habit.id);

      // debugPrint('✅ Habit update completed');
    } catch (e) {
      // debugPrint('❌ Error updating habit: $e');
      rethrow;
    }
  }

  // SIMPLIFIED: Schedule notification
  Future<void> _scheduleNotification() async {
    try {
      // debugPrint('🔔 SCHEDULING NOTIFICATION');

      // Cancel existing notifications first
      await _notificationService.cancelHabitNotifications(habit.id);

      // Check permissions
      final hasPermission = await _notificationService.checkPermissions();
      if (!hasPermission) {
        // debugPrint('❌ Notification permission not granted');
        return;
      }

      // Generate unique ID
      final notificationId = _generateNotificationId();

      // Schedule the reminder
      await _notificationService.scheduleHabitReminder(
        id: notificationId,
        title: 'Habit Reminder: ${habit.name}',
        body: 'Time to complete your habit: ${habit.name}',
        time: _selectedTime,
        habitId: habit.id.toString(),
        repeatDaily: _repeatDaily,
      );

      // debugPrint('✅ Notification scheduling completed');
    } catch (e, stackTrace) {
      // debugPrint('❌ ERROR in scheduling: $e');
      // debugPrint('Stack trace: $stackTrace');

      // Fallback: Show test notification
      await _notificationService.showTestNotification(habit.name);
    }
  }

  // Generate unique notification ID
  int _generateNotificationId() {
    return (habit.id * 10000) +
        (_selectedTime.hour * 100 + _selectedTime.minute);
  }

  // Get snooze duration
  // int _getSnoozeDuration() {
  //   return _useCustomSnooze
  //       ? _customSnoozeMinutes
  //       : _snoozeOptions[_selectedSnoozeIndex];
  // }

  // Test methods
  Future<void> testNotification() async {
    try {
      await _notificationService.showTestNotification(habit.name);
    } catch (e) {
      // debugPrint('❌ Error testing notification: $e');
    }
  }

  Future<void> checkPendingNotifications() async {
    try {
      // debugPrint('📋 ========== CHECKING PENDING NOTIFICATIONS ==========');

      final pending = await _notificationService.getPendingNotifications();
      // debugPrint('   - Total pending: ${pending.length}');

      int ourNotifications = 0;
      for (final notification in pending) {
        if (notification.payload?.contains('habit_${habit.id}') == true) {
          ourNotifications++;
          // debugPrint('   ✅ OUR NOTIFICATION:');
          // debugPrint('      ID: ${notification.id}');
          // debugPrint('      Title: ${notification.title}');
          // debugPrint('      Body: ${notification.body}');
          // debugPrint('      Payload: ${notification.payload}');
        }
      }

      if (ourNotifications == 0) {
        // debugPrint('   ❌ NO NOTIFICATIONS FOUND FOR HABIT ${habit.id}');
        // debugPrint('   This could mean:');
        // debugPrint('   1. Notification was never scheduled');
        // debugPrint('   2. Notification already triggered');
        // debugPrint('   3. Notification was cancelled');
      } else {
        // debugPrint(
          // '   📊 Found $ourNotifications notifications for this habit',
        // );
      }
    } catch (e) {
      // debugPrint('❌ Error checking pending notifications: $e');
    }
  }

  Future<void> checkPermissions() async {
    try {
      final hasPermission = await _notificationService.checkPermissions();
      // debugPrint('   - Permission granted: $hasPermission');
    } catch (e) {
      // debugPrint('❌ Error checking permissions: $e');
    }
  }

  // Reset reminder data
  Future<void> resetReminderData() async {
    try {
      await _repository.deleteAllReminderSettingsForHabit(habit.id);

      await Supabase.instance.client
          .from('habits')
          .update({'reminder_enabled': false, 'reminder_time': null})
          .eq('id', habit.id);

      await _notificationService.cancelHabitNotifications(habit.id);

      _reminderSetting = ReminderSettingModel.empty(habitId: habit.id);
      _initializeFormFromModel(_reminderSetting!);

      // debugPrint('✅ Reminder data reset successfully');
    } catch (e) {
      // debugPrint('❌ Error resetting reminder data: $e');
    }
  }

  // Format time string
  String getTimeString(TimeOfDay time) {
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final displayHour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    return '$displayHour:$minute $period';
  }

  // Debug current state
  void debugCurrentState() {
    // debugPrint('🎯 CURRENT STATE:');
    // debugPrint('   Habit: ${habit.name} (ID: ${habit.id})');
    // debugPrint('   Time: ${getTimeString(_selectedTime)}');
    // debugPrint('   Enabled: $_pushNotification');
    // debugPrint('   Repeat: $_repeatDaily');
    // debugPrint('   Has Changes: $_hasChanges');
  }
}
