import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } on PlatformException catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print('Error getting biometrics: $e');
      return [];
    }
  }

  /// Authenticate user using biometrics
  Future<BiometricResult> authenticate({
    required String reason,
    String? title,
    String? subtitle,
    String? cancelButtonText,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricResult(
          success: false,
          errorMessage: 'Biometric authentication is not available on this device',
        );
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        return BiometricResult(success: true);
      } else {
        return BiometricResult(
          success: false,
          errorMessage: 'Authentication failed',
        );
      }
    } on PlatformException catch (e) {
      String errorMessage;
      switch (e.code) {
        case auth_error.notAvailable:
          errorMessage = 'Biometric authentication not available';
          break;
        case auth_error.notEnrolled:
          errorMessage = 'No fingerprint enrolled. Please add fingerprint in device settings.';
          break;
        case auth_error.lockedOut:
          errorMessage = 'Too many failed attempts. Please use password.';
          break;
        case auth_error.permanentlyLockedOut:
          errorMessage = 'Biometric authentication is permanently locked. Please use password.';
          break;
        default:
          errorMessage = 'Authentication error: ${e.message}';
      }
      return BiometricResult(
        success: false,
        errorMessage: errorMessage,
      );
    } catch (e) {
      return BiometricResult(
        success: false,
        errorMessage: 'Unexpected error: $e',
      );
    }
  }
}

class BiometricResult {
  final bool success;
  final String? errorMessage;

  BiometricResult({
    required this.success,
    this.errorMessage,
  });
}