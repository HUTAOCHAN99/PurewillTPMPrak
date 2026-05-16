import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BadgeNotificationService {
  static final BadgeNotificationService _instance = BadgeNotificationService._internal();
  factory BadgeNotificationService() => _instance;
  BadgeNotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Initialize khusus untuk badge notifications
  Future<void> initialize({Function(String?)? onBadgeNotificationTap}) async {
    if (_isInitialized) {
      // debugPrint('ℹ️ BadgeNotificationService already initialized');
      return;
    }

    try {
      // debugPrint('🔄 Initializing BadgeNotificationService...');

      // Android setup
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS setup - simplified untuk versi baru
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize notifications plugin
      await _notificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // debugPrint('🎯 Badge notification tapped: ${response.payload}');
          // debugPrint('📱 Notification ID: ${response.id}');
          onBadgeNotificationTap?.call(response.payload);
        },
      );

      // Create dedicated channel untuk badge achievements
      await _createBadgeNotificationChannel();

      // Test basic notification capability
      // debugPrint('🧪 Testing notification capability...');
      try {
        await _notificationsPlugin.show(
          111111,
          'Test Notification',
          'If you see this, notifications are working!',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'badge_achievements_channel',
              'Achievement Badges',
              importance: Importance.max,
            ),
          ),
        );
        // debugPrint('✅ Basic notification test PASSED');
      } catch (e) {
        // debugPrint('❌ Basic notification test FAILED: $e');
      }

      _isInitialized = true;
      // debugPrint('✅ BadgeNotificationService initialized successfully');
    } catch (e, stack) {
      // debugPrint('❌ Error initializing BadgeNotificationService: $e');
      // debugPrint('Stack trace: $stack');
      _isInitialized = false;
    }
  }

  // Check permissions untuk Android dan iOS
  // Future<void> _checkPermissions() async {
  //   try {
  //     // Check Android permissions (Android 13+)
  //     final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
  //         _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
  //     if (androidPlugin != null) {
  //       // Untuk Android, permission biasanya sudah termasuk dalam initialize
        // debugPrint('🤖 Android notification setup completed');
  //     }

  //     // Check iOS permissions
  //     final IOSFlutterLocalNotificationsPlugin? iosPlugin = 
  //         _notificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      
  //     if (iosPlugin != null) {
  //       final bool? granted = await iosPlugin.requestPermissions(
  //         alert: true,
  //         badge: true,
  //         sound: true,
  //       );
        // debugPrint('📱 iOS notification permission: $granted');
  //     }

  //   } catch (e) {
      // debugPrint('❌ Error checking permissions: $e');
  //   }
  // }

  // Create dedicated channel untuk badge notifications
  Future<void> _createBadgeNotificationChannel() async {
    try {
      const AndroidNotificationChannel badgeChannel = AndroidNotificationChannel(
        'badge_achievements_channel', // channelId
        'Achievement Badges', // channelName
        description: 'Notifications when you earn new achievement badges',
        importance: Importance.max, // Max importance untuk floating/heads-up
        playSound: true,
        enableVibration: true,
        showBadge: true,
        ledColor: Color(0xFF7C3AED), // Purple color untuk LED
        enableLights: true,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(badgeChannel);

      // debugPrint('📢 Notification channel created: badge_achievements_channel');
    } catch (e) {
      // debugPrint('❌ Error creating notification channel: $e');
    }
  }

  // Main method untuk show floating badge notification
  Future<void> showFloatingBadge({
    required String badgeName,
    required String badgeDescription,
    required int badgeId,
    String? imageUrl,
  }) async {
    try {
      if (!_isInitialized) {
        // debugPrint('⚠️ Service not initialized, initializing now...');
        await initialize();
      }

      // debugPrint('🎯 Preparing to show badge: $badgeName');

      // Android details dengan setting yang lebih eksplisit
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'badge_achievements_channel', // channelId - HARUS SAMA dengan yang dibuat
        'Achievement Badges',
        channelDescription: 'Notifications when you earn new achievement badges',
        importance: Importance.max, // Max importance untuk heads-up
        priority: Priority.high, // High priority
        color: Colors.purple,
        enableVibration: true,
        playSound: true,
        autoCancel: true,
        showWhen: true,
        styleInformation: BigTextStyleInformation(
          badgeDescription,
          htmlFormatBigText: true,
          contentTitle: '🎉 $badgeName',
          htmlFormatContentTitle: true,
          summaryText: 'Achievement Unlocked!',
          htmlFormatSummaryText: true,
        ),
        ticker: '🎉 New Achievement Unlocked!', // Text yang muncul di status bar
        timeoutAfter: 5000, // Auto cancel setelah 5 detik
        visibility: NotificationVisibility.public, // Visible di lock screen
        fullScreenIntent: true, // Penting untuk floating notification
        colorized: true, // Warna notification
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

      // iOS details
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        subtitle: 'Achievement Unlocked!',
        threadIdentifier: 'badge_achievements',
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      // debugPrint('📢 Showing notification with ID: $notificationId');

      // Show notification
      await _notificationsPlugin.show(
        notificationId,
        '🎉 Achievement Unlocked!', // Title
        badgeName, // Body
        details,
        payload: 'badge_$badgeId',
      );

      // debugPrint('✅ Floating badge notification shown: $badgeName (ID: $badgeId)');

    } catch (e) {
      // debugPrint('❌ Error showing badge notification: $e');
      // debugPrint('Stack trace: $stack');
    }
  }

  // Method untuk show multiple badges (jika dapat beberapa sekaligus)
  Future<void> showMultipleBadges(List<Map<String, dynamic>> badges) async {
    if (badges.isEmpty) return;

    // debugPrint('🔄 Showing ${badges.length} badge notifications...');

    // Show first badge immediately
    final firstBadge = badges.first;
    await showFloatingBadge(
      badgeName: firstBadge['name'] as String,
      badgeDescription: firstBadge['description'] as String,
      badgeId: firstBadge['id'] as int,
    );

    // Schedule subsequent badges dengan delay
    for (int i = 1; i < badges.length; i++) {
      await Future.delayed(Duration(seconds: 3 + i)); // Delay bertambah
      final badge = badges[i];
      await showFloatingBadge(
        badgeName: badge['name'] as String,
        badgeDescription: badge['description'] as String,
        badgeId: badge['id'] as int,
      );
    }

    // debugPrint('✅ All ${badges.length} badge notifications shown');
  }

  // Method untuk progress badge (hampir dapat achievement)
  Future<void> showProgressNotification({
    required String badgeName,
    required int currentProgress,
    required int targetProgress,
    required String progressType,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final progressPercent = (currentProgress / targetProgress * 100).toInt();
      final progressText = '$currentProgress/$targetProgress ($progressPercent%)';

      // debugPrint('📊 Showing progress notification: $badgeName - $progressText');

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'badge_achievements_channel',
        'Achievement Badges',
        importance: Importance.high,
        priority: Priority.defaultPriority,
        color: Colors.blue,
        enableVibration: false,
        playSound: false,
        autoCancel: true,
        showWhen: true,
        styleInformation: BigTextStyleInformation(
          'You are $progressPercent% close to earning "$badgeName"!\nKeep going! 💪',
          htmlFormatBigText: true,
          contentTitle: '🏆 Almost There!',
          htmlFormatContentTitle: true,
          summaryText: 'Badge Progress',
          htmlFormatSummaryText: true,
        ),
        ticker: '🏆 Progress update for $badgeName',
      );

      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
        subtitle: 'Progress Update',
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000) + 1000;

      await _notificationsPlugin.show(
        notificationId,
        '🏆 Almost There!',
        '$badgeName: $progressText',
        details,
        payload: 'progress_$badgeName',
      );

      // debugPrint('📊 Progress notification shown for: $badgeName');
    } catch (e) {
      // debugPrint('❌ Error showing progress notification: $e');
      // debugPrint('Stack trace: $stack');
    }
  }

  // Enhanced test method dengan multiple scenarios
  Future<void> showTestBadge() async {
    // debugPrint('🧪 Showing test badge notification...');
    
    // Test 1: Basic floating badge
    await showFloatingBadge(
      badgeName: 'Test Achievement 🏆',
      badgeDescription: 'This is a test badge notification with floating effect. Congratulations! 🎉 You have successfully earned this achievement by completing your goals.',
      badgeId: 999,
    );

    await Future.delayed(const Duration(seconds: 2));

    // Test 2: Progress notification
    await showProgressNotification(
      badgeName: 'Master Habit Builder',
      currentProgress: 7,
      targetProgress: 10,
      progressType: 'habit_count',
    );

    await Future.delayed(const Duration(seconds: 2));

    // Test 3: Simple notification (fallback test)
    try {
      await _notificationsPlugin.show(
        888,
        'Test Basic Notification',
        'If you see this, notifications are working! Basic notification test passed. ✅',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'badge_achievements_channel',
            'Achievement Badges',
            importance: Importance.high,
          ),
        ),
      );
      // debugPrint('✅ Basic test notification sent');
    } catch (e) {
      // debugPrint('❌ Basic test notification failed: $e');
    }
  }

  // Test multiple badges
  Future<void> showTestMultipleBadges() async {
    final testBadges = [
      {
        'id': 1001,
        'name': 'First Steps 👣',
        'description': 'You completed your first habit! Great start to your journey.',
      },
      {
        'id': 1002,
        'name': '3-Day Streak 🔥',
        'description': 'Amazing! You maintained a 3-day streak. Keep up the consistency!',
      },
      {
        'id': 1003,
        'name': 'Habit Collector 📚',
        'description': 'You created 5 active habits. You are building great routines!',
      },
    ];

    await showMultipleBadges(testBadges);
  }

  // Cancel specific badge notification
  Future<void> cancelBadgeNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      // debugPrint('🗑️ Canceled notification with ID: $id');
    } catch (e) {
      // debugPrint('❌ Error canceling notification: $e');
    }
  }

  // Cancel all badge notifications
  Future<void> cancelAllBadgeNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      // debugPrint('🗑️ Canceled all badge notifications');
    } catch (e) {
      // debugPrint('❌ Error canceling all notifications: $e');
    }
  }

  // Get pending notifications (untuk debug)
  Future<void> debugPendingNotifications() async {
    try {
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      // debugPrint('📋 Pending notifications: ${pending.length}');
      // for (final notification in pending) {
        // debugPrint('   - ID: ${notification.id}, Title: ${notification.title}');
      // }
    } catch (e) {
      // debugPrint('❌ Error getting pending notifications: $e');
    }
  }

  // Check if service is initialized
  bool get isInitialized => _isInitialized;

  // Get notification plugin instance (untuk advanced usage)
  FlutterLocalNotificationsPlugin get notificationsPlugin => _notificationsPlugin;

  // Cleanup
  void dispose() {
    _isInitialized = false;
    // debugPrint('♻️ BadgeNotificationService disposed');
  }
}