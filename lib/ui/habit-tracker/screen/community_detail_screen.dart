// lib/ui/habit-tracker/screen/community_detail_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/data/services/community/report_service.dart';
import 'package:purewill/ui/habit-tracker/screen/post_search_delegate.dart';
import 'package:purewill/ui/habit-tracker/widget/community/user_profile_dialog.dart';
import 'package:purewill/ui/habit-tracker/widget/community/community_provider.dart' as community_provider;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:purewill/data/services/community/post_service.dart';
import 'package:purewill/data/services/community/community_service.dart';
import 'package:purewill/domain/model/community_model.dart';
import 'package:purewill/ui/habit-tracker/widget/community/post_card.dart';
import 'package:purewill/ui/habit-tracker/widget/community/create_post_dialog.dart';
import 'package:purewill/ui/habit-tracker/widget/community/comments_screen.dart';
import 'package:purewill/ui/habit-tracker/widget/community/share_post_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

// Provider untuk current user
final currentUserProvider = Provider<User?>((ref) {
  final supabase = Supabase.instance.client;
  return supabase.auth.currentUser;
});

// Provider untuk post service
final postServiceProvider = Provider((ref) => PostService());

// Provider untuk community service
final communityServiceProvider = Provider((ref) => CommunityService());

// Provider untuk cek akses komunitas
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

class _CommunityDetailScreenState extends ConsumerState<CommunityDetailScreen> {
  late final PostService _postService;
  late final CommunityService _communityService;

  bool _isJoining = false;
  bool _isLoadingUser = true;
  String? _currentUserId;

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showFabNotifier = ValueNotifier<bool>(true);

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

  void _openSidebar() {
    final isAdmin = false;

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
        onPostCreated: () {},
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
        onShared: () {},
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

    await showDialog(
      context: context,
      builder: (context) => CreatePostDialog(
        communityId: widget.communityId,
        userId: _currentUserId!,
        initialContent: post.content,
        initialImageUrl: post.imageUrl,
        isEditing: true,
        postId: post.id,
        onPostCreated: () {},
      ),
    );
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

  void _showError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.fixed,
        ),
      );
    });
  }

  void _showSuccess(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.fixed,
        ),
      );
    });
  }

  void _showInfo(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.fixed,
        ),
      );
    });
  }

  // ============ BANNED SCREEN ============

  Widget _buildBannedScreen(String? message) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.communityName),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.block,
                  size: 50,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Akses Diblokir',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  message ?? 'Akun Anda sedang di-ban. Anda tidak dapat mengakses fitur komunitas.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _openAppealEmail,
                icon: const Icon(Icons.email),
                label: const Text('Ajukan Banding via Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _showAppealInstructions,
                icon: const Icon(Icons.help_outline),
                label: const Text('Cara Mengajukan Banding'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAppealEmail() async {
    final user = Supabase.instance.client.auth.currentUser;
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'ahmadzhofir1808@gmail.com',
      query: encodeQueryParameters({
        'subject': 'BANDING AKUN - PureWill - ${user?.id ?? ''}',
        'body': '''
Halo Admin PureWill,

Saya ingin mengajukan banding atas ban akun saya.

Informasi akun:
- User ID: ${user?.id ?? 'Tidak diketahui'}
- Email: ${user?.email ?? 'Tidak diketahui'}

Alasan banding:
(Silakan jelaskan alasan Anda di sini dengan detail)

Saya berjanji akan mematuhi aturan komunitas PureWill ke depannya.

Terima kasih atas perhatiannya.

Hormat saya,
${user?.email ?? 'Pengguna PureWill'}
''',
      }),
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showError('Tidak dapat membuka email. Silakan buka Gmail manual dan kirim ke ahmadzhofir1808@gmail.com');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showAppealInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cara Mengajukan Banding'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Klik tombol "Ajukan Banding via Email"'),
            SizedBox(height: 8),
            Text('2. Email akan terbuka di aplikasi email Anda'),
            SizedBox(height: 8),
            Text('3. Isi alasan banding dengan jelas'),
            SizedBox(height: 8),
            Text('4. Kirim email ke ahmadzhofir1808@gmail.com'),
            SizedBox(height: 16),
            Text(
              'Admin akan memproses banding Anda dalam 1x24 jam.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openAppealEmail();
            },
            child: const Text('Buka Email'),
          ),
        ],
      ),
    );
  }

  // ============ NORMAL SCREEN ============

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
            color: Colors.black.withValues(alpha: 0.1),
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
            ref.invalidate(community_provider.communityPostsStreamProvider(widget.communityId));
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
              onPressed: () {
                ref.invalidate(community_provider.communityPostsStreamProvider(widget.communityId));
              },
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
    final canAccessAsync = ref.watch(canAccessCommunityProvider);
    final banMessageAsync = ref.watch(userBanMessageProvider);

    // Cek status ban terlebih dahulu
    return canAccessAsync.when(
      data: (canAccess) {
        if (!canAccess) {
          return banMessageAsync.when(
            data: (message) => _buildBannedScreen(message),
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => _buildBannedScreen('Akun Anda sedang di-ban. Hubungi admin.'),
          );
        }

        // User normal, lanjutkan ke konten komunitas
        return _buildNormalContent();
      },
      loading: () => _buildLoadingUser(),
      error: (_, __) => _buildNormalContent(),
    );
  }

  Widget _buildNormalContent() {
    if (_isLoadingUser) {
      return _buildLoadingUser();
    }

    if (_currentUserId == null) {
      return _buildNotLoggedInScreen();
    }

    final communityAsync = ref.watch(
      communityDetailsProvider(widget.communityId),
    );

    final postsAsync = ref.watch(community_provider.communityPostsStreamProvider(widget.communityId));

    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(widget.communityName),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: PostSearchDelegate(
                    communityId: widget.communityId,
                    currentUserId: _currentUserId,
                    onLikeTapped: (post) async {
                      if (_currentUserId != null) {
                        await _postService.toggleLikePost(post.id, _currentUserId!);
                      }
                    },
                    onCommentTapped: (post) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommentsScreen(
                            postId: post.id,
                            communityName: widget.communityName,
                          ),
                        ),
                      );
                    },
                    onShareTapped: (post) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => SharePostDialog(
                          originalPost: post,
                          userId: _currentUserId!,
                          onShared: () {},
                        ),
                      );
                    },
                    onMoreTapped: (post) => _showPostOptions(post),
                  ),
                );
              },
              tooltip: 'Cari postingan',
            ),
            ..._buildAppBarActions(communityAsync),
          ],
        ),
        body: Column(
          children: [
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

// ============ COMMUNITY SIDEBAR ============

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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  if (userId != null)
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Profil Saya'),
                      onTap: () {
                        Navigator.pop(context);
                        onOpenProfile();
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.person_add_outlined),
                    title: const Text('Undang Pengguna'),
                    onTap: () {
                      Navigator.pop(context);
                      onInviteUsers();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.group_outlined),
                    title: const Text('Anggota Komunitas'),
                    onTap: () {
                      Navigator.pop(context);
                      onViewMembers();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text('Laporkan Komunitas'),
                    onTap: () {
                      Navigator.pop(context);
                      onReportCommunity();
                    },
                  ),
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

// Helper function untuk encode query parameters
String encodeQueryParameters(Map<String, String> params) {
  return params.entries
      .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
}