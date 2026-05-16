// lib/ui/habit-tracker/screen/post_search_delegate.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/data/services/community/post_service.dart';
import 'package:purewill/domain/model/community_model.dart';
import 'package:purewill/ui/habit-tracker/widget/community/post_card.dart';

// Provider untuk post service
final postServiceProvider = Provider((ref) => PostService());

class PostSearchDelegate extends SearchDelegate<String> {
  final String communityId;
  final String? currentUserId;
  final Function(CommunityPost) onLikeTapped;
  final Function(CommunityPost) onCommentTapped;
  final Function(CommunityPost) onShareTapped;
  final Function(CommunityPost) onMoreTapped;

  PostSearchDelegate({
    required this.communityId,
    this.currentUserId,
    required this.onLikeTapped,
    required this.onCommentTapped,
    required this.onShareTapped,
    required this.onMoreTapped,
  });

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildEmptyState();
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return FutureBuilder<List<CommunityPost>>(
      future: PostService().searchPosts(
        query: query,
        communityId: communityId,
        limit: 50,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 50, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Gagal memuat hasil pencarian',
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString().length > 100
                        ? '${snapshot.error.toString().substring(0, 100)}...'
                        : snapshot.error.toString(),
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return _buildNoResultsState();
        }

        return _buildPostList(posts);
      },
    );
  }

  Widget _buildPostList(List<CommunityPost> posts) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final post = posts[index];
        
        // Gunakan widget PostCard yang sama
        return PostCard(
          key: ValueKey(post.id),
          post: post,
          userId: currentUserId ?? '',
          onLikeToggled: () => onLikeTapped(post),
          onCommentTapped: () => onCommentTapped(post),
          onShareTapped: () => onShareTapped(post),
          onMoreTapped: () => onMoreTapped(post),
          onImageSaved: () {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gambar berhasil disimpan ke galeri'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            const Text(
              'Cari postingan di komunitas',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ketik kata kunci untuk mencari postingan berdasarkan konten',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('Tips sehat'),
                _buildSuggestionChip('Pengalaman'),
                _buildSuggestionChip('Motivasi'),
                _buildSuggestionChip('Pertanyaan'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              'Tidak ditemukan untuk "$query"',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coba kata kunci lain atau periksa ejaan',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => query = '',
              icon: const Icon(Icons.refresh),
              label: const Text('Cari Ulang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () => query = text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue[100]!),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.blue[700],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  String get searchFieldLabel => 'Cari postingan dalam komunitas...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: Colors.black,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: const TextStyle(color: Colors.grey),
        border: InputBorder.none,
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}