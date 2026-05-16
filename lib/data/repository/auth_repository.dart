import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabaseClient;
  AuthRepository(this._supabaseClient);

  Future<User?> login({required String email, required String password}) async {
    try {
      final AuthResponse response = await _supabaseClient.auth
          .signInWithPassword(email: email, password: password);
      return response.user;
    } on AuthException catch (e, stackTrace) {
      log(
        'AUTH FAILURE: Supabase login failed.',
        error: e,
        stackTrace: stackTrace,
        name: 'AUTH_REPO',
      );
      rethrow;
    } catch (e, stackTrace) {
      log(
        'GENERAL FAILURE: Unexpected error during sign in.',
        error: e,
        stackTrace: stackTrace,
        name: 'AUTH_REPO',
      );
      rethrow;
    }
  }

  Future<User?> signup({
    required String fullname,
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          "full_name": fullname,
          "email": email, // tambah ini
        },
      );

      // Debug log untuk melihat response
      log(
        'SIGNUP RESPONSE: ${response.user?.email} - ${response.user?.userMetadata}',
        name: 'AUTH_REPO',
      );

      return response.user;
    } on AuthException catch (e, stackTrace) {
      log(
        'AUTH FAILURE: Supabase signup failed: ${e.message}',
        error: e,
        stackTrace: stackTrace,
        name: 'AUTH_REPO',
      );
      rethrow;
    } catch (e, stackTrace) {
      log(
        'GENERAL FAILURE: Unexpected error during signup: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'AUTH_REPO',
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _supabaseClient.auth.signOut();
    } on AuthException {
      rethrow;
    } catch (e, stackTrace) {
      log(
        'GENERAL FAILURE: Unexpected error during logout.',
        error: e,
        stackTrace: stackTrace,
        name: 'AUTH_REPO',
      );
      rethrow;
    }
  }

  Future<User?> verifySignupOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final AuthResponse response = await _supabaseClient.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.signup,
      );

      return response.user;
    } on AuthException catch (e, stackTrace) {
      log(
        'AUTH FAILURE: Supabase signup code verification failed.',
        error: e,
        stackTrace: stackTrace,
        name: 'AUTH_REPO',
      );
      rethrow;
    } catch (e, stackTrace) {
      log(
        'GENERAL FAILURE: Unexpected error during verify signup code .',
        error: e,
        stackTrace: stackTrace,
        name: 'AUTH_REPO',
      );
      rethrow;
    }
  }

  Future<void> resendSignupOTP({required String email}) async {
    try {
      await _supabaseClient.auth.resend(email: email, type: OtpType.signup);
    } on AuthException catch (e, stackTrace) {
      log(
        'AUTH FAILURE: Supabase resend signup codo failed.',
        error: e,
        stackTrace: stackTrace,
        name: 'AUTH_REPO',
      );
      rethrow;
    } catch (e, stackTrace) {
      log(
        'GENERAL FAILURE: Unexpected error during resend signup code .',
        error: e,
        stackTrace: stackTrace,
        name: 'AUTH_REPO',
      );
      rethrow;
    }
  }

  Future<void> sendPasswordResetOTP({required String email}) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email);
    } on AuthException catch (e, stackTrace) {
      log(
        'AUTH FAILURE: Supabase send password reset code failed.',
        error: e,
        stackTrace: stackTrace,
        name: 'AUTH_REPO',
      );
      rethrow;
    } catch (e, stackTrace) {
      log(
        'GENERAL FAILURE: Unexpected error during send password reset code .',
        error: e,
        stackTrace: stackTrace,
        name: 'AUTH_REPO',
      );
      rethrow;
    }
  }

  Future<User?> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _supabaseClient.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.recovery,
      );

      return response.user;
    } on AuthException catch (e, stackTrace) {
      log(
        'AUTH FAILURE: Supabase send password reset code failed.',
        error: e,
        stackTrace: stackTrace,
        name: 'AUTH_REPO',
      );
      rethrow;
    } catch (e, stackTrace) {
      log(
        'GENERAL FAILURE: Unexpected error during send password reset code .',
        error: e,
        stackTrace: stackTrace,
        name: 'AUTH_REPO',
      );
      rethrow;
    }
  }

  Future<void> resendPasswordResetOtp({required String email}) async {
    try {
      await _supabaseClient.auth.resend(email: email, type: OtpType.recovery);
    } on AuthException catch (e, stackTrace) {
      log(
        'AUTH FAILURE: Supabase send password reset code failed.',
        error: e,
        stackTrace: stackTrace,
        name: 'AUTH_REPO',
      );
      rethrow;
    } catch (e, stackTrace) {
      log(
        'GENERAL FAILURE: Unexpected error during send password reset code .',
        error: e,
        stackTrace: stackTrace,
        name: 'AUTH_REPO',
      );
      rethrow;
    }
  }

  Future<User?> updatePassword({required String newPassword}) async {
    try {
      final response = await _supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return response.user;
    } on AuthException catch (e, stackTrace) {
      log(
        'AUTH FAILURE: Supabase send password reset code failed.',
        error: e,
        stackTrace: stackTrace,
        name: 'AUTH_REPO',
      );
      rethrow;
    } catch (e, stackTrace) {
      log(
        'GENERAL FAILURE: Unexpected error during send password reset code .',
        error: e,
        stackTrace: stackTrace,
        name: 'AUTH_REPO',
      );
      rethrow;
    }
  }

  Future<void> updateUserRole({
    required String userId,
    required String newRole,
    required String updatedBy, // Admin yang melakukan update
  }) async {
    try {
      await _supabaseClient
          .from('profiles')
          .update({
            'role': newRole,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      // Log aktivitas role change
      await _logRoleChange(userId, newRole, updatedBy);
    } on PostgrestException catch (e, stackTrace) {
      log(
        'DATABASE FAILURE: Failed to update user role.',
        error: e,
        stackTrace: stackTrace,
        name: 'AUTH_REPO',
      );
      rethrow;
    } catch (e, stackTrace) {
      log(
        'GENERAL FAILURE: Unexpected error during role update.',
        error: e,
        stackTrace: stackTrace,
        name: 'AUTH_REPO',
      );
      rethrow;
    }
  }

  Future<String?> getUserRole(String userId) async {
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select('role')
          .eq('user_id', userId)
          .single();

      return response['role'] as String?;
    } catch (e) {
      log('Error getting user role: $e', name: 'AUTH_REPO');
      return null;
    }
  }

  Future<void> _logRoleChange(
    String userId,
    String newRole,
    String updatedBy,
  ) async {
    await _supabaseClient.from('role_change_logs').insert({
      'user_id': userId,
      'old_role': 'user', // Karena hanya user ke doctor
      'new_role': newRole,
      'changed_by': updatedBy,
      'changed_at': DateTime.now().toIso8601String(),
    });
  }
}
