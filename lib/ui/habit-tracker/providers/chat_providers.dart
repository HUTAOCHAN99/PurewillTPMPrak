// lib/providers/chat_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purewill/data/repository/user_repository.dart';
import 'package:purewill/domain/model/profile_model.dart';
import 'package:purewill/data/services/chatbot/chatbot_service.dart';

// ============ AUTH & USER PROVIDERS ============

// Provider untuk mendapatkan Supabase client
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Provider untuk mendapatkan user repository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return UserRepository(supabaseClient);
});

// Provider untuk mendapatkan current user dari Supabase Auth
final currentUserProvider = Provider<User?>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return supabase.auth.currentUser;
});

// Provider untuk mendapatkan profile dari current user
final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  
  final userRepository = ref.watch(userRepositoryProvider);
  try {
    final profile = await userRepository.fetchUserProfile(user.id);
    return profile;
  } catch (e) {
    print('❌ Error fetching profile: $e');
    return null;
  }
});

// Provider untuk mendapatkan display name (full_name atau email)
final currentDisplayNameProvider = FutureProvider<String>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  final user = ref.watch(currentUserProvider);
  
  if (profile?.fullName != null && profile!.fullName!.isNotEmpty) {
    return profile.fullName!;
  }
  
  if (user?.email != null && user!.email!.isNotEmpty) {
    return user.email!.split('@').first;
  }
  
  return 'Pengguna';
});

// ============ CHAT PROVIDERS ============

// Provider untuk ChatBotService - instance akan hidup selama app
final chatBotServiceProvider = Provider<ChatBotService>((ref) {
  return ChatBotService();
}, name: 'chatBotService');

// Provider untuk menyimpan nama user di seluruh app
final chatUserNameProvider = StateProvider<String?>((ref) => null);

// Provider untuk tracking apakah chat sudah diinisialisasi
final chatInitializedProvider = StateProvider<bool>((ref) => false);