// lib/ui/habit-tracker/widget/community/chat_bubble_comment.dart
import 'package:flutter/material.dart';
import 'package:purewill/domain/model/community_model.dart';

class ChatBubble extends StatelessWidget {
  final CommunityComment comment;
  final bool isCurrentUser;
  final VoidCallback? onLike;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final VoidCallback? onAvatarTap;
  final bool showTail;
  final bool isReply;

  const ChatBubble({
    super.key,
    required this.comment,
    required this.isCurrentUser,
    this.onLike,
    this.onReply,
    this.onDelete,
    this.onReport,
    this.onAvatarTap,
    this.showTail = true,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final bubbleColor = isCurrentUser
        ? (isDarkMode ? Colors.blue[800] : Colors.blue[100])
        : (isDarkMode ? Colors.grey[800] : Colors.grey[100]);

    final textColor = isCurrentUser
        ? (isDarkMode ? Colors.white : Colors.blue[900])
        : (isDarkMode ? Colors.white : Colors.grey[900]);

    final timestampColor = isCurrentUser
        ? (isDarkMode ? Colors.blue[300] : Colors.blue[600])
        : (isDarkMode ? Colors.grey[400] : Colors.grey[600]);

    final avatarUrl = comment.author?.avatarUrl;
    final authorName = comment.author?.fullName ?? 'Pengguna';
    final level = comment.author?.level ?? 1;

    Widget buildAvatarWidget() {
      final avatar = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: avatarUrl != null && avatarUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(avatarUrl),
                  fit: BoxFit.cover,
                )
              : null,
          color: avatarUrl == null || avatarUrl.isEmpty
              ? Colors.blueGrey[100]
              : null,
        ),
        child: avatarUrl == null || avatarUrl.isEmpty
            ? Center(
                child: Text(
                  authorName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Colors.blueGrey[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              )
            : null,
      );

      return onAvatarTap != null
          ? GestureDetector(
              onTap: onAvatarTap,
              child: avatar,
            )
          : avatar;
    }

    Widget buildLevelBadge() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Lv.$level',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    Widget buildPopupMenu() {
      return PopupMenuButton<String>(
        icon: Icon(Icons.more_horiz, size: 18, color: timestampColor),
        onSelected: (value) {
          if (value == 'delete' && onDelete != null) {
            onDelete!();
          } else if (value == 'report' && onReport != null) {
            onReport!();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.flag_outlined, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Laporkan', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          if (onDelete != null)
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Hapus', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
        ],
      );
    }

    return Container(
      margin: EdgeInsets.only(
        left: isCurrentUser ? 48 : 12,
        right: isCurrentUser ? 12 : 48,
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            Column(
              children: [
                buildAvatarWidget(),
                if (!isReply) ...[
                  const SizedBox(height: 4),
                  buildLevelBadge(),
                ],
              ],
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: isCurrentUser
                          ? const Radius.circular(16)
                          : showTail
                              ? const Radius.circular(4)
                              : const Radius.circular(16),
                      topRight: isCurrentUser
                          ? showTail
                              ? const Radius.circular(4)
                              : const Radius.circular(16)
                          : const Radius.circular(16),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isCurrentUser && !isReply) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    authorName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  buildLevelBadge(),
                                ],
                              ),
                            ),
                            buildPopupMenu(),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        comment.content,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(comment.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: timestampColor,
                            ),
                          ),
                          Row(
                            children: [
                              if (onLike != null)
                                GestureDetector(
                                  onTap: onLike,
                                  child: Row(
                                    children: [
                                      Icon(
                                        comment.isLikedByUser == true
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: 14,
                                        color: comment.isLikedByUser == true
                                            ? Colors.red
                                            : timestampColor,
                                      ),
                                      if (comment.likesCount > 0) ...[
                                        const SizedBox(width: 2),
                                        Text(
                                          comment.likesCount.toString(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: timestampColor,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              const SizedBox(width: 12),
                              if (onReply != null && !isReply)
                                GestureDetector(
                                  onTap: onReply,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.reply,
                                        size: 14,
                                        color: timestampColor,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Balas',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: timestampColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (showTail)
                  Positioned(
                    bottom: 0,
                    left: isCurrentUser ? null : -8,
                    right: isCurrentUser ? -8 : null,
                    child: CustomPaint(
                      painter: ChatBubbleTailPainter(
                        color: bubbleColor!,
                        isCurrentUser: isCurrentUser,
                      ),
                      size: const Size(16, 12),
                    ),
                  ),
              ],
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            Column(
              children: [
                buildAvatarWidget(),
                const SizedBox(height: 4),
                buildLevelBadge(),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}j';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}h';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}

class ChatBubbleTailPainter extends CustomPainter {
  final Color color;
  final bool isCurrentUser;

  ChatBubbleTailPainter({
    required this.color,
    required this.isCurrentUser,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    if (isCurrentUser) {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, 0);
      path.close();
    } else {
      path.moveTo(size.width, size.height);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width, 0);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ChatBubbleTailPainter oldDelegate) =>
      color != oldDelegate.color || isCurrentUser != oldDelegate.isCurrentUser;
}