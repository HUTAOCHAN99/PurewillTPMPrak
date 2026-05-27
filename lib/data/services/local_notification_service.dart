// lib/data/services/local_notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  Function(String?)? _onNotificationTap;
  Function(NotificationResponse)? _onForegroundNotification;
  bool _isInitialized = false;
  bool _isWeb = false;
  
  // Track errors
  String? _lastError;
  final List<String> _errorLog = [];

  Future<void> initialize({
    Function(String?)? onNotificationTap,
    Function(NotificationResponse)? onForegroundNotification,
  }) async {
    try {
      debugPrint('🔧 [INIT] Starting LocalNotificationService initialization...');
      
      // Cek apakah running di Web
      _isWeb = kIsWeb;
      if (_isWeb) {
        debugPrint('⚠️ [INIT] Running on Web - Notifications are not supported on web platform');
        debugPrint('✅ [INIT] Web mode - Notification service initialized (mock mode)');
        _isInitialized = true;
        return;
      }
      
      if (_isInitialized) {
        debugPrint('⚠️ [INIT] Already initialized, skipping...');
        return;
      }
      
      _onNotificationTap = onNotificationTap;
      _onForegroundNotification = onForegroundNotification;
      
      // Initialize timezone
      debugPrint('🔧 [INIT] Initializing timezone...');
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      debugPrint('✅ [INIT] Timezone initialized');
      
      // Android settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS settings
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      debugPrint('🔧 [INIT] Initializing flutter_local_notifications plugin...');
      await _flutterLocalNotificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _onDidReceiveBackgroundNotificationResponse,
      );
      debugPrint('✅ [INIT] Plugin initialized');
      
      // Create notification channels for Android
      if (Platform.isAndroid) {
        debugPrint('🔧 [INIT] Creating Android notification channels...');
        await _createNotificationChannels();
      }
      
      _isInitialized = true;
      _lastError = null;
      debugPrint('✅ [INIT] Local Notification Service initialized SUCCESSFULLY');
      
    } catch (e, stackTrace) {
      _lastError = e.toString();
      _errorLog.add('INIT_ERROR: $e');
      debugPrint('❌ [INIT] FAILED: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      
      // Jangan rethrow untuk web, biarkan app tetap jalan
      if (!_isWeb) {
        rethrow;
      }
    }
  }

  Future<void> _createNotificationChannels() async {
    // Skip if web
    if (_isWeb) return;
    
    try {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin == null) {
        throw Exception('AndroidFlutterLocalNotificationsPlugin is null');
      }

      // Main habit reminder channel
      debugPrint('🔧 [CHANNEL] Creating habit_reminder_channel...');
      final habitChannel = AndroidNotificationChannel(
        'habit_reminder_channel',
        'Habit Reminders',
        description: 'Daily habit reminders with sound and vibration',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        vibrationPattern: Int64List.fromList([500, 500, 500, 500, 500]),
      );
      await androidPlugin.createNotificationChannel(habitChannel);
      debugPrint('✅ [CHANNEL] habit_reminder_channel created');

      // Test channel
      debugPrint('🔧 [CHANNEL] Creating test_channel...');
      final testChannel = AndroidNotificationChannel(
        'test_channel',
        'Test Notifications',
        description: 'Test notifications',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        vibrationPattern: Int64List.fromList([500, 500, 500]),
      );
      await androidPlugin.createNotificationChannel(testChannel);
      debugPrint('✅ [CHANNEL] test_channel created');

      // Custom channel
      debugPrint('🔧 [CHANNEL] Creating custom_channel...');
      final customChannel = AndroidNotificationChannel(
        'custom_channel',
        'Custom Notifications',
        description: 'Custom notifications',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        vibrationPattern: Int64List.fromList([500, 500, 500]),
      );
      await androidPlugin.createNotificationChannel(customChannel);
      debugPrint('✅ [CHANNEL] custom_channel created');
      
    } catch (e) {
      _lastError = e.toString();
      _errorLog.add('CHANNEL_ERROR: $e');
      debugPrint('❌ [CHANNEL] Failed to create channels: $e');
      if (!_isWeb) {
        rethrow;
      }
    }
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    if (_isWeb) return;
    debugPrint('📱 [FOREGROUND] Notification tapped: ${response.payload}');
    if (_onForegroundNotification != null) {
      _onForegroundNotification!(response);
    }
    if (_onNotificationTap != null) {
      _onNotificationTap!(response.payload);
    }
  }

  @pragma('vm:entry-point')
  static void _onDidReceiveBackgroundNotificationResponse(NotificationResponse response) {
    debugPrint('📱 [BACKGROUND] Notification received: ${response.payload}');
  }

  AndroidFlutterLocalNotificationsPlugin? getAndroidPlugin() {
    if (_isWeb) return null;
    if (Platform.isAndroid) {
      return _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    }
    return null;
  }

  Future<bool> checkPermissions() async {
    if (_isWeb) {
      debugPrint('⚠️ [PERMISSION] Web platform - Notifications not supported');
      return false;
    }
    
    try {
      debugPrint('🔧 [PERMISSION] Checking notification permissions...');
      if (Platform.isAndroid) {
        final android = getAndroidPlugin();
        if (android != null) {
          final enabled = await android.areNotificationsEnabled();
          debugPrint('📱 [PERMISSION] Notifications enabled: $enabled');
          return enabled ?? true;
        }
      }
      debugPrint('✅ [PERMISSION] Permission check passed');
      return true;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ [PERMISSION] Error checking permissions: $e');
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    if (_isWeb) {
      debugPrint('⚠️ [PERMISSION] Web platform - Notifications not supported');
      return false;
    }
    
    try {
      debugPrint('🔧 [PERMISSION] Requesting notification permissions...');
      if (Platform.isAndroid) {
        final android = getAndroidPlugin();
        if (android != null) {
          final result = await android.requestNotificationsPermission();
          debugPrint('📱 [PERMISSION] Android permission result: $result');
          return result ?? true;
        }
      }
      return true;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ [PERMISSION] Error requesting permissions: $e');
      return false;
    }
  }

  // Main method to schedule habit reminders
  Future<Map<String, dynamic>> scheduleHabitReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required String habitId,
    bool repeatDaily = true,
    bool enableSound = true,
    bool enableVibration = true,
  }) async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'error': null,
      'scheduledDate': null,
    };
    
    // Skip if running on web
    if (_isWeb) {
      result['success'] = true;
      result['message'] = 'Web platform - Notifications are not supported (mock success)';
      debugPrint('⚠️ [SCHEDULE] Web platform - Skipping actual notification scheduling');
      return result;
    }
    
    try {
      debugPrint('🔔 [SCHEDULE] ========== START SCHEDULING ==========');
      debugPrint('🔔 [SCHEDULE] ID: $id');
      debugPrint('🔔 [SCHEDULE] Title: $title');
      debugPrint('🔔 [SCHEDULE] Time: ${time.hour}:${time.minute}');
      debugPrint('🔔 [SCHEDULE] Repeat daily: $repeatDaily');
      
      if (!_isInitialized) {
        debugPrint('⚠️ [SCHEDULE] Service not initialized, initializing...');
        await initialize();
      }

      // Check permission first
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        result['message'] = 'Notification permission not granted';
        result['error'] = 'PERMISSION_DENIED';
        debugPrint('❌ [SCHEDULE] $result');
        return result;
      }

      // Cancel existing notification
      debugPrint('🔧 [SCHEDULE] Cancelling existing notification ID: $id');
      await cancelNotification(id);
      
      // Build notification details
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'habit_reminder_channel',
        'Habit Reminders',
        channelDescription: 'Daily habit reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: enableSound,
        enableVibration: enableVibration,
        vibrationPattern: enableVibration ? Int64List.fromList([500, 500, 500]) : null,
        styleInformation: const DefaultStyleInformation(true, true),
        ongoing: false,
        autoCancel: true,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Calculate scheduled time
      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year, now.month, now.day, time.hour, time.minute, 0
      );
      
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
        debugPrint('⏰ [SCHEDULE] Time is in the past, scheduling for tomorrow');
      }
      
      result['scheduledDate'] = scheduledDate;
      final minutesFromNow = scheduledDate.difference(now).inMinutes;
      debugPrint('📅 [SCHEDULE] Scheduled date: $scheduledDate');
      debugPrint('⏱️ [SCHEDULE] Minutes from now: $minutesFromNow');
      
      if (repeatDaily) {
        // Use daily reminder scheduling
        await _scheduleDailyReminder(
          id: id,
          title: title,
          body: body,
          time: time,
          details: details,
          habitId: habitId,
        );
      } else {
        // One-time notification using zonedSchedule
        debugPrint('🔧 [SCHEDULE] Using zonedSchedule (one-time)...');
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledDate, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'habit_$habitId',
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint('✅ [SCHEDULE] zonedSchedule completed');
      }
      
      // Verify notification was scheduled
      final isScheduled = await isNotificationScheduled(id);
      if (isScheduled) {
        result['success'] = true;
        result['message'] = 'Notification scheduled successfully';
        debugPrint('✅ [SCHEDULE] SUCCESS! Notification ID $id scheduled');
      } else {
        result['message'] = 'Notification scheduled but verification failed';
        result['error'] = 'VERIFICATION_FAILED';
        debugPrint('⚠️ [SCHEDULE] Notification scheduled but not found in pending list');
      }
      
      debugPrint('🔔 [SCHEDULE] ========== END SCHEDULING ==========');
      return result;
      
    } catch (e, stackTrace) {
      _lastError = e.toString();
      _errorLog.add('SCHEDULE_ERROR: $e');
      result['success'] = false;
      result['message'] = 'Failed to schedule notification';
      result['error'] = e.toString();
      debugPrint('❌ [SCHEDULE] ERROR: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      return result;
    }
  }

  Future<void> _scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required NotificationDetails details,
    required String habitId,
  }) async {
    if (_isWeb) return;
    
    try {
      // Method 1: Try periodicShow first
      debugPrint('🔧 [SCHEDULE] Trying periodicShow for daily reminder...');
      await _flutterLocalNotificationsPlugin.periodicallyShow(
        id,
        title,
        body,
        RepeatInterval.daily,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'habit_$habitId',
      );
      debugPrint('✅ [SCHEDULE] periodicShow succeeded');
    } catch (e) {
      debugPrint('⚠️ [SCHEDULE] periodicShow failed: $e, trying fallback method...');
      
      // Method 2: Fallback to zonedSchedule with time component
      final now = DateTime.now();
      var nextDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (nextDate.isBefore(now)) {
        nextDate = nextDate.add(const Duration(days: 1));
      }
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(nextDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'habit_$habitId',
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('✅ [SCHEDULE] Fallback zonedSchedule with time component succeeded');
    }
  }

  Future<bool> isNotificationScheduled(int id) async {
    if (_isWeb) return false;
    
    try {
      final pending = await getPendingNotifications();
      final exists = pending.any((n) => n.id == id);
      debugPrint('🔍 [VERIFY] Notification ID $id ${exists ? "exists" : "does not exist"} in pending list');
      return exists;
    } catch (e) {
      debugPrint('❌ [VERIFY] Error checking notification: $e');
      return false;
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (_isWeb) return [];
    
    try {
      final pending = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      debugPrint('📋 [PENDING] Total: ${pending.length}');
      for (final notification in pending) {
        debugPrint('   - ID: ${notification.id}, Title: ${notification.title}');
      }
      return pending;
    } catch (e) {
      debugPrint('❌ [PENDING] Error getting pending: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> showTestNotification(String habitName) async {
    final result = <String, dynamic>{'success': false, 'message': ''};
    
    if (_isWeb) {
      result['success'] = true;
      result['message'] = 'Web platform - Test notification simulated';
      debugPrint('⚠️ [TEST] Web platform - Simulating test notification for: $habitName');
      return result;
    }
    
    try {
      debugPrint('🔔 [TEST] Showing test notification for: $habitName');
      
      final androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([500, 500, 500]),
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      );
      
      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _flutterLocalNotificationsPlugin.show(
        999,
        'Test Notification',
        'This is a test notification for habit: $habitName',
        details,
        payload: 'test_notification',
      );
      
      result['success'] = true;
      result['message'] = 'Test notification shown';
      debugPrint('✅ [TEST] Test notification shown successfully');
      
    } catch (e) {
      result['success'] = false;
      result['message'] = e.toString();
      debugPrint('❌ [TEST] Error: $e');
    }
    
    return result;
  }

  Future<Map<String, dynamic>> showImmediateTestNotification({
    required String title,
    required String body,
    int id = 9999,
  }) async {
    final result = <String, dynamic>{'success': false, 'message': ''};
    
    if (_isWeb) {
      result['success'] = true;
      result['message'] = 'Web platform - Immediate test notification simulated';
      debugPrint('⚠️ [IMMEDIATE] Web platform - Simulating test notification: $title');
      return result;
    }
    
    try {
      debugPrint('🔔 [IMMEDIATE] Showing immediate test notification');
      debugPrint('   Title: $title');
      debugPrint('   Body: $body');
      
      final androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      );
      
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: 'immediate_test',
      );
      
      result['success'] = true;
      result['message'] = 'Immediate test notification shown';
      debugPrint('✅ [IMMEDIATE] Test notification shown');
      
    } catch (e) {
      result['success'] = false;
      result['message'] = e.toString();
      debugPrint('❌ [IMMEDIATE] Error: $e');
    }
    
    return result;
  }

  Future<void> cancelNotification(int id) async {
    if (_isWeb) return;
    
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('🔕 [CANCEL] Cancelled notification ID: $id');
    } catch (e) {
      debugPrint('❌ [CANCEL] Error: $e');
    }
  }

  Future<void> cancelHabitNotifications(int habitId) async {
    if (_isWeb) return;
    
    try {
      await cancelNotification(habitId);
      final pending = await getPendingNotifications();
      for (final notification in pending) {
        if (notification.id == habitId || 
            notification.payload?.contains('habit_$habitId') == true) {
          await cancelNotification(notification.id);
        }
      }
      debugPrint('🔕 [CANCEL] Cancelled all notifications for habit $habitId');
    } catch (e) {
      debugPrint('❌ [CANCEL] Error: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    if (_isWeb) return;
    
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('🔕 [CANCEL] Cancelled all notifications');
    } catch (e) {
      debugPrint('❌ [CANCEL] Error: $e');
    }
  }

  static Future<void> handleNotificationOnStartup() async {
    // Skip for web
    if (kIsWeb) return;
    
    try {
      final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
      final initialMessage = await plugin.getNotificationAppLaunchDetails();
      
      if (initialMessage?.didNotificationLaunchApp ?? false) {
        final payload = initialMessage?.notificationResponse?.payload;
        debugPrint('📱 [STARTUP] App launched from notification: $payload');
      }
    } catch (e) {
      debugPrint('❌ [STARTUP] Error: $e');
    }
  }

  // Get error log for debugging
  List<String> getErrorLog() {
    return List.from(_errorLog);
  }
  
  String? getLastError() {
    return _lastError;
  }
  
  Future<void> clearErrorLog() async {
    _errorLog.clear();
    _lastError = null;
    debugPrint('🧹 [DEBUG] Error log cleared');
  }
}