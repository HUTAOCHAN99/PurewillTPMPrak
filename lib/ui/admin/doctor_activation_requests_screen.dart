// lib/ui/admin/doctor_activation_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purewill/data/services/doctor/doctor_activation_service.dart';

class DoctorActivationRequestsScreen extends ConsumerStatefulWidget {
  const DoctorActivationRequestsScreen({super.key});

  @override
  DoctorActivationRequestsScreenState createState() =>
      DoctorActivationRequestsScreenState();
}

class DoctorActivationRequestsScreenState
    extends ConsumerState<DoctorActivationRequestsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _userRole;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allRequests = [];
  String _filterStatus = 'all';

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
          .maybeSingle();

      if (mounted) {
        setState(() {
          _userRole = response?['role'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error checking user role: $e');
    }
  }

  Future<void> _loadAllRequests() async {
    try {
      final service = ref.read(doctorActivationServiceProvider);
      final requests = await service.getAllRequests();

      if (mounted) {
        setState(() {
          _allRequests = requests;
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
        title: const Text('Aktivasi Dokter'),
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

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      case 'expired':
        return 'Kadaluarsa';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<String?> _getAdminName(String adminId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('user_id', adminId)
          .maybeSingle();
      return response?['full_name'] as String?;
    } catch (e) {
      return null;
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP berhasil disalin'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Request'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('User ID', request['user_id']),
              const Divider(),
              _buildDetailItem('Nama Lengkap', request['full_name']),
              const Divider(),
              _buildDetailItem('Email', request['user_email']),
              const Divider(),
              _buildDetailItem('Status', _getStatusText(request['status'])),
              const Divider(),
              _buildDetailItem('Dibuat Pada', _formatDate(DateTime.parse(request['created_at']))),
              if (request['expires_at'] != null) ...[
                const Divider(),
                _buildDetailItem('Kadaluarsa Pada', _formatDate(DateTime.parse(request['expires_at']))),
              ],
              if (request['otp_code'] != null) ...[
                const Divider(),
                _buildDetailItem('Kode OTP', request['otp_code']),
              ],
              if (request['approved_by'] != null) ...[
                const Divider(),
                _buildDetailItem('Disetujui Oleh', request['approved_by']),
              ],
              if (request['approved_at'] != null) ...[
                const Divider(),
                _buildDetailItem('Disetujui Pada', _formatDate(DateTime.parse(request['approved_at']))),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          if (request['status'] == 'pending')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _approveRequest(request['id']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Setujui'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
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

    if (!mounted) return;
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final service = ref.read(doctorActivationServiceProvider);
      final result = await service.approveDoctorActivation(
        requestId: requestId,
        adminId: user.id,
      );

      if (mounted) Navigator.pop(context);

      if (result.success && mounted) {
        // Show OTP dialog to admin
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Request Disetujui'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Berikan kode OTP berikut ke user:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'KODE OTP',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 2,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        result.otpCode ?? '',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'User harus memasukkan kode ini untuk menyelesaikan aktivasi.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'OTP akan kadaluarsa dalam 24 jam.',
                  style: TextStyle(fontSize: 11, color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadAllRequests();
                },
                child: const Text('OK'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (result.otpCode != null) {
                    _copyToClipboard(result.otpCode!);
                  }
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Salin OTP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                ),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Gagal menyetujui request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
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

  Future<void> _rejectRequest(String requestId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Request'),
        content: const Text('Apakah Anda yakin ingin menolak request ini?'),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (mounted) Navigator.pop(context);
              
              if (!mounted) return;
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                final service = ref.read(doctorActivationServiceProvider);
                final result = await service.updateRequestStatus(
                  requestId: requestId,
                  status: 'rejected',
                  adminId: user.id,
                );

                if (mounted) Navigator.pop(context);

                if (result.success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Request berhasil ditolak'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  await _loadAllRequests();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.error ?? 'Gagal menolak request'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Ya, Tolak'),
          ),
        ],
      ),
    );
  }

  Future<void> _resendOTP(Map<String, dynamic> request) async {
    if (!mounted) return;
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final service = ref.read(doctorActivationServiceProvider);
      final result = await service.resendOTP(requestId: request['id']);

      if (mounted) Navigator.pop(context);

      if (result.success && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.refresh, color: Colors.orange),
                SizedBox(width: 8),
                Text('OTP Baru'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Kode OTP baru untuk user:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'KODE OTP BARU',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 2,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        result.otpCode ?? '',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'OTP baru akan kadaluarsa dalam 24 jam.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadAllRequests();
                },
                child: const Text('OK'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (result.otpCode != null) {
                    _copyToClipboard(result.otpCode!);
                  }
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Salin OTP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                ),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Gagal mengirim ulang OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Aktivasi Dokter')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userRole != 'admin') {
      return _buildAccessDeniedScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivasi Dokter'),
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
                  _buildStatusChip('all', 'Semua (${_allRequests.length})'),
                  _buildStatusChip('pending', 'Menunggu (${_statusCounts['pending'] ?? 0})'),
                  _buildStatusChip('approved', 'Disetujui (${_statusCounts['approved'] ?? 0})'),
                  _buildStatusChip('completed', 'Selesai (${_statusCounts['completed'] ?? 0})'),
                  _buildStatusChip('rejected', 'Ditolak (${_statusCounts['rejected'] ?? 0})'),
                  _buildStatusChip('expired', 'Kadaluarsa (${_statusCounts['expired'] ?? 0})'),
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
                                ? 'Tidak ada request'
                                : 'Tidak ada request dengan status ${_getStatusText(_filterStatus)}',
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
    final statusColor = _getStatusColor(status);
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
        selectedColor: statusColor.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: isSelected ? statusColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? statusColor : Colors.grey,
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
    final dateStr = _formatDate(createdAt);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _getStatusText(status).toUpperCase(),
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
                      'Expired: ${_formatDate(DateTime.parse(request['expires_at']))}',
                      style: const TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ],
                ),
              ),
            if (status == 'approved' && request['otp_code'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kode OTP untuk User:',
                              style: TextStyle(fontSize: 11, color: Colors.green),
                            ),
                            const SizedBox(height: 2),
                            SelectableText(
                              request['otp_code'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18, color: Colors.green),
                        onPressed: () {
                          _copyToClipboard(request['otp_code']);
                        },
                      ),
                    ],
                  ),
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
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                      child: const Text('Detail'),
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
                      child: const Text('Setujui'),
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
                      child: const Text('Tolak'),
                    ),
                  ),
                ],
              ),
            if (status == 'approved')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _resendOTP(request);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                      child: const Text('Kirim Ulang OTP'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _showRequestDetails(request);
                      },
                      child: const Text('Detail'),
                    ),
                  ),
                ],
              ),
            if (status == 'completed')
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      '✓ User telah menyelesaikan aktivasi',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ),
            if (status == 'rejected')
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.cancel, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      '✗ Request telah ditolak',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ),
            if (status == 'expired')
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.timer_off, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      '⏰ OTP telah kadaluarsa',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}