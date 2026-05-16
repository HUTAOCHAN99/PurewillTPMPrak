import 'dart:developer';
import 'package:purewill/domain/model/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserRepository {
  final SupabaseClient _supabaseClient;
  static const String _userTableName = 'profiles';

  UserRepository(this._supabaseClient);

  Future<void> createUserProfile({
    required String userId,
    required String fullName,
  }) async {
    try {
      await _supabaseClient.from(_userTableName).insert({
        'user_id': userId,
        'full_name': fullName,
      });
      log(
        'CREATE USER PROFILE SUCCESS: Profile created for user $userId.',
        name: 'USER_REPO',
      );
    } catch (e, stackTrace) {
      log(
        'CREATE USER PROFILE FAILURE: Failed to create profile for user $userId.',
        error: e,
        stackTrace: stackTrace,
        name: 'USER_REPO',
      );
      rethrow;
    }
  }

  Future<ProfileModel?> fetchUserProfile(String userId) async {
    try {
      final response = await _supabaseClient
          .from(_userTableName)
          .select('*')
          .eq('user_id', userId.toString())
          .single();
        return ProfileModel.fromJson(response);
    } catch (e, stackTrace) {
      print(e.toString());
      print(stackTrace.toString());
      log(
        'FETCH USER PROFILE FAILURE: Failed to fetch profile for user $userId.',
        error: e,
        stackTrace: stackTrace,
        name: 'USER_REPO',
      );
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (fullName != null) {
        updateData['full_name'] = fullName;
      }
      if (avatarUrl != null) {
        updateData['avatar_url'] = avatarUrl;
      }

      if (updateData.isEmpty) {
        log('UPDATE PROFILE: No data provided to update.', name: 'USER_REPO');
        return;
      }

      await _supabaseClient
          .from(_userTableName)
          .update(updateData)
          .eq('id', userId);
      log(
        'UPDATE PROFILE SUCCESS: Profile updated for user $userId.',
        name: 'USER_REPO',
      );
    } catch (e, stackTrace) {
      log(
        'UPDATE USER PROFILE FAILURE: Failed to update profile for user $userId.',
        error: e,
        stackTrace: stackTrace,
        name: 'USER_REPO',
      );
      rethrow;
    }
  }
}
