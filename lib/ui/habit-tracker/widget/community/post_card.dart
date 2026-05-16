import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:purewill/domain/model/community_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:purewill/data/services/community/image_saver_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PostCard extends StatefulWidget {
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
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isImageLoading = false;

  void _showImageFullscreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ImageFullscreenDialog(
        imageUrl: widget.post.imageUrl!,
        post: widget.post,
        onSaveImage: () => _saveImage(context),
        onLikeTapped: widget.onLikeToggled,
        onCommentTapped: () {
          Navigator.pop(context); // Tutup dialog gambar
          widget.onCommentTapped(); // Buka komentar
        },
        onShareTapped: widget.onShareTapped,
      ),
    );
  }

  Future<void> _saveImage(BuildContext context) async {
    if (widget.post.imageUrl == null) return;

    final imageSaver = ImageSaverService();
    
    // Tampilkan indikator loading
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
      final success = await imageSaver.saveImageToGallery(widget.post.imageUrl!);
      
      Navigator.pop(context); // Tutup loading dialog
      
      if (success) {
        // Tampilkan snackbar sukses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gambar berhasil disimpan ke galeri'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Panggil callback jika ada
        widget.onImageSaved?.call();
      } else {
        // Tampilkan error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Izin Diperlukan'),
            content: const Text('Aplikasi membutuhkan izin akses ke galeri untuk menyimpan gambar.'),
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
      Navigator.pop(context); // Tutup loading dialog
      
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
                widget.post.imageUrl!,
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
          
          // Overlay untuk indikator bisa diklik (hanya muncul saat tidak loading)
          if (!_isImageLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: widget.post.author?.avatarUrl != null
                      ? NetworkImage(widget.post.author!.avatarUrl!)
                      : null,
                  child: widget.post.author?.avatarUrl == null
                      ? Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.grey[600],
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                
                // Author info dan timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.author?.fullName ?? 'Anonymous',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            timeago.format(widget.post.createdAt, locale: 'en'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (widget.post.isEdited) ...[
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
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: widget.onMoreTapped,
                  color: Colors.grey[600],
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Post content
            if (widget.post.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  widget.post.content,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            
            // Image
            if (widget.post.hasImage) _buildImage(),
            
            // Shared indicator
            if (widget.post.isShared)
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
            
            // Stats dan actions
            const SizedBox(height: 16),
            _buildStats(),
            const SizedBox(height: 12),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        if (widget.post.likesCount > 0) ...[
          Icon(
            Icons.favorite,
            size: 16,
            color: Colors.red[400],
          ),
          const SizedBox(width: 4),
          Text(
            _formatNumber(widget.post.likesCount),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16),
        ],
        if (widget.post.commentsCount > 0) ...[
          Icon(
            Icons.comment,
            size: 16,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 4),
          Text(
            _formatNumber(widget.post.commentsCount),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16),
        ],
        if (widget.post.shareCount > 0) ...[
          Icon(
            Icons.share,
            size: 16,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 4),
          Text(
            _formatNumber(widget.post.shareCount),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
        const Spacer(),
        Text(
          '${widget.post.viewCount} views',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Like button
          Expanded(
            child: TextButton.icon(
              onPressed: widget.onLikeToggled,
              icon: Icon(
                widget.post.isLikedByUser == true
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: widget.post.isLikedByUser == true ? Colors.red : Colors.grey[600],
                size: 20,
              ),
              label: Text(
                'Like',
                style: TextStyle(
                  color: widget.post.isLikedByUser == true ? Colors.red : Colors.grey[600],
                ),
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
          // Photo View untuk zoom dan pan
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

          // App Bar Custom (top) dengan tombol close dan save
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(
              height: 56,
              color: Colors.black.withOpacity(0.5),
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

          // Bottom bar untuk tombol aksi (SINGLE BARIS seperti di post card)
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
                    Colors.black.withOpacity(0.9),
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Like button
                  Expanded(
                    child: _buildBottomBarButton(
                      icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                      label: 'Like',
                      count: _likesCount,
                      isActive: _isLiked,
                      onTap: () {
                        widget.onLikeTapped?.call();
                        setState(() {
                          _isLiked = !_isLiked;
                          _likesCount = _isLiked 
                              ? _likesCount + 1 
                              : _likesCount - 1;
                        });
                      },
                    ),
                  ),
                  
                  // Comment button
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
                  
                  // Share button
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
                  
                  // Save button
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

          // Loading overlay untuk save
          if (_isSaving)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
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

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Future<void> _saveImage() async {
    setState(() => _isSaving = true);
    
    try {
      final imageSaver = ImageSaverService();
      final success = await imageSaver.saveImageToGallery(widget.imageUrl);
      
      if (mounted) {
        if (success) {
          // Panggil callback untuk notifikasi di parent
          widget.onSaveImage();
          
          // Tampilkan snackbar sukses
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

  Future<void> _shareImage() async {
    try {
      await Share.share(
        widget.imageUrl,
        subject: 'Gambar dari PureWill Community - ${widget.post.author?.fullName}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membagikan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyImageLink() async {
    await Clipboard.setData(ClipboardData(text: widget.imageUrl));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link gambar disalin ke clipboard'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}