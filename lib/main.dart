import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/data/repository/plan_repository.dart';
import 'package:purewill/data/services/local_notification_service.dart';
import 'package:purewill/data/services/reminder_sync_service.dart';
import 'package:purewill/data/services/badge_notification_service.dart';
import 'package:purewill/data/services/badge_service.dart';
import 'package:purewill/ui/habit-tracker/screen/auth_wrapper.dart';
import 'package:purewill/ui/habit-tracker/screen/badge_xp_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/home_screen.dart';
import 'package:purewill/ui/auth/screen/login_screen.dart';
import 'package:purewill/ui/auth/screen/signup_screen.dart';
import 'package:purewill/ui/auth/screen/resetpassword_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final badgeNotificationService = BadgeNotificationService();
late BadgeService badgeService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Sync premium status saat app startup
      final planRepo = PlanRepository();
      await planRepo.syncPremiumStatus();

      // Check badges untuk user
      await checkUserBadges(user.id);
    }
  });
  // Initialize Badge Notification Service
  await badgeNotificationService.initialize(
    onBadgeNotificationTap: (payload) {
      // debugPrint('🎯 Badge notification tapped with payload: $payload');
      _handleBadgeNotification(payload);
    },
  );

  // Initialize Badge Service
  badgeService = BadgeService(
    Supabase.instance.client,
    badgeNotificationService,
  );

  // debugPrint('✅ Badge Service initialized');

  // Initialize existing Notification Service
  final notificationService = LocalNotificationService();
  await notificationService.initialize(
    onNotificationTap: (payload) {
      // debugPrint('🔔 General notification tapped with payload: $payload');
      _handleNotificationPayload(payload);
    },
  );

  // debugPrint('✅ Local Notification Service initialized');

  // Handle notification pada app startup
  await LocalNotificationService.handleNotificationOnStartup();

  // Initialize Reminder Sync Service
  await _initializeReminderSyncService();

  runApp(const ProviderScope(child: MyApp()));
}

// Handle badge notification payload
void _handleBadgeNotification(String? payload) {
  if (payload == null) return;

  // debugPrint('🎯 Handling badge notification payload: $payload');

  if (payload.startsWith('badge_')) {
    final badgeId = payload.replaceFirst('badge_', '');
    // debugPrint('   - Badge ID from notification: $badgeId');
  } else if (payload.startsWith('progress_')) {
    final badgeName = payload.replaceFirst('progress_', '');
    // debugPrint('   - Progress notification for: $badgeName');
  }
}

// Handle general notification payload
void _handleNotificationPayload(String? payload) {
  if (payload == null) return;

  // debugPrint('🎯 Handling general notification payload: $payload');

  if (payload.startsWith('habit_')) {
    final habitId = payload.replaceFirst('habit_', '');
    // debugPrint('   - Habit ID from notification: $habitId');
  }
}

// Initialize Reminder Sync Service dengan retry mechanism
Future<void> _initializeReminderSyncService() async {
  bool syncInitialized = false;
  int retryCount = 0;
  const maxRetries = 3;

  while (!syncInitialized && retryCount < maxRetries) {
    try {
      await ReminderSyncService().initialize();
      syncInitialized = true;
      // debugPrint('✅ ReminderSyncService initialized successfully');
    } catch (e, stackTrace) {
      retryCount++;
      if (retryCount < maxRetries) {
        // debugPrint('🔄 Retrying in 2 seconds...');
        await Future.delayed(const Duration(seconds: 2));
      } else {
        // debugPrint(
        // '⚠️ ReminderSyncService initialization failed after $maxRetries attempts',
        // );
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
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// Function untuk check badges ketika user login
Future<void> checkUserBadges(String userId) async {
  try {
    // debugPrint('🔍 Checking badges for user: $userId');
    await badgeService.checkAllBadges(userId);
  } catch (e) {
    // debugPrint('❌ Error checking user badges: $e');
  }
}

// Global function untuk trigger badge check dari mana saja
Future<void> triggerBadgeCheck(String userId) async {
  await badgeService.checkAllBadges(userId);
}

// Provider untuk badge service
final badgeServiceProvider = Provider<BadgeService>((ref) {
  return badgeService;
});
