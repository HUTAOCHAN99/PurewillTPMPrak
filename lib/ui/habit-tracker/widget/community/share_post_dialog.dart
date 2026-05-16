import 'package:flutter/material.dart';
import 'package:purewill/data/services/community/post_service.dart';
import 'package:purewill/data/services/community/community_service.dart';
import 'package:purewill/domain/model/community_model.dart';

class SharePostDialog extends StatefulWidget {
  final CommunityPost originalPost;
  final String userId;
  final VoidCallback? onShared;

  const SharePostDialog({
    super.key,
    required this.originalPost,
    required this.userId,
    this.onShared,
  });

  @override
  State<SharePostDialog> createState() => _SharePostDialogState();
}

class _SharePostDialogState extends State<SharePostDialog> {
  final PostService _postService = PostService();
  final CommunityService _communityService = CommunityService();
  
  final TextEditingController _commentController = TextEditingController();
  List<Community> _userCommunities = [];
  String? _selectedCommunityId;
  bool _isLoading = false;
  bool _loadingCommunities = true;

  @override
  void initState() {
    super.initState();
    _loadUserCommunities();
  }

  Future<void> _loadUserCommunities() async {
    try {
      final communities = await _communityService.getUserCommunities(widget.userId);
      // Filter out current community
      setState(() {
        _userCommunities = communities
            .where((c) => c.id != widget.originalPost.communityId)
            .toList();
        _loadingCommunities = false;
      });
    } catch (e) {
      print('Error loading communities: $e');
      setState(() => _loadingCommunities = false);
    }
  }

  Future<void> _sharePost() async {
    if (_selectedCommunityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih komunitas tujuan')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _postService.sharePostToCommunity(
        originalPostId: widget.originalPost.id,
        targetCommunityId: _selectedCommunityId!,
        userId: widget.userId,
        additionalComment: _commentController.text.isNotEmpty
            ? _commentController.text
            : null,
      );

      Navigator.pop(context);
      if (widget.onShared != null) {
        widget.onShared!();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post berhasil dibagikan!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bagikan ke Komunitas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.originalPost.content.length > 100
                ? '${widget.originalPost.content.substring(0, 100)}...'
                : widget.originalPost.content,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              hintText: 'Tambahkan komentar (opsional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          const Text(
            'Pilih Komunitas Tujuan:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildCommunitiesList(),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildCommunitiesList() {
    if (_loadingCommunities) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userCommunities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Anda belum bergabung dengan komunitas lain',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: _userCommunities.length,
        itemBuilder: (context, index) {
          final community = _userCommunities[index];
          return RadioListTile<String>(
            value: community.id,
            groupValue: _selectedCommunityId,
            onChanged: (value) {
              setState(() => _selectedCommunityId = value);
            },
            title: Text(community.name),
            subtitle: Text('${community.memberCount} anggota'),
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.people),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Batal'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sharePost,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Bagikan'),
          ),
        ),
      ],
    );
  }
}