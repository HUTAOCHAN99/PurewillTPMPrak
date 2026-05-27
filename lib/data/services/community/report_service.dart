// lib/data/services/community/report_service.dart
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ============ ENUMS ============

enum ReportStatus {
  pending,
  reviewed,
  resolved,
  rejected,
}

enum BanType {
  temporary,  // Ban sementara
  permanent,  // Ban permanen
}

extension ReportStatusExtension on ReportStatus {
  String get value {
    switch (this) {
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.reviewed:
        return 'reviewed';
      case ReportStatus.resolved:
        return 'resolved';
      case ReportStatus.rejected:
        return 'rejected';
    }
  }

  static ReportStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ReportStatus.pending;
      case 'reviewed':
        return ReportStatus.reviewed;
      case 'resolved':
        return ReportStatus.resolved;
      case 'rejected':
        return ReportStatus.rejected;
      default:
        return ReportStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.reviewed:
        return 'Direview';
      case ReportStatus.resolved:
        return 'Selesai';
      case ReportStatus.rejected:
        return 'Ditolak';
    }
  }
}

extension BanTypeExtension on BanType {
  String get value {
    switch (this) {
      case BanType.temporary:
        return 'temporary';
      case BanType.permanent:
        return 'permanent';
    }
  }

  static BanType fromString(String value) {
    switch (value) {
      case 'temporary':
        return BanType.temporary;
      case 'permanent':
        return BanType.permanent;
      default:
        return BanType.temporary;
    }
  }

  String get displayName {
    switch (this) {
      case BanType.temporary:
        return 'Sementara';
      case BanType.permanent:
        return 'Permanen';
    }
  }
}

class ReportService {
  final SupabaseClient _supabase;

  ReportService() : _supabase = Supabase.instance.client;

  // ============ CREATE REPORT (USER) ============

  Future<bool> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? description,
    String? postId,
    String? commentId,
    String? communityId,
  }) async {
    try {
      await _supabase.from('user_reports').insert({
        'reporter_id': reporterId,
        'reported_user_id': reportedUserId,
        'reason': reason,
        'description': description,
        'post_id': postId,
        'comment_id': commentId,
        'community_id': communityId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      developer.log('✅ Report created: reported user $reportedUserId by $reporterId');
      return true;
    } catch (e) {
      developer.log('❌ Error creating report: $e');
      return false;
    }
  }

  Future<List<String>> getReportReasons() async {
    return [
      'Spam atau iklan yang tidak diinginkan',
      'Konten pornografi atau tidak pantas',
      'Ujaran kebencian atau pelecehan',
      'Penipuan atau penyesatan',
      'Pencurian identitas',
      'Pelecehan atau intimidasi',
      'Pembulian atau perundungan',
      'Informasi pribadi yang sensitif',
      'Pelanggaran hak cipta',
      'Kata-kata kasar atau tidak sopan',
      'Konten kekerasan',
      'Lainnya'
    ];
  }

  // ============ BLOCK USER ============

  Future<bool> blockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    try {
      await _supabase.from('user_blocks').insert({
        'blocker_id': blockerId,
        'blocked_user_id': blockedUserId,
        'created_at': DateTime.now().toIso8601String(),
      });

      developer.log('✅ User blocked: $blockedUserId by $blockerId');
      return true;
    } catch (e) {
      developer.log('❌ Error blocking user: $e');
      return false;
    }
  }

  Future<bool> isUserBlocked({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      final response = await _supabase
          .from('user_blocks')
          .select()
          .or('(blocker_id.eq.$currentUserId,blocked_user_id.eq.$targetUserId),'
              '(blocker_id.eq.$targetUserId,blocked_user_id.eq.$currentUserId)')
          .maybeSingle();

      return response != null;
    } catch (e) {
      developer.log('Error checking block status: $e');
      return false;
    }
  }

  // ============ BAN USER ============

  Future<bool> banUser({
    required String adminId,
    required String userId,
    required String reason,
    required BanType banType,
    int? durationHours,
    String? reportId,
  }) async {
    try {
      final now = DateTime.now();
      DateTime? expiresAt;

      if (banType == BanType.temporary && durationHours != null) {
        expiresAt = now.add(Duration(hours: durationHours));
      }

      await _supabase.from('user_bans').insert({
        'admin_id': adminId,
        'user_id': userId,
        'reason': reason,
        'ban_type': banType.value,
        'duration_hours': durationHours,
        'expires_at': expiresAt?.toIso8601String(),
        'report_id': reportId,
        'status': 'active',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      // Update user role menjadi banned
      await _supabase
          .from('profiles')
          .update({'role': 'banned'})
          .eq('user_id', userId);

      // Kirim notifikasi ke user yang diban
      await _createBanNotification(
        userId: userId,
        reason: reason,
        banType: banType,
        expiresAt: expiresAt,
      );

      developer.log('✅ User $userId banned by admin $adminId, type: ${banType.value}');
      return true;
    } catch (e) {
      developer.log('❌ Error banning user: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> checkUserBanStatus(String userId) async {
    try {
      final ban = await _supabase
          .from('user_bans')
          .select('*')
          .eq('user_id', userId)
          .eq('status', 'active')
          .maybeSingle();

      if (ban == null) return null;

      // Cek apakah ban sudah expired
      final expiresAt = ban['expires_at'] as String?;
      if (expiresAt != null) {
        final expiryDate = DateTime.parse(expiresAt);
        if (DateTime.now().isAfter(expiryDate)) {
          // Ban sudah expired, update status
          await _supabase
              .from('user_bans')
              .update({'status': 'expired'})
              .eq('id', ban['id']);

          // Kembalikan role user
          await _supabase
              .from('profiles')
              .update({'role': 'user'})
              .eq('user_id', userId);

          return null;
        }
      }

      return ban;
    } catch (e) {
      developer.log('Error checking ban status: $e');
      return null;
    }
  }

  Future<bool> canUserAccessCommunity(String userId) async {
    try {
      final banStatus = await checkUserBanStatus(userId);
      return banStatus == null;
    } catch (e) {
      return true;
    }
  }

  Future<String?> getUserBanMessage(String userId) async {
    try {
      final ban = await checkUserBanStatus(userId);
      if (ban == null) return null;

      final expiresAt = ban['expires_at'] as String?;
      final banType = ban['ban_type'] as String;
      final reason = ban['reason'] as String;

      if (banType == 'temporary' && expiresAt != null) {
        final expiryDate = DateTime.parse(expiresAt);
        return 'Akun Anda sedang di-ban sementara.\n\nAlasan: $reason\n\nBan akan berakhir pada: ${_formatDateTime(expiryDate)}\n\nSilakan hubungi admin jika ingin mengajukan banding.';
      } else {
        return 'Akun Anda telah di-ban permanen.\n\nAlasan: $reason\n\nSilakan hubungi admin di ahmadzhofir1808@gmail.com untuk mengajukan banding.';
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> openAppealEmail() async {
    final currentUser = _supabase.auth.currentUser;
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'ahmadzhofir1808@gmail.com',
      query: encodeQueryParameters(<String, String>{
        'subject': 'BANDING AKUN - PureWill - ${currentUser?.id ?? ''}',
        'body': '''
Halo Admin PureWill,

Saya ingin mengajukan banding atas ban akun saya.

Informasi akun:
- User ID: ${currentUser?.id ?? 'Tidak diketahui'}
- Email: ${currentUser?.email ?? 'Tidak diketahui'}

Alasan banding:
(Silakan jelaskan alasan Anda di sini dengan detail)

Saya berjanji akan mematuhi aturan komunitas PureWill ke depannya.

Terima kasih atas perhatiannya.

Hormat saya,
${currentUser?.email ?? 'Pengguna PureWill'}
''',
      }),
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        developer.log('Cannot launch email');
      }
    } catch (e) {
      developer.log('Error opening email: $e');
    }
  }

  // ============ APPEAL (BANDING) ============

  Future<bool> createAppeal({
    required String userId,
    required String banId,
    required String reason,
  }) async {
    try {
      await _supabase.from('user_appeals').insert({
        'user_id': userId,
        'ban_id': banId,
        'reason': reason,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Kirim notifikasi ke admin
      await _createAppealNotification(userId: userId, reason: reason);

      developer.log('✅ Appeal created for user $userId');
      return true;
    } catch (e) {
      developer.log('❌ Error creating appeal: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAllAppeals({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('user_appeals')
          .select('''
            *,
            user:profiles!user_appeals_user_id_fkey(
              user_id,
              full_name,
              email,
              avatar_url
            ),
            ban:user_bans!user_appeals_ban_id_fkey(
              id,
              reason,
              ban_type,
              duration_hours,
              created_at,
              expires_at
            )
          ''');

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      developer.log('Error getting appeals: $e');
      return [];
    }
  }

  Future<bool> processAppeal({
    required String appealId,
    required String adminId,
    required String status,
    String? adminNote,
  }) async {
    try {
      if (status == 'approved') {
        final appeal = await _supabase
            .from('user_appeals')
            .select('user_id, ban_id')
            .eq('id', appealId)
            .single();

        await _supabase
            .from('user_bans')
            .update({'status': 'appealed'})
            .eq('id', appeal['ban_id']);

        await _supabase
            .from('profiles')
            .update({'role': 'user'})
            .eq('user_id', appeal['user_id']);

        await _createAppealApprovedNotification(
          userId: appeal['user_id'],
          adminNote: adminNote,
        );
      } else {
        final appeal = await _supabase
            .from('user_appeals')
            .select('user_id')
            .eq('id', appealId)
            .single();

        await _createAppealRejectedNotification(
          userId: appeal['user_id'],
          adminNote: adminNote,
        );
      }

      await _supabase
          .from('user_appeals')
          .update({
            'status': status,
            'admin_id': adminId,
            'admin_note': adminNote,
            'processed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', appealId);

      developer.log('✅ Appeal $appealId processed: $status');
      return true;
    } catch (e) {
      developer.log('Error processing appeal: $e');
      return false;
    }
  }

  // ============ ADMIN: GET REPORTS ============

  Future<List<Map<String, dynamic>>> getAllReports({
    ReportStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      developer.log('📋 Fetching reports from database...');
      developer.log('   Status filter: ${status?.value ?? 'all'}');

      var queryBuilder = _supabase
          .from('user_reports')
          .select('*');

      if (status != null) {
        queryBuilder = queryBuilder.eq('status', status.value);
        developer.log('🔍 Filtering by status: ${status.value}');
      }

      final reportsData = await queryBuilder
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      developer.log('📊 Found ${reportsData.length} reports from user_reports table');

      if (reportsData.isEmpty) {
        developer.log('⚠️ No reports found in user_reports table');
        return [];
      }

      final List<Map<String, dynamic>> reports = [];

      for (var report in reportsData) {
        final enrichedReport = Map<String, dynamic>.from(report);

        developer.log('   Processing report ID: ${report['id']}');

        // Fetch reporter profile separately
        try {
          final reporterId = report['reporter_id'] as String?;
          if (reporterId != null && reporterId.isNotEmpty) {
            final reporterProfile = await _supabase
                .from('profiles')
                .select('user_id, full_name, avatar_url, role')
                .eq('user_id', reporterId)
                .maybeSingle();

            if (reporterProfile != null) {
              enrichedReport['reporter'] = reporterProfile;
              developer.log('      Reporter name: ${reporterProfile['full_name']}');
            } else {
              enrichedReport['reporter'] = {
                'user_id': reporterId,
                'full_name': 'Unknown User',
                'avatar_url': null,
                'role': 'user',
              };
            }
          }
        } catch (e) {
          developer.log('      Error fetching reporter profile: $e');
          enrichedReport['reporter'] = {
            'user_id': report['reporter_id'],
            'full_name': 'Unknown User',
            'avatar_url': null,
            'role': 'user',
          };
        }

        // Fetch reported user profile separately
        try {
          final reportedUserId = report['reported_user_id'] as String?;
          if (reportedUserId != null && reportedUserId.isNotEmpty) {
            final reportedProfile = await _supabase
                .from('profiles')
                .select('user_id, full_name, avatar_url, role')
                .eq('user_id', reportedUserId)
                .maybeSingle();

            if (reportedProfile != null) {
              enrichedReport['reported_user'] = reportedProfile;
              developer.log('      Reported name: ${reportedProfile['full_name']}');
            } else {
              enrichedReport['reported_user'] = {
                'user_id': reportedUserId,
                'full_name': 'Unknown User',
                'avatar_url': null,
                'role': 'user',
              };
            }
          }
        } catch (e) {
          developer.log('      Error fetching reported user profile: $e');
          enrichedReport['reported_user'] = {
            'user_id': report['reported_user_id'],
            'full_name': 'Unknown User',
            'avatar_url': null,
            'role': 'user',
          };
        }

        // Fetch post content if exists
        final postId = report['post_id'] as String?;
        if (postId != null && postId.isNotEmpty) {
          try {
            final post = await _supabase
                .from('community_posts')
                .select('id, content, image_url, created_at, author_id')
                .eq('id', postId)
                .maybeSingle();

            if (post != null) {
              enrichedReport['post_content'] = post;

              final authorId = post['author_id'] as String?;
              if (authorId != null && authorId.isNotEmpty) {
                final author = await _supabase
                    .from('profiles')
                    .select('full_name')
                    .eq('user_id', authorId)
                    .maybeSingle();
                if (author != null) {
                  enrichedReport['post_author'] = author['full_name'];
                }
              }
            }
          } catch (e) {
            developer.log('      Error fetching post: $e');
          }
        }

        // Fetch comment content if exists
        final commentId = report['comment_id'] as String?;
        if (commentId != null && commentId.isNotEmpty) {
          try {
            final comment = await _supabase
                .from('community_comments')
                .select('id, content, created_at, author_id')
                .eq('id', commentId)
                .maybeSingle();

            if (comment != null) {
              enrichedReport['comment_content'] = comment;

              final authorId = comment['author_id'] as String?;
              if (authorId != null && authorId.isNotEmpty) {
                final author = await _supabase
                    .from('profiles')
                    .select('full_name')
                    .eq('user_id', authorId)
                    .maybeSingle();
                if (author != null) {
                  enrichedReport['comment_author'] = author['full_name'];
                }
              }
            }
          } catch (e) {
            developer.log('      Error fetching comment: $e');
          }
        }

        reports.add(enrichedReport);
        developer.log('   ✅ Successfully processed report: ${report['id']}');
      }

      developer.log('✅ Successfully processed ${reports.length} reports');
      return reports;
    } catch (e, stackTrace) {
      developer.log('❌ Error getting reports: $e');
      developer.log('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getReportById(String reportId) async {
    try {
      final report = await _supabase
          .from('user_reports')
          .select('*')
          .eq('id', reportId)
          .maybeSingle();

      if (report == null) return null;

      final enrichedReport = Map<String, dynamic>.from(report);

      final reporterId = report['reporter_id'] as String?;
      if (reporterId != null && reporterId.isNotEmpty) {
        final reporterProfile = await _supabase
            .from('profiles')
            .select('user_id, full_name, avatar_url, role')
            .eq('user_id', reporterId)
            .maybeSingle();
        if (reporterProfile != null) {
          enrichedReport['reporter'] = reporterProfile;
        }
      }

      final reportedUserId = report['reported_user_id'] as String?;
      if (reportedUserId != null && reportedUserId.isNotEmpty) {
        final reportedProfile = await _supabase
            .from('profiles')
            .select('user_id, full_name, avatar_url, role')
            .eq('user_id', reportedUserId)
            .maybeSingle();
        if (reportedProfile != null) {
          enrichedReport['reported_user'] = reportedProfile;
        }
      }

      final postId = report['post_id'] as String?;
      if (postId != null && postId.isNotEmpty) {
        final post = await _supabase
            .from('community_posts')
            .select('id, content, image_url, created_at, author_id')
            .eq('id', postId)
            .maybeSingle();
        if (post != null) {
          enrichedReport['post_content'] = post;

          final authorId = post['author_id'] as String?;
          if (authorId != null && authorId.isNotEmpty) {
            final author = await _supabase
                .from('profiles')
                .select('full_name')
                .eq('user_id', authorId)
                .maybeSingle();
            if (author != null) {
              enrichedReport['post_author'] = author['full_name'];
            }
          }
        }
      }

      final commentId = report['comment_id'] as String?;
      if (commentId != null && commentId.isNotEmpty) {
        final comment = await _supabase
            .from('community_comments')
            .select('id, content, created_at, author_id')
            .eq('id', commentId)
            .maybeSingle();
        if (comment != null) {
          enrichedReport['comment_content'] = comment;

          final authorId = comment['author_id'] as String?;
          if (authorId != null && authorId.isNotEmpty) {
            final author = await _supabase
                .from('profiles')
                .select('full_name')
                .eq('user_id', authorId)
                .maybeSingle();
            if (author != null) {
              enrichedReport['comment_author'] = author['full_name'];
            }
          }
        }
      }

      return enrichedReport;
    } catch (e) {
      developer.log('❌ Error getting report by ID: $e');
      return null;
    }
  }

  // ============ ADMIN: UPDATE REPORT STATUS ============

  Future<bool> updateReportStatus({
    required String reportId,
    required ReportStatus newStatus,
    String? adminNote,
  }) async {
    try {
      final updateData = {
        'status': newStatus.value,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (adminNote != null) {
        updateData['admin_note'] = adminNote;
      }

      await _supabase
          .from('user_reports')
          .update(updateData)
          .eq('id', reportId);

      developer.log('✅ Report $reportId status updated to ${newStatus.value}');
      return true;
    } catch (e) {
      developer.log('❌ Error updating report status: $e');
      return false;
    }
  }

  // ============ ADMIN: STATISTICS ============

  Future<int> getPendingReportsCount() async {
    try {
      final response = await _supabase
          .from('user_reports')
          .select('id')
          .eq('status', 'pending');

      final count = response.length;
      developer.log('📊 Pending reports count: $count');
      return count;
    } catch (e) {
      developer.log('Error getting pending reports count: $e');
      return 0;
    }
  }

  Future<Map<String, int>> getReportStatistics() async {
    try {
      final pendingResponse = await _supabase
          .from('user_reports')
          .select('id')
          .eq('status', 'pending');

      final reviewedResponse = await _supabase
          .from('user_reports')
          .select('id')
          .eq('status', 'reviewed');

      final resolvedResponse = await _supabase
          .from('user_reports')
          .select('id')
          .eq('status', 'resolved');

      final rejectedResponse = await _supabase
          .from('user_reports')
          .select('id')
          .eq('status', 'rejected');

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final todayResponse = await _supabase
          .from('user_reports')
          .select('id')
          .gte('created_at', startOfDay.toIso8601String());

      final allReportsResponse = await _supabase
          .from('user_reports')
          .select('id');

      final stats = {
        'pending': pendingResponse.length,
        'reviewed': reviewedResponse.length,
        'resolved': resolvedResponse.length,
        'rejected': rejectedResponse.length,
        'today': todayResponse.length,
        'total': allReportsResponse.length,
      };

      developer.log('📊 Report statistics: $stats');
      return stats;
    } catch (e) {
      developer.log('Error getting report statistics: $e');
      return {
        'pending': 0,
        'reviewed': 0,
        'resolved': 0,
        'rejected': 0,
        'today': 0,
        'total': 0,
      };
    }
  }

  // ============ ADMIN: DELETE REPORT ============

  Future<bool> deleteReport(String reportId) async {
    try {
      await _supabase.from('user_reports').delete().eq('id', reportId);
      developer.log('✅ Report $reportId deleted');
      return true;
    } catch (e) {
      developer.log('❌ Error deleting report: $e');
      return false;
    }
  }

  // ============ ADMIN: TAKE ACTION ============

  Future<bool> takeActionOnReportedContent({
    required String reportId,
    required String action,
    String? note,
  }) async {
    try {
      final report = await getReportById(reportId);
      if (report == null) return false;

      bool actionSuccess = false;

      switch (action) {
        case 'delete_post':
          final postId = report['post_id'] as String?;
          if (postId != null && postId.isNotEmpty) {
            await _supabase
                .from('community_posts')
                .update({'deleted_at': DateTime.now().toIso8601String()})
                .eq('id', postId);
            actionSuccess = true;
            developer.log('✅ Post $postId deleted');
          }
          break;

        case 'delete_comment':
          final commentId = report['comment_id'] as String?;
          if (commentId != null && commentId.isNotEmpty) {
            await _supabase
                .from('community_comments')
                .update({'deleted_at': DateTime.now().toIso8601String()})
                .eq('id', commentId);
            actionSuccess = true;
            developer.log('✅ Comment $commentId deleted');
          }
          break;

        case 'warn_user':
          await _createWarningNotification(
            userId: report['reported_user_id'] as String,
            reason: report['reason'] as String,
            description: report['description'] as String?,
          );
          actionSuccess = true;
          break;
      }

      if (actionSuccess) {
        await updateReportStatus(
          reportId: reportId,
          newStatus: ReportStatus.resolved,
          adminNote: note,
        );
      }

      return actionSuccess;
    } catch (e) {
      developer.log('❌ Error taking action on report: $e');
      return false;
    }
  }

  // ============ DEBUG METHOD ============

  Future<void> debugCheckReports() async {
    try {
      developer.log('========== DEBUG REPORT CHECK ==========');

      final currentUser = _supabase.auth.currentUser;
      developer.log('👤 Current User ID: ${currentUser?.id}');

      if (currentUser != null) {
        final profile = await _supabase
            .from('profiles')
            .select('role, full_name')
            .eq('user_id', currentUser.id)
            .maybeSingle();
        developer.log('👤 User Role: ${profile?['role']}');
        developer.log('👤 User Name: ${profile?['full_name']}');
      }

      developer.log('\n📊 Direct query to user_reports...');
      try {
        final directQuery = await _supabase
            .from('user_reports')
            .select('*');
        developer.log('✅ Direct query success! Found ${directQuery.length} reports');
        for (var report in directQuery) {
          developer.log('   - Report ID: ${report['id']}, Status: ${report['status']}, Reason: ${report['reason']}');
        }
      } catch (e) {
        developer.log('❌ Direct query failed: $e');
      }

      developer.log('\n📊 Query with status filter...');
      try {
        final pendingReports = await _supabase
            .from('user_reports')
            .select('*')
            .eq('status', 'pending');
        developer.log('✅ Found ${pendingReports.length} pending reports');
        for (var report in pendingReports) {
          developer.log('   - ${report['id']}: ${report['reason']}');
        }
      } catch (e) {
        developer.log('❌ Query with filter failed: $e');
      }

      developer.log('\n📊 Testing profile fetch...');
      try {
        final testProfile = await _supabase
            .from('profiles')
            .select('user_id, full_name, role')
            .limit(1);
        developer.log('✅ Profile fetch success! Found ${testProfile.length} profiles');
        if (testProfile.isNotEmpty) {
          developer.log('   Sample: ${testProfile.first['full_name']} (${testProfile.first['role']})');
        }
      } catch (e) {
        developer.log('❌ Profile fetch failed: $e');
      }

      developer.log('========== DEBUG COMPLETE ==========');
    } catch (e) {
      developer.log('❌ Debug error: $e');
    }
  }

  // ============ PRIVATE METHODS ============

  Future<void> _createBanNotification({
    required String userId,
    required String reason,
    required BanType banType,
    DateTime? expiresAt,
  }) async {
    String message;
    if (banType == BanType.temporary && expiresAt != null) {
      final duration = expiresAt.difference(DateTime.now());
      final hours = duration.inHours;
      message = 'Akun Anda telah dibanned sementara selama $hours jam karena: $reason\n\nBan akan berakhir pada: ${_formatDateTime(expiresAt)}';
    } else {
      message = 'Akun Anda telah dibanned permanen karena: $reason\n\nHubungi admin di ahmadzhofir1808@gmail.com untuk mengajukan banding.';
    }

    await _supabase.from('community_notifications').insert({
      'user_id': userId,
      'type': 'ban_warning',
      'title': 'Peringatan: Akun Anda Di-ban',
      'message': message,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _createWarningNotification({
    required String userId,
    required String reason,
    String? description,
  }) async {
    try {
      await _supabase.from('community_notifications').insert({
        'user_id': userId,
        'type': 'warning',
        'title': 'Peringatan dari Admin',
        'message': 'Anda menerima peringatan karena: $reason${description != null ? '\n\nDetail: $description' : ''}\n\nHarap perhatikan aturan komunitas kami.',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      developer.log('✅ Warning notification sent to user: $userId');
    } catch (e) {
      developer.log('Error creating warning notification: $e');
    }
  }

  Future<void> _createAppealNotification({
    required String userId,
    required String reason,
  }) async {
    final admins = await _supabase
        .from('profiles')
        .select('user_id')
        .eq('role', 'admin');

    for (var admin in admins) {
      await _supabase.from('community_notifications').insert({
        'user_id': admin['user_id'],
        'type': 'appeal',
        'title': 'Permintaan Banding Baru',
        'message': 'User $userId mengajukan banding dengan alasan: $reason',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _createAppealApprovedNotification({
    required String userId,
    String? adminNote,
  }) async {
    await _supabase.from('community_notifications').insert({
      'user_id': userId,
      'type': 'appeal_response',
      'title': 'Banding Anda Diterima',
      'message': 'Banding Anda telah diterima. Akun Anda telah diaktifkan kembali.\n\nCatatan admin: ${adminNote ?? "Selamat bergabung kembali!"}',
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _createAppealRejectedNotification({
    required String userId,
    String? adminNote,
  }) async {
    await _supabase.from('community_notifications').insert({
      'user_id': userId,
      'type': 'appeal_response',
      'title': 'Banding Anda Ditolak',
      'message': 'Banding Anda telah ditolak.\n\nCatatan admin: ${adminNote ?? "Keputusan tidak dapat diubah."}',
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ============ TEST METHOD ============

  Future<bool> testCreateReport() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        developer.log('No user logged in for test report');
        return false;
      }

      final users = await _supabase
          .from('profiles')
          .select('user_id')
          .neq('user_id', currentUser.id)
          .limit(1);

      if (users.isEmpty) {
        developer.log('No other user found for test report');
        return false;
      }

      final reportedUserId = users[0]['user_id'];

      await _supabase.from('user_reports').insert({
        'reporter_id': currentUser.id,
        'reported_user_id': reportedUserId,
        'reason': 'Test Report',
        'description': 'This is a test report created for debugging purposes',
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      developer.log('✅ Test report created successfully');
      return true;
    } catch (e) {
      developer.log('❌ Error creating test report: $e');
      return false;
    }
  }

  // ============ HELPER METHODS ============

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}