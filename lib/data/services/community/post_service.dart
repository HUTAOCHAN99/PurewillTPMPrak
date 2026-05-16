import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purewill/domain/model/community_model.dart';

class PostService {
  final SupabaseClient _supabase;

  PostService() : _supabase = Supabase.instance.client;

  // ============ POST CRUD ============

  Future<CommunityPost> createPost({
    required String communityId,
    required String userId,
    required String content,
    String? imageUrl,
  }) async {
    try {
      // Validasi content
      if (content.trim().isEmpty) {
        throw Exception('Konten post tidak boleh kosong');
      }

      // Validasi user memiliki profile
      final userProfile = await _supabase
          .from('profiles')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (userProfile == null) {
        // Get user data from current session
        final user = _supabase.auth.currentUser;
        final email = user?.email ?? 'user@example.com';
        final fullName = email.split('@').first;

        // Create profile
        await _supabase.from('profiles').insert({
          'user_id': userId,
          'full_name': fullName,
          'level': 1,
          'current_xp': 0,
          'xp_to_next_level': 100,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // Buat post
      final response = await _supabase
          .from('community_posts')
          .insert({
            'community_id': communityId,
            'author_id': userId,
            'content': content,
            'image_url': imageUrl,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('''
            *,
            communities!community_posts_community_id_fkey(
              name,
              icon_name,
              color
            )
          ''')
          .single();

      // Log activity
      await _supabase.from('community_activities').insert({
        'community_id': communityId,
        'user_id': userId,
        'activity_type': 'post',
        'description': 'User created a new post',
        'metadata': {
          'post_id': response['id'],
          'content_preview': content.length > 50
              ? '${content.substring(0, 50)}...'
              : content,
          'has_image': imageUrl != null,
        },
      });

      return CommunityPost.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<CommunityPost> updatePost({
    required String postId,
    required String content,
    String? imageUrl,
  }) async {
    try {
      final response = await _supabase
          .from('community_posts')
          .update({
            'content': content,
            'image_url': imageUrl,
            'updated_at': DateTime.now().toIso8601String(),
            'is_edited': true,
          })
          .eq('id', postId)
          .select('''
            *,
            profiles!community_posts_author_id_fkey(
              user_id,
              full_name,
              avatar_url
            )
          ''')
          .single();

      return CommunityPost.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      await _supabase
          .from('community_posts')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', postId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<CommunityPost>> getCommunityPosts(
    String communityId, {
    String? userId,
  }) async {
    try {
      return await _getPostsWithSeparateProfiles(communityId, userId: userId);
    } catch (e) {
      rethrow;
    }
  }

  // METHOD: Get posts dengan profiles terpisah
  Future<List<CommunityPost>> _getPostsWithSeparateProfiles(
    String communityId, {
    String? userId,
  }) async {
    try {
      // 1. Get posts tanpa profiles
      final postsResponse = await _supabase
          .from('community_posts')
          .select('''
  id,
  community_id,
  author_id,
  content,
  image_url,
  created_at,
  updated_at,
  is_pinned,
  is_edited,
  deleted_at,
  likes_count,
  comments_count,
  share_count,
  view_count,
  shared_from_post_id,
  shared_from_community_id,
  communities!community_posts_community_id_fkey(
    id, name, description, icon_name, color, 
    cover_image_url, created_at, updated_at,
    is_active, member_count, admin_id,
    categories!communities_category_id_fkey(
      id, name, created_at
    )
  )
''')
          .eq('community_id', communityId)
          .filter('deleted_at', 'is', null)
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false);

      if (postsResponse.isEmpty) {
        return [];
      }

      // 2. Get all unique author IDs
      final authorIds = (postsResponse as List)
          .map<String>((post) => post['author_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      // 3. Get profiles for all authors
      final Map<String, Map<String, dynamic>> authorProfiles = {};

      if (authorIds.isNotEmpty) {
        final profilesResponse = await _supabase
            .from('profiles')
            .select('user_id, full_name, avatar_url, level, current_xp')
            .inFilter('user_id', authorIds);

        for (var profile in profilesResponse) {
          final profileUserId = profile['user_id']?.toString();
          if (profileUserId != null) {
            authorProfiles[profileUserId] = Map<String, dynamic>.from(profile);
          }
        }
      }

      // 4. Combine posts with profiles
      final posts = <CommunityPost>[];
      for (var postData in postsResponse) {
        try {
          final authorId = postData['author_id']?.toString() ?? '';
          final authorProfile = authorProfiles[authorId];

          // Prepare JSON dengan profile data
          final postJson = Map<String, dynamic>.from(postData);

          if (authorProfile != null) {
            postJson['profiles'] = authorProfile;
          } else {
            // Create fallback profile
            postJson['profiles'] = {
              'user_id': authorId,
              'full_name': 'Pengguna',
              'avatar_url': null,
              'level': 1,
              'current_xp': 0,
            };
          }

          final post = CommunityPost.fromJson(postJson);
          posts.add(post);
        } catch (e) {
          continue;
        }
      }

      // 5. Jika ada userId, cek like dan view status
      if (userId != null && userId.isNotEmpty) {
        return await _enrichPostsWithUserStatus(posts, userId);
      }

      return posts;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CommunityPost>> _enrichPostsWithUserStatus(
    List<CommunityPost> posts,
    String userId,
  ) async {
    try {
      return await Future.wait(
        posts.map((post) async {
          try {
            final isLiked = await isPostLikedByUser(post.id, userId);
            final isViewed = await isPostViewedByUser(post.id, userId);

            return post.copyWith(
              isLikedByUser: isLiked,
              isViewedByUser: isViewed,
            );
          } catch (e) {
            return post;
          }
        }).toList(),
      );
    } catch (e) {
      return posts;
    }
  }

  Stream<List<CommunityPost>> streamCommunityPosts(
    String communityId,
    String userId,
  ) {
    return _supabase
        .from('community_posts')
        .stream(primaryKey: ['id'])
        .eq('community_id', communityId)
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false)
        .asyncMap((posts) async {
          try {
            final filteredPosts = (posts as List)
                .where((post) => post['deleted_at'] == null)
                .toList();

            if (filteredPosts.isEmpty) {
              return [];
            }

            return await getCommunityPosts(communityId, userId: userId);
          } catch (e) {
            return [];
          }
        });
  }

  Future<List<CommunityPost>> searchPosts({
    required String query,
    String? communityId,
    int limit = 20,
  }) async {
    try {
      // 1. Query posts terlebih dahulu
      var queryBuilder = _supabase
          .from('community_posts')
          .select('''
  *,
  communities!community_posts_community_id_fkey(
    id, 
    name, 
    icon_name
  )
''')
          .filter('deleted_at', 'is', null);

      if (communityId != null && communityId.isNotEmpty) {
        queryBuilder = queryBuilder.eq('community_id', communityId);
      }

      if (query.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('content', '%$query%');
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .limit(limit);

      if (response.isEmpty) {
        return [];
      }

      // 2. Ambil author profiles secara terpisah
      final authorIds = (response as List)
          .map<String>((post) => post['author_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final Map<String, dynamic> authorProfiles = {};

      if (authorIds.isNotEmpty) {
        final profilesResponse = await _supabase
            .from('profiles')
            .select('user_id, full_name, avatar_url, level, current_xp')
            .inFilter('user_id', authorIds);

        for (var profile in profilesResponse) {
          final profileUserId = profile['user_id']?.toString();
          if (profileUserId != null) {
            authorProfiles[profileUserId] = Map<String, dynamic>.from(profile);
          }
        }
      }

      // 3. Combine posts dengan profiles
      final posts = <CommunityPost>[];
      for (var postData in response) {
        try {
          final authorId = postData['author_id']?.toString() ?? '';
          final authorProfile = authorProfiles[authorId];

          // Prepare JSON dengan profile data
          final postJson = Map<String, dynamic>.from(postData);

          if (authorProfile != null) {
            postJson['profiles'] = authorProfile;
          } else {
            // Create fallback profile
            postJson['profiles'] = {
              'user_id': authorId,
              'full_name': 'Pengguna',
              'avatar_url': null,
              'level': 1,
              'current_xp': 0,
            };
          }

          final post = CommunityPost.fromJson(postJson);
          posts.add(post);
        } catch (e) {
          print('Error parsing post: $e');
          continue;
        }
      }

      return posts;
    } catch (e) {
      print('Error searching posts: $e');
      return [];
    }
  }

  Future<List<CommunityPost>> getUserPosts(String userId) async {
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
          .eq('author_id', userId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CommunityPost.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ============ POST LIKES ============

  Future<bool> toggleLikePost(String postId, String userId) async {
    try {
      final existingLike = await _supabase
          .from('community_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await _supabase
            .from('community_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);

        // Decrement likes count
        await _supabase.rpc(
          'decrement_post_likes',
          params: {'post_id': postId},
        );

        return false;
      } else {
        // Like
        await _supabase.from('community_likes').insert({
          'post_id': postId,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Increment likes count
        await _supabase.rpc(
          'increment_post_likes',
          params: {'post_id': postId},
        );

        return true;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getPostLikesCount(String postId) async {
    try {
      final response = await _supabase
          .from('community_likes')
          .select()
          .eq('post_id', postId);
      return response.length;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> isPostLikedByUser(String postId, String userId) async {
    try {
      final existingLike = await _supabase
          .from('community_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();
      return existingLike != null;
    } catch (e) {
      return false;
    }
  }

  // ============ POST VIEWS ============

  Future<void> trackPostView(String postId, String userId) async {
    try {
      final existingView = await _supabase
          .from('community_post_views')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingView == null) {
        await _supabase.from('community_post_views').insert({
          'post_id': postId,
          'user_id': userId,
        });

        await _supabase.rpc(
          'increment_post_views',
          params: {'post_id': postId},
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<bool> isPostViewedByUser(String postId, String userId) async {
    try {
      final view = await _supabase
          .from('community_post_views')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();
      return view != null;
    } catch (e) {
      return false;
    }
  }

  // ============ POST SHARES ============

  Future<CommunityPost> sharePostToCommunity({
    required String originalPostId,
    required String targetCommunityId,
    required String userId,
    String? additionalComment,
  }) async {
    try {
      // Get original post
      final originalPost = await _supabase
          .from('community_posts')
          .select('''
            *,
            profiles!community_posts_author_id_fkey(
              user_id,
              full_name,
              avatar_url
            )
          ''')
          .eq('id', originalPostId)
          .single();

      // Create new post in target community
      final newPost = await createPost(
        communityId: targetCommunityId,
        userId: userId,
        content: additionalComment ?? 'Shared from another community',
        imageUrl: originalPost['image_url'],
      );

      // Update shared_from fields
      await _supabase
          .from('community_posts')
          .update({
            'shared_from_post_id': originalPostId,
            'shared_from_community_id': originalPost['community_id'],
          })
          .eq('id', newPost.id);

      // Increment share count
      await _supabase.rpc(
        'increment_post_shares',
        params: {'post_id': originalPostId},
      );

      // Record share activity
      await _supabase.from('community_post_shares').insert({
        'original_post_id': originalPostId,
        'shared_post_id': newPost.id,
        'shared_by_user_id': userId,
        'shared_to_community_id': targetCommunityId,
      });

      return newPost.copyWith(
        sharedFromPostId: originalPostId,
        sharedFromCommunityId: originalPost['community_id'],
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CommunityPostShare>> getPostShares(String postId) async {
    try {
      final response = await _supabase
          .from('community_post_shares')
          .select('''
            *,
            original_post!original_post_id(*, profiles!community_posts_author_id_fkey(user_id, full_name, avatar_url)),
            shared_post!shared_post_id(*, profiles!community_posts_author_id_fkey(user_id, full_name, avatar_url), communities(name))
          ''')
          .eq('original_post_id', postId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CommunityPostShare.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ============ UTILITY METHODS ============

  Future<bool> ensureUserProfileExists(String userId) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (profile == null) {
        // Get user email from auth
        final user = _supabase.auth.currentUser;
        final email = user?.email ?? 'user@example.com';
        final fullName = email.split('@').first;

        await _supabase.from('profiles').insert({
          'user_id': userId,
          'full_name': fullName,
          'level': 1,
          'current_xp': 0,
          'xp_to_next_level': 100,
          'is_premium_user': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        return true;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Alternative method untuk get posts
  Future<List<CommunityPost>> getCommunityPostsAlternative(
    String communityId, {
    String? userId,
  }) async {
    try {
      // Simple query tanpa join kompleks
      final postsResponse = await _supabase
          .from('community_posts')
          .select('''
            id,
            community_id,
            author_id,
            content,
            image_url,
            created_at,
            updated_at,
            is_pinned,
            is_edited,
            likes_count,
            comments_count,
            share_count,
            view_count
          ''')
          .eq('community_id', communityId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      if (postsResponse.isEmpty) {
        return [];
      }

      // Get profiles separately
      final authorIds = (postsResponse as List)
          .map<String>((post) => post['author_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final profilesResponse = await _supabase
          .from('profiles')
          .select('user_id, full_name, avatar_url')
          .inFilter('user_id', authorIds);

      final profilesMap = {
        for (var profile in profilesResponse)
          profile['user_id'].toString(): profile,
      };

      // Build posts manually
      final posts = postsResponse.map<CommunityPost>((postData) {
        final authorId = postData['author_id']?.toString() ?? '';
        final profile = profilesMap[authorId];

        return CommunityPost(
          id: postData['id']?.toString() ?? '',
          communityId: postData['community_id']?.toString() ?? '',
          authorId: authorId,
          content: postData['content']?.toString() ?? '',
          imageUrl: postData['image_url']?.toString(),
          createdAt: DateTime.parse(
            postData['created_at']?.toString() ??
                DateTime.now().toIso8601String(),
          ),
          updatedAt: postData['updated_at'] != null
              ? DateTime.parse(postData['updated_at'].toString())
              : null,
          isPinned: postData['is_pinned'] == true,
          isEdited: postData['is_edited'] == true,
          likesCount: (postData['likes_count'] as int?) ?? 0,
          commentsCount: (postData['comments_count'] as int?) ?? 0,
          shareCount: (postData['share_count'] as int?) ?? 0,
          viewCount: (postData['view_count'] as int?) ?? 0,
          author: profile != null
              ? Profile(
                  userId: authorId,
                  fullName: profile['full_name']?.toString() ?? 'Pengguna',
                  avatarUrl: profile['avatar_url']?.toString(),
                )
              : null,
        );
      }).toList();

      return posts;
    } catch (e) {
      return [];
    }
  }
}
