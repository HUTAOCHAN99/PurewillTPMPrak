import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/domain/model/plan_model.dart';
import 'package:purewill/ui/admin/admin_dashboard_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/badge_xp_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/membership_screen.dart';
import 'package:purewill/ui/habit-tracker/widget/habit_detail/doctor_activation_screen.dart';
import 'package:purewill/ui/habit-tracker/widget/menu_button.dart';

class HabitHeader extends ConsumerWidget {
  final String userName;
  final String userEmail;
  final String userRole;
  final VoidCallback onLogout;
  final bool isPremiumUser;
  final PlanModel? currentPlan;

  const HabitHeader({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.onLogout,
    this.isPremiumUser = false,
    this.currentPlan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(176, 230, 216, 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              SizedBox(width: 8),
              Text(
                'PureWill',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          _buildUserAvatarWithPremium(context),
        ],
      ),
    );
  }

  Widget _buildUserAvatarWithPremium(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isPremiumUser ? Colors.yellow : Colors.grey.shade300,
              width: isPremiumUser ? 2 : 1.5,
            ),
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: isPremiumUser
                ? Colors.deepPurple[50]
                : Colors.white,
            child: IconButton(
              icon: Icon(
                Icons.person,
                color: isPremiumUser
                    ? Colors.deepPurple
                    : const Color(0xFF7C3AED),
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _showUserProfileMenu(context),
            ),
          ),
        ),
        // Badge premium kecil di sudut
        if (isPremiumUser)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.yellow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.deepPurple,
                  size: 10,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getRoleColor() {
    switch (userRole.toLowerCase()) {
      case 'doctor':
        return const Color(0xFF10B981); // Emerald green
      case 'admin':
        return const Color(0xFFEF4444); // Red
      default: // user
        return const Color(0xFF7C3AED); // Purple
    }
  }

  IconData _getRoleIcon() {
    switch (userRole.toLowerCase()) {
      case 'doctor':
        return Icons.medical_services;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  String _getRoleText() {
    switch (userRole.toLowerCase()) {
      case 'doctor':
        return 'Doctor';
      case 'admin':
        return 'Admin';
      default:
        return 'User';
    }
  }

  // Helper function untuk opacity (kompatibel dengan Flutter terbaru)
  Color _withOpacity(Color color, double opacity) {
    return color.withAlpha((opacity * 255).round());
  }

  void _showUserProfileMenu(BuildContext context) {
    bool darkMode = false; // Contoh state untuk dark mode
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Avatar dengan status premium
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: isPremiumUser
                          ? Colors.deepPurple
                          : const Color(0xFF7C3AED),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    if (userRole == 'doctor' || userRole == 'admin')
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: _getRoleColor()),
                          ),
                          child: Icon(
                            userRole == 'doctor' 
                                ? Icons.verified 
                                : Icons.shield,
                            color: _getRoleColor(),
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  userEmail,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                
                // Tampilkan status role dan membership
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Badge role
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _withOpacity(_getRoleColor(), 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _withOpacity(_getRoleColor(), 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getRoleIcon(),
                            color: _getRoleColor(),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            userRole.toUpperCase(),
                            style: TextStyle(
                              color: _getRoleColor(),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Badge membership
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isPremiumUser 
                            ? _withOpacity(Colors.deepPurple, 0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isPremiumUser 
                              ? _withOpacity(Colors.deepPurple, 0.3)
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPremiumUser ? Icons.star : Icons.person_outline,
                            color: isPremiumUser ? Colors.deepPurple : Colors.grey,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isPremiumUser ? 'Premium' : 'Free',
                            style: TextStyle(
                              color: isPremiumUser ? Colors.deepPurple : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Menu items
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        MenuButton(
                          icon: Icons.emoji_events_outlined,
                          title: 'Badge & XP',
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToBadgeXpScreen(context);
                          },
                        ),

                        // Menu aktivasi doctor (hanya untuk user biasa)
                        if (userRole == 'user')
                          MenuButton(
                            icon: Icons.medical_services,
                            title: 'Activate Doctor Account',
                            subtitle: 'Request verification via OTP',
                            onTap: () {
                              Navigator.pop(context);
                              _navigateToDoctorActivationScreen(context);
                            },
                          ),

                        // Menu admin panel (hanya untuk admin)
                        if (userRole == 'admin')
                          MenuButton(
                            icon: Icons.admin_panel_settings,
                            title: 'Admin Dashboard',
                            subtitle: 'Manage doctor activations',
                            onTap: () {
                              Navigator.pop(context);
                              _navigateToAdminDashboard(context);
                            },
                          ),

                        MenuButton(
                          icon: isPremiumUser ? Icons.star : Icons.upgrade,
                          title: isPremiumUser ? 'My Membership' : 'Upgrade to Premium',
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToMembershipScreen(context);
                          },
                        ),
                        
                        MenuButton(
                          icon: Icons.settings_outlined,
                          title: 'Settings',
                          onTap: () {
                            Navigator.pop(context);
                            _showComingSoonSnackbar(context, 'Settings');
                          },
                        ),
                        
                        MenuButton(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          onTap: () {
                            Navigator.pop(context);
                            _showComingSoonSnackbar(context, 'Help & Support');
                          },
                        ),
                        
                        MenuButton(
                          icon: Icons.info_outline,
                          title: 'About',
                          onTap: () {
                            Navigator.pop(context);
                            _showAboutDialog(context);
                          },
                        ),
                        
                        MenuButton(
                          icon: Icons.people_outline,
                          title: 'Friends',
                          onTap: () {
                            Navigator.pop(context);
                            _showComingSoonSnackbar(context, 'Friends');
                          },
                        ),
                        
                        MenuButton(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          badgeCount: 3, // Contoh notifikasi belum dibaca
                          onTap: () {
                            Navigator.pop(context);
                            _showComingSoonSnackbar(context, 'Notifications');
                          },
                        ),
                        
                        MenuButton(
                          icon: Icons.bar_chart_outlined,
                          title: 'Statistics',
                          onTap: () {
                            Navigator.pop(context);
                            _showComingSoonSnackbar(context, 'Statistics');
                          },
                        ),
                        
                        // Dark Mode dengan switch
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Icon(
                              darkMode ? Icons.dark_mode : Icons.light_mode,
                              color: darkMode ? Colors.deepPurple : Colors.orange,
                            ),
                            title: Text(
                              'Dark Mode',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: darkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            trailing: Switch(
                              value: darkMode,
                              onChanged: (value) {
                                _toggleDarkMode(value);
                                // setStateIfMounted(() {
                                //   darkMode = value;
                                // });
                              },
                              activeColor: Colors.deepPurple,
                            ),
                            onTap: () {
                              _toggleDarkMode(!darkMode);
                              // setStateIfMounted(() {
                              //   darkMode = !darkMode;
                              // });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10),
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showLogoutConfirmation(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, size: 18),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToMembershipScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const MembershipScreen())
    );
  }

  void _navigateToDoctorActivationScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DoctorActivationScreen(
          userEmail: userEmail,
          userName: userName,
        ),
      ),
    );
  }

  void _navigateToAdminDashboard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AdminDashboardScreen(),
      ),
    );
  }

  void _navigateToBadgeXpScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const BadgeXpScreen())
    );
  }

  void _showComingSoonSnackbar(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('About PureWill'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PureWill - Habit Tracker',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Version: 1.0.0'),
              SizedBox(height: 8),
              Text(
                'PureWill helps you build better habits, track your progress, and connect with a supportive community.',
              ),
              SizedBox(height: 16),
              Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Habit tracking and reminders'),
              Text('• Progress visualization'),
              Text('• Community support'),
              Text('• Doctor consultation'),
              Text('• Badge and XP system'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleDarkMode(bool value) {
    // Implement dark mode toggle
    // Bisa menggunakan ThemeProvider atau Riverpod untuk state management
    // Untuk sekarang, kita hanya log saja
    debugPrint('Dark mode toggled: $value');
    // Dalam aplikasi nyata, ini akan memanggil ThemeProvider
    // Contoh: ref.read(themeProvider.notifier).toggleTheme();
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to logout?'),
            SizedBox(height: 8),
            Text(
              'Your data will be saved and you can login again anytime.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onLogout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
