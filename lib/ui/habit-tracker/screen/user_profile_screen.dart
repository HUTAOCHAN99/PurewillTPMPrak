import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purewill/data/services/community/community_service.dart';
import 'package:purewill/data/services/community/profile_service.dart';
import 'package:purewill/data/services/community/friendship_service.dart';
import 'package:purewill/data/services/community/report_service.dart';
import 'package:purewill/domain/model/community_model.dart';
import 'package:purewill/domain/model/friendship_model.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? userName;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  late final CommunityService _communityService;
  late final ProfileService _profileService;
  late final FriendshipService _friendshipService;
  late final ReportService _reportService;
  
  Profile? _userProfile;
  Friendship? _friendshipStatus;
  bool _isLoading = true;
  bool _isProcessingFriendRequest = false;
  bool _isProcessingReport = false;
  bool _isProcessingChat = false;
  
  final List<Community> _joinedCommunities = [];
  int _postsCount = 0;
  int _friendsCount = 0;

  @override
  void initState() {
    super.initState();
    _communityService = CommunityService();
    _profileService = ProfileService();
    _friendshipService = FriendshipService();
    _reportService = ReportService();
    _loadProfile();
    _loadUserData();
    _loadFriendshipStatus();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getUserProfile(widget.userId);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final communities = await _communityService.getCommunities(widget.userId);
      
      if (mounted) {
        setState(() {
          _joinedCommunities.clear();
          _joinedCommunities.addAll(communities);
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadFriendshipStatus() async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null || currentUserId == widget.userId) return;

      final friendship = await _friendshipService.getFriendshipStatus(
        currentUserId: currentUserId,
        targetUserId: widget.userId,
      );

      if (mounted) {
        setState(() {
          _friendshipStatus = friendship;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _handleFriendRequest() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      _showSnackBar('Silakan login terlebih dahulu');
      return;
    }

    if (currentUserId == widget.userId) {
      _showSnackBar('Tidak dapat menambahkan diri sendiri sebagai teman');
      return;
    }

    setState(() => _isProcessingFriendRequest = true);

    try {
      if (_friendshipStatus == null) {
        // Send friend request
        final newFriendship = await _friendshipService.sendFriendRequest(
          senderId: currentUserId,
          receiverId: widget.userId,
        );
        
        setState(() => _friendshipStatus = newFriendship);
        _showSnackBar('Permintaan pertemanan telah dikirim');
      } else if (_friendshipStatus!.isPending) {
        if (_friendshipStatus!.senderId == currentUserId) {
          // Cancel friend request
          await _friendshipService.cancelFriendRequest(_friendshipStatus!.id);
          setState(() => _friendshipStatus = null);
          _showSnackBar('Permintaan pertemanan dibatalkan');
        } else {
          // Accept friend request
          final acceptedFriendship = await _friendshipService.acceptFriendRequest(_friendshipStatus!.id);
          setState(() => _friendshipStatus = acceptedFriendship);
          _showSnackBar('Permintaan pertemanan diterima');
        }
      } else if (_friendshipStatus!.isAccepted) {
        // Remove friend
        await _friendshipService.removeFriend(_friendshipStatus!.id);
        setState(() => _friendshipStatus = null);
        _showSnackBar('Teman telah dihapus');
      }
    } catch (e) {
      _showSnackBar('Gagal memproses permintaan pertemanan: $e');
    } finally {
      setState(() => _isProcessingFriendRequest = false);
    }
  }

  Future<void> _handleChat() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      _showSnackBar('Silakan login terlebih dahulu');
      return;
    }

    if (currentUserId == widget.userId) {
      _showSnackBar('Tidak dapat mengirim pesan ke diri sendiri');
      return;
    }

    setState(() => _isProcessingChat = true);

    try {
      // Navigate to chat screen
      // TODO: Implement chat navigation
      _showSnackBar('Fitur chat akan segera hadir');
    } catch (e) {
      _showSnackBar('Gagal membuka chat: $e');
    } finally {
      setState(() => _isProcessingChat = false);
    }
  }

  Future<void> _handleReport() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      _showSnackBar('Silakan login terlebih dahulu');
      return;
    }

    if (currentUserId == widget.userId) {
      _showSnackBar('Tidak dapat melaporkan diri sendiri');
      return;
    }

    setState(() => _isProcessingReport = true);

    try {
      final result = await _showReportDialog();
      if (result != null) {
        // Tambahkan default value untuk reason
        final reason = result['reason'] ?? 'Lainnya';
        final description = result['description']?.trim();
        
        final reported = await _reportService.reportUser(
          reporterId: currentUserId,
          reportedUserId: widget.userId,
          reason: reason,
          description: description,
        );

        if (reported) {
          _showSnackBar('Laporan telah dikirim');
        } else {
          _showSnackBar('Gagal mengirim laporan');
        }
      }
    } catch (e) {
      _showSnackBar('Gagal melaporkan pengguna: $e');
    } finally {
      setState(() => _isProcessingReport = false);
    }
  }

  Future<Map<String, String>?> _showReportDialog() async {
    final reasons = await _reportService.getReportReasons();
    
    String? selectedReason;
    final descriptionController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Laporkan Pengguna'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih alasan pelaporan:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...reasons.map((reason) {
                      return RadioListTile<String>(
                        title: Text(reason),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value;
                          });
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                    const Text(
                      'Deskripsi (opsional):',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Jelaskan lebih detail...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: selectedReason == null
                      ? null
                      : () => Navigator.pop(context, {
                            'reason': selectedReason!,
                            'description': descriptionController.text.trim(),
                          }),
                  child: const Text('Laporkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Widget _buildHeader() {
    final isCurrentUser = widget.userId == Supabase.instance.client.auth.currentUser?.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white,
            backgroundImage: _userProfile?.avatarUrl != null
                ? NetworkImage(_userProfile!.avatarUrl!)
                : null,
            child: _userProfile?.avatarUrl == null
                ? Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.blue.shade200,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile?.fullName ?? widget.userName ?? 'Pengguna',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Level ${_userProfile?.level ?? 1}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!isCurrentUser) ...[
            const SizedBox(height: 16),
            _buildFriendButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildFriendButton() {
    final isCurrentUser = widget.userId == Supabase.instance.client.auth.currentUser?.id;
    if (isCurrentUser) return const SizedBox();

    if (_isProcessingFriendRequest) {
      return const CircularProgressIndicator();
    }

    String buttonText = 'Tambah Teman';
    Color buttonColor = Colors.blue;
    
    if (_friendshipStatus != null) {
      if (_friendshipStatus!.isPending) {
        if (_friendshipStatus!.senderId == Supabase.instance.client.auth.currentUser?.id) {
          buttonText = 'Permintaan Dikirim';
          buttonColor = Colors.grey;
        } else {
          buttonText = 'Terima Permintaan';
          buttonColor = Colors.green;
        }
      } else if (_friendshipStatus!.isAccepted) {
        buttonText = 'Teman';
        buttonColor = Colors.green;
      }
    }

    return ElevatedButton(
      onPressed: _handleFriendRequest,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(buttonText),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Komunitas', _joinedCommunities.length.toString()),
          _buildStatItem('Post', _postsCount.toString()),
          _buildStatItem('Teman', _friendsCount.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildXPBar() {
    if (_userProfile == null) return const SizedBox();

    final progress = (_userProfile!.currentXp / _userProfile!.xpToNextLevel).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'XP: ${_userProfile!.currentXp} / ${_userProfile!.xpToNextLevel}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Level ${_userProfile!.level}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            color: Colors.blue,
            borderRadius: BorderRadius.circular(10),
            minHeight: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildJoinedCommunities() {
    if (_joinedCommunities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.group,
                size: 50,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'Belum bergabung dengan komunitas',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Komunitas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          ..._joinedCommunities.take(3).map((community) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconForCommunity(community.iconName),
                    color: Colors.blue,
                  ),
                ),
                title: Text(
                  community.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text('${community.memberCount} anggota'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            );
          }),
          if (_joinedCommunities.length > 3)
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () {},
                child: Text(
                  'Lihat ${_joinedCommunities.length - 3} komunitas lainnya',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isCurrentUser = widget.userId == Supabase.instance.client.auth.currentUser?.id;
    
    // Jika ini profile sendiri, tidak tampilkan tombol action
    if (isCurrentUser) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Chat Button
          Expanded(
            child: _isProcessingChat
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _handleChat,
                    icon: const Icon(Icons.chat, size: 20),
                    label: const Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          
          // Report Button
          Expanded(
            child: _isProcessingReport
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _handleReport,
                    icon: const Icon(Icons.report, size: 20),
                    label: const Text('Laporkan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCommunity(String? iconName) {
    switch (iconName) {
      case 'fitness':
        return Icons.fitness_center;
      case 'nutrition':
        return Icons.restaurant;
      case 'mental':
        return Icons.psychology;
      case 'support':
        return Icons.health_and_safety;
      default:
        return Icons.group;
    }
  }

  Widget _buildLoadingState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat profil...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat profil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadProfile,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_userProfile == null) {
      return _buildErrorState('Profil tidak ditemukan');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildStats(),
            _buildXPBar(),
            _buildJoinedCommunities(),
            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}