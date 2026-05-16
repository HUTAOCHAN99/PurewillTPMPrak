// lib/data/services/community/friendship_service.dart
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purewill/domain/model/friendship_model.dart';
import 'package:purewill/domain/model/community_model.dart';

class FriendshipService {
  final SupabaseClient _supabase;

  FriendshipService() : _supabase = Supabase.instance.client;

  // ============ FRIENDSHIP CRUD ============

  Future<Friendship?> getFriendshipStatus({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      final response = await _supabase
          .from('friendships')
          .select('''
            *,
            sender:profiles!friendships_sender_id_fkey(*),
            receiver:profiles!friendships_receiver_id_fkey(*)
          ''')
          .or('(sender_id.eq.$currentUserId,receiver_id.eq.$targetUserId),'
              '(sender_id.eq.$targetUserId,receiver_id.eq.$currentUserId)')
          .maybeSingle();

      if (response == null) return null;
      return Friendship.fromJson(response);
    } catch (e) {
      developer.log('Error getting friendship status: $e');
      return null;
    }
  }

  Future<Friendship> sendFriendRequest({
    required String senderId,
    required String receiverId,
  }) async {
    try {
      // Cek apakah sudah ada permintaan pertemanan
      final existing = await getFriendshipStatus(
        currentUserId: senderId,
        targetUserId: receiverId,
      );

      if (existing != null) {
        // Jika sudah ditolak, update status menjadi pending lagi
        if (existing.isRejected) {
          final response = await _supabase
              .from('friendships')
              .update({
                'status': FriendshipStatus.pending,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', existing.id)
              .select('''
                *,
                sender:profiles!friendships_sender_id_fkey(*),
                receiver:profiles!friendships_receiver_id_fkey(*)
              ''')
              .single();

          return Friendship.fromJson(response);
        }
        return existing;
      }

      // Buat permintaan pertemanan baru
      final response = await _supabase
          .from('friendships')
          .insert({
            'sender_id': senderId,
            'receiver_id': receiverId,
            'status': FriendshipStatus.pending,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('''
            *,
            sender:profiles!friendships_sender_id_fkey(*),
            receiver:profiles!friendships_receiver_id_fkey(*)
          ''')
          .single();

      // Buat notifikasi
      await _createFriendRequestNotification(
        senderId: senderId,
        receiverId: receiverId,
        friendshipId: response['id'].toString(),
      );

      developer.log('✅ Friend request sent to: $receiverId');
      return Friendship.fromJson(response);
    } catch (e) {
      developer.log('❌ Error sending friend request: $e');
      rethrow;
    }
  }

  Future<Friendship> acceptFriendRequest(String friendshipId) async {
    try {
      final response = await _supabase
          .from('friendships')
          .update({
            'status': FriendshipStatus.accepted,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', friendshipId)
          .select('''
            *,
            sender:profiles!friendships_sender_id_fkey(*),
            receiver:profiles!friendships_receiver_id_fkey(*)
          ''')
          .single();

      // Update notifikasi
      await _updateFriendRequestNotification(friendshipId, accepted: true);

      developer.log('✅ Friend request accepted: $friendshipId');
      return Friendship.fromJson(response);
    } catch (e) {
      developer.log('❌ Error accepting friend request: $e');
      rethrow;
    }
  }

  Future<Friendship> rejectFriendRequest(String friendshipId) async {
    try {
      final response = await _supabase
          .from('friendships')
          .update({
            'status': FriendshipStatus.rejected,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', friendshipId)
          .select('''
            *,
            sender:profiles!friendships_sender_id_fkey(*),
            receiver:profiles!friendships_receiver_id_fkey(*)
          ''')
          .single();

      // Update notifikasi
      await _updateFriendRequestNotification(friendshipId, accepted: false);

      developer.log('✅ Friend request rejected: $friendshipId');
      return Friendship.fromJson(response);
    } catch (e) {
      developer.log('❌ Error rejecting friend request: $e');
      rethrow;
    }
  }

  Future<void> removeFriend(String friendshipId) async {
    try {
      await _supabase
          .from('friendships')
          .delete()
          .eq('id', friendshipId);

      developer.log('✅ Friend removed: $friendshipId');
    } catch (e) {
      developer.log('❌ Error removing friend: $e');
      rethrow;
    }
  }

  Future<void> cancelFriendRequest(String friendshipId) async {
    try {
      await _supabase
          .from('friendships')
          .delete()
          .eq('id', friendshipId);

      // Hapus notifikasi terkait
      await _supabase
          .from('community_notifications')
          .delete()
          .eq('friendship_id', friendshipId);

      developer.log('✅ Friend request cancelled: $friendshipId');
    } catch (e) {
      developer.log('❌ Error cancelling friend request: $e');
      rethrow;
    }
  }

  // ============ NOTIFICATION METHODS ============

  Future<void> _createFriendRequestNotification({
    required String senderId,
    required String receiverId,
    required String friendshipId,
  }) async {
    try {
      // Ambil data sender
      final senderProfile = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('user_id', senderId)
          .single();

      await _supabase.from('community_notifications').insert({
        'user_id': receiverId,
        'type': 'friend_request',
        'title': 'Permintaan Pertemanan',
        'message':
            '${senderProfile['full_name']} mengirimkan permintaan pertemanan',
        'sender_id': senderId,
        'friendship_id': friendshipId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      developer.log('Error creating friend request notification: $e');
    }
  }

  Future<void> _updateFriendRequestNotification(
    String friendshipId, {
    required bool accepted,
  }) async {
    try {
      // Dapatkan notifikasi yang sesuai
      final notification = await _supabase
          .from('community_notifications')
          .select('id, sender_id, user_id')
          .eq('friendship_id', friendshipId)
          .eq('type', 'friend_request')
          .maybeSingle();

      if (notification != null) {
        // Update notifikasi untuk pengirim
        await _supabase.from('community_notifications').insert({
          'user_id': notification['sender_id'],
          'type': 'friend_request_response',
          'title': accepted ? 'Permintaan Diterima' : 'Permintaan Ditolak',
          'message': accepted
              ? 'Permintaan pertemanan Anda telah diterima'
              : 'Permintaan pertemanan Anda telah ditolak',
          'sender_id': notification['user_id'],
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      developer.log('Error updating friend request notification: $e');
    }
  }

  // ============ GET FRIENDS LIST ============

  Future<List<Profile>> getFriends(String userId) async {
    try {
      final response = await _supabase
          .from('friendships')
          .select('''
            *,
            sender:profiles!friendships_sender_id_fkey(*),
            receiver:profiles!friendships_receiver_id_fkey(*)
          ''')
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .eq('status', FriendshipStatus.accepted);

      final friends = <Profile>[];
      for (var friendship in response) {
        final friendData = Friendship.fromJson(friendship);
        if (friendData.senderId == userId && friendData.receiver != null) {
          friends.add(friendData.receiver!);
        } else if (friendData.receiverId == userId && friendData.sender != null) {
          friends.add(friendData.sender!);
        }
      }

      return friends;
    } catch (e) {
      developer.log('Error getting friends: $e');
      return [];
    }
  }

  Future<List<Friendship>> getPendingRequests(String userId) async {
    try {
      final response = await _supabase
          .from('friendships')
          .select('''
            *,
            sender:profiles!friendships_sender_id_fkey(*),
            receiver:profiles!friendships_receiver_id_fkey(*)
          ''')
          .eq('receiver_id', userId)
          .eq('status', FriendshipStatus.pending)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Friendship.fromJson(json))
          .toList();
    } catch (e) {
      developer.log('Error getting pending requests: $e');
      return [];
    }
  }

  Future<int> getFriendCount(String userId) async {
    try {
      final response = await _supabase
          .rpc('get_friend_count', params: {'user_id': userId});
      return response as int? ?? 0;
    } catch (e) {
      developer.log('Error getting friend count: $e');
      return 0;
    }
  }

  // ============ CHECK RELATIONSHIP ============

  Future<String> getRelationshipStatus({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      if (currentUserId == targetUserId) return 'self';

      final friendship = await getFriendshipStatus(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
      );

      if (friendship == null) return FriendshipStatus.none;

      if (friendship.isPending) {
        return friendship.senderId == currentUserId
            ? 'request_sent'
            : 'request_received';
      }

      return friendship.status;
    } catch (e) {
      developer.log('Error getting relationship status: $e');
      return FriendshipStatus.none;
    }
  }
}