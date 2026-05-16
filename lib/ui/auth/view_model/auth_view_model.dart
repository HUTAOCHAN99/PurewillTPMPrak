import 'package:flutter_riverpod/legacy.dart';
import 'package:purewill/data/repository/auth_repository.dart';
import 'package:purewill/data/repository/habit_repository.dart';
import 'package:purewill/data/repository/habit_session_repository.dart';
import 'package:purewill/data/repository/user_repository.dart';
import 'package:purewill/data/services/auth/biometric_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purewill/data/repository/secure_storage_repository.dart';

enum AuthStatus { initial, success, loading, failure }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final User? user;

  AuthState({this.status = AuthStatus.initial, this.errorMessage, this.user});

  AuthState copyWith({AuthStatus? status, String? errorMessage, User? user}) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final UserRepository _userRepository;
  final HabitRepository _habitRepository;
  final HabitSessionRepository _habitSessionRepository;
  
  final BiometricService _biometricService = BiometricService();
  final SecureStorageRepository _secureStorage = SecureStorageRepository();

  AuthViewModel(
    this._repository,
    this._userRepository,
    this._habitRepository,
    this._habitSessionRepository,
  ) : super(AuthState());

  Future<void> login(String email, String password) async {
    try {
      print("email: $email, password: $password");
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      final user = await _repository.login(email: email, password: password);
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.success,
          errorMessage: null,
          user: user,
        );
      }
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(status: AuthStatus.failure, errorMessage: "error");
      rethrow;
    }
  }

  Future<void> signup(String fullname, String email, String password) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      final user = await _repository.signup(
        fullname: fullname,
        email: email,
        password: password,
      );

      await _habitRepository.initializeDefaultHabitsForUser(user!.id);

      state = state.copyWith(
        status: AuthStatus.success,
        errorMessage: null,
        user: user,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(status: AuthStatus.failure, errorMessage: "error");
    }
  }

  Future<void> logout() async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      await _repository.logout();

      state = AuthState(
        status: AuthStatus.initial,
        user: null,
        errorMessage: null,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: "Logout failed",
      );
    }
  }

  Future<void> verifySignupOtp(String email, String otp) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      final user = await _repository.verifySignupOTP(email: email, otp: otp);

      await _userRepository.createUserProfile(
        userId: user!.id,
        fullName: user.userMetadata!["full_name"],
      );

      state = state.copyWith(
        status: AuthStatus.success,
        errorMessage: null,
        user: user,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(status: AuthStatus.failure, errorMessage: "error");
      print(e.toString());
    }
  }

  Future<void> resendSignupOTP(String email) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      await _repository.resendSignupOTP(email: email);
      state = state.copyWith(status: AuthStatus.success, errorMessage: null);
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(status: AuthStatus.failure, errorMessage: "error");
    }
  }

  Future<void> sendPasswordResetOTP(String email) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      await _repository.sendPasswordResetOTP(email: email);
      state = state.copyWith(status: AuthStatus.success, errorMessage: null);
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(status: AuthStatus.failure, errorMessage: "error");
    }
  }

  Future<void> verifyPasswordResetOtp(String email, String otp) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      final user = await _repository.verifyPasswordResetOtp(
        email: email,
        otp: otp,
      );
      state = state.copyWith(
        status: AuthStatus.success,
        errorMessage: null,
        user: user,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(status: AuthStatus.failure, errorMessage: "error");
    }
  }

  Future<void> resendPasswordResetOtp(String email) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      await _repository.resendPasswordResetOtp(email: email);
      state = state.copyWith(status: AuthStatus.success, errorMessage: null);
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(status: AuthStatus.failure, errorMessage: "error");
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      final user = await _repository.updatePassword(newPassword: newPassword);
      state = state.copyWith(
        status: AuthStatus.success,
        errorMessage: null,
        user: user,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(status: AuthStatus.failure, errorMessage: "error");
    }
  }

  // ============ METHOD BIOMETRIC (TAMBAHKAN INI) ============

  /// Login with biometric (fingerprint)
  Future<bool> loginWithBiometric() async {
    try {
      final isAvailable = await _biometricService.isBiometricAvailable();
      if (!isAvailable) {
        state = state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Biometric authentication is not available on this device',
        );
        return false;
      }

      final savedCredentials = await _secureStorage.getSavedCredentials();
      if (savedCredentials == null) {
        state = state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'No saved login found. Please login first.',
        );
        return false;
      }

      final result = await _biometricService.authenticate(
        reason: 'Authenticate to login to PureWill',
        title: 'Login with Fingerprint',
        subtitle: 'Place your finger on the sensor to continue',
        cancelButtonText: 'Use Password Instead',
      );

      if (!result.success) {
        state = state.copyWith(
          status: AuthStatus.failure,
          errorMessage: result.errorMessage ?? 'Biometric authentication failed',
        );
        return false;
      }

      state = state.copyWith(status: AuthStatus.loading);
      
      final user = await _repository.login(
        email: savedCredentials.email,
        password: savedCredentials.password,
      );

      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.success,
          errorMessage: null,
          user: user,
        );
        return true;
      } else {
        state = state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Failed to login with saved credentials',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Biometric login failed: $e',
      );
      return false;
    }
  }

  /// Check if biometric login is available and enabled
  Future<bool> isBiometricLoginAvailable() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final isEnabled = await _secureStorage.isBiometricEnabled();
    return isAvailable && isEnabled;
  }

  /// Save credentials after successful login
  Future<void> saveCredentialsForBiometric({
    required String email,
    required String password,
    required bool enableBiometric,
  }) async {
    await _secureStorage.saveCredentials(
      email: email,
      password: password,
      enableBiometric: enableBiometric,
    );
  }

  /// Clear saved credentials on logout
  Future<void> clearSavedCredentials() async {
    await _secureStorage.clearCredentials();
  }
}