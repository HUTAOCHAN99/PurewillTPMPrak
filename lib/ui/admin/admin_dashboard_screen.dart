// lib/ui/admin/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purewill/data/services/doctor/doctor_activation_service.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  AdminDashboardScreenState createState() => AdminDashboardScreenState();
}

class AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _userRole;
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingRequests = [];
  int _activeUsers = 0;
  int _totalDoctors = 0;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadDashboardData();
  }

  Future<void> _checkUserRole() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('user_id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _userRole = response['role'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error checking user role: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      // Load pending doctor activation requests
      final service = ref.read(doctorActivationServiceProvider);
      final requests = await service.getPendingRequests();

      // Get active users count - cara yang benar untuk count
      final usersResponse = await _supabase
          .from('profiles')
          .select('*')
          .eq('role', 'user');

      // Get doctors count
      final doctorsResponse = await _supabase
          .from('profiles')
          .select('*')
          .eq('role', 'doctor');

      if (mounted) {
        setState(() {
          _pendingRequests = requests;
          _activeUsers = usersResponse.length; // Gunakan .length
          _totalDoctors = doctorsResponse.length; // Gunakan .length
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper function untuk opacity
  Color _withOpacity(Color color, double opacity) {
    return color.withAlpha((opacity * 255).round());
  }

  Widget _buildAccessDeniedScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Akses Ditolak',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Hanya administrator yang dapat mengakses halaman ini.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading screen
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    // Cek apakah user adalah admin
    if (_userRole != 'admin') {
      return _buildAccessDeniedScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context), // Tambahkan context
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadDashboardData();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Admin Panel',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Selamat datang, Admin',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Stats Cards
              Row(
                children: [
                  _buildStatCard(
                    title: 'Total Users',
                    value: _activeUsers.toString(),
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    title: 'Total Doctors',
                    value: _totalDoctors.toString(),
                    icon: Icons.medical_services,
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatCard(
                    title: 'Pending Requests',
                    value: _pendingRequests.length.toString(),
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    title: 'Today',
                    value: DateTime.now().day.toString(),
                    icon: Icons.calendar_today,
                    color: Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Pending Requests Section
              if (_pendingRequests.isNotEmpty)
                _buildPendingRequestsSection(),
              if (_pendingRequests.isEmpty)
                _buildNoRequestsSection(),

              const SizedBox(height: 32),

              // Quick Actions
              _buildQuickActionsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _withOpacity(color, 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _withOpacity(color, 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pending Activation Requests',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'Ada ${_pendingRequests.length} request yang perlu ditinjau',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _pendingRequests.length,
          itemBuilder: (context, index) {
            final request = _pendingRequests[index];
            return _buildRequestCard(request);
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => const DoctorActivationRequestsScreen(),
              //   ),
              // );
              _showComingSoonSnackbar(context, 'Doctor Activation Requests Screen');
            },
            child: const Text('Lihat Semua Requests'),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final createdAt = DateTime.parse(request['created_at']);
    final timeAgo = _timeAgo(createdAt);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request['full_name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _withOpacity(Colors.orange, 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _withOpacity(Colors.orange, 0.3)),
                  ),
                  child: Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.email, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request['user_email'] ?? 'No email',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  timeAgo,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showRequestDetails(context, request); // Tambahkan context
                    },
                    child: const Text('Detail'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _approveRequest(context, request['id']); // Tambahkan context
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRequestsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            'Tidak Ada Request Pending',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Semua request aktivasi dokter telah diproses.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildQuickActionCard(
              title: 'Manage Users',
              icon: Icons.people,
              color: Colors.blue,
              onTap: () {
                _showComingSoonSnackbar(context, 'User management');
              },
            ),
            _buildQuickActionCard(
              title: 'Doctor Requests',
              icon: Icons.medical_services,
              color: Colors.green,
              onTap: () {
                _showComingSoonSnackbar(context, 'Doctor Requests');
              },
            ),
            _buildQuickActionCard(
              title: 'Reports',
              icon: Icons.analytics,
              color: Colors.purple,
              onTap: () {
                _showComingSoonSnackbar(context, 'Reports');
              },
            ),
            _buildQuickActionCard(
              title: 'Settings',
              icon: Icons.settings,
              color: Colors.orange,
              onTap: () {
                _showComingSoonSnackbar(context, 'Settings');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _withOpacity(color, 0.1),
                _withOpacity(color, 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  void _showRequestDetails(BuildContext context, Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Nama'),
                subtitle: Text(request['full_name'] ?? 'Unknown'),
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(request['user_email'] ?? 'No email'),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Tanggal Request'),
                subtitle: Text(DateTime.parse(request['created_at']).toString()),
              ),
              if (request['expires_at'] != null)
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text('Expires At'),
                  subtitle: Text(DateTime.parse(request['expires_at']).toString()),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _approveRequest(context, request['id']);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonSnackbar(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _approveRequest(BuildContext context, String requestId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final service = ref.read(doctorActivationServiceProvider);
      final result = await service.approveDoctorActivation(
        requestId: requestId,
        adminId: user.id,
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Request approved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadDashboardData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to approve request'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }
}