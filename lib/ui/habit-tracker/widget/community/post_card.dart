// lib/ui/habit-tracker/widget/community/post_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:purewill/domain/model/community_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:purewill/data/services/community/image_saver_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:purewill/ui/habit-tracker/widget/community/community_provider.dart';
import 'package:purewill/ui/habit-tracker/widget/community/report_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostCard extends ConsumerStatefulWidget {
  final CommunityPost post;
  final String userId;
  final VoidCallback onLikeToggled;
  final VoidCallback onCommentTapped;
  final VoidCallback onShareTapped;
  final VoidCallback onMoreTapped;
  final VoidCallback? onImageSaved;

  const PostCard({
    super.key,
    required this.post,
    required this.userId,
    required this.onLikeToggled,
    required this.onCommentTapped,
    required this.onShareTapped,
    required this.onMoreTapped,
    this.onImageSaved,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _isImageLoading = false;
  late CommunityPost _currentPost;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
  }

  void _showReportDialog() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login untuk melaporkan')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        reportedUserId: widget.post.authorId,
        postId: widget.post.id,
        reporterId: user.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final likeStatusAsync = ref.watch(postLikeStatusProvider(widget.post.id));
    
    likeStatusAsync.whenData((isLiked) {
      if (mounted && _currentPost.isLikedByUser != isLiked) {
        setState(() {
          final newLikeCount = isLiked 
              ? _currentPost.likesCount + 1 
              : _currentPost.likesCount - 1;
          _currentPost = _currentPost.copyWith(
            isLikedByUser: isLiked,
            likesCount: newLikeCount.clamp(0, double.infinity).toInt(),
          );
        });
      }
    });

    final postsStreamAsync = ref.watch(communityPostsStreamProvider(widget.post.communityId));
    
    postsStreamAsync.whenData((posts) {
      final updatedPost = posts.firstWhere(
        (p) => p.id == widget.post.id,
        orElse: () => _currentPost,
      );
      if (mounted && 
          (_currentPost.likesCount != updatedPost.likesCount ||
           _currentPost.isLikedByUser != updatedPost.isLikedByUser)) {
        setState(() {
          _currentPost = updatedPost;
        });
      }
    });

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan author info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _showUserProfile(),
                  borderRadius: BorderRadius.circular(20),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _currentPost.author?.avatarUrl != null
                        ? NetworkImage(_currentPost.author!.avatarUrl!)
                        : null,
                    child: _currentPost.author?.avatarUrl == null
                        ? Icon(
                            Icons.person,
                            size: 20,
                            color: Colors.grey[600],
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => _showUserProfile(),
                        child: Text(
                          _currentPost.author?.fullName ?? 'Anonymous',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            timeago.format(_currentPost.createdAt, locale: 'en'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_currentPost.isEdited) ...[
                            const SizedBox(width: 4),
                            Text(
                              '• Edited',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // More options button
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  color: Colors.grey[600],
                  onSelected: (value) {
                    if (value == 'report') {
                      _showReportDialog();
                    } else if (value == 'edit' && _currentPost.authorId == widget.userId) {
                      widget.onMoreTapped();
                    } else if (value == 'delete' && _currentPost.authorId == widget.userId) {
                      _confirmDelete();
                    } else if (value == 'copy') {
                      _copyPostLink();
                    } else if (value == 'save_image' && _currentPost.hasImage) {
                      _saveImage(context);
                    }
                  },
                  itemBuilder: (context) => [
                    if (_currentPost.authorId == widget.userId) ...[
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 12),
                            Text('Edit Post'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Hapus Post', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                    ],
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Laporkan Post', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Salin Link'),
                        ],
                      ),
                    ),
                    if (_currentPost.hasImage)
                      const PopupMenuItem(
                        value: 'save_image',
                        child: Row(
                          children: [
                            Icon(Icons.download_outlined, size: 20),
                            SizedBox(width: 12),
                            Text('Simpan Gambar'),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Post content
            if (_currentPost.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _currentPost.content,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            
            // Image
            if (_currentPost.hasImage) _buildImage(),
            
            // Shared indicator
            if (_currentPost.isShared)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.repeat,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Shared from another community',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            _buildStats(),
            const SizedBox(height: 12),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Post'),
        content: const Text('Apakah Anda yakin ingin menghapus post ini?'),
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
      widget.onMoreTapped();
    }
  }

  void _copyPostLink() {
    // Implement copy link
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link disalin ke clipboard')),
    );
  }

  void _showUserProfile() {
    // TODO: Implement user profile navigation
  }

  Widget _buildImage() {
    return GestureDetector(
      onTap: () => _showImageFullscreen(context),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 300,
              ),
              child: Image.network(
                _currentPost.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _isImageLoading = false);
                      }
                    });
                    return child;
                  }
                  
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _isImageLoading = true);
                    }
                  });
                  
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _isImageLoading = false);
                    }
                  });
                  
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Overlay untuk indikator bisa diklik
          if (!_isImageLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: const Center(
                  child: Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        if (_currentPost.likesCount > 0) ...[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              Icons.favorite,
              size: 16,
              color: Colors.red[400],
              key: ValueKey(_currentPost.likesCount),
            ),
          ),
          const SizedBox(width: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
            child: Text(
              _formatNumber(_currentPost.likesCount),
              key: ValueKey(_currentPost.likesCount),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        if (_currentPost.commentsCount > 0) ...[
          Icon(
            Icons.comment,
            size: 16,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 4),
          Text(
            _formatNumber(_currentPost.commentsCount),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16),
        ],
        if (_currentPost.shareCount > 0) ...[
          Icon(
            Icons.share,
            size: 16,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 4),
          Text(
            _formatNumber(_currentPost.shareCount),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
        const Spacer(),
        Text(
          '${_currentPost.viewCount} views',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final isLiked = _currentPost.isLikedByUser ?? false;
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Like button with animation
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  final newIsLiked = !isLiked;
                  final newLikeCount = newIsLiked 
                      ? _currentPost.likesCount + 1 
                      : _currentPost.likesCount - 1;
                  _currentPost = _currentPost.copyWith(
                    isLikedByUser: newIsLiked,
                    likesCount: newLikeCount.clamp(0, double.infinity).toInt(),
                  );
                });
                widget.onLikeToggled();
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey(isLiked),
                  color: isLiked ? Colors.red : Colors.grey[600],
                  size: 20,
                ),
              ),
              label: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isLiked ? Colors.red : Colors.grey[600],
                  fontWeight: isLiked ? FontWeight.w600 : FontWeight.normal,
                ),
                child: const Text('Like'),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          // Comment button
          Expanded(
            child: TextButton.icon(
              onPressed: widget.onCommentTapped,
              icon: Icon(
                Icons.comment_outlined,
                color: Colors.grey[600],
                size: 20,
              ),
              label: const Text(
                'Comment',
                style: TextStyle(color: Colors.grey),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          // Share button
          Expanded(
            child: TextButton.icon(
              onPressed: widget.onShareTapped,
              icon: Icon(
                Icons.share_outlined,
                color: Colors.grey[600],
                size: 20,
              ),
              label: const Text(
                'Share',
                style: TextStyle(color: Colors.grey),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageFullscreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ImageFullscreenDialog(
        imageUrl: _currentPost.imageUrl!,
        post: _currentPost,
        onSaveImage: () => _saveImage(context),
        onLikeTapped: () {
          widget.onLikeToggled();
        },
        onCommentTapped: () {
          Navigator.pop(context);
          widget.onCommentTapped();
        },
        onShareTapped: widget.onShareTapped,
      ),
    );
  }

  Future<void> _saveImage(BuildContext context) async {
    if (_currentPost.imageUrl == null) return;

    final imageSaver = ImageSaverService();
    
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Menyimpan gambar...'),
          ],
        ),
      ),
    );

    try {
      final success = await imageSaver.saveImageToGallery(_currentPost.imageUrl!);
      
      if (!mounted) return;
      Navigator.pop(context);
      
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gambar berhasil disimpan ke galeri'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onImageSaved?.call();
      } else {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Izin Diperlukan'),
            content: const Text(
              'Aplikasi membutuhkan izin akses ke galeri untuk menyimpan gambar.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await openAppSettings();
                },
                child: const Text('Buka Pengaturan'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan gambar: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

// Dialog untuk fullscreen image
class ImageFullscreenDialog extends StatefulWidget {
  final String imageUrl;
  final CommunityPost post;
  final VoidCallback onSaveImage;
  final VoidCallback? onLikeTapped;
  final VoidCallback? onCommentTapped;
  final VoidCallback? onShareTapped;

  const ImageFullscreenDialog({
    super.key,
    required this.imageUrl,
    required this.post,
    required this.onSaveImage,
    this.onLikeTapped,
    this.onCommentTapped,
    this.onShareTapped,
  });

  @override
  State<ImageFullscreenDialog> createState() => _ImageFullscreenDialogState();
}

class _ImageFullscreenDialogState extends State<ImageFullscreenDialog> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLiked = false;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByUser == true;
    _likesCount = widget.post.likesCount;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PhotoView(
            imageProvider: NetworkImage(widget.imageUrl),
            loadingBuilder: (context, event) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _isLoading) {
                  setState(() => _isLoading = false);
                }
              });
              return Center(
                child: CircularProgressIndicator(
                  value: event == null || event.expectedTotalBytes == null
                      ? null
                      : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal memuat gambar',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              );
            },
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.0,
            initialScale: PhotoViewComputedScale.contained,
            heroAttributes: PhotoViewHeroAttributes(tag: widget.imageUrl),
          ),

          // App Bar Custom (top)
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(
              height: 56,
              color: Colors.black.withValues(alpha: 0.5),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: _isSaving
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Icon(Icons.download, color: Colors.white),
                    onPressed: _isSaving ? null : _saveImage,
                    tooltip: 'Simpan ke Galeri',
                  ),
                ],
              ),
            ),
          ),

          // Bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildBottomBarButton(
                      icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                      label: 'Like',
                      count: _likesCount,
                      isActive: _isLiked,
                      onTap: () {
                        setState(() {
                          _isLiked = !_isLiked;
                          _likesCount = _isLiked 
                              ? _likesCount + 1 
                              : _likesCount - 1;
                        });
                        widget.onLikeTapped?.call();
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildBottomBarButton(
                      icon: Icons.comment_outlined,
                      label: 'Comment',
                      count: widget.post.commentsCount,
                      onTap: () {
                        widget.onCommentTapped?.call();
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildBottomBarButton(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      count: widget.post.shareCount,
                      onTap: () {
                        widget.onShareTapped?.call();
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildBottomBarButton(
                      icon: Icons.download_outlined,
                      label: 'Save',
                      isLoading: _isSaving,
                      onTap: _isSaving ? null : _saveImage,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isSaving)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Menyimpan gambar...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBarButton({
    required IconData icon,
    required String label,
    int count = 0,
    bool isActive = false,
    bool isLoading = false,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(
                  icon,
                  color: isActive ? Colors.red : Colors.white,
                  size: 24,
                ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.red : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(height: 2),
                Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    color: isActive ? Colors.red : Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveImage() async {
    setState(() => _isSaving = true);
    
    try {
      final imageSaver = ImageSaverService();
      final success = await imageSaver.saveImageToGallery(widget.imageUrl);
      
      if (mounted) {
        if (success) {
          widget.onSaveImage();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gambar berhasil disimpan ke galeri!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          _showPermissionDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Izin Diperlukan'),
        content: const Text(
          'Aplikasi membutuhkan izin akses ke galeri untuk menyimpan gambar. '
          'Silakan berikan izin di pengaturan perangkat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }
}