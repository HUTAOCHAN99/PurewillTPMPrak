// lib/ui/habit-tracker/widget/community/report_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/data/services/community/report_service.dart';
import 'package:purewill/ui/habit-tracker/widget/community/community_provider.dart';

class ReportDialog extends ConsumerStatefulWidget {
  final String reportedUserId;
  final String? postId;
  final String? commentId;
  final String reporterId;

  const ReportDialog({
    super.key,
    required this.reportedUserId,
    required this.reporterId,
    this.postId,
    this.commentId,
  });

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  final ReportService _reportService = ReportService();
  String? _selectedReason;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  List<String> _reasons = [];

  @override
  void initState() {
    super.initState();
    _loadReasons();
  }

  Future<void> _loadReasons() async {
    final reasons = await _reportService.getReportReasons();
    setState(() {
      _reasons = reasons;
    });
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih alasan pelaporan')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      print('🔍 SUBMITTING REPORT:');
      print('   reporterId: ${widget.reporterId}');
      print('   reportedUserId: ${widget.reportedUserId}');
      print('   reason: $_selectedReason');
      print('   description: ${_descriptionController.text}');
      print('   postId: ${widget.postId}');
      print('   commentId: ${widget.commentId}');

      final success = await _reportService.reportUser(
        reporterId: widget.reporterId,
        reportedUserId: widget.reportedUserId,
        reason: _selectedReason!,
        description: _descriptionController.text.isNotEmpty 
            ? _descriptionController.text 
            : null,
        postId: widget.postId,
        commentId: widget.commentId,
      );

      print('✅ Report result: $success');

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Laporan berhasil dikirim. Terima kasih!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengirim laporan. Silakan coba lagi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error submitting report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flag, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Laporkan Konten',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Mengapa Anda melaporkan konten ini?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            
            // Dropdown alasan
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  hint: const Text('Pilih alasan'),
                  isExpanded: true,
                  items: _reasons.map((reason) {
                    return DropdownMenuItem(
                      value: reason,
                      child: Text(reason),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value;
                    });
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Deskripsi tambahan
            const Text(
              'Deskripsi tambahan (opsional)',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Jelaskan detail pelaporan Anda...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Tombol aksi
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Kirim Laporan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}