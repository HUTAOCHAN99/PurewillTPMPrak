import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/ui/auth/auth_provider.dart';
import 'package:purewill/ui/auth/screen/login_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/home_screen.dart';
import 'package:purewill/ui/habit-tracker/habit_provider.dart'
    as habit_provider;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    final supabaseClient = ref.read(supabaseClientProvider);
    supabaseClient.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;

      if (event == AuthChangeEvent.signedOut) {
        // Clear semua provider state saat logout
        ref.invalidate(habit_provider.habitNotifierProvider);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LoginScreen()),
              (Route<dynamic> route) => false,
            );
          }
        });
      } else if (event == AuthChangeEvent.signedIn) {
        // Clear dan refresh provider state saat login
        ref.invalidate(habit_provider.habitNotifierProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state untuk reactive updates
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;

    if (currentUser != null) {
      return HomeScreen();
    } else {
      return LoginScreen();
    }
  }
}
