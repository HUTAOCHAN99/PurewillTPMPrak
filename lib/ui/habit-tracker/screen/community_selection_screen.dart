// lib\ui\habit-tracker\screen\community_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/data/services/community/index.dart';
import 'package:purewill/domain/model/community_model.dart';
import 'package:purewill/ui/habit-tracker/screen/community_detail_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/consultation_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/habit_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/home_screen.dart';
import 'package:purewill/ui/habit-tracker/widget/clean_bottom_navigation_bar.dart';
import 'package:purewill/ui/habit-tracker/widget/community/community_confirmation_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider untuk mengelola state komunitas
final communitiesProvider = FutureProvider.autoDispose<List<Community>>((ref) async {
  final communityService = CommunityService();
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];
  
  return await communityService.getCommunities(user.id);
});

class CommunitySelectionScreen extends ConsumerStatefulWidget {
  const CommunitySelectionScreen({super.key});

  @override
  ConsumerState<CommunitySelectionScreen> createState() => _CommunitySelectionScreenState();
}

class _CommunitySelectionScreenState extends ConsumerState<CommunitySelectionScreen> {
  final int _currentIndex = 3; // Index untuk tab komunitas
  String? _currentUserId;
  
  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }
  
  void _getCurrentUser() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _currentUserId = user.id;
    }
  }

  void _onNavBarTap(int index) {
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ), 
      );
    } else if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HabitScreen(),
        ), 
      );
    } else if (index == 2) {
      // Navigate to NoFap screen
      // TODO: Uncomment when NoFapScreen is available
      // Navigator.of(context).pushReplacement(
      //   MaterialPageRoute(
      //     builder: (context) => const NoFapScreen(),
      //   ), 
      // );
    } else if (index == 3) {
      return; // Stay in community screen
    } else if (index == 4) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const ConsultationScreen(),
        ), 
      );
    }
  }

  Future<void> _joinCommunity(Community community) async {
    if (_currentUserId == null) return;
    
    try {
      final communityService = CommunityService();
      final success = await communityService.joinCommunity(
        community.id,
        _currentUserId!,
      );
      
      if (success && mounted) {
        // Refresh data
        ref.invalidate(communitiesProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil bergabung dengan ${community.name}! 🎉'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _leaveCommunity(Community community) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Komunitas'),
        content: Text('Apakah Anda yakin ingin keluar dari ${community.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              if (_currentUserId == null) return;
              
              try {
                final communityService = CommunityService();
                final success = await communityService.leaveCommunity(
                  community.id,
                  _currentUserId!,
                );
                
                if (success) {
                  // Refresh data
                  ref.invalidate(communitiesProvider);
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Anda telah keluar dari ${community.name}'),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Keluar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCommunityDetail(Community community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityDetailScreen(
          communityId: community.id,
          communityName: community.name,
        ),
      ),
    );
  }

  void _showConfirmationDialog(Community community) {
    showDialog(
      context: context,
      builder: (context) => CommunityConfirmationDialog(
        community: community,
        onJoin: () => _joinCommunity(community),
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildJoinedCommunityCard(Community community) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToCommunityDetail(community),
        onLongPress: () => _leaveCommunity(community),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getColorFromHex(community.color ?? '#7C3AED').withAlpha((0.15 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconFromName(community.iconName ?? 'people'),
                  color: _getColorFromHex(community.color ?? '#7C3AED'),
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                community.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 12,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${community.memberCount}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha((0.1 * 255).toInt()),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableCommunityCard(Community community) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: () => _showConfirmationDialog(community),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getColorFromHex(community.color ?? '#7C3AED').withAlpha((0.1 * 255).toInt()),
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
                          '${community.memberCount} anggota',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
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
      default:
        return Icons.people;
    }
  }

  @override
  Widget build(BuildContext context) {
    final communitiesAsync = ref.watch(communitiesProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Komunitas',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Implement search functionality
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Pencarian'),
                  content: const Text('Fitur pencarian akan segera hadir!'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.search, size: 28),
            color: Colors.grey[600],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F5F5),
              Color(0xFFE8F4F8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: communitiesAsync.when(
                  data: (communities) {
                    final joinedCommunities = communities
                        .where((c) => c.isJoined)
                        .toList();
                    
                    final availableCommunities = communities
                        .where((c) => !c.isJoined)
                        .toList();

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section: Komunitas yang Diikuti
                          if (joinedCommunities.isNotEmpty) ...[
                            _buildSectionTitle(
                              'Komunitas Anda',
                              '${joinedCommunities.length} komunitas',
                            ),
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.2,
                              ),
                              itemCount: joinedCommunities.length,
                              itemBuilder: (context, index) {
                                return _buildJoinedCommunityCard(joinedCommunities[index]);
                              },
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Section: Temukan Komunitas Lain
                          _buildSectionTitle(
                            'Temukan Komunitas',
                            '${availableCommunities.length} komunitas tersedia',
                          ),
                          const SizedBox(height: 12),
                          availableCommunities.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'Tidak ada komunitas yang tersedia untuk saat ini',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: availableCommunities.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    return _buildAvailableCommunityCard(availableCommunities[index]);
                                  },
                                ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 50, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: $error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(communitiesProvider),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CleanBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
