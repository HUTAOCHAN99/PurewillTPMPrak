// lib/ui/admin/screens/doctor_activation_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purewill/data/services/doctor/doctor_activation_service.dart';

class DoctorActivationRequestsScreen extends ConsumerStatefulWidget {
  const DoctorActivationRequestsScreen({super.key});

  @override
  DoctorActivationRequestsScreenState createState() => DoctorActivationRequestsScreenState();
}

class DoctorActivationRequestsScreenState extends ConsumerState<DoctorActivationRequestsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _userRole;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allRequests = [];
  String _filterStatus = 'all'; // all, pending, approved, completed, rejected, expired

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadAllRequests();
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

  Future<void> _loadAllRequests() async {
    try {
      final service = ref.read(doctorActivationServiceProvider);
      // Get all requests
      final response = await _supabase
          .from('doctor_activation_requests')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _allRequests = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading requests: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredRequests {
    if (_filterStatus == 'all') return _allRequests;
    return _allRequests.where((req) => req['status'] == _filterStatus).toList();
  }

  Map<String, int> get _statusCounts {
    final counts = <String, int>{};
    for (final request in _allRequests) {
      final status = request['status'] as String? ?? 'unknown';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  Widget _buildAccessDeniedScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Requests'),
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
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Doctor Requests')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userRole != 'admin') {
      return _buildAccessDeniedScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Activation Requests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter Chips
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip('all', 'All (${_allRequests.length})'),
                  _buildStatusChip('pending', 'Pending (${_statusCounts['pending'] ?? 0})'),
                  _buildStatusChip('approved', 'Approved (${_statusCounts['approved'] ?? 0})'),
                  _buildStatusChip('completed', 'Completed (${_statusCounts['completed'] ?? 0})'),
                  _buildStatusChip('rejected', 'Rejected (${_statusCounts['rejected'] ?? 0})'),
                  _buildStatusChip('expired', 'Expired (${_statusCounts['expired'] ?? 0})'),
                ],
              ),
            ),
          ),

          // Requests List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAllRequests,
              child: _filteredRequests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.list_alt, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            _filterStatus == 'all'
                                ? 'No requests found'
                                : 'No ${_filterStatus} requests',
                            style: const TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: _filteredRequests.length,
                      itemBuilder: (context, index) {
                        final request = _filteredRequests[index];
                        return _buildRequestItem(request);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, String label) {
    final isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterStatus = status;
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: _getStatusColor(status).withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? _getStatusColor(status) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? _getStatusColor(status) : Colors.grey,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestItem(Map<String, dynamic> request) {
    final status = request['status'] as String? ?? 'unknown';
    final statusColor = _getStatusColor(status);
    final createdAt = DateTime.parse(request['created_at']);
    final dateStr = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    request['full_name'] ?? 'Unknown User',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
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
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(width: 16),
                if (request['approved_by'] != null) ...[
                  const Icon(Icons.person, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  FutureBuilder(
                    future: _getAdminName(request['approved_by']),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? 'Admin',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      );
                    },
                  ),
                ],
              ],
            ),
            if (request['expires_at'] != null && status == 'approved')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      'Expires: ${DateTime.parse(request['expires_at']).toString()}',
                      style: const TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _showRequestDetails(request);
                      },
                      child: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _approveRequest(request['id']);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _rejectRequest(request['id']);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            if (status == 'approved')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _resendOTP(request);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text('Resend OTP'),
                    ),
                  ),
                ],
              ),
            if (status == 'completed')
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '✓ User has completed activation',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<String?> _getAdminName(String adminId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('user_id', adminId)
          .single();
      return response['full_name'] as String?;
    } catch (e) {
      return null;
    }
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('User ID', request['user_id']),
              _buildDetailItem('Full Name', request['full_name']),
              _buildDetailItem('Email', request['user_email']),
              _buildDetailItem('Status', request['status']),
              _buildDetailItem('Created At', request['created_at']),
              if (request['expires_at'] != null)
                _buildDetailItem('Expires At', request['expires_at']),
              if (request['approved_by'] != null)
                _buildDetailItem('Approved By', request['approved_by']),
              if (request['approved_at'] != null)
                _buildDetailItem('Approved At', request['approved_at']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (request['status'] == 'pending')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _approveRequest(request['id']);
              },
              child: const Text('Approve'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            value?.toString() ?? 'N/A',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRequest(String requestId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final service = ref.read(doctorActivationServiceProvider);
      final result = await service.approveDoctorActivation(
        requestId: requestId,
        adminId: user.id,
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Request approved'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadAllRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to approve'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: const Text('Are you sure you want to reject this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _supabase
                    .from('doctor_activation_requests')
                    .update({
                      'status': 'rejected',
                      'updated_at': DateTime.now().toIso8601String(),
                    })
                    .eq('id', requestId);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Request rejected'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.pop(context);
                await _loadAllRequests();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _resendOTP(Map<String, dynamic> request) async {
    // Implement resend OTP logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Resend OTP feature coming soon'),
      ),
    );
  }
}