// lib/ui/habit-tracker/screen/community_detail_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/ui/habit-tracker/screen/post_search_delegate.dart';
import 'package:purewill/ui/habit-tracker/widget/community/user_profile_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:purewill/data/services/community/post_service.dart';
import 'package:purewill/data/services/community/community_service.dart';
import 'package:purewill/domain/model/community_model.dart';
import 'package:purewill/ui/habit-tracker/widget/community/post_card.dart';
import 'package:purewill/ui/habit-tracker/widget/community/create_post_dialog.dart';
import 'package:purewill/ui/habit-tracker/widget/community/comments_screen.dart';
import 'package:purewill/ui/habit-tracker/widget/community/share_post_dialog.dart';

// Provider untuk current user
final currentUserProvider = Provider<User?>((ref) {
  final supabase = Supabase.instance.client;
  return supabase.auth.currentUser;
});

// Provider untuk post service
final postServiceProvider = Provider((ref) => PostService());

// Provider untuk community service
final communityServiceProvider = Provider((ref) => CommunityService());

// Provider untuk post dalam komunitas
final communityPostsProvider = StreamProvider.autoDispose
    .family<List<CommunityPost>, String>((ref, communityId) async* {
      final postService = ref.read(postServiceProvider);
      final user = ref.watch(currentUserProvider);

      if (user == null) {
        yield [];
        return;
      }

      try {
        yield* postService.streamCommunityPosts(communityId, user.id);
      } catch (e) {
        yield [];
      }
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
      try {
        // Coba ambil profile dan friend count
        final supabase = Supabase.instance.client;

        // Get profile
        final profileResponse = await supabase
            .from('profiles')
            .select('user_id, full_name, avatar_url, level, current_xp')
            .eq('user_id', userId)
            .maybeSingle();

        Profile? profile;
        if (profileResponse != null) {
          profile = Profile.fromJson(profileResponse);
        }

        // Get friend count (hanya count saja untuk performa)
        final friendCountResponse = await supabase
            .from('friendships')
            .select()
            .or('(sender_id.eq.$userId,receiver_id.eq.$userId)')
            .eq('status', 'accepted');

        final friendCount = friendCountResponse.length;

        return {'profile': profile, 'friendCount': friendCount};
      } catch (e) {
        return {'profile': null, 'friendCount': 0};
      }
    });

class CommunityDetailScreen extends ConsumerStatefulWidget {
  final String communityId;
  final String communityName;

  const CommunityDetailScreen({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  ConsumerState<CommunityDetailScreen> createState() =>
      _CommunityDetailScreenState();
}

class CommunitySidebar extends StatelessWidget {
  final String communityId;
  final String communityName;
  final String? userId;
  final bool isAdmin;
  final VoidCallback onInviteUsers;
  final VoidCallback onViewMembers;
  final VoidCallback onReportCommunity;
  final VoidCallback onLeaveCommunity;
  final VoidCallback onDeleteCommunity;
  final VoidCallback onOpenProfile;

  const CommunitySidebar({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.userId,
    required this.isAdmin,
    required this.onInviteUsers,
    required this.onViewMembers,
    required this.onReportCommunity,
    required this.onLeaveCommunity,
    required this.onDeleteCommunity,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.people,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          communityName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Komunitas Aktif',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  // Profile
                  if (userId != null)
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Profil Saya'),
                      onTap: () {
                        Navigator.pop(context);
                        onOpenProfile();
                      },
                    ),

                  // Undang Pengguna
                  ListTile(
                    leading: const Icon(Icons.person_add_outlined),
                    title: const Text('Undang Pengguna'),
                    onTap: () {
                      Navigator.pop(context);
                      onInviteUsers();
                    },
                  ),

                  // Anggota
                  ListTile(
                    leading: const Icon(Icons.group_outlined),
                    title: const Text('Anggota Komunitas'),
                    onTap: () {
                      Navigator.pop(context);
                      onViewMembers();
                    },
                  ),

                  // Laporkan Komunitas
                  ListTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text('Laporkan Komunitas'),
                    onTap: () {
                      Navigator.pop(context);
                      onReportCommunity();
                    },
                  ),

                  // Keluar dari Komunitas
                  ListTile(
                    leading: const Icon(
                      Icons.exit_to_app_outlined,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Keluar dari Komunitas',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onLeaveCommunity();
                    },
                  ),

                  // Hapus Komunitas (hanya admin)
                  if (isAdmin)
                    ListTile(
                      leading: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      title: const Text(
                        'Hapus Komunitas',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onDeleteCommunity();
                      },
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Tombol Close
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityDetailScreenState extends ConsumerState<CommunityDetailScreen> {
  late final PostService _postService;
  late final CommunityService _communityService;

  bool _isJoining = false;
  bool _isLoadingUser = true;
  String? _currentUserId;

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showFabNotifier = ValueNotifier<bool>(true);
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  Timer? _scrollDebounceTimer;

  @override
  void initState() {
    super.initState();
    _postService = ref.read(postServiceProvider);
    _communityService = ref.read(communityServiceProvider);

    _scrollController.addListener(_handleScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUser();
      _updateLastSeen();
    });
  }

  void _handleScroll() {
    if (_scrollDebounceTimer?.isActive ?? false) {
      _scrollDebounceTimer?.cancel();
    }

    _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (!_showFabNotifier.value) _showFabNotifier.value = true;
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_showFabNotifier.value) _showFabNotifier.value = false;
      }
    });
  }

  Future<void> _updateLastSeen() async {
    if (_currentUserId != null) {
      await _communityService.updateLastSeen(
        _currentUserId!,
        widget.communityId,
      );
    }
  }

  void _openSidebar() {
    final user = Supabase.instance.client.auth.currentUser;
    final isAdmin = false; // Tambahkan logika cek admin jika diperlukan

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommunitySidebar(
        communityId: widget.communityId,
        communityName: widget.communityName,
        userId: _currentUserId,
        isAdmin: isAdmin,
        onInviteUsers: _showInviteUsers,
        onViewMembers: _showMembers,
        onReportCommunity: _reportCommunity,
        onLeaveCommunity: _leaveCommunity,
        onDeleteCommunity: _deleteCommunity,
        onOpenProfile: _openUserProfile,
      ),
    );
  }

  void _onImageSaved() {
    _showSuccess('Gambar berhasil disimpan ke galeri!');
  }

  void _showInviteUsers() {
    if (_currentUserId == null) {
      _showError('Silakan login untuk mengundang pengguna');
      return;
    }

    _showInfo('Fitur undang pengguna akan segera hadir');
  }

  void _showMembers() {
    _showInfo('Fitur lihat anggota akan segera hadir');
  }

  Future<void> _deleteCommunity() async {
    if (_currentUserId == null) {
      _showError('Silakan login untuk mengakses fitur ini');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Komunitas'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus komunitas ini? '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
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
      // Implement delete community logic
      _showInfo('Fitur hapus komunitas akan segera hadir');
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _showFabNotifier.dispose();
    _scrollDebounceTimer?.cancel();
    super.dispose();
  }

  void _checkUser() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.id;
        _isLoadingUser = false;
      });
    } else {
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  void _showCreatePostDialog() {
    if (_currentUserId == null) {
      _showError('Silakan login untuk membuat post');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => CreatePostDialog(
        communityId: widget.communityId,
        userId: _currentUserId!,
        onPostCreated: () {
          ref.invalidate(communityPostsProvider(widget.communityId));
        },
      ),
    );
  }

  void _showComments(CommunityPost post) {
    if (_currentUserId == null) {
      _showError('Silakan login untuk melihat komentar');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(
          postId: post.id,
          communityName: widget.communityName,
        ),
      ),
    );
  }

  Future<void> _toggleLikePost(CommunityPost post) async {
    if (_currentUserId == null) {
      _showError('Silakan login untuk memberikan like');
      return;
    }

    try {
      await _postService.toggleLikePost(post.id, _currentUserId!);
    } catch (e) {
      _showError('Error: ${e.toString()}');
    }
  }

  void _showPostOptions(CommunityPost post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (post.authorId == _currentUserId) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Post'),
                onTap: () {
                  Navigator.pop(context);
                  _editPost(post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Hapus Post',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost(post);
                },
              ),
              const Divider(),
            ],
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Laporkan Post'),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Salin Link'),
              onTap: () {
                Navigator.pop(context);
                _copyPostLink(post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Bagikan ke Komunitas Lain'),
              onTap: () {
                Navigator.pop(context);
                _shareToOtherCommunity(post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.save_alt_outlined),
              title: const Text('Simpan Gambar'),
              onTap: () {
                Navigator.pop(context);
                _showInfo('Fitur simpan gambar akan segera hadir');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareToOtherCommunity(CommunityPost post) {
    if (_currentUserId == null) {
      _showError('Silakan login untuk membagikan post');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SharePostDialog(
        originalPost: post,
        userId: _currentUserId!,
        onShared: () {
          ref.invalidate(communityPostsProvider(widget.communityId));
        },
      ),
    );
  }

  Future<void> _deletePost(CommunityPost post) async {
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
      try {
        await _postService.deletePost(post.id);
        _showSuccess('Post berhasil dihapus');
      } catch (e) {
        _showError('Error: ${e.toString()}');
      }
    }
  }

  void _showReportDialog(CommunityPost post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Laporkan Post'),
        content: const Text(
          'Terima kasih telah melaporkan. Tim kami akan meninjau laporan ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _editPost(CommunityPost post) async {
    if (_currentUserId == null) return;

    final result = await showDialog(
      context: context,
      builder: (context) => CreatePostDialog(
        communityId: widget.communityId,
        userId: _currentUserId!,
        initialContent: post.content,
        initialImageUrl: post.imageUrl,
        isEditing: true,
        postId: post.id,
        onPostCreated: () {
          ref.invalidate(communityPostsProvider(widget.communityId));
        },
      ),
    );

    if (result == true) {
      // Stream akan otomatis update
    }
  }

  void _copyPostLink(CommunityPost post) {
    Clipboard.setData(
      ClipboardData(text: 'https://app.example.com/post/${post.id}'),
    );
    _showInfo('Link disalin ke clipboard');
  }

  Future<void> _joinCommunity() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      _showError('Silakan login untuk bergabung dengan komunitas');
      return;
    }

    setState(() => _isJoining = true);
    try {
      final success = await _communityService.joinCommunity(
        widget.communityId,
        _currentUserId!,
      );

      if (success) {
        ref.invalidate(communityDetailsProvider(widget.communityId));
        _showSuccess('Berhasil bergabung dengan komunitas!');
      } else {
        _showError('Gagal bergabung. Mungkin Anda sudah menjadi anggota.');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      setState(() => _isJoining = false);
    }
  }

  Future<void> _leaveCommunity() async {
    if (_currentUserId == null) {
      _showError('Silakan login untuk mengakses fitur ini');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Komunitas'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari komunitas ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await _communityService.leaveCommunity(
          widget.communityId,
          _currentUserId!,
        );

        if (success) {
          ref.invalidate(communityDetailsProvider(widget.communityId));
          _showSuccess('Berhasil keluar dari komunitas');
        }
      } catch (e) {
        _showError('Error: ${e.toString()}');
      }
    }
  }

  void _shareCommunity() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bagikan Komunitas'),
        content: const Text('Bagikan link komunitas ini ke teman-teman Anda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(
                  text:
                      'https://app.example.com/community/${widget.communityId}',
                ),
              );
              _showInfo('Link komunitas disalin ke clipboard');
              Navigator.pop(context);
            },
            child: const Text('Salin Link'),
          ),
        ],
      ),
    );
  }

  void _reportCommunity() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Laporkan Komunitas'),
        content: const Text(
          'Terima kasih telah melaporkan. Tim kami akan meninjau laporan ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ============ SEARCH HANDLERS ============

  Future<void> _handleSearchPostLike(CommunityPost post) async {
    if (_currentUserId == null) {
      _showError('Silakan login untuk memberikan like');
      return;
    }

    try {
      await _postService.toggleLikePost(post.id, _currentUserId!);
    } catch (e) {
      _showError('Error: ${e.toString()}');
    }
  }

  void _handleSearchPostComment(CommunityPost post) {
    if (_currentUserId == null) {
      _showError('Silakan login untuk melihat komentar');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(
          postId: post.id,
          communityName: widget.communityName,
        ),
      ),
    );
  }

  void _handleSearchPostShare(CommunityPost post) {
    if (_currentUserId == null) {
      _showError('Silakan login untuk membagikan post');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SharePostDialog(
        originalPost: post,
        userId: _currentUserId!,
        onShared: () {
          ref.invalidate(communityPostsProvider(widget.communityId));
        },
      ),
    );
  }

  void _handleSearchPostMore(CommunityPost post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (post.authorId == _currentUserId) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Post'),
                onTap: () {
                  Navigator.pop(context);
                  _editPost(post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Hapus Post',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost(post);
                },
              ),
              const Divider(),
            ],
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Laporkan Post'),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Salin Link'),
              onTap: () {
                Navigator.pop(context);
                _copyPostLink(post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Bagikan ke Komunitas Lain'),
              onTap: () {
                Navigator.pop(context);
                _handleSearchPostShare(post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.save_alt_outlined),
              title: const Text('Simpan Gambar'),
              onTap: () {
                Navigator.pop(context);
                _showInfo('Fitur simpan gambar akan segera hadir');
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============ PROFILE HANDLERS ============

  void _openUserProfile() {
    if (_currentUserId == null) {
      _showError('Silakan login untuk melihat profil');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => UserProfileDialog(userId: _currentUserId!),
    );
  }

  // ============ UTILITY METHODS ============

  void _showError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.fixed,
          ),
        );
      } catch (e) {
        // Ignore error
      }
    });
  }

  void _showSuccess(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.fixed,
          ),
        );
      } catch (e) {
        // Ignore error
      }
    });
  }

  void _showInfo(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.fixed,
          ),
        );
      } catch (e) {
        // Ignore error
      }
    });
  }

  Widget _buildJoinButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        onPressed: _isJoining ? null : _joinCommunity,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isJoining
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Bergabung dengan Komunitas',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
      ),
    );
  }

  Widget _buildCommunityHeader(Community community) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(
                    int.parse(community.color!.replaceAll('#', '0xff')),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconData(community.iconName ?? 'people'),
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (community.description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          community.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Community stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.people,
                value: community.memberCount.toString(),
                label: 'Anggota',
              ),
              _buildStatItem(icon: Icons.forum, value: 'Post', label: 'Aktif'),
              _buildStatItem(
                icon: Icons.today,
                value: 'Hari ini',
                label: 'Aktifitas',
              ),
            ],
          ),

          if (!community.isJoined) const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, size: 20, color: Colors.grey[700]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'sports':
        return Icons.sports;
      case 'music':
        return Icons.music_note;
      case 'book':
        return Icons.menu_book;
      case 'code':
        return Icons.code;
      case 'fitness':
        return Icons.fitness_center;
      case 'food':
        return Icons.restaurant;
      case 'travel':
        return Icons.travel_explore;
      case 'business':
        return Icons.business;
      case 'health':
        return Icons.health_and_safety;
      case 'education':
        return Icons.school;
      default:
        return Icons.people;
    }
  }

  Widget _buildEmptyState(bool isMember) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            isMember ? 'Belum ada post' : 'Belum ada aktivitas',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isMember
                ? 'Jadilah yang pertama membuat post!'
                : 'Bergabunglah untuk melihat dan membuat post',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (isMember && _currentUserId != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showCreatePostDialog,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Buat Post Pertama'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingUser() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: Text(widget.communityName)),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat komunitas...'),
          ],
        ),
      ),
    );
  }

  Widget _buildNotLoggedInScreen() {
    return Scaffold(
      appBar: AppBar(title: Text(widget.communityName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Silakan login untuk mengakses komunitas',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Nikmati berbagi pengalaman dan berinteraksi dengan anggota komunitas ${widget.communityName}',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
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
                  minimumSize: const Size(200, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Login Sekarang'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostsContent(
    AsyncValue<List<CommunityPost>> postsAsync,
    Community community,
    String currentUserId,
  ) {
    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return _buildEmptyState(community.isJoined);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(communityPostsProvider(widget.communityId));
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Column(
                children: [
                  PostCard(
                    key: ValueKey(post.id),
                    post: post,
                    userId: currentUserId,
                    onLikeToggled: () => _toggleLikePost(post),
                    onCommentTapped: () => _showComments(post),
                    onShareTapped: () => _shareToOtherCommunity(post),
                    onMoreTapped: () => _showPostOptions(post),
                    onImageSaved: _onImageSaved,
                  ),
                  if (index < posts.length - 1) const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat post...'),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat post',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.invalidate(communityPostsProvider(widget.communityId)),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Gagal memuat detail komunitas',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error.length > 100 ? '${error.substring(0, 100)}...' : error,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.invalidate(communityDetailsProvider(widget.communityId)),
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

  List<Widget> _buildAppBarActions(AsyncValue<Community> communityAsync) {
    return [
      IconButton(
        icon: const Icon(Icons.menu),
        onPressed: _openSidebar,
        tooltip: 'Menu Komunitas',
      ),
    ];
  }

  void _showInviteFriendsDialog(Community community) {
    if (_currentUserId == null) {
      _showError('Silakan login untuk mengundang teman');
      return;
    }

    _showInfo('Fitur undang teman akan segera hadir');
  }

  Widget _buildFloatingActionButton(AsyncValue<Community> communityAsync) {
    return ValueListenableBuilder<bool>(
      valueListenable: _showFabNotifier,
      builder: (context, showFab, child) {
        return AnimatedOpacity(
          opacity: showFab ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedSlide(
            offset: showFab ? Offset.zero : const Offset(0, 2),
            duration: const Duration(milliseconds: 200),
            child: Builder(
              builder: (context) {
                return communityAsync.when(
                  data: (community) {
                    if (community.isJoined && _currentUserId != null) {
                      return FloatingActionButton.extended(
                        onPressed: _showCreatePostDialog,
                        icon: const Icon(Icons.add, size: 24),
                        label: const Text(
                          'Buat Post',
                          style: TextStyle(fontSize: 16),
                        ),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return _buildLoadingUser();
    }

    if (_currentUserId == null) {
      return _buildNotLoggedInScreen();
    }

    final communityAsync = ref.watch(
      communityDetailsProvider(widget.communityId),
    );
    final postsAsync = ref.watch(communityPostsProvider(widget.communityId));

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(widget.communityName),
          actions: [
            // Search Icon
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: PostSearchDelegate(
                    communityId: widget.communityId,
                    currentUserId: _currentUserId,
                    onLikeTapped: _handleSearchPostLike,
                    onCommentTapped: _handleSearchPostComment,
                    onShareTapped: _handleSearchPostShare,
                    onMoreTapped: _handleSearchPostMore,
                  ),
                );
              },
              tooltip: 'Cari postingan',
            ),

            // Community menu dan profile button
            ..._buildAppBarActions(communityAsync),
          ],
        ),
        body: Column(
          children: [
            // Unread posts badge
            FutureBuilder<int>(
              future: _communityService.getUnreadPostsCount(
                _currentUserId!,
                widget.communityId,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data! > 0) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.blue[50],
                    child: Row(
                      children: [
                        Icon(Icons.new_releases, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          '${snapshot.data} post baru sejak kunjungan terakhir',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            // Scroll ke atas untuk lihat post baru
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Text(
                            'Lihat',
                            style: TextStyle(color: Colors.blue, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            Expanded(
              child: communityAsync.when(
                data: (community) {
                  return Column(
                    children: [
                      _buildCommunityHeader(community),
                      if (!community.isJoined) _buildJoinButton(),
                      Expanded(
                        child: _buildPostsContent(
                          postsAsync,
                          community,
                          _currentUserId!,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Memuat komunitas...'),
                    ],
                  ),
                ),
                error: (error, stack) => _buildError(error.toString()),
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(communityAsync),
      ),
    );
  }
}
