// lib/domain/model/friendship_model.dart
import 'package:purewill/domain/model/community_model.dart';

class FriendshipStatus {
  static const String none = 'none';
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';
}

class Friendship {
  final String id;
  final String senderId;
  final String receiverId;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Profile? sender;
  final Profile? receiver;

  Friendship({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.sender,
    this.receiver,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    Profile? sender;
    Profile? receiver;

    if (json['sender'] != null && json['sender'] is Map) {
      sender = Profile.fromJson(Map<String, dynamic>.from(json['sender']));
    }
    
    if (json['receiver'] != null && json['receiver'] is Map) {
      receiver = Profile.fromJson(Map<String, dynamic>.from(json['receiver']));
    }

    return Friendship(
      id: json['id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      status: json['status']?.toString() ?? FriendshipStatus.none,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : null,
      sender: sender,
      receiver: receiver,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sender': sender?.toJson(),
      'receiver': receiver?.toJson(),
    };
  }

  bool get isPending => status == FriendshipStatus.pending;
  bool get isAccepted => status == FriendshipStatus.accepted;
  bool get isRejected => status == FriendshipStatus.rejected;
  bool get isFriend => isAccepted;
}