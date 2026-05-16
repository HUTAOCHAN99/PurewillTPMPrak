import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CategoryModel {
  final int id;
  final String name;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    DateTime parseCreatedAt(dynamic date) {
      if (date is String) {
        return DateTime.parse(date);
      }
      return DateTime.now();
    }

    return CategoryModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? 'Unknown',
      createdAt: parseCreatedAt(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String()
    };
  }
}

class Profile {
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final int level;
  final int currentXp;
  final int xpToNextLevel;

  Profile({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.level = 1,
    this.currentXp = 0,
    this.xpToNextLevel = 100,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    String userId = 'unknown';
    String fullName = 'Pengguna';
    String? avatarUrl;
    int level = 1;
    int currentXp = 0;
    int xpToNextLevel = 100;

    // Cek jika ini dari auth.users (ada email field)
    if (json['email'] != null) {
      userId = json['id']?.toString() ?? 'unknown';
      fullName = json['raw_user_meta_data']?['full_name']?.toString() ??
          json['full_name']?.toString() ??
          json['email']?.toString().split('@').first ??
          'Pengguna';
      avatarUrl = json['raw_user_meta_data']?['avatar_url']?.toString() ??
          json['avatar_url']?.toString();
    }
    // Cek jika ini dari profiles table
    else if (json['user_id'] != null) {
      userId = json['user_id']?.toString() ?? 'unknown';
      fullName = json['full_name']?.toString() ?? 'Pengguna';
      avatarUrl = json['avatar_url']?.toString();
      level = json['level'] is int ? json['level'] : 1;
      currentXp = json['current_xp'] is int ? json['current_xp'] : 0;
      xpToNextLevel = json['xp_to_next_level'] is int
          ? json['xp_to_next_level']
          : 100;
    }
    // Cek jika nested dalam auth.users format
    else if (json['id'] is Map) {
      final authData = Map<String, dynamic>.from(json['id']);
      userId = authData['id']?.toString() ?? 'unknown';
      fullName =
          authData['email']?.toString().split('@').first ?? 'Pengguna';
    }

    return Profile(
      userId: userId,
      fullName: fullName,
      avatarUrl: avatarUrl,
      level: level,
      currentXp: currentXp,
      xpToNextLevel: xpToNextLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'level': level,
      'current_xp': currentXp,
      'xp_to_next_level': xpToNextLevel,
    };
  }

  Profile copyWith({
    String? userId,
    String? fullName,
    String? avatarUrl,
    int? level,
    int? currentXp,
    int? xpToNextLevel,
  }) {
    return Profile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
    );
  }
}

class Community {
  final String id;
  final String name;
  final String? description;
  final String? iconName;
  final String? color;
  final String? coverImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int memberCount;
  final String? adminId;
  final List<String>? rules;
  final List<String>? tags;
  final bool isJoined;

  Community({
    required this.id,
    required this.name,
    this.description,
    this.iconName = 'people',
    this.color = '#7C3AED',
    this.coverImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.memberCount = 0,
    this.adminId,
    this.rules,
    this.tags,
    this.isJoined = false,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    // Parse category jika ada
    CategoryModel? category;
    if (json['categories'] != null) {
      try {
        if (json['categories'] is Map) {
          category = CategoryModel.fromJson(
            Map<String, dynamic>.from(json['categories']),
          );
        } else if (json['categories'] is List &&
            (json['categories'] as List).isNotEmpty) {
          category = CategoryModel.fromJson(
            Map<String, dynamic>.from((json['categories'] as List).first),
          );
        }
      } catch (e) {
        // Ignore error
      }
    }

    // Parse dates dengan error handling
    DateTime parseDate(dynamic date) {
      if (date == null) {
        return DateTime.now();
      }
      if (date is String) {
        try {
          return DateTime.parse(date);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    // Parse rules
    List<String>? rules;
    if (json['rules'] != null) {
      if (json['rules'] is String) {
        try {
          final parsed = jsonDecode(json['rules'] as String) as List;
          rules = parsed.map((e) => e.toString()).toList();
        } catch (e) {
          rules = [];
        }
      } else if (json['rules'] is List) {
        rules = (json['rules'] as List).map((e) => e.toString()).toList();
      }
    }

    // Parse tags
    List<String>? tags;
    if (json['tags'] != null) {
      if (json['tags'] is String) {
        try {
          final parsed = jsonDecode(json['tags'] as String) as List;
          tags = parsed.map((e) => e.toString()).toList();
        } catch (e) {
          // Ignore error
        }
      } else if (json['tags'] is List) {
        tags = (json['tags'] as List).map((e) => e.toString()).toList();
      }
    }

    return Community(
      id: json['id']?.toString() ?? 'unknown',
      name: json['name']?.toString() ?? 'Unknown Community',
      description: json['description']?.toString(),
      iconName: json['icon_name']?.toString() ?? 'people',
      color: json['color']?.toString() ?? '#7C3AED',
      coverImageUrl: json['cover_image_url']?.toString(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      isActive: json['is_active'] == true,
      memberCount: json['member_count'] is int
          ? json['member_count']
          : json['member_count'] is String
              ? int.tryParse(json['member_count'].toString()) ?? 0
              : 0,
      adminId: json['admin_id']?.toString(),
      rules: rules,
      tags: tags,
      isJoined: json['is_joined'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'color': color,
      'cover_image_url': coverImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'member_count': memberCount,
      'admin_id': adminId,
      'rules': rules,
      'tags': tags,
      'is_joined': isJoined,
    };
  }

  Community copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    String? color,
    String? coverImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? memberCount,
    String? adminId,
    CategoryModel? category,
    List<String>? rules,
    List<String>? tags,
    bool? isJoined,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      memberCount: memberCount ?? this.memberCount,
      adminId: adminId ?? this.adminId,
      rules: rules ?? this.rules,
      tags: tags ?? this.tags,
      isJoined: isJoined ?? this.isJoined,
    );
  }
}

class CommunityPost {
  final String id;
  final String communityId;
  final String authorId;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPinned;
  final bool isEdited;
  final DateTime? deletedAt;
  final int likesCount;
  final int commentsCount;
  final int shareCount;
  final int viewCount;
  final String? sharedFromPostId;
  final String? sharedFromCommunityId;
  final Profile? author;
  final Community? community;
  final bool? isLikedByUser;
  final bool? isViewedByUser;

  CommunityPost({
    required this.id,
    required this.communityId,
    required this.authorId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
    this.isPinned = false,
    this.isEdited = false,
    this.deletedAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.shareCount = 0,
    this.viewCount = 0,
    this.sharedFromPostId,
    this.sharedFromCommunityId,
    this.author,
    this.community,
    this.isLikedByUser,
    this.isViewedByUser,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    Profile? author;

    if (json['profiles'] != null) {
      try {
        // Coba parse sebagai Map
        if (json['profiles'] is Map) {
          author = Profile.fromJson(
            Map<String, dynamic>.from(json['profiles']),
          );
        }
        // Atau jika profiles adalah List (array)
        else if (json['profiles'] is List &&
            (json['profiles'] as List).isNotEmpty) {
          author = Profile.fromJson(
            Map<String, dynamic>.from((json['profiles'] as List).first),
          );
        }
        // Atau jika profiles adalah string JSON
        else if (json['profiles'] is String) {
          try {
            final parsed = jsonDecode(json['profiles'] as String);
            if (parsed is Map) {
              author = Profile.fromJson(Map<String, dynamic>.from(parsed));
            } else if (parsed is List && parsed.isNotEmpty) {
              author = Profile.fromJson(
                Map<String, dynamic>.from(parsed.first),
              );
            }
          } catch (e) {
            // Ignore error
          }
        }
      } catch (e) {
        // Ignore error
      }
    }

    // Parse community jika ada
    Community? community;
    if (json['communities'] != null) {
      try {
        if (json['communities'] is Map) {
          community = Community.fromJson(
            Map<String, dynamic>.from(json['communities']),
          );
        } else if (json['communities'] is List &&
            (json['communities'] as List).isNotEmpty) {
          community = Community.fromJson(
            Map<String, dynamic>.from((json['communities'] as List).first),
          );
        }
      } catch (e) {
        // Ignore error
      }
    }

    // VALIDASI: Image URL harus null atau URL Supabase, BUKAN Base64
    final imageUrl = json['image_url']?.toString();
    if (imageUrl != null && _isInvalidImageUrl(imageUrl)) {
      // Invalid URL, set to null
    }

    // Validasi khusus untuk URL Supabase bucket 'communities'
    bool isValidSupabaseUrl(String? url) {
      if (url == null || url.isEmpty) return false;

      // Cek jika Base64
      if (url.startsWith('data:image')) return false;

      // Cek jika mengandung Base64 pattern
      if (url.contains('base64,')) return false;

      // Cek jika URL Supabase Storage dengan bucket 'communities'
      final isSupabaseUrl =
          url.contains('supabase.co/storage/v1/object/public/');
      final isCommunitiesBucket = url.contains('/communities/');
      final isHttps = url.startsWith('https://');

      return isSupabaseUrl && isCommunitiesBucket && isHttps;
    }

    // Buat profile fallback jika author null
    if (author == null) {
      final authorId = json['author_id']?.toString() ?? 'unknown';
      author = Profile(
        userId: authorId,
        fullName: 'Pengguna',
        avatarUrl: null,
        level: 1,
        currentXp: 0,
        xpToNextLevel: 100,
      );
    }

    // Parse dates
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is String) {
        try {
          return DateTime.parse(date);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return CommunityPost(
      id: json['id']?.toString() ?? '',
      communityId: json['community_id']?.toString() ?? '',
      authorId: json['author_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      imageUrl:
          _isInvalidImageUrl(imageUrl) || !isValidSupabaseUrl(imageUrl)
              ? null
              : imageUrl,
      createdAt: parseDate(json['created_at']),
      updatedAt:
          json['updated_at'] != null ? parseDate(json['updated_at']) : null,
      isPinned: json['is_pinned'] == true,
      isEdited: json['is_edited'] == true,
      deletedAt:
          json['deleted_at'] != null ? parseDate(json['deleted_at']) : null,
      likesCount: json['likes_count'] is int
          ? json['likes_count']
          : json['likes_count'] is String
              ? int.tryParse(json['likes_count'].toString()) ?? 0
              : 0,
      commentsCount: json['comments_count'] is int
          ? json['comments_count']
          : json['comments_count'] is String
              ? int.tryParse(json['comments_count'].toString()) ?? 0
              : 0,
      shareCount: json['share_count'] is int
          ? json['share_count']
          : json['share_count'] is String
              ? int.tryParse(json['share_count'].toString()) ?? 0
              : 0,
      viewCount: json['view_count'] is int
          ? json['view_count']
          : json['view_count'] is String
              ? int.tryParse(json['view_count'].toString()) ?? 0
              : 0,
      sharedFromPostId: json['shared_from_post_id']?.toString(),
      sharedFromCommunityId: json['shared_from_community_id']?.toString(),
      author: author,
      community: community,
      isLikedByUser: json['is_liked_by_user'] == true,
      isViewedByUser: json['is_viewed_by_user'] == true,
    );
  }

  static bool _isInvalidImageUrl(String? url) {
    if (url == null) return false;
    if (url.startsWith('data:image')) return true;
    if (url.length < 10) return true;
    if (url.contains('base64,')) return true;
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'community_id': communityId,
      'author_id': authorId,
      'content': content,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_pinned': isPinned,
      'is_edited': isEdited,
      'deleted_at': deletedAt?.toIso8601String(),
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'share_count': shareCount,
      'view_count': viewCount,
      'shared_from_post_id': sharedFromPostId,
      'shared_from_community_id': sharedFromCommunityId,
      'profiles': author?.toJson(),
      'communities': community?.toJson(),
      'is_liked_by_user': isLikedByUser,
      'is_viewed_by_user': isViewedByUser,
    };
  }

  CommunityPost copyWith({
    String? id,
    String? communityId,
    String? authorId,
    String? content,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isEdited,
    DateTime? deletedAt,
    int? likesCount,
    int? commentsCount,
    int? shareCount,
    int? viewCount,
    String? sharedFromPostId,
    String? sharedFromCommunityId,
    Profile? author,
    Community? community,
    bool? isLikedByUser,
    bool? isViewedByUser,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isEdited: isEdited ?? this.isEdited,
      deletedAt: deletedAt ?? this.deletedAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      shareCount: shareCount ?? this.shareCount,
      viewCount: viewCount ?? this.viewCount,
      sharedFromPostId: sharedFromPostId ?? this.sharedFromPostId,
      sharedFromCommunityId:
          sharedFromCommunityId ?? this.sharedFromCommunityId,
      author: author ?? this.author,
      community: community ?? this.community,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      isViewedByUser: isViewedByUser ?? this.isViewedByUser,
    );
  }

  bool get hasImage =>
      imageUrl != null &&
      imageUrl!.isNotEmpty &&
      !_isInvalidImageUrl(imageUrl);
  bool get isShared =>
      sharedFromPostId != null && sharedFromPostId!.isNotEmpty;

  bool get isValidImageUrl {
    if (imageUrl == null) return false;

    final url = imageUrl!;
    final isSupabaseUrl =
        url.contains('supabase.co/storage/v1/object/public/');
    final isCommunitiesBucket = url.contains('/communities/');
    final isHttps = url.startsWith('https://');
    final notBase64 = !url.contains('base64,') && !url.startsWith('data:');

    return isSupabaseUrl && isCommunitiesBucket && isHttps && notBase64;
  }
}

class CommunityComment {
  final String id;
  final String postId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? parentCommentId;
  final DateTime? deletedAt;
  final Profile? author;
  final List<CommunityComment>? replies;
  final bool? isLikedByUser;
  final int likesCount;
  final int replyCount;

  CommunityComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.parentCommentId,
    this.deletedAt,
    this.author,
    this.replies,
    this.isLikedByUser,
    this.likesCount = 0,
    this.replyCount = 0,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    Profile? author;

    if (json['profiles'] != null) {
      try {
        if (json['profiles'] is Map) {
          author = Profile.fromJson(
            Map<String, dynamic>.from(json['profiles']),
          );
        } else if (json['profiles'] is List &&
            (json['profiles'] as List).isNotEmpty) {
          author = Profile.fromJson(
            Map<String, dynamic>.from((json['profiles'] as List).first),
          );
        }
      } catch (e) {
        // Ignore error
      }
    }

    // Buat profile fallback jika author null
    if (author == null) {
      final authorId = json['author_id']?.toString() ?? 'unknown';
      author = Profile(
        userId: authorId,
        fullName: 'Pengguna',
        avatarUrl: null,
        level: 1,
        currentXp: 0,
        xpToNextLevel: 100,
      );
    }

    // Parse dates
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is String) {
        try {
          return DateTime.parse(date);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return CommunityComment(
      id: json['id']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? '',
      authorId: json['author_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      parentCommentId: json['parent_comment_id']?.toString(),
      deletedAt:
          json['deleted_at'] != null ? parseDate(json['deleted_at']) : null,
      author: author,
      isLikedByUser: json['is_liked_by_user'] == true,
      likesCount: json['likes_count'] is int ? json['likes_count'] : 0,
      replyCount: json['reply_count'] is int ? json['reply_count'] : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'author_id': authorId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'parent_comment_id': parentCommentId,
      'deleted_at': deletedAt?.toIso8601String(),
      'profiles': author?.toJson(),
      'is_liked_by_user': isLikedByUser,
      'likes_count': likesCount,
      'reply_count': replyCount,
    };
  }

  CommunityComment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? parentCommentId,
    DateTime? deletedAt,
    Profile? author,
    List<CommunityComment>? replies,
    bool? isLikedByUser,
    int? likesCount,
    int? replyCount,
  }) {
    return CommunityComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      deletedAt: deletedAt ?? this.deletedAt,
      author: author ?? this.author,
      replies: replies ?? this.replies,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      likesCount: likesCount ?? this.likesCount,
      replyCount: replyCount ?? this.replyCount,
    );
  }

  bool get hasReplies => replies != null && replies!.isNotEmpty;
  bool get isReply =>
      parentCommentId != null && parentCommentId!.isNotEmpty;
}

class CommunityPostShare {
  final String id;
  final String originalPostId;
  final String sharedPostId;
  final String sharedByUserId;
  final String? sharedToCommunityId;
  final DateTime createdAt;
  final CommunityPost? originalPost;
  final CommunityPost? sharedPost;

  CommunityPostShare({
    required this.id,
    required this.originalPostId,
    required this.sharedPostId,
    required this.sharedByUserId,
    this.sharedToCommunityId,
    required this.createdAt,
    this.originalPost,
    this.sharedPost,
  });

  factory CommunityPostShare.fromJson(Map<String, dynamic> json) {
    CommunityPost? originalPost;
    CommunityPost? sharedPost;

    if (json['original_post'] != null && json['original_post'] is Map) {
      originalPost = CommunityPost.fromJson(
        Map<String, dynamic>.from(json['original_post']),
      );
    }

    if (json['shared_post'] != null && json['shared_post'] is Map) {
      sharedPost = CommunityPost.fromJson(
        Map<String, dynamic>.from(json['shared_post']),
      );
    }

    return CommunityPostShare(
      id: json['id']?.toString() ?? '',
      originalPostId: json['original_post_id']?.toString() ?? '',
      sharedPostId: json['shared_post_id']?.toString() ?? '',
      sharedByUserId: json['shared_by_user_id']?.toString() ?? '',
      sharedToCommunityId: json['shared_to_community_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      originalPost: originalPost,
      sharedPost: sharedPost,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'original_post_id': originalPostId,
      'shared_post_id': sharedPostId,
      'shared_by_user_id': sharedByUserId,
      'shared_to_community_id': sharedToCommunityId,
      'created_at': createdAt.toIso8601String(),
      'original_post': originalPost?.toJson(),
      'shared_post': sharedPost?.toJson(),
    };
  }
}

class CommunityNotification {
  final String id;
  final String userId;
  final String type; // 'comment', 'like', 'mention', 'follow'
  final String title;
  final String message;
  final String? postId;
  final String? commentId;
  final String? senderId;
  final String? communityId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  // Enriched data
  final CommunityPost? post;
  final CommunityComment? comment;
  final Profile? sender;

  CommunityNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.postId,
    this.commentId,
    this.senderId,
    this.communityId,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.post,
    this.comment,
    this.sender,
  });

  factory CommunityNotification.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is String) {
        try {
          return DateTime.parse(date);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return CommunityNotification(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'unknown',
      title: json['title']?.toString() ?? 'Notifikasi',
      message: json['message']?.toString() ?? '',
      postId: json['post_id']?.toString(),
      commentId: json['comment_id']?.toString(),
      senderId: json['sender_id']?.toString(),
      communityId: json['community_id']?.toString(),
      isRead: json['is_read'] == true,
      createdAt: parseDate(json['created_at']),
      readAt: json['read_at'] != null ? parseDate(json['read_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'post_id': postId,
      'comment_id': commentId,
      'sender_id': senderId,
      'community_id': communityId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  CommunityNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    String? postId,
    String? commentId,
    String? senderId,
    String? communityId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    CommunityPost? post,
    CommunityComment? comment,
    Profile? sender,
  }) {
    return CommunityNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
      senderId: senderId ?? this.senderId,
      communityId: communityId ?? this.communityId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      post: post ?? this.post,
      comment: comment ?? this.comment,
      sender: sender ?? this.sender,
    );
  }

  bool get isCommentNotification => type == 'comment';
  bool get isLikeNotification => type == 'like';
  bool get isMentionNotification => type == 'mention';

  IconData get icon {
    switch (type) {
      case 'comment':
        return Icons.comment;
      case 'like':
        return Icons.favorite;
      case 'mention':
        return Icons.alternate_email;
      default:
        return Icons.notifications;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'comment':
        return Colors.blue;
      case 'like':
        return Colors.red;
      case 'mention':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}