// lib/ui/habit-tracker/widget/community/community_search_delegate.dart
import 'package:flutter/material.dart';
import 'package:purewill/data/services/community/community_service.dart';
import 'package:purewill/domain/model/community_model.dart';
import 'package:purewill/ui/habit-tracker/widget/community/community_confirmation_dialog.dart';

class CommunitySearchDelegate extends SearchDelegate<Community?> {
  final String? currentUserId;
  final CommunityService _communityService = CommunityService();
  
  CommunitySearchDelegate({this.currentUserId});
  
  @override
  String get searchFieldLabel => 'Cari komunitas...';
  
  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }
  
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }
  
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }
  
  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Masukkan kata kunci pencarian'),
          ],
        ),
      );
    }
    
    return FutureBuilder<List<Community>>(
      future: _communityService.searchCommunities(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Mencari komunitas...'),
              ],
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 50, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    query = '';
                    showSuggestions(context);
                  },
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }
        
        final communities = snapshot.data ?? [];
        
        if (communities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada komunitas ditemukan',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Coba dengan kata kunci lain',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: communities.length,
          itemBuilder: (context, index) {
            final community = communities[index];
            return _buildSearchResultCard(context, community);
          },
        );
      },
    );
  }
  
  Widget _buildSearchResultCard(BuildContext context, Community community) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          close(context, community);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getColorFromHex(community.color ?? '#7C3AED').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getIconFromName(community.iconName ?? 'people'),
                  color: _getColorFromHex(community.color ?? '#7C3AED'),
                  size: 30,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      community.description ?? 'Deskripsi tidak tersedia',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatNumber(community.memberCount),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (community.isJoined) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Bergabung',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
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
  
  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse('0x$hexColor'));
  }
  
  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'psychology':
        return Icons.psychology;
      case 'restaurant':
        return Icons.restaurant;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'work':
        return Icons.work;
      case 'menu_book':
        return Icons.menu_book;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'school':
        return Icons.school;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'bedtime':
        return Icons.bedtime;
      case 'water_drop':
        return Icons.water_drop;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'language':
        return Icons.language;
      case 'phone_disabled':
        return Icons.phone_disabled;
      case 'edit':
        return Icons.edit;
      case 'schedule':
        return Icons.schedule;
      default:
        return Icons.people;
    }
  }
  
  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}