import 'dart:async';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purewill/domain/model/community_model.dart';

class NotificationService {
  final SupabaseClient _supabase;

  NotificationService() : _supabase = Supabase.instance.client;

  // ============ NOTIFICATION MANAGEMENT ============

  // Stream notifikasi real-time
  Stream<List<CommunityNotification>> streamNotifications(String userId) {
    return _supabase
        .from('community_notifications')
        .stream(primaryKey: ['id'])
        .asyncMap((data) async {
          try {
            final raw = (data as List)
                .map((json) => CommunityNotification.fromJson(json))
                .where((n) => n.userId == userId && n.isRead == false)
                .toList();

            // sort terbaru di atas
            raw.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return await _enrichNotifications(raw);
          } catch (e) {
            developer.log('Error in streamNotifications: $e');
            return [];
          }
        });
  }

  Future<List<CommunityNotification>> _enrichNotifications(
    List<CommunityNotification> notifications,
  ) async {
    try {
      // Ambil data post untuk notifikasi terkait post
      final postIds = notifications
          .where((n) => n.postId != null)
          .map((n) => n.postId!)
          .toSet()
          .toList();

      final commentIds = notifications
          .where((n) => n.commentId != null)
          .map((n) => n.commentId!)
          .toSet()
          .toList();

      // Ambil data post
      final Map<String, CommunityPost> postsMap = {};
      if (postIds.isNotEmpty) {
        final postsResponse = await _supabase
            .from('community_posts')
            .select('id, content, author_id, community_id')
            .inFilter('id', postIds);

        for (var post in postsResponse) {
          postsMap[post['id'].toString()] = CommunityPost.fromJson(post);
        }
      }

      // Ambil data komentar
      final Map<String, CommunityComment> commentsMap = {};
      if (commentIds.isNotEmpty) {
        final commentsResponse = await _supabase
            .from('community_comments')
            .select('id, content, author_id, post_id')
            .inFilter('id', commentIds);

        for (var comment in commentsResponse) {
          commentsMap[comment['id'].toString()] = CommunityComment.fromJson(
            comment,
          );
        }
      }

      // Gabungkan data
      return notifications.map((notification) {
        if (notification.postId != null &&
            postsMap.containsKey(notification.postId)) {
          notification = notification.copyWith(
            post: postsMap[notification.postId!],
          );
        }
        if (notification.commentId != null &&
            commentsMap.containsKey(notification.commentId)) {
          notification = notification.copyWith(
            comment: commentsMap[notification.commentId!],
          );
        }
        return notification;
      }).toList();
    } catch (e) {
      developer.log('Error enriching notifications: $e');
      return notifications;
    }
  }

  // ============ NOTIFICATION CREATION METHODS ============
  // NOTE: Methods ini sekarang di-nonaktifkan karena notifikasi dihandle oleh database trigger
  // Biarkan kosong untuk menghindari double notification

  // Buat notifikasi untuk komentar baru
  Future<void> createCommentNotification({
    required String commentId,
    required String postId,
    required String commentAuthorId,
    required String postAuthorId,
    required String communityId,
  }) async {
    // NOTIFIKASI SEKARANG DIHANDLE OLEH TRIGGER DATABASE
    // Method ini dibiarkan kosong untuk backward compatibility
    developer.log('ℹ️ Notifikasi komentar dihandle oleh database trigger');
    return;
  }

  // Buat notifikasi untuk tag
  Future<void> createMentionNotification({
    required List<String> mentionedUserIds,
    required String postId,
    required String senderId,
    required String communityId,
  }) async {
    // NOTIFIKASI SEKARANG DIHANDLE OLEH TRIGGER DATABASE
    // Method ini dibiarkan kosong untuk backward compatibility
    developer.log('ℹ️ Notifikasi mention dihandle oleh database trigger');
    return;
  }

  // Buat notifikasi untuk like
  Future<void> createLikeNotification({
    required String postId,
    required String likerId,
    required String postAuthorId,
    required String communityId,
  }) async {
    // NOTIFIKASI SEKARANG DIHANDLE OLEH TRIGGER DATABASE
    // Method ini dibiarkan kosong untuk backward compatibility
    developer.log('ℹ️ Notifikasi like dihandle oleh database trigger');
    return;
  }

  // ============ NOTIFICATION MANAGEMENT METHODS ============
  // Methods di bawah ini TETAP BERFUNGSI karena tidak berhubungan dengan creation

  // Tandai notifikasi sebagai sudah dibaca
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('community_notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (e) {
      developer.log('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Tandai semua notifikasi sebagai sudah dibaca
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('community_notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      developer.log('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  // Hapus notifikasi
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('community_notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      developer.log('Error deleting notification: $e');
      rethrow;
    }
  }

  // Dapatkan jumlah notifikasi yang belum dibaca
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('community_notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      developer.log('Error getting unread count: $e');
      return 0;
    }
  }

  // Dapatkan semua notifikasi
  Future<List<CommunityNotification>> getNotifications(
    String userId, {
    bool unreadOnly = false,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('community_notifications')
          .select('*')
          .eq('user_id', userId);

      if (unreadOnly) {
        queryBuilder = queryBuilder.eq('is_read', false);
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final notifications = (response as List)
          .map((json) => CommunityNotification.fromJson(json))
          .toList();

      return await _enrichNotifications(notifications);
    } catch (e) {
      developer.log('❌ Error getting notifications: $e');
      return [];
    }
  }

  // Cleanup resources jika perlu
  void dispose() {
    // Tidak ada subscription yang perlu di-dispose
  }
}