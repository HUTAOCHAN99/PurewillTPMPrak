// lib/ui/admin/admin_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/data/services/community/report_service.dart';
import 'package:purewill/ui/habit-tracker/widget/community/community_provider.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ReportStatus? _selectedStatus;

  final List<MapEntry<String, ReportStatus?>> _tabs = [
    const MapEntry('Semua', null),
    const MapEntry('Pending', ReportStatus.pending),
    const MapEntry('Direview', ReportStatus.reviewed),
    const MapEntry('Selesai', ReportStatus.resolved),
    const MapEntry('Ditolak', ReportStatus.rejected),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    
    // Set default ke tab Pending (index 1)
    _selectedStatus = ReportStatus.pending;
    _tabController.index = 1;
    
    _tabController.addListener(() {
      final index = _tabController.index;
      if (index < _tabs.length) {
        setState(() {
          _selectedStatus = _tabs[index].value;
        });
        print('🔄 Tab changed to: ${_tabs[index].key}, status: ${_selectedStatus?.value ?? 'all'}');
        // Refresh data when tab changes
        ref.invalidate(adminReportsProvider(_selectedStatus));
      }
    });
    
    // Panggil debug setelah build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reportService = ReportService();
      reportService.debugCheckReports();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(reportStatisticsProvider);
    final reportsAsync = ref.watch(adminReportsProvider(_selectedStatus));

    // Debug print
    reportsAsync.whenData((reports) {
      print('🔍 UI REPORTS: ${reports.length} reports for status: ${_selectedStatus?.value ?? 'all'}');
      if (reports.isNotEmpty) {
        print('   First report ID: ${reports.first['id']}');
        print('   Status: ${reports.first['status']}');
        print('   Reporter: ${reports.first['reporter']?['full_name']}');
        print('   Reason: ${reports.first['reason']}');
      } else {
        print('   ⚠️ No reports found for status: ${_selectedStatus?.value ?? 'all'}');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Pengguna'),
        backgroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((tab) {
            return statsAsync.when(
              data: (stats) {
                String label = tab.key;
                if (tab.value == ReportStatus.pending) {
                  final pendingCount = stats['pending'] ?? 0;
                  if (pendingCount > 0) {
                    label = '$label ($pendingCount)';
                  }
                }
                return Tab(text: label);
              },
              loading: () => Tab(text: tab.key),
              error: (_, __) => Tab(text: tab.key),
            );
          }).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('🔄 Manual refresh triggered');
              ref.invalidate(reportStatisticsProvider);
              ref.invalidate(adminReportsProvider(_selectedStatus));
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              print('🐛 Running debug check...');
              final reportService = ReportService();
              await reportService.debugCheckReports();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Debug check completed. Check console.')),
              );
            },
            tooltip: 'Debug',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              print('➕ Creating test report...');
              final reportService = ReportService();
              final success = await reportService.testCreateReport();
              if (success && mounted) {
                print('✅ Test report created successfully');
                ref.invalidate(reportStatisticsProvider);
                ref.invalidate(adminReportsProvider(_selectedStatus));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test report created! Refresh to see it.')),
                );
              } else {
                print('❌ Failed to create test report');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to create test report'), backgroundColor: Colors.red),
                );
              }
            },
            tooltip: 'Create Test Report',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          print('🔄 Pull to refresh');
          ref.invalidate(reportStatisticsProvider);
          ref.invalidate(adminReportsProvider(_selectedStatus));
        },
        child: reportsAsync.when(
          data: (reports) {
            if (reports.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return _buildReportCard(context, report);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) {
            print('❌ Error in reportsAsync: $error');
            return _buildErrorState(error.toString());
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedStatus == ReportStatus.pending
                ? 'Tidak ada laporan pending'
                : 'Tidak ada laporan',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Laporan dari pengguna akan muncul di sini',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final reportService = ReportService();
              final success = await reportService.testCreateReport();
              if (success && mounted) {
                ref.invalidate(reportStatisticsProvider);
                ref.invalidate(adminReportsProvider(_selectedStatus));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test report created! Refresh to see it.')),
                );
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Test Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat laporan',
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              error,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(reportStatisticsProvider);
              ref.invalidate(adminReportsProvider(_selectedStatus));
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, Map<String, dynamic> report) {
    final status = ReportStatusExtension.fromString(
      report['status']?.toString() ?? 'pending',
    );
    final createdAt = DateTime.parse(report['created_at']);

    final reporter = report['reporter'] as Map<String, dynamic>?;
    final reportedUser = report['reported_user'] as Map<String, dynamic>?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showReportDetail(context, report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Laporan #${report['id'].toString().substring(0, 8)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withAlpha((0.1 * 255).toInt()),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status.displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _timeAgo(createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onPressed: () => _showReportOptions(context, report),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildUserChip(
                      label: 'Pelapor',
                      name: reporter?['full_name'] ?? 'Unknown',
                      avatarUrl: reporter?['avatar_url'],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  ),
                  Expanded(
                    child: _buildUserChip(
                      label: 'Terlapor',
                      name: reportedUser?['full_name'] ?? 'Unknown',
                      avatarUrl: reportedUser?['avatar_url'],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alasan Pelaporan:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report['reason']?.toString() ?? 'Tidak ada alasan',
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (report['description'] != null && 
                        report['description'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text(
                          '📝 ${report['description']}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_hasReportedContent(report))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildReportedContent(report),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasReportedContent(Map<String, dynamic> report) {
    return report['post_content'] != null || report['comment_content'] != null;
  }

  Widget _buildUserChip({
    required String label,
    required String name,
    String? avatarUrl,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportedContent(Map<String, dynamic> report) {
    final postContent = report['post_content'] as Map<String, dynamic>?;
    final commentContent = report['comment_content'] as Map<String, dynamic>?;

    if (postContent != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.article, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Konten Post yang Dilaporkan:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (report['post_author'] != null)
                  Text(
                    'Oleh: ${report['post_author']}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                postContent['content']?.toString() ?? 'Konten tidak tersedia',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            if (postContent['image_url'] != null && 
                postContent['image_url'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  postContent['image_url'],
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (commentContent != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.comment, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Komentar yang Dilaporkan:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (report['comment_author'] != null)
                  Text(
                    'Oleh: ${report['comment_author']}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                commentContent['content']?.toString() ?? 'Komentar tidak tersedia',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showReportDetail(BuildContext context, Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ReportDetailSheet(
        report: report,
        onStatusChanged: () {
          ref.invalidate(reportStatisticsProvider);
          ref.invalidate(adminReportsProvider(_selectedStatus));
        },
      ),
    );
  }

  void _showReportOptions(BuildContext context, Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Lihat Detail'),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDetail(context, report);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Hapus Laporan', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteReport(context, report['id']);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteReport(BuildContext context, String reportId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Laporan'),
        content: const Text('Apakah Anda yakin ingin menghapus laporan ini?'),
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

    if (confirm == true && mounted) {
      final facade = ref.read(communityFacadeProvider);
      final success = await facade.deleteReport(reportId);
      
      if (mounted) {
        if (success) {
          ref.invalidate(reportStatisticsProvider);
          ref.invalidate(adminReportsProvider(_selectedStatus));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Laporan berhasil dihapus')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menghapus laporan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.reviewed:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.rejected:
        return Colors.red;
    }
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) {
      return '${diff.inDays} hari lalu';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} menit lalu';
    } else {
      return 'baru saja';
    }
  }
}

// ============ REPORT DETAIL SHEET ============

class ReportDetailSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> report;
  final VoidCallback onStatusChanged;

  const ReportDetailSheet({
    super.key,
    required this.report,
    required this.onStatusChanged,
  });

  @override
  ConsumerState<ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends ConsumerState<ReportDetailSheet> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final status = ReportStatusExtension.fromString(
      widget.report['status']?.toString() ?? 'pending',
    );
    final createdAt = DateTime.parse(widget.report['created_at']);

    final reporter = widget.report['reporter'] as Map<String, dynamic>?;
    final reportedUser = widget.report['reported_user'] as Map<String, dynamic>?;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withAlpha((0.1 * 255).toInt()),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.displayName,
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(createdAt),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ID Laporan: ${widget.report['id']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Detail Pengguna',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildUserDetailCard('Pelapor', reporter),
                    const SizedBox(height: 12),
                    _buildUserDetailCard('Terlapor', reportedUser),
                    const SizedBox(height: 24),
                    const Text(
                      'Alasan Pelaporan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.report['reason']?.toString() ?? 'Tidak ada alasan',
                            style: const TextStyle(fontSize: 15),
                          ),
                          if (widget.report['description'] != null &&
                              widget.report['description'].toString().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Text(
                                widget.report['description'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (widget.report['post_content'] != null)
                      _buildPostContent(widget.report['post_content']),
                    if (widget.report['comment_content'] != null)
                      _buildCommentContent(widget.report['comment_content']),
                    const SizedBox(height: 24),
                    const Text(
                      'Tindakan Admin',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildActionButtons(context, status),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserDetailCard(String title, Map<String, dynamic>? user) {
    final userName = user?['full_name']?.toString() ?? 'Unknown';
    final userRole = user?['role']?.toString() ?? 'User';
    final avatarUrl = user?['avatar_url']?.toString();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
            child: !hasAvatar
                ? Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 20),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  userName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  userRole,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent(Map<String, dynamic> post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Konten Post yang Dilaporkan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  post['content']?.toString() ?? 'Konten tidak tersedia',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              if (post['image_url'] != null && 
                  post['image_url'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post['image_url'],
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentContent(Map<String, dynamic> comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Komentar yang Dilaporkan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              comment['content']?.toString() ?? 'Komentar tidak tersedia',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ReportStatus currentStatus) {
    final facade = ref.read(communityFacadeProvider);
    final hasPost = widget.report['post_content'] != null;
    final hasComment = widget.report['comment_content'] != null;

    if (currentStatus == ReportStatus.resolved || currentStatus == ReportStatus.rejected) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              currentStatus == ReportStatus.resolved ? Icons.check_circle : Icons.cancel,
              color: currentStatus == ReportStatus.resolved ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                currentStatus == ReportStatus.resolved
                    ? 'Laporan ini telah diselesaikan'
                    : 'Laporan ini ditolak',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : () => _markAsReviewed(facade),
                icon: const Icon(Icons.visibility),
                label: const Text('Tandai Direview'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : () => _rejectReport(facade),
                icon: const Icon(Icons.close),
                label: const Text('Tolak'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (hasPost) ...[
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _deletePostAction(facade),
            icon: const Icon(Icons.delete),
            label: const Text('Hapus Post Ini'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 0),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (hasComment) ...[
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _deleteCommentAction(facade),
            icon: const Icon(Icons.delete),
            label: const Text('Hapus Komentar Ini'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 0),
            ),
          ),
          const SizedBox(height: 8),
        ],
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : () => _warnUserAction(facade),
          icon: const Icon(Icons.warning_amber),
          label: const Text('Berikan Peringatan ke Pengguna'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size(double.infinity, 0),
          ),
        ),
      ],
    );
  }

  Future<void> _markAsReviewed(dynamic facade) async {
    setState(() => _isProcessing = true);
    final success = await facade.updateReportStatus(
      reportId: widget.report['id'],
      newStatus: ReportStatus.reviewed,
    );
    if (mounted) setState(() => _isProcessing = false);
    
    if (success && mounted) {
      widget.onStatusChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan ditandai sebagai direview')),
        );
        if (mounted) Navigator.pop(context);
      }
    }
  }

  Future<void> _rejectReport(dynamic facade) async {
    setState(() => _isProcessing = true);
    final success = await facade.updateReportStatus(
      reportId: widget.report['id'],
      newStatus: ReportStatus.rejected,
      adminNote: 'Laporan ditolak karena tidak memenuhi kriteria',
    );
    if (mounted) setState(() => _isProcessing = false);
    
    if (success && mounted) {
      widget.onStatusChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan ditolak'), backgroundColor: Colors.red),
        );
        if (mounted) Navigator.pop(context);
      }
    }
  }

  Future<void> _deletePostAction(dynamic facade) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Post'),
        content: const Text('Apakah Anda yakin ingin menghapus post ini?\n\nTindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isProcessing = true);
      final success = await facade.takeActionOnReportedContent(
        reportId: widget.report['id'],
        action: 'delete_post',
        note: 'Dihapus oleh admin berdasarkan laporan pengguna',
      );
      if (mounted) setState(() => _isProcessing = false);
      
      if (success && mounted) {
        widget.onStatusChanged();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post berhasil dihapus'), backgroundColor: Colors.green),
          );
          if (mounted) Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _deleteCommentAction(dynamic facade) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Komentar'),
        content: const Text('Apakah Anda yakin ingin menghapus komentar ini?\n\nTindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isProcessing = true);
      final success = await facade.takeActionOnReportedContent(
        reportId: widget.report['id'],
        action: 'delete_comment',
        note: 'Dihapus oleh admin berdasarkan laporan pengguna',
      );
      if (mounted) setState(() => _isProcessing = false);
      
      if (success && mounted) {
        widget.onStatusChanged();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Komentar berhasil dihapus'), backgroundColor: Colors.green),
          );
          if (mounted) Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _warnUserAction(dynamic facade) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Berikan Peringatan'),
        content: const Text('Kirim peringatan ke pengguna yang dilaporkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Kirim', style: TextStyle(color: Colors.orange))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isProcessing = true);
      final success = await facade.takeActionOnReportedContent(
        reportId: widget.report['id'],
        action: 'warn_user',
        note: 'Pengguna menerima peringatan',
      );
      if (mounted) setState(() => _isProcessing = false);
      
      if (success && mounted) {
        widget.onStatusChanged();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Peringatan berhasil dikirim'), backgroundColor: Colors.orange),
          );
          if (mounted) Navigator.pop(context);
        }
      }
    }
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.reviewed:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.rejected:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}