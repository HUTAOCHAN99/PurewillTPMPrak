import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageRepository {
  static const String _keyEmail = 'saved_email';
  static const String _keyPassword = 'saved_password';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyLastLoginEmail = 'last_login_email';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Save user credentials after successful login
  Future<void> saveCredentials({
    required String email,
    required String password,
    required bool enableBiometric,
  }) async {
    if (enableBiometric) {
      await _storage.write(key: _keyEmail, value: email);
      await _storage.write(key: _keyPassword, value: _encodePassword(password));
      await _storage.write(key: _keyBiometricEnabled, value: 'true');
      await _storage.write(key: _keyLastLoginEmail, value: email);
    } else {
      await clearCredentials();
    }
  }

  /// Get saved credentials for biometric login
  Future<SavedCredentials?> getSavedCredentials() async {
    try {
      final email = await _storage.read(key: _keyEmail);
      final encodedPassword = await _storage.read(key: _keyPassword);
      final isEnabled = await _storage.read(key: _keyBiometricEnabled);

      if (email != null && encodedPassword != null && isEnabled == 'true') {
        final password = _decodePassword(encodedPassword);
        return SavedCredentials(email: email, password: password);
      }
      return null;
    } catch (e) {
      print('Error getting saved credentials: $e');
      return null;
    }
  }

  /// Check if biometric login is enabled
  Future<bool> isBiometricEnabled() async {
    final isEnabled = await _storage.read(key: _keyBiometricEnabled);
    return isEnabled == 'true';
  }

  /// Get last logged in email
  Future<String?> getLastLoginEmail() async {
    return await _storage.read(key: _keyLastLoginEmail);
  }

  /// Clear all saved credentials
  Future<void> clearCredentials() async {
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyPassword);
    await _storage.delete(key: _keyBiometricEnabled);
  }

  /// Disable biometric login
  Future<void> disableBiometric() async {
    await clearCredentials();
  }

  String _encodePassword(String password) {
    return base64.encode(utf8.encode(password));
  }

  String _decodePassword(String encoded) {
    return utf8.decode(base64.decode(encoded));
  }
}

class SavedCredentials {
  final String email;
  final String password;

  SavedCredentials({
    required this.email,
    required this.password,
  });
}