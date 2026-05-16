// lib/data/services/community/report_service.dart
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final SupabaseClient _supabase;

  ReportService() : _supabase = Supabase.instance.client;

  // ============ REPORT METHODS ============

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

      developer.log('✅ User reported: $reportedUserId');
      return true;
    } catch (e) {
      developer.log('❌ Error reporting user: $e');
      return false;
    }
  }

  Future<List<String>> getReportReasons() async {
    // Daftar alasan pelaporan standar
    return [
      'Spam atau iklan yang tidak diinginkan',
      'Konten pornografi atau tidak pantas',
      'Ujaran kebencian atau pelecehan',
      'Penipuan atau penyesatan',
      'Pencurian identitas',
      'Peletakan atau pelecehan',
      'Pembulian atau intimidasi',
      'Informasi pribadi',
      'Pelanggaran hak cipta',
      'Lainnya'
    ];
  }

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

      developer.log('✅ User blocked: $blockedUserId');
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
}