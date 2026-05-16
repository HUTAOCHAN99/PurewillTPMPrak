import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purewill/domain/model/community_model.dart';

class ProfileService {
  final SupabaseClient _supabase;

  ProfileService() : _supabase = Supabase.instance.client;

  // ============ PROFILE MANAGEMENT ============

  Future<Profile?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('user_id, full_name, avatar_url, level, current_xp')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return Profile.fromJson(response);
      }

      return Profile(
        userId: userId,
        fullName: 'Pengguna',
        avatarUrl: null,
        level: 1,
        currentXp: 0,
      );
    } catch (e) {
      developer.log('❌ Error getting user profile: $e', name: 'ProfileService');
      return Profile(
        userId: userId,
        fullName: 'Pengguna',
        avatarUrl: null,
        level: 1,
        currentXp: 0,
      );
    }
  }

  Future<Map<String, Profile>> getProfiles(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return {};

      final profilesResponse = await _supabase
          .from('profiles')
          .select('user_id, full_name, avatar_url, level, current_xp')
          .inFilter('user_id', userIds);

      final Map<String, Profile> profilesMap = {};
      for (var profile in profilesResponse) {
        final userIdStr = profile['user_id'].toString();
        profilesMap[userIdStr] = Profile.fromJson({
          'user_id': profile['user_id'],
          'full_name': profile['full_name'] ?? 'Pengguna',
          'avatar_url': profile['avatar_url'],
          'level': profile['level'],
          'current_xp': profile['current_xp'],
        });
      }

      return profilesMap;
    } catch (e) {
      developer.log('❌ Error fetching profiles: $e', name: 'ProfileService');
      return {};
    }
  }

Future<List<CommunityPost>> searchPostsAdvanced({
  required String query,
  String? communityId,
  String? userId,
  String? authorId,
  DateTime? startDate,
  DateTime? endDate,
  bool includeComments = false,
  int limit = 20,
  int offset = 0,
}) async {
  try {
    var queryBuilder = _supabase
        .from('community_posts')
        .select('''
          *,
          profiles!community_posts_author_id_fkey(
            user_id,
            full_name,
            avatar_url
          ),
          communities(name, icon_name)
        ''')
        .filter('deleted_at', 'is', null)
        .ilike('content', '%$query%');

    // Filter berdasarkan komunitas
    if (communityId != null) {
      queryBuilder = queryBuilder.eq('community_id', communityId);
    }

    // Filter berdasarkan author
    if (authorId != null) {
      queryBuilder = queryBuilder.eq('author_id', authorId);
    }

    // Filter berdasarkan tanggal
    if (startDate != null) {
      queryBuilder = queryBuilder.gte('created_at', startDate.toIso8601String());
    }
    if (endDate != null) {
      queryBuilder = queryBuilder.lte('created_at', endDate.toIso8601String());
    }

    // Jika mencari di komentar juga
    if (includeComments) {
      try {
        final commentsQuery = await _supabase
            .from('community_comments')
            .select('post_id')
            .ilike('content', '%$query%')
            .filter('deleted_at', 'is', null);

        final postIdsFromComments = (commentsQuery as List)
            .map((c) => c['post_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();

        if (postIdsFromComments.isNotEmpty) {
          queryBuilder = queryBuilder.inFilter('id', postIdsFromComments);
        }
      } catch (e) {
        developer.log('Error searching comments: $e');
      }
    }

    final response = await queryBuilder
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => CommunityPost.fromJson(json))
        .toList();
  } catch (e) {
    developer.log('❌ Error searching posts: $e');
    return [];
  }
}


  // Method untuk mencari post yang men-tag user
  Future<List<CommunityPost>> getPostsTaggingUser(String userId) async {
    try {
      final response = await _supabase
          .from('community_posts')
          .select('''
          *,
          profiles!community_posts_author_id_fkey(
            user_id,
            full_name,
            avatar_url
          ),
          communities(name, icon_name)
        ''')
          .contains('mentions', [userId])
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CommunityPost.fromJson(json))
          .toList();
    } catch (e) {
      developer.log(
        '❌ Error getting posts tagging user: $e',
        name: 'PostService',
      );
      return [];
    }
  }
}
