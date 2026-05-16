import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purewill/domain/model/community_model.dart';

class CommunityService {
  final SupabaseClient _supabase;

  CommunityService() : _supabase = Supabase.instance.client;

  // ============ COMMUNITY MANAGEMENT ============

  Future<List<Community>> getCommunities(String userId) async {
    try {
      final communitiesResponse = await _supabase
          .from('communities')
          .select('''
            *,
            categories (id, name, created_at)
          ''')
          .eq('is_active', true)
          .order('member_count', ascending: false);

      final userMemberships = await _supabase
          .from('community_members')
          .select('community_id')
          .eq('user_id', userId)
          .eq('is_banned', false);

      final joinedCommunityIds = (userMemberships as List<dynamic>)
          .map((item) => item['community_id'] as String)
          .toSet();

      return (communitiesResponse as List)
          .map(
            (json) => Community.fromJson({
              ...json,
              'is_joined': joinedCommunityIds.contains(json['id']),
            }),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Community>> getUserCommunities(String userId) async {
    try {
      final response = await _supabase
          .from('community_members')
          .select('''
            communities!inner(*, categories (id, name, created_at))
          ''')
          .eq('user_id', userId)
          .eq('is_banned', false);

      return (response as List)
          .map(
            (json) =>
                Community.fromJson({...json['communities'], 'is_joined': true}),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> joinCommunity(String communityId, String userId) async {
    try {
      // Check if already a member
      final existingMember = await _supabase
          .from('community_members')
          .select()
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember != null) {
        return false;
      }

      await _supabase.from('community_members').insert({
        'community_id': communityId,
        'user_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
        'role': 'member',
      });

      // Update member count
      await _supabase.rpc(
        'increment_member_count',
        params: {'community_id': communityId},
      );

      // Log activity
      await _supabase.from('community_activities').insert({
        'community_id': communityId,
        'user_id': userId,
        'activity_type': 'join',
        'description': 'User joined the community',
        'metadata': {'community_id': communityId},
      });

      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> leaveCommunity(String communityId, String userId) async {
    try {
      await _supabase
          .from('community_members')
          .delete()
          .eq('community_id', communityId)
          .eq('user_id', userId);

      // Update member count
      await _supabase.rpc(
        'decrement_member_count',
        params: {'community_id': communityId},
      );

      // Log activity
      await _supabase.from('community_activities').insert({
        'community_id': communityId,
        'user_id': userId,
        'activity_type': 'leave',
        'description': 'User left the community',
        'metadata': {'community_id': communityId},
      });

      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<Community> getCommunityDetails(
    String communityId,
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('communities')
          .select('''
            *,
            categories (id, name, created_at)
          ''')
          .eq('id', communityId)
          .single();

      // Check if user is a member
      final isMember = await _supabase
          .from('community_members')
          .select()
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .eq('is_banned', false)
          .maybeSingle()
          .then((result) => result != null);

      return Community.fromJson({...response, 'is_joined': isMember});
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Community>> searchCommunities(String query) async {
    try {
      final response = await _supabase
          .from('communities')
          .select('''
            *,
            categories (id, name, created_at)
          ''')
          .ilike('name', '%$query%')
          .eq('is_active', true)
          .order('member_count', ascending: false)
          .limit(20);

      return (response as List)
          .map((json) => Community.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Community>> getTrendingCommunities(String userId) async {
    try {
      final response = await _supabase
          .from('communities')
          .select('''
            *,
            categories (id, name, created_at)
          ''')
          .eq('is_active', true)
          .order('member_count', ascending: false)
          .limit(8);

      final communities = (response as List).map((json) async {
        final isMember = await _supabase
            .from('community_members')
            .select()
            .eq('community_id', json['id'])
            .eq('user_id', userId)
            .eq('is_banned', false)
            .maybeSingle()
            .then((result) => result != null);

        return Community.fromJson({...json, 'is_joined': isMember});
      }).toList();

      return await Future.wait(communities);
    } catch (e) {
      return [];
    }
  }

  Future<bool> isCommunityMember(String userId, String communityId) async {
    try {
      final membership = await _supabase
          .from('community_members')
          .select()
          .eq('user_id', userId)
          .eq('community_id', communityId)
          .eq('is_banned', false)
          .maybeSingle();
      return membership != null;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getCommunityStats(String communityId) async {
    try {
      // Get member count
      final membersResponse = await _supabase
          .from('community_members')
          .select()
          .eq('community_id', communityId)
          .eq('is_banned', false);

      // Get posts count
      final postsResponse = await _supabase
          .from('community_posts')
          .select()
          .eq('community_id', communityId)
          .filter('deleted_at', 'is', null);

      // Get today's activity count
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final activitiesResponse = await _supabase
          .from('community_activities')
          .select()
          .eq('community_id', communityId)
          .gte('created_at', startOfDay.toIso8601String());

      // Get total likes and comments
      final posts = await _supabase
          .from('community_posts')
          .select('likes_count, comments_count')
          .eq('community_id', communityId)
          .filter('deleted_at', 'is', null);

      int totalLikes = 0;
      int totalComments = 0;

      for (var post in posts) {
        totalLikes += (post['likes_count'] as int?) ?? 0;
        totalComments += (post['comments_count'] as int?) ?? 0;
      }

      return {
        'member_count': membersResponse.length,
        'post_count': postsResponse.length,
        'today_activity_count': activitiesResponse.length,
        'total_likes': totalLikes,
        'total_comments': totalComments,
        'active_members': membersResponse.length,
        'last_activity': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'member_count': 0,
        'post_count': 0,
        'today_activity_count': 0,
        'total_likes': 0,
        'total_comments': 0,
        'active_members': 0,
        'last_activity': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<void> updateLastSeen(String userId, String communityId) async {
    try {
      await _supabase
          .from('community_members')
          .update({'last_seen_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('community_id', communityId);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<int> getUnreadPostsCount(String userId, String communityId) async {
    try {
      final membership = await _supabase
          .from('community_members')
          .select('last_seen_at')
          .eq('user_id', userId)
          .eq('community_id', communityId)
          .maybeSingle();

      if (membership == null || membership['last_seen_at'] == null) {
        return 0;
      }

      final lastSeen = DateTime.parse(membership['last_seen_at'] as String);

      final response = await _supabase
          .from('community_posts')
          .select()
          .eq('community_id', communityId)
          .filter('deleted_at', 'is', null)
          .gte('created_at', lastSeen.toIso8601String());

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getUserCommunityActivities(
    String userId,
    int limit,
  ) async {
    try {
      final response = await _supabase
          .from('community_activities')
          .select('''
            *,
            communities!community_activities_community_id_fkey(name, icon_name, color)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }
}