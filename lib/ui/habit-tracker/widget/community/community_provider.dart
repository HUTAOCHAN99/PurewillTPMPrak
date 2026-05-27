// lib/ui/habit-tracker/widget/community/community_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/data/services/community/community_service.dart';
import 'package:purewill/data/services/community/image_saver_service.dart';
import 'package:purewill/data/services/community/notification_service.dart';
import 'package:purewill/data/services/community/post_service.dart';
import 'package:purewill/data/services/community/comment_service.dart';
import 'package:purewill/data/services/community/image_service.dart';
import 'package:purewill/data/services/community/profile_service.dart';
import 'package:purewill/data/services/community/friendship_service.dart';
import 'package:purewill/data/services/community/report_service.dart';
import 'package:purewill/data/services/community/facade_service.dart';
import 'package:purewill/domain/model/community_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Providers untuk masing-masing service
final communityServiceProvider = Provider((ref) => CommunityService());
final postServiceProvider = Provider((ref) => PostService());
final commentServiceProvider = Provider((ref) => CommentService());
final imageServiceProvider = Provider((ref) => ImageService());
final profileServiceProvider = Provider((ref) => ProfileService());
final imageSaverServiceProvider = Provider((ref) => ImageSaverService());
final notificationServiceProvider = Provider((ref) => NotificationService());
final friendshipServiceProvider = Provider((ref) => FriendshipService());
final reportServiceProvider = Provider((ref) => ReportService());

// Facade provider untuk kemudahan penggunaan
final communityFacadeProvider = Provider(
  (ref) => CommunityFacadeService(
    communityService: ref.read(communityServiceProvider),
    postService: ref.read(postServiceProvider),
    commentService: ref.read(commentServiceProvider),
    imageService: ref.read(imageServiceProvider),
    profileService: ref.read(profileServiceProvider),
    friendshipService: ref.read(friendshipServiceProvider),
    reportService: ref.read(reportServiceProvider),
  ),
);

// Provider untuk current user
final currentUserProvider = Provider<User?>((ref) {
  final supabase = Supabase.instance.client;
  return supabase.auth.currentUser;
});

// Provider untuk cek status ban user
final userBanStatusProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final reportService = ReportService();
  return await reportService.checkUserBanStatus(user.id);
});

// Provider untuk cek apakah user bisa akses komunitas
final canAccessCommunityProvider = FutureProvider.autoDispose<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return true;

  final reportService = ReportService();
  return await reportService.canUserAccessCommunity(user.id);
});

// Provider untuk pesan ban
final userBanMessageProvider = FutureProvider.autoDispose<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final reportService = ReportService();
  return await reportService.getUserBanMessage(user.id);
});

// Provider untuk real-time like status per post
final postLikeStatusProvider = StreamProvider.autoDispose
    .family<bool, String>((ref, postId) {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  final controller = StreamController<bool>.broadcast();

  if (user == null) {
    controller.add(false);
    controller.close();
    return controller.stream;
  }

  Future.microtask(() async {
    final postService = ref.read(postServiceProvider);
    final isLiked = await postService.isPostLikedByUser(postId, user.id);
    if (!controller.isClosed) {
      controller.add(isLiked);
    }
  });

  final channel = supabase
      .channel('like_status_$postId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'community_likes',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'post_id',
          value: postId,
        ),
        callback: (payload) async {
          final newLikeUserId = payload.newRecord['user_id'] as String?;
          if (newLikeUserId == user.id && !controller.isClosed) {
            controller.add(true);
          }
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'community_likes',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'post_id',
          value: postId,
        ),
        callback: (payload) async {
          final oldLikeUserId = payload.oldRecord['user_id'] as String?;
          if (oldLikeUserId == user.id && !controller.isClosed) {
            controller.add(false);
          }
        },
      )
      .subscribe();

  ref.onDispose(() {
    if (!controller.isClosed) {
      controller.close();
    }
    supabase.removeChannel(channel);
  });

  return controller.stream;
});

// Provider untuk real-time posts stream
final communityPostsStreamProvider = StreamProvider.autoDispose
    .family<List<CommunityPost>, String>((ref, communityId) {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  final controller = StreamController<List<CommunityPost>>.broadcast();

  if (user == null) {
    controller.add([]);
    controller.close();
    return controller.stream;
  }

  final postService = ref.read(postServiceProvider);

  Future.microtask(() async {
    final posts = await postService.getCommunityPosts(communityId, userId: user.id);
    if (!controller.isClosed) {
      controller.add(posts);
    }
  });

  final channel = supabase
      .channel('posts_changes_$communityId')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'community_posts',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'community_id',
          value: communityId,
        ),
        callback: (payload) async {
          print('🔔 Real-time post update detected!');
          final updatedPosts = await postService.getCommunityPosts(
            communityId,
            userId: user.id,
          );
          if (!controller.isClosed) {
            controller.add(updatedPosts);
          }
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'community_posts',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'community_id',
          value: communityId,
        ),
        callback: (payload) async {
          print('🔔 New post detected!');
          final updatedPosts = await postService.getCommunityPosts(
            communityId,
            userId: user.id,
          );
          if (!controller.isClosed) {
            controller.add(updatedPosts);
          }
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'community_posts',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'community_id',
          value: communityId,
        ),
        callback: (payload) async {
          print('🔔 Post deleted detected!');
          final updatedPosts = await postService.getCommunityPosts(
            communityId,
            userId: user.id,
          );
          if (!controller.isClosed) {
            controller.add(updatedPosts);
          }
        },
      )
      .subscribe();

  ref.onDispose(() {
    if (!controller.isClosed) {
      controller.close();
    }
    supabase.removeChannel(channel);
  });

  return controller.stream;
});

// Provider untuk community details
final communityDetailsProvider = FutureProvider.autoDispose
    .family<Community, String>((ref, communityId) async {
  final communityService = ref.read(communityServiceProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    throw Exception('User not authenticated');
  }

  return await communityService.getCommunityDetails(communityId, user.id);
});

// Provider untuk user profile dengan statistik teman
final userProfileWithStatsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, userId) async {
  final facade = ref.read(communityFacadeProvider);
  return await facade.getUserProfileWithStats(userId);
});

// Provider untuk reports
final adminReportsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, ReportStatus?>((ref, status) async {
  final facade = ref.read(communityFacadeProvider);
  try {
    print('📊 [Provider] Fetching reports for status: ${status?.value ?? 'all'}');
    final reports = await facade.getAllReports(status: status, limit: 100);
    print('✅ [Provider] Retrieved ${reports.length} reports');
    return reports;
  } catch (e) {
    print('❌ [Provider] Error in adminReportsProvider: $e');
    return [];
  }
});

final pendingReportsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final facade = ref.read(communityFacadeProvider);
  try {
    final count = await facade.getPendingReportsCount();
    print('📊 Pending reports count: $count');
    return count;
  } catch (e) {
    print('❌ Error getting pending reports count: $e');
    return 0;
  }
});

final reportStatisticsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final facade = ref.read(communityFacadeProvider);
  try {
    final stats = await facade.getReportStatistics();
    print('📊 Report statistics: $stats');
    return stats;
  } catch (e) {
    print('❌ Error getting report statistics: $e');
    return {
      'pending': 0,
      'reviewed': 0,
      'resolved': 0,
      'rejected': 0,
      'today': 0,
      'total': 0,
    };
  }
});