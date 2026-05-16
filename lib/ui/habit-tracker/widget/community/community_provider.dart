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

final userProfileWithStatsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, userId) async {
  final facade = ref.read(communityFacadeProvider);
  return await facade.getUserProfileWithStats(userId);
});