// lib\data\services\community\facade_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:purewill/data/services/community/friendship_service.dart';
import 'package:purewill/data/services/community/index.dart';
import 'package:purewill/data/services/community/report_service.dart';
import 'package:purewill/domain/model/community_model.dart';
import 'package:purewill/domain/model/friendship_model.dart';

// Facade untuk menyederhanakan penggunaan service
class CommunityFacadeService {
  final CommunityService _communityService;
  final PostService _postService;
  final CommentService _commentService;
  final ImageService _imageService;
  final ProfileService _profileService;
  final FriendshipService _friendshipService;
  final ReportService _reportService;

  CommunityFacadeService({
    required CommunityService communityService,
    required PostService postService,
    required CommentService commentService,
    required ImageService imageService,
    required ProfileService profileService,
    required FriendshipService friendshipService,
    required ReportService reportService,
  })  : _communityService = communityService,
        _postService = postService,
        _commentService = commentService,
        _imageService = imageService,
        _profileService = profileService,
        _friendshipService = friendshipService,
        _reportService = reportService;

  // ============ FACADE METHODS ============

  // Komunitas
  Future<List<Community>> getCommunities(String userId) =>
      _communityService.getCommunities(userId);

  Future<Community> getCommunityDetails(String communityId, String userId) =>
      _communityService.getCommunityDetails(communityId, userId);

  Future<bool> joinCommunity(String communityId, String userId) =>
      _communityService.joinCommunity(communityId, userId);

  Future<bool> leaveCommunity(String communityId, String userId) =>
      _communityService.leaveCommunity(communityId, userId);

  Future<void> updateLastSeen(String userId, String communityId) =>
      _communityService.updateLastSeen(userId, communityId);

  Future<int> getUnreadPostsCount(String userId, String communityId) =>
      _communityService.getUnreadPostsCount(userId, communityId);

  // Post
  Future<List<CommunityPost>> getCommunityPosts(
    String communityId, {
    String? userId,
  }) =>
      _postService.getCommunityPosts(communityId, userId: userId);

  Future<CommunityPost> createPostWithImage({
    required String communityId,
    required String userId,
    required String content,
    XFile? imageFile,
  }) async {
    String? imageUrl;

    if (imageFile != null) {
      final file = File(imageFile.path);
      if (!await file.exists()) {
        throw Exception('Image file tidak ditemukan');
      }

      imageUrl = await _imageService.uploadImage(file, userId);
    }

    return _postService.createPost(
      communityId: communityId,
      userId: userId,
      content: content,
      imageUrl: imageUrl,
    );
  }

  Future<CommunityPost> createPost({
    required String communityId,
    required String userId,
    required String content,
    String? imageUrl,
  }) =>
      _postService.createPost(
        communityId: communityId,
        userId: userId,
        content: content,
        imageUrl: imageUrl,
      );

  Future<CommunityPost> updatePost({
    required String postId,
    required String content,
    String? imageUrl,
  }) =>
      _postService.updatePost(
        postId: postId,
        content: content,
        imageUrl: imageUrl,
      );

  Future<bool> deletePost(String postId) => _postService.deletePost(postId);

  Future<bool> toggleLikePost(String postId, String userId) =>
      _postService.toggleLikePost(postId, userId);

  Future<bool> isPostLikedByUser(String postId, String userId) =>
      _postService.isPostLikedByUser(postId, userId);

  Future<void> trackPostView(String postId, String userId) =>
      _postService.trackPostView(postId, userId);

  Future<bool> isPostViewedByUser(String postId, String userId) =>
      _postService.isPostViewedByUser(postId, userId);

  Future<List<CommunityPost>> searchPosts({
    required String query,
    String? communityId,
    int limit = 20,
  }) =>
      _postService.searchPosts(
        query: query,
        communityId: communityId,
        limit: limit,
      );

  Future<List<CommunityPost>> getUserPosts(String userId) =>
      _postService.getUserPosts(userId);

  Future<CommunityPost> sharePostToCommunity({
    required String originalPostId,
    required String targetCommunityId,
    required String userId,
    String? additionalComment,
  }) =>
      _postService.sharePostToCommunity(
        originalPostId: originalPostId,
        targetCommunityId: targetCommunityId,
        userId: userId,
        additionalComment: additionalComment,
      );

  // Komentar
  Future<CommunityComment> addComment({
    required String postId,
    required String userId,
    required String content,
    String? parentCommentId,
  }) =>
      _commentService.addComment(
        postId: postId,
        userId: userId,
        content: content,
        parentCommentId: parentCommentId,
      );

  Future<List<CommunityComment>> getPostComments(
    String postId, {
    String? userId,
  }) =>
      _commentService.getPostComments(postId, userId: userId);

  Future<bool> toggleLikeComment(String commentId, String userId) =>
      _commentService.toggleLikeComment(commentId, userId);

  Future<bool> isCommentLikedByUser(String commentId, String userId) =>
      _commentService.isCommentLikedByUser(commentId, userId);

  Future<CommunityComment?> getCommentById(String commentId) =>
      _commentService.getCommentById(commentId);

  // Gambar
  Future<XFile?> pickImage() => _imageService.pickImage();

  Future<String?> uploadImage(File file, String userId) =>
      _imageService.uploadImage(file, userId);

  // Profile
  Future<Profile?> getUserProfile(String userId) =>
      _profileService.getUserProfile(userId);

  // ============ FRIENDSHIP METHODS ============

  Future<Friendship?> getFriendshipStatus({
    required String currentUserId,
    required String targetUserId,
  }) =>
      _friendshipService.getFriendshipStatus(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
      );

  Future<Friendship> sendFriendRequest({
    required String senderId,
    required String receiverId,
  }) =>
      _friendshipService.sendFriendRequest(
        senderId: senderId,
        receiverId: receiverId,
      );

  Future<Friendship> acceptFriendRequest(String friendshipId) =>
      _friendshipService.acceptFriendRequest(friendshipId);

  Future<Friendship> rejectFriendRequest(String friendshipId) =>
      _friendshipService.rejectFriendRequest(friendshipId);

  Future<void> removeFriend(String friendshipId) =>
      _friendshipService.removeFriend(friendshipId);

  Future<void> cancelFriendRequest(String friendshipId) =>
      _friendshipService.cancelFriendRequest(friendshipId);

  Future<String> getRelationshipStatus({
    required String currentUserId,
    required String targetUserId,
  }) =>
      _friendshipService.getRelationshipStatus(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
      );

  Future<List<Profile>> getFriends(String userId) =>
      _friendshipService.getFriends(userId);

  Future<List<Friendship>> getPendingRequests(String userId) =>
      _friendshipService.getPendingRequests(userId);

  Future<int> getFriendCount(String userId) =>
      _friendshipService.getFriendCount(userId);

  // ============ REPORT METHODS ============

  Future<bool> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? description,
    String? postId,
    String? commentId,
    String? communityId,
  }) =>
      _reportService.reportUser(
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        reason: reason,
        description: description,
        postId: postId,
        commentId: commentId,
        communityId: communityId,
      );

  Future<List<String>> getReportReasons() => _reportService.getReportReasons();

  Future<bool> blockUser({
    required String blockerId,
    required String blockedUserId,
  }) =>
      _reportService.blockUser(
        blockerId: blockerId,
        blockedUserId: blockedUserId,
      );

  Future<bool> isUserBlocked({
    required String currentUserId,
    required String targetUserId,
  }) =>
      _reportService.isUserBlocked(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
      );

  // ============ UTILITY METHODS ============

  Future<bool> ensureUserProfileExists(String userId) =>
      _postService.ensureUserProfileExists(userId);

  // Method untuk mendapatkan profile dengan statistik
  Future<Map<String, dynamic>> getUserProfileWithStats(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      final friendCount = await getFriendCount(userId);
      
      return {
        'profile': profile,
        'friendCount': friendCount,
      };
    } catch (e) {
      rethrow;
    }
  }
}