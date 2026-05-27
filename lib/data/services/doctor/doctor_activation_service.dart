// lib/data/services/doctor/doctor_activation_service.dart
import 'dart:developer' as dev;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

final doctorActivationServiceProvider = Provider(
  (ref) => DoctorActivationService(),
);

class DoctorActivationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Random _random = Random();

  // Generate 6 digit OTP
  String _generateOTP() {
    return (_random.nextInt(900000) + 100000).toString();
  }

  // Get current user ID
  Future<String?> _getCurrentUserId() async {
    final user = _supabase.auth.currentUser;
    return user?.id;
  }

  // Get user role
  Future<String?> _getUserRole(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();
      return response?['role'] as String?;
    } catch (e) {
      dev.log('Error getting user role: $e', name: 'DOCTOR_ACTIVATION');
      return null;
    }
  }

  // Helper to show OTP in console and copy to clipboard
  Future<void> _showOTP({
    required String otpCode,
    required String userEmail,
    required String fullName,
    BuildContext? context,
  }) async {
    // Print to console
    dev.log('╔════════════════════════════════════════════════════════════╗', name: 'DOCTOR_ACTIVATION');
    dev.log('║                    DOCTOR ACTIVATION OTP                    ║', name: 'DOCTOR_ACTIVATION');
    dev.log('╠════════════════════════════════════════════════════════════╣', name: 'DOCTOR_ACTIVATION');
    dev.log('║ To Email: $userEmail', name: 'DOCTOR_ACTIVATION');
    dev.log('║ User Name: $fullName', name: 'DOCTOR_ACTIVATION');
    dev.log('║ OTP Code: $otpCode', name: 'DOCTOR_ACTIVATION');
    dev.log('║                                                            ║', name: 'DOCTOR_ACTIVATION');
    dev.log('║ Enter this OTP in the app to activate doctor account       ║', name: 'DOCTOR_ACTIVATION');
    dev.log('╚════════════════════════════════════════════════════════════╝', name: 'DOCTOR_ACTIVATION');
    
    // Copy to clipboard
    await Clipboard.setData(ClipboardData(text: otpCode));
    dev.log('📋 OTP copied to clipboard: $otpCode', name: 'DOCTOR_ACTIVATION');
    
    // Show snackbar if context provided (with mounted check)
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP: $otpCode (copied to clipboard)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // USER: Request aktivasi dokter
  Future<ActivationResult> requestDoctorActivation({
    required String userId,
    required String userEmail,
    required String fullName,
  }) async {
    try {
      dev.log('=== REQUEST DOCTOR ACTIVATION ===', name: 'DOCTOR_ACTIVATION');
      dev.log('User ID: $userId', name: 'DOCTOR_ACTIVATION');
      dev.log('User Email: $userEmail', name: 'DOCTOR_ACTIVATION');
      dev.log('Full Name: $fullName', name: 'DOCTOR_ACTIVATION');
      
      // Check current role
      final currentRole = await _getUserRole(userId);
      
      if (currentRole == 'doctor') {
        return ActivationResult(
          success: false,
          error: 'Akun Anda sudah berstatus dokter',
        );
      }

      if (currentRole == 'admin') {
        return ActivationResult(
          success: false,
          error: 'Admin tidak perlu aktivasi dokter',
        );
      }

      // Check if already has pending request
      final existingRequest = await _supabase
          .from('doctor_activation_requests')
          .select()
          .eq('user_id', userId)
          .eq('status', 'pending')
          .maybeSingle();
      
      if (existingRequest != null) {
        return ActivationResult(
          success: false,
          error: 'Anda sudah memiliki request yang sedang diproses',
          requestId: existingRequest['id'] as String?,
        );
      }

      // Check if already has approved request waiting for OTP
      final approvedRequest = await _supabase
          .from('doctor_activation_requests')
          .select()
          .eq('user_id', userId)
          .eq('status', 'approved')
          .maybeSingle();
      
      if (approvedRequest != null) {
        return ActivationResult(
          success: false,
          error: 'Request Anda sudah disetujui. Silakan masukkan OTP.',
          requestId: approvedRequest['id'] as String?,
        );
      }

      // Create activation request
      final response = await _supabase
          .from('doctor_activation_requests')
          .insert({
            'user_id': userId,
            'user_email': userEmail,
            'full_name': fullName,
            'status': 'pending',
            'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select();
      
      dev.log('Request created: ${response[0]['id']}', name: 'DOCTOR_ACTIVATION');

      return ActivationResult(
        success: true,
        requestId: response[0]['id'] as String?,
        message: 'Request aktivasi berhasil dikirim. Menunggu persetujuan admin.',
      );
    } catch (e, stackTrace) {
      dev.log('Error: $e', error: e, stackTrace: stackTrace, name: 'DOCTOR_ACTIVATION');
      return ActivationResult(
        success: false,
        error: 'Gagal mengirim request: ${e.toString()}',
      );
    }
  }

  // ADMIN: Approve request and send OTP
  Future<ActivationResult> approveDoctorActivation({
    required String requestId,
    required String adminId,
    BuildContext? context,
  }) async {
    try {
      dev.log('=== ADMIN APPROVE REQUEST ===', name: 'DOCTOR_ACTIVATION');
      dev.log('Request ID: $requestId', name: 'DOCTOR_ACTIVATION');
      dev.log('Admin ID: $adminId', name: 'DOCTOR_ACTIVATION');
      
      // Verify admin role
      final adminRole = await _getUserRole(adminId);
      if (adminRole != 'admin') {
        return ActivationResult(
          success: false,
          error: 'Hanya admin yang dapat approve request',
        );
      }
      
      // Get request details
      final request = await _supabase
          .from('doctor_activation_requests')
          .select()
          .eq('id', requestId)
          .maybeSingle();
      
      if (request == null) {
        return ActivationResult(
          success: false,
          error: 'Request tidak ditemukan',
        );
      }
      
      if (request['status'] != 'pending') {
        return ActivationResult(
          success: false,
          error: 'Request sudah diproses',
        );
      }

      final userId = request['user_id'] as String;
      final userEmail = request['user_email'] as String;
      final fullName = request['full_name'] as String;
      final otpCode = _generateOTP();
      final expiresAt = DateTime.now().add(const Duration(hours: 24));
      
      // 1. Update request status to approved with OTP
      await _supabase
          .from('doctor_activation_requests')
          .update({
            'status': 'approved',
            'approved_by': adminId,
            'approved_at': DateTime.now().toIso8601String(),
            'otp_code': otpCode,
            'expires_at': expiresAt.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
      
      // 2. Save OTP to temp table
      try {
        // Expire old OTPs
        await _supabase
            .from('doctor_otp_temp')
            .update({'status': 'expired', 'updated_at': DateTime.now().toIso8601String()})
            .eq('user_id', userId)
            .eq('purpose', 'doctor_activation')
            .eq('status', 'active');
        
        // Insert new OTP
        await _supabase.from('doctor_otp_temp').insert({
          'user_id': userId,
          'otp_code': otpCode,
          'purpose': 'doctor_activation',
          'status': 'active',
          'expires_at': expiresAt.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        });
        
        dev.log('OTP $otpCode saved for user $userId', name: 'DOCTOR_ACTIVATION');
      } catch (e) {
        dev.log('Error saving OTP: $e', name: 'DOCTOR_ACTIVATION');
      }
      
      // 3. Show OTP to admin (for now, email will be implemented later)
      await _showOTP(
        otpCode: otpCode,
        userEmail: userEmail,
        fullName: fullName,
        context: context,
      );

      dev.log('=== APPROVE REQUEST SUCCESS ===', name: 'DOCTOR_ACTIVATION');

      return ActivationResult(
        success: true,
        message: 'Request approved. OTP: $otpCode',
        otpCode: otpCode,
        requestId: requestId,
      );
    } catch (e, stackTrace) {
      dev.log('Error: $e', error: e, stackTrace: stackTrace, name: 'DOCTOR_ACTIVATION');
      return ActivationResult(
        success: false,
        error: 'Gagal approve request: ${e.toString()}',
      );
    }
  }

  // USER: Verify OTP and become doctor
  Future<ActivationResult> verifyDoctorActivationOTP({
    required String userId,
    required String otp,
  }) async {
    try {
      dev.log('=== VERIFY OTP ===', name: 'DOCTOR_ACTIVATION');
      dev.log('User ID: $userId', name: 'DOCTOR_ACTIVATION');
      dev.log('OTP: $otp', name: 'DOCTOR_ACTIVATION');
      
      // Check OTP in temp table
      final tempOtp = await _supabase
          .from('doctor_otp_temp')
          .select()
          .eq('user_id', userId)
          .eq('otp_code', otp)
          .eq('purpose', 'doctor_activation')
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();
      
      dev.log('Temp OTP result: $tempOtp', name: 'DOCTOR_ACTIVATION');
      
      if (tempOtp == null) {
        // Check if OTP exists but expired
        final expiredOtp = await _supabase
            .from('doctor_otp_temp')
            .select()
            .eq('user_id', userId)
            .eq('otp_code', otp)
            .eq('purpose', 'doctor_activation')
            .maybeSingle();
        
        if (expiredOtp != null) {
          final expiresAt = DateTime.parse(expiredOtp['expires_at'] as String);
          if (DateTime.now().isAfter(expiresAt)) {
            return ActivationResult(
              success: false,
              error: 'OTP telah kadaluarsa. Silakan minta OTP baru ke admin.',
            );
          }
        }
        
        return ActivationResult(
          success: false,
          error: 'OTP tidak valid. Periksa kembali kode OTP Anda.',
        );
      }
      
      // Check if request is approved
      final request = await _supabase
          .from('doctor_activation_requests')
          .select()
          .eq('user_id', userId)
          .eq('status', 'approved')
          .maybeSingle();
      
      dev.log('Request result: $request', name: 'DOCTOR_ACTIVATION');
      
      if (request == null) {
        return ActivationResult(
          success: false,
          error: 'Request tidak ditemukan atau belum disetujui admin',
        );
      }
      
      // Update user role to doctor
      final profileUpdate = await _supabase
          .from('profiles')
          .update({
            'role': 'doctor',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .select();
      
      dev.log('Profile update result: $profileUpdate', name: 'DOCTOR_ACTIVATION');
      
      // Update request status to completed
      await _supabase
          .from('doctor_activation_requests')
          .update({
            'status': 'completed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', request['id']);
      
      // Mark OTP as used
      await _supabase
          .from('doctor_otp_temp')
          .update({
            'status': 'used',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tempOtp['id']);
      
      // Verify role has changed
      final verifyRole = await _getUserRole(userId);
      dev.log('User role after update: ${verifyRole ?? "null"}', name: 'DOCTOR_ACTIVATION');
      
      if (verifyRole != 'doctor') {
        return ActivationResult(
          success: false,
          error: 'Gagal mengupdate role, silakan coba lagi.',
        );
      }
      
      dev.log('=== VERIFY OTP SUCCESS ===', name: 'DOCTOR_ACTIVATION');
      
      return ActivationResult(
        success: true,
        message: 'Selamat! Akun dokter Anda telah berhasil diaktifkan.',
      );
    } catch (e, stackTrace) {
      dev.log('Error: $e', error: e, stackTrace: stackTrace, name: 'DOCTOR_ACTIVATION');
      return ActivationResult(
        success: false,
        error: 'Verifikasi gagal: ${e.toString()}',
      );
    }
  }

  // ADMIN: Resend OTP
  Future<ActivationResult> resendOTP({
    required String requestId,
    BuildContext? context,
  }) async {
    try {
      dev.log('=== RESEND OTP ===', name: 'DOCTOR_ACTIVATION');
      dev.log('Request ID: $requestId', name: 'DOCTOR_ACTIVATION');
      
      // Get request details
      final request = await _supabase
          .from('doctor_activation_requests')
          .select()
          .eq('id', requestId)
          .maybeSingle();
      
      if (request == null) {
        return ActivationResult(
          success: false,
          error: 'Request tidak ditemukan',
        );
      }
      
      if (request['status'] != 'approved') {
        return ActivationResult(
          success: false,
          error: 'Request belum disetujui atau sudah selesai',
        );
      }
      
      final userId = request['user_id'] as String;
      final userEmail = request['user_email'] as String;
      final fullName = request['full_name'] as String;
      final newOtp = _generateOTP();
      final expiresAt = DateTime.now().add(const Duration(hours: 24));
      
      // Update request with new OTP
      await _supabase
          .from('doctor_activation_requests')
          .update({
            'otp_code': newOtp,
            'expires_at': expiresAt.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
      
      // Update OTP in temp table
      await _supabase
          .from('doctor_otp_temp')
          .update({'status': 'expired', 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('purpose', 'doctor_activation')
          .eq('status', 'active');
      
      await _supabase.from('doctor_otp_temp').insert({
        'user_id': userId,
        'otp_code': newOtp,
        'purpose': 'doctor_activation',
        'status': 'active',
        'expires_at': expiresAt.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Show new OTP
      await _showOTP(
        otpCode: newOtp,
        userEmail: userEmail,
        fullName: fullName,
        context: context,
      );
      
      dev.log('=== RESEND OTP SUCCESS ===', name: 'DOCTOR_ACTIVATION');
      
      return ActivationResult(
        success: true,
        message: 'OTP baru berhasil dikirim: $newOtp',
        otpCode: newOtp,
      );
    } catch (e, stackTrace) {
      dev.log('Error: $e', error: e, stackTrace: stackTrace, name: 'DOCTOR_ACTIVATION');
      return ActivationResult(
        success: false,
        error: 'Gagal mengirim ulang OTP: ${e.toString()}',
      );
    }
  }

  // ADMIN: Update request status (reject, etc)
  Future<ActivationResult> updateRequestStatus({
    required String requestId,
    required String status,
    String? adminId,
    String? reason,
  }) async {
    try {
      dev.log('=== UPDATE REQUEST STATUS ===', name: 'DOCTOR_ACTIVATION');
      dev.log('Request ID: $requestId, Status: $status', name: 'DOCTOR_ACTIVATION');
      
      // Verify admin role if adminId provided
      if (adminId != null) {
        final adminRole = await _getUserRole(adminId);
        if (adminRole != 'admin') {
          return ActivationResult(
            success: false,
            error: 'Hanya admin yang dapat mengubah status request',
          );
        }
      }
      
      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (adminId != null && status == 'rejected') {
        updateData['approved_by'] = adminId;
        updateData['approved_at'] = DateTime.now().toIso8601String();
        if (reason != null) {
          updateData['rejection_reason'] = reason;
        }
      }
      
      await _supabase
          .from('doctor_activation_requests')
          .update(updateData)
          .eq('id', requestId);
      
      dev.log('Status updated to: $status', name: 'DOCTOR_ACTIVATION');
      
      return ActivationResult(
        success: true,
        message: 'Request berhasil di${_getStatusMessage(status)}',
      );
    } catch (e, stackTrace) {
      dev.log('Error: $e', error: e, stackTrace: stackTrace, name: 'DOCTOR_ACTIVATION');
      return ActivationResult(
        success: false,
        error: 'Gagal mengupdate status: ${e.toString()}',
      );
    }
  }

  // ADMIN: Get all requests
  Future<List<Map<String, dynamic>>> getAllRequests() async {
    try {
      final currentUserId = await _getCurrentUserId();
      final currentRole = await _getUserRole(currentUserId ?? '');
      
      dev.log('Getting requests for user role: ${currentRole ?? "null"}', name: 'DOCTOR_ACTIVATION');
      
      if (currentRole != 'admin') {
        // Non-admin only see their own requests
        final response = await _supabase
            .from('doctor_activation_requests')
            .select()
            .eq('user_id', currentUserId ?? '')
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(response);
      }
      
      // Admin sees all
      final response = await _supabase
          .from('doctor_activation_requests')
          .select()
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      dev.log('Error getting requests: $e', name: 'DOCTOR_ACTIVATION');
      return [];
    }
  }

  // ADMIN: Get pending requests
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      final response = await _supabase
          .from('doctor_activation_requests')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      dev.log('Error getting pending requests: $e', name: 'DOCTOR_ACTIVATION');
      return [];
    }
  }

  // Get request by ID
  Future<Map<String, dynamic>?> getRequestById(String requestId) async {
    try {
      final response = await _supabase
          .from('doctor_activation_requests')
          .select()
          .eq('id', requestId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      dev.log('Error getting request by ID: $e', name: 'DOCTOR_ACTIVATION');
      return null;
    }
  }

  // Get user activation status
  Future<String?> getUserActivationStatus(String userId) async {
    try {
      final response = await _supabase
          .from('doctor_activation_requests')
          .select('status')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      return response?['status'] as String?;
    } catch (e) {
      dev.log('Error getting user activation status: $e', name: 'DOCTOR_ACTIVATION');
      return null;
    }
  }

  // Check if user has approved request (waiting for OTP)
  Future<bool> hasApprovedRequest(String userId) async {
    try {
      final response = await _supabase
          .from('doctor_activation_requests')
          .select()
          .eq('user_id', userId)
          .eq('status', 'approved')
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      dev.log('Error checking approved request: $e', name: 'DOCTOR_ACTIVATION');
      return false;
    }
  }

  // Check if user is doctor
  Future<bool> isUserDoctor(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();
      
      return response != null && response['role'] == 'doctor';
    } catch (e) {
      dev.log('Error checking is user doctor: $e', name: 'DOCTOR_ACTIVATION');
      return false;
    }
  }

  // Get dashboard statistics for admin
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final allRequests = await getAllRequests();
      
      int pending = 0;
      int approved = 0;
      int completed = 0;
      int rejected = 0;
      int expired = 0;
      
      for (final request in allRequests) {
        final status = request['status'] as String? ?? '';
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'approved':
            approved++;
            break;
          case 'completed':
            completed++;
            break;
          case 'rejected':
            rejected++;
            break;
          case 'expired':
            expired++;
            break;
        }
      }
      
      return {
        'totalRequests': allRequests.length,
        'pendingRequests': pending,
        'approvedRequests': approved,
        'completedRequests': completed,
        'rejectedRequests': rejected,
        'expiredRequests': expired,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      dev.log('Error getting dashboard stats: $e', name: 'DOCTOR_ACTIVATION');
      return {
        'totalRequests': 0,
        'pendingRequests': 0,
        'approvedRequests': 0,
        'completedRequests': 0,
        'rejectedRequests': 0,
        'expiredRequests': 0,
        'error': e.toString(),
      };
    }
  }

  // Helper: Get status message in Indonesian
  String _getStatusMessage(String status) {
    switch (status) {
      case 'approved':
        return 'setujui';
      case 'rejected':
        return 'tolak';
      case 'cancelled':
        return 'batalkan';
      default:
        return status;
    }
  }
}

class ActivationResult {
  final bool success;
  final String? error;
  final String? message;
  final String? requestId;
  final String? otpCode;

  ActivationResult({
    required this.success,
    this.error,
    this.message,
    this.requestId,
    this.otpCode,
  });
}