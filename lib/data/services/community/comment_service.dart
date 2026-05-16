import 'dart:developer' as developer;
import 'package:purewill/data/services/community/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purewill/domain/model/community_model.dart';

class CommentService {
  final SupabaseClient _supabase;

  CommentService() : _supabase = Supabase.instance.client;

  // ============ COMMENT CRUD ============

  Future<CommunityComment> addComment({
    required String postId,
    required String userId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final response = await _supabase
          .from('community_comments')
          .insert({
            'post_id': postId,
            'author_id': userId,
            'content': content,
            'parent_comment_id': parentCommentId,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('''
          *,
          profiles!community_comments_author_id_fkey(
            user_id,
            full_name,
            avatar_url,
            level,
            current_xp
          )
        ''')
          .single();

      // Update comments count in post
      await _supabase.rpc(
        'increment_post_comments',
        params: {'post_id': postId},
      );

      final comment = CommunityComment.fromJson(response);

      // PERBAIKAN: Query dengan alias yang jelas
      final postResponse = await _supabase
          .from('community_posts')
          .select('author_id, community_id')
          .eq('id', postId)
          .single();

      if (postResponse != null) {
        final postAuthorId = postResponse['author_id']?.toString();
        final communityId = postResponse['community_id']?.toString();

        if (postAuthorId != null && communityId != null) {
          // Trigger notifikasi
          final notificationService = NotificationService();
          await notificationService.createCommentNotification(
            commentId: comment.id,
            postId: postId,
            commentAuthorId: userId,
            postAuthorId: postAuthorId,
            communityId: communityId,
          );
        }
      }

      developer.log('✅ Komentar berhasil ditambahkan dengan ID: ${comment.id}');
      return comment;
    } catch (e) {
      developer.log('❌ Error adding comment: $e');
      rethrow;
    }
  }

  Future<List<CommunityComment>> getPostComments(
    String postId, {
    String? userId,
  }) async {
    try {
      // PERBAIKAN: Hapus parameter 'name'
      developer.log('🔄 Mengambil komentar untuk post $postId...');

      // Ambil komentar dengan profile author
      final commentsResponse = await _supabase
          .from('community_comments')
          .select('''
            *,
            profiles!community_comments_author_id_fkey(
              user_id,
              full_name,
              avatar_url,
              level,
              current_xp
            )
          ''')
          .eq('post_id', postId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: true);

      // PERBAIKAN: Hapus parameter 'name'
      developer.log('💬 ${commentsResponse.length} komentar ditemukan');

      // Map ke model
      final comments = (commentsResponse as List)
          .map((json) => CommunityComment.fromJson(json))
          .toList();

      // Group comments by parent
      final Map<String, List<CommunityComment>> repliesMap = {};
      final List<CommunityComment> topLevelComments = [];

      for (var comment in comments) {
        if (comment.parentCommentId != null) {
          repliesMap
              .putIfAbsent(comment.parentCommentId!, () => [])
              .add(comment);
        } else {
          topLevelComments.add(comment);
        }
      }

      // Attach replies to parent comments
      final List<CommunityComment> finalComments = [];
      for (var comment in topLevelComments) {
        final replies = repliesMap[comment.id] ?? [];
        if (replies.isNotEmpty) {
          finalComments.add(comment.copyWith(replies: replies));
        } else {
          finalComments.add(comment);
        }
      }

      // If userId provided, check like status
      if (userId != null) {
        return await Future.wait(
          finalComments.map((comment) async {
            final isLiked = await isCommentLikedByUser(comment.id, userId);
            return comment.copyWith(isLikedByUser: isLiked);
          }).toList(),
        );
      }

      return finalComments;
    } catch (e) {
      // PERBAIKAN: Hapus parameter 'name'
      developer.log('❌ Error fetching comments: $e');
      rethrow;
    }
  }

  // ============ COMMENT LIKES ============

  Future<bool> isCommentLikedByUser(String commentId, String userId) async {
    try {
      final existingLike = await _supabase
          .from('community_comment_likes')
          .select()
          .eq('comment_id', commentId)
          .eq('user_id', userId)
          .maybeSingle();
      return existingLike != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleLikeComment(String commentId, String userId) async {
    try {
      final existingLike = await _supabase
          .from('community_comment_likes')
          .select()
          .eq('comment_id', commentId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await _supabase
            .from('community_comment_likes')
            .delete()
            .eq('comment_id', commentId)
            .eq('user_id', userId);
        return false;
      } else {
        // Like
        await _supabase.from('community_comment_likes').insert({
          'comment_id': commentId,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
        return true;
      }
    } catch (e) {
      // PERBAIKAN: Hapus parameter 'name'
      developer.log('❌ Error toggling comment like: $e');
      return false;
    }
  }

  // ============ GET COMMENT BY ID ============

  Future<CommunityComment?> getCommentById(String commentId) async {
    try {
      final response = await _supabase
          .from('community_comments')
          .select('''
            *,
            profiles!community_comments_author_id_fkey(
              user_id,
              full_name,
              avatar_url,
              level,
              current_xp
            )
          ''')
          .eq('id', commentId)
          .maybeSingle();

      if (response == null) return null;

      return CommunityComment.fromJson(response);
    } catch (e) {
      // PERBAIKAN: Hapus parameter 'name'
      developer.log('❌ Error getting comment: $e');
      return null;
    }
  }
}
