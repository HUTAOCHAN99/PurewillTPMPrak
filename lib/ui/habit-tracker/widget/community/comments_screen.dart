// lib/ui/habit-tracker/widget/community/comments_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/ui/habit-tracker/screen/user_profile_screen.dart';
import 'package:purewill/ui/habit-tracker/widget/community/chat_bubble_comment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purewill/data/services/community/comment_service.dart';
import 'package:purewill/domain/model/community_model.dart';

// Provider untuk comment service
final commentServiceProvider = Provider((ref) => CommentService());

// Provider untuk komentar post
final postCommentsProvider = StreamProvider.autoDispose
    .family<List<CommunityComment>, String>((ref, postId) async* {
  final commentService = ref.read(commentServiceProvider);
  final user = Supabase.instance.client.auth.currentUser;

  if (user == null) {
    yield [];
    return;
  }

  try {
    // Get initial comments
    final initialComments =
        await commentService.getPostComments(postId, userId: user.id);

    // Return as stream
    yield initialComments;
  } catch (e) {
    yield [];
  }
});

class CommentsScreen extends ConsumerStatefulWidget {
  final String postId;
  final String communityName;

  const CommentsScreen({
    super.key,
    required this.postId,
    required this.communityName,
  });

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  late final CommentService _commentService;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _commentFocusNode = FocusNode();
  String? _currentUserId;
  String? _replyingToCommentId;
  String? _replyingToUserName;
  bool _isLoading = true;
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _commentService = ref.read(commentServiceProvider);
    _getCurrentUser();

    // Auto focus ke text field setelah sedikit delay
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _commentFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _getCurrentUser() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.id;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _postComment() async {
    if (_currentUserId == null) {
      _showError('Silakan login untuk mengomentari');
      return;
    }

    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isPostingComment = true);

    try {
      await _commentService.addComment(
        postId: widget.postId,
        userId: _currentUserId!,
        content: content,
        parentCommentId: _replyingToCommentId,
      );

      // Clear fields
      _commentController.clear();
      _cancelReply();

      // Refresh comments
      ref.invalidate(postCommentsProvider(widget.postId));

      // Scroll ke bawah
      _scrollToBottom();
    } catch (e) {
      _showError('Gagal mengirim komentar: ${e.toString()}');
    } finally {
      setState(() => _isPostingComment = false);
    }
  }

  void _replyToComment(CommunityComment comment) {
    setState(() {
      _replyingToCommentId = comment.id;
      _replyingToUserName = comment.author?.fullName;
    });

    _commentFocusNode.requestFocus();
    _scrollToBottom();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
  }

  Future<void> _toggleLikeComment(CommunityComment comment) async {
    if (_currentUserId == null) {
      _showError('Silakan login untuk memberikan like');
      return;
    }

    try {
      await _commentService.toggleLikeComment(comment.id, _currentUserId!);
      ref.invalidate(postCommentsProvider(widget.postId));
    } catch (e) {
      _showError('Gagal memberikan like: ${e.toString()}');
    }
  }

  Future<void> _deleteComment(CommunityComment comment) async {
    if (_currentUserId == null || comment.authorId != _currentUserId) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Komentar'),
        content: const Text('Apakah Anda yakin ingin menghapus komentar ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Implement soft delete
      _showInfo('Fitur hapus komentar akan segera hadir');
    }
  }

  void _showUserProfile(CommunityComment comment) {
    if (comment.author == null) {
      _showError('Tidak dapat membuka profil pengguna ini');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: comment.authorId,
          userName: comment.author?.fullName,
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildReplyIndicator() {
    if (_replyingToUserName == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue[50],
      child: Row(
        children: [
          const Icon(Icons.reply, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Membalas $_replyingToUserName',
              style: TextStyle(color: Colors.blue[800], fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: _cancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Reply indicator
          _buildReplyIndicator(),

          // Input field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: _replyingToUserName != null
                        ? 'Balas $_replyingToUserName...'
                        : 'Tulis komentar...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _postComment(),
                ),
              ),
              const SizedBox(width: 8),
              _isPostingComment
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      onPressed: _postComment,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommunityComment comment, bool hasReplies) {
    final isCurrentUser = comment.authorId == _currentUserId;
    final replies = comment.replies ?? [];

    return Column(
      children: [
        // Komentar utama
        ChatBubble(
          comment: comment,
          isCurrentUser: isCurrentUser,
          onLike: () => _toggleLikeComment(comment),
          onReply: () => _replyToComment(comment),
          onDelete: comment.authorId == _currentUserId
              ? () => _deleteComment(comment)
              : null,
          onAvatarTap: () => _showUserProfile(comment),
          showTail: true,
          isReply: false,
        ),

        // Replies jika ada
        if (hasReplies && replies.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: isCurrentUser ? 0 : 48),
            child: Column(
              children: replies.map((reply) {
                final isReplyCurrentUser = reply.authorId == _currentUserId;
                return ChatBubble(
                  comment: reply,
                  isCurrentUser: isReplyCurrentUser,
                  onLike: () => _toggleLikeComment(reply),
                  onReply: () => _replyToComment(reply),
                  onDelete: reply.authorId == _currentUserId
                      ? () => _deleteComment(reply)
                      : null,
                  onAvatarTap: () => _showUserProfile(reply),
                  showTail: false, // Replies tidak punya tail
                  isReply: true,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Belum ada komentar',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Jadilah yang pertama mengomentari',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Memuat komentar...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat komentar',
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              error.length > 100 ? '${error.substring(0, 100)}...' : error,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(postCommentsProvider(widget.postId)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.login, size: 60, color: Colors.blue),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Silakan login untuk melihat dan menulis komentar',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text('Login Sekarang'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Komentar'),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        ),
        body: _buildLoadingState(),
      );
    }

    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Komentar'),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        ),
        body: _buildNotLoggedInState(),
      );
    }

    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Komentar'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(postCommentsProvider(widget.postId));
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final hasReplies = comment.replies?.isNotEmpty ?? false;
                      return _buildCommentItem(comment, hasReplies);
                    },
                  ),
                );
              },
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error.toString()),
            ),
          ),

          // Input komentar
          _buildCommentInput(),
        ],
      ),
    );
  }
}