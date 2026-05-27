// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/data/repository/plan_repository.dart';
import 'package:purewill/data/services/local_notification_service.dart';
import 'package:purewill/data/services/reminder_sync_service.dart';
import 'package:purewill/data/services/badge_notification_service.dart';
import 'package:purewill/data/services/badge_service.dart';
import 'package:purewill/data/services/timezone_service.dart';
import 'package:purewill/ui/habit-tracker/screen/auth_wrapper.dart';
import 'package:purewill/ui/habit-tracker/screen/badge_xp_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/home_screen.dart';
import 'package:purewill/ui/auth/screen/login_screen.dart';
import 'package:purewill/ui/auth/screen/signup_screen.dart';
import 'package:purewill/ui/auth/screen/resetpassword_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/pet_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

final badgeNotificationService = BadgeNotificationService();
late BadgeService badgeService;

// Global navigator key for handling notifications from background
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize Timezone Service
  final timezoneService = TimezoneService();
  await timezoneService.initialize();

  if (kIsWeb) {
    debugPrint('🌐 Running on Web - Timezone: ${timezoneService.timezoneName}');
  } else {
    debugPrint(
      '📱 Running on Mobile - Timezone: ${timezoneService.timezoneName}',
    );
  }
  debugPrint('   Offset: ${timezoneService.getTimezoneOffset()}');
  debugPrint('   Current time: ${timezoneService.getCurrentTimeString()}');

  // Initialize Local Notification Service (web compatible)
  final notificationService = LocalNotificationService();
  await notificationService.initialize(
    onNotificationTap: (payload) {
      debugPrint('🔔 General notification tapped with payload: $payload');
      _handleNotificationPayload(payload);
    },
    onForegroundNotification: (response) {
      debugPrint('📱 Foreground notification received: ${response.payload}');
      _showInAppNotification(response.payload);

      // Reschedule for next day if this is a daily reminder
      if (response.payload != null &&
          response.payload!.startsWith('habit_')) {
        _rescheduleNextDayReminder(response.payload!);
      }
    },
  );

  // Request notification permission only on mobile platforms (not web)
  if (!kIsWeb) {
    final hasPermission = await notificationService.requestPermissions();
    if (hasPermission) {
      debugPrint('✅ Notification permission granted by user');
    } else {
      debugPrint('⚠️ Notification permission denied by user');
    }
  } else {
    debugPrint('⚠️ Running on Web - Skipping notification permission request');
  }

  // Sync premium status after login
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final planRepo = PlanRepository();
      await planRepo.syncPremiumStatus();
      await checkUserBadges(user.id);
    }
  });

  // Initialize Badge Notification Service (web compatible)
  await badgeNotificationService.initialize(
    onBadgeNotificationTap: (payload) {
      debugPrint('🎯 Badge notification tapped with payload: $payload');
      _handleBadgeNotification(payload);
    },
  );

  // Initialize Badge Service
  badgeService = BadgeService(
    Supabase.instance.client,
    badgeNotificationService,
  );

  debugPrint('✅ Badge Service initialized');

  // Handle notification pada app startup (skip for web)
  if (!kIsWeb) {
    await LocalNotificationService.handleNotificationOnStartup();
  }

  // Initialize Reminder Sync Service (skip for web)
  if (!kIsWeb) {
    await _initializeReminderSyncService();
  } else {
    debugPrint('⚠️ Running on Web - Skipping ReminderSyncService initialization');
  }

  runApp(const ProviderScope(child: MyApp()));
}

// Reschedule reminder for next day
void _rescheduleNextDayReminder(String payload) {
  // Skip for web
  if (kIsWeb) return;
  
  final habitIdStr = payload.replaceFirst('habit_', '');
  final habitId = int.tryParse(habitIdStr);
  if (habitId != null) {
    debugPrint('🔄 Rescheduling reminder for habit: $habitId for tomorrow');
    Future.microtask(() async {
      try {
        await ReminderSyncService().rescheduleReminderForHabit(habitId);
      } catch (e) {
        debugPrint('❌ Error rescheduling reminder: $e');
      }
    });
  }
}

void _showInAppNotification(String? payload) {
  final context = scaffoldMessengerKey.currentState?.context;
  if (context != null) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Habit Reminder',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Time to complete your habit!',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

void _handleBadgeNotification(String? payload) {
  if (payload == null) return;
  debugPrint('🎯 Handling badge notification payload: $payload');
  if (payload.startsWith('badge_') || payload.startsWith('progress_')) {
    _navigateToBadgesScreen();
  }
}

void _handleNotificationPayload(String? payload) {
  if (payload == null) return;
  debugPrint('🎯 Handling general notification payload: $payload');
  if (payload.startsWith('habit_')) {
    final habitId = payload.replaceFirst('habit_', '');
    debugPrint('   - Habit ID from notification: $habitId');
    _navigateToHabitDetail(habitId);
  }
}

void _navigateToBadgesScreen() {
  final context = navigatorKey.currentContext;
  if (context != null) {
    final currentRoute = ModalRoute.of(context);
    if (currentRoute?.settings.name != '/badges') {
      navigatorKey.currentState?.pushNamed('/badges');
    }
  }
}

void _navigateToHabitDetail(String habitId) {
  final context = navigatorKey.currentContext;
  if (context != null) {
    debugPrint('Navigate to habit detail: $habitId');
    // navigatorKey.currentState?.pushNamed('/habit-detail', arguments: habitId);
  }
}

Future<void> _initializeReminderSyncService() async {
  bool syncInitialized = false;
  int retryCount = 0;
  const maxRetries = 3;

  while (!syncInitialized && retryCount < maxRetries) {
    try {
      await ReminderSyncService().initialize();
      syncInitialized = true;
      debugPrint('✅ ReminderSyncService initialized successfully');
    } catch (e) {
      retryCount++;
      debugPrint(
        '⚠️ ReminderSyncService initialization attempt $retryCount failed: $e',
      );
      if (retryCount < maxRetries) {
        debugPrint('🔄 Retrying in 2 seconds...');
        await Future.delayed(const Duration(seconds: 2));
      } else {
        debugPrint(
          '⚠️ ReminderSyncService initialization failed after $maxRetries attempts',
        );
      }
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PureWill',
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter',
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/signup': (context) => const SignupScreen(),
        '/signup-password': (context) => const ResetPasswordScreen(),
        '/badges': (context) => const BadgeXpScreen(),
        '/logout': (context) => const LoginScreen(),
        '/game': (context) => const PetScreen (),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

Future<void> checkUserBadges(String userId) async {
  try {
    debugPrint('🔍 Checking badges for user: $userId');
    await badgeService.checkAllBadges(userId);
  } catch (e) {
    debugPrint('❌ Error checking user badges: $e');
  }
}

Future<void> triggerBadgeCheck(String userId) async {
  await badgeService.checkAllBadges(userId);
}

final badgeServiceProvider = Provider<BadgeService>((ref) {
  return badgeService;
});