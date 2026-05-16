// lib/data/services/doctor/doctor_activation_service.dart
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import developer log dengan alias
import 'dart:developer' as dev;

final doctorActivationServiceProvider = Provider(
  (ref) => DoctorActivationService(),
);

class DoctorActivationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Random _random = Random();

  // Cek apakah tabel doctor_activation_requests ada
  Future<bool> _ensureTableExists() async {
    try {
      // Coba query tabel untuk memastikan ada
      await _supabase.from('doctor_activation_requests').select().limit(1);
      return true;
    } catch (e) {
      dev.log(
        'Table doctor_activation_requests does not exist: $e',
        name: 'DOCTOR_ACTIVATION',
      );
      return false;
    }
  }

  // Cek apakah tabel admin_notifications ada
  Future<bool> _ensureNotificationsTableExists() async {
    try {
      await _supabase.from('admin_notifications').select().limit(1);
      return true;
    } catch (e) {
      dev.log(
        'Table admin_notifications does not exist: $e',
        name: 'DOCTOR_ACTIVATION',
      );
      return false;
    }
  }

  // Generate 8 digit OTP
  String _generateOTP() {
    return (_random.nextInt(90000000) + 10000000).toString();
  }

  // Request OTP untuk aktivasi dokter
  Future<ActivationResult> requestDoctorActivation({
    required String userId,
    required String userEmail,
    required String fullName,
  }) async {
    try {
      // Cek apakah tabel ada
      final tableExists = await _ensureTableExists();
      if (!tableExists) {
        return ActivationResult(
          success: false,
          error:
              'Sistem aktivasi dokter sedang dalam maintenance. Silakan hubungi administrator.',
        );
      }

      // Cek apakah user sudah memiliki role doctor
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

      // Cek apakah sudah ada request pending
      final existingRequest = await _getPendingRequest(userId);
      if (existingRequest != null) {
        return ActivationResult(
          success: false,
          error: 'Anda sudah memiliki request aktivasi yang sedang diproses',
          requestId: existingRequest['id'],
        );
      }

      // Generate OTP
      final otp = _generateOTP();
      final expiresAt = DateTime.now().add(const Duration(minutes: 15));

      // Simpan ke database
      final response = await _supabase
          .from('doctor_activation_requests')
          .insert({
            'user_id': userId,
            'user_email': userEmail,
            'full_name': fullName,
            'otp_code': otp,
            'status': 'pending',
            'expires_at': expiresAt.toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // Kirim OTP ke email user (untuk konfirmasi)
      await _sendOTPEmail(email: userEmail, userName: fullName, otp: otp);

      // Notify admin jika tabel notifications ada
      final notificationsTableExists = await _ensureNotificationsTableExists();
      if (notificationsTableExists) {
        await _notifyAdminAboutRequest(
          userId: userId,
          userEmail: userEmail,
          userName: fullName,
          requestId: response['id'],
        );
      }

      return ActivationResult(
        success: true,
        requestId: response['id'],
        message:
            'Request aktivasi berhasil dikirim. Admin akan meninjau permintaan Anda.',
      );
    } catch (e, stackTrace) {
      dev.log(
        'Error requesting doctor activation: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'DOCTOR_ACTIVATION',
      );

      // Handle specific errors
      if (e.toString().contains('foreign key constraint')) {
        return ActivationResult(
          success: false,
          error: 'User tidak ditemukan. Silakan login kembali.',
        );
      }

      return ActivationResult(
        success: false,
        error: 'Gagal mengirim request: ${e.toString()}',
      );
    }
  }

  // Admin approve request dan kirim OTP ke user
  Future<ActivationResult> approveDoctorActivation({
    required String requestId,
    required String adminId,
  }) async {
    try {
      // Cek apakah tabel ada
      final tableExists = await _ensureTableExists();
      if (!tableExists) {
        return ActivationResult(
          success: false,
          error: 'Tabel aktivasi tidak ditemukan',
        );
      }

      // Get request details
      final request = await _supabase
          .from('doctor_activation_requests')
          .select()
          .eq('id', requestId)
          .single();

      if (request['status'] != 'pending') {
        return ActivationResult(
          success: false,
          error: 'Request sudah diproses',
        );
      }

      // Generate OTP baru untuk verifikasi user
      final otp = _generateOTP();
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      // Update request status dan tambahkan OTP
      await _supabase
          .from('doctor_activation_requests')
          .update({
            'status': 'approved',
            'approved_by': adminId,
            'approved_at': DateTime.now().toIso8601String(),
            'otp_code': otp, // OTP untuk verifikasi user
            'expires_at': expiresAt.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      // Kirim OTP ke email user
      await _sendActivationOTPEmail(
        email: request['user_email'],
        userName: request['full_name'],
        otp: otp,
      );

      return ActivationResult(
        success: true,
        message: 'Request approved. OTP telah dikirim ke email user.',
      );
    } catch (e, stackTrace) {
      dev.log(
        'Error approving doctor activation: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'DOCTOR_ACTIVATION',
      );

      return ActivationResult(
        success: false,
        error: 'Gagal approve request: ${e.toString()}',
      );
    }
  }

  // User verifikasi OTP untuk aktivasi final
  Future<ActivationResult> verifyDoctorActivationOTP({
    required String userId,
    required String otp,
  }) async {
    try {
      // Cek apakah tabel ada
      final tableExists = await _ensureTableExists();
      if (!tableExists) {
        return ActivationResult(
          success: false,
          error: 'Sistem aktivasi tidak tersedia',
        );
      }

      // Cari request yang approved dan belum expired
      final requests = await _supabase
          .from('doctor_activation_requests')
          .select()
          .eq('user_id', userId)
          .eq('status', 'approved')
          .eq('otp_code', otp);

      if (requests.isEmpty) {
        return ActivationResult(
          success: false,
          error: 'OTP tidak valid atau sudah kadaluarsa',
        );
      }

      final request = requests[0];

      // Cek expiry
      final expiresAt = DateTime.parse(request['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        // Update status ke expired
        await _supabase
            .from('doctor_activation_requests')
            .update({
              'status': 'expired',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', request['id']);

        return ActivationResult(success: false, error: 'OTP telah kadaluarsa');
      }

      // Update role user ke 'doctor'
      await _supabase
          .from('profiles')
          .update({
            'role': 'doctor',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      // Update request status ke completed
      await _supabase
          .from('doctor_activation_requests')
          .update({
            'status': 'completed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', request['id']);

      return ActivationResult(
        success: true,
        message: 'Akun dokter berhasil diaktifkan!',
      );
    } catch (e, stackTrace) {
      dev.log(
        'Error verifying OTP: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'DOCTOR_ACTIVATION',
      );

      return ActivationResult(
        success: false,
        error: 'Verifikasi gagal: ${e.toString()}',
      );
    }
  }

  // Get user's current role
  Future<String?> _getUserRole(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('user_id', userId)
          .single();

      return response['role'] as String?;
    } catch (e) {
      dev.log('Error getting user role: $e', name: 'DOCTOR_ACTIVATION');
      return null;
    }
  }

  // Get pending request for user
  Future<Map<String, dynamic>?> _getPendingRequest(String userId) async {
    try {
      final response = await _supabase
          .from('doctor_activation_requests')
          .select()
          .eq('user_id', userId)
          .eq('status', 'pending')
          .maybeSingle();

      return response;
    } catch (e) {
      // Handle case when table doesn't exist
      if (e.toString().contains('Could not find the table')) {
        dev.log(
          'Table doctor_activation_requests does not exist yet',
          name: 'DOCTOR_ACTIVATION',
        );
        return null;
      }
      dev.log('Error getting pending request: $e', name: 'DOCTOR_ACTIVATION');
      return null;
    }
  }

  // Send OTP email (simulasi)
  Future<void> _sendOTPEmail({
    required String email,
    required String userName,
    required String otp,
  }) async {
    // Implementasi pengiriman email nyata menggunakan service email
    dev.log('OTP untuk $email: $otp', name: 'DOCTOR_ACTIVATION');

    // Dalam aplikasi produksi, gunakan service email seperti Resend
    /*
    try {
      await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer YOUR_RESEND_API_KEY',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'from': 'noreply@purewill.com',
          'to': email,
          'subject': 'Doctor Activation Request',
          'html': '''
            <h2>Doctor Activation Request</h2>
            <p>Hello $userName,</p>
            <p>Your request to become a doctor has been received.</p>
            <p>Admin will review your request shortly.</p>
            <p>Your OTP for reference: <strong>$otp</strong></p>
          ''',
        }),
      );
    } catch (e) {
      dev.log('Failed to send email: $e', name: 'DOCTOR_ACTIVATION');
    }
    */
  }

  // Send activation OTP email
  Future<void> _sendActivationOTPEmail({
    required String email,
    required String userName,
    required String otp,
  }) async {
    dev.log('Activation OTP untuk $email: $otp', name: 'DOCTOR_ACTIVATION');

    // Implementasi pengiriman email nyata
    /*
    try {
      await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer YOUR_RESEND_API_KEY',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'from': 'noreply@purewill.com',
          'to': email,
          'subject': 'Your Doctor Activation OTP',
          'html': '''
            <h2>Doctor Activation OTP</h2>
            <p>Hello $userName,</p>
            <p>Your request to become a doctor has been approved!</p>
            <p>Use this OTP to complete your activation:</p>
            <h1 style="color: #7C3AED; font-size: 32px; letter-spacing: 8px;">$otp</h1>
            <p>This OTP will expire in 10 minutes.</p>
          ''',
        }),
      );
    } catch (e) {
      dev.log('Failed to send activation email: $e', name: 'DOCTOR_ACTIVATION');
    }
    */
  }

  // Notify admin (simulasi)
  Future<void> _notifyAdminAboutRequest({
    required String userId,
    required String userEmail,
    required String userName,
    required String requestId,
  }) async {
    try {
      // Simpan notification di database
      await _supabase.from('admin_notifications').insert({
        'type': 'doctor_activation_request',
        'title': 'New Doctor Activation Request',
        'message': '$userName ($userEmail) wants to become a doctor',
        'metadata': {
          'user_id': userId,
          'user_email': userEmail,
          'user_name': userName,
          'request_id': requestId,
        },
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      dev.log('Failed to notify admin: $e', name: 'DOCTOR_ACTIVATION');
    }
  }

  // Get all pending requests (untuk admin)
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      final tableExists = await _ensureTableExists();
      if (!tableExists) return [];

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
      final tableExists = await _ensureTableExists();
      if (!tableExists) return null;

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

  // Get all doctor activation requests (for admin)
  Future<List<Map<String, dynamic>>> getAllRequests() async {
    try {
      final tableExists = await _ensureTableExists();
      if (!tableExists) return [];

      final response = await _supabase
          .from('doctor_activation_requests')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      dev.log('Error getting all requests: $e', name: 'DOCTOR_ACTIVATION');
      return [];
    }
  }

  // Update request status
  Future<ActivationResult> updateRequestStatus({
    required String requestId,
    required String status,
    String? adminId,
  }) async {
    try {
      final updates = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (adminId != null && (status == 'approved' || status == 'rejected')) {
        updates['approved_by'] = adminId;
        updates['${status == 'approved' ? 'approved' : 'rejected'}_at'] =
            DateTime.now().toIso8601String();
      }

      await _supabase
          .from('doctor_activation_requests')
          .update(updates)
          .eq('id', requestId);

      return ActivationResult(
        success: true,
        message: 'Request $status successfully',
      );
    } catch (e) {
      return ActivationResult(
        success: false,
        error: 'Failed to update status: $e',
      );
    }
  }

  // Resend OTP untuk request yang sudah approved
  Future<ActivationResult> resendActivationOTP({
    required String requestId,
    required String adminId,
  }) async {
    try {
      // Cek apakah tabel ada
      final tableExists = await _ensureTableExists();
      if (!tableExists) {
        return ActivationResult(
          success: false,
          error: 'Tabel aktivasi tidak ditemukan',
        );
      }

      // Get request details
      final request = await _supabase
          .from('doctor_activation_requests')
          .select()
          .eq('id', requestId)
          .single();

      if (request['status'] != 'approved') {
        return ActivationResult(
          success: false,
          error: 'Request belum disetujui',
        );
      }

      // Generate OTP baru
      final otp = _generateOTP();
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      // Update OTP dan expiry
      await _supabase
          .from('doctor_activation_requests')
          .update({
            'otp_code': otp,
            'expires_at': expiresAt.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      // Kirim OTP ke email user
      await _sendActivationOTPEmail(
        email: request['user_email'],
        userName: request['full_name'],
        otp: otp,
      );

      return ActivationResult(
        success: true,
        message: 'OTP berhasil dikirim ulang ke email user.',
      );
    } catch (e, stackTrace) {
      dev.log(
        'Error resending OTP: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'DOCTOR_ACTIVATION',
      );

      return ActivationResult(
        success: false,
        error: 'Gagal mengirim ulang OTP: ${e.toString()}',
      );
    }
  }

  // Get statistics for admin dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final tableExists = await _ensureTableExists();
      if (!tableExists) {
        return {
          'totalRequests': 0,
          'pendingRequests': 0,
          'approvedRequests': 0,
          'completedRequests': 0,
          'rejectedRequests': 0,
          'expiredRequests': 0,
        };
      }

      // Get all requests untuk hitung statistik
      final allRequests = await getAllRequests();

      // Hitung berdasarkan status
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

  // Get requests by status
  Future<List<Map<String, dynamic>>> getRequestsByStatus(String status) async {
    try {
      final tableExists = await _ensureTableExists();
      if (!tableExists) return [];

      final response = await _supabase
          .from('doctor_activation_requests')
          .select()
          .eq('status', status)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      dev.log(
        'Error getting requests by status: $e',
        name: 'DOCTOR_ACTIVATION',
      );
      return [];
    }
  }

  // Get requests by user ID
  Future<List<Map<String, dynamic>>> getRequestsByUserId(String userId) async {
    try {
      final tableExists = await _ensureTableExists();
      if (!tableExists) return [];

      final response = await _supabase
          .from('doctor_activation_requests')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      dev.log(
        'Error getting requests by user ID: $e',
        name: 'DOCTOR_ACTIVATION',
      );
      return [];
    }
  }

  // Delete request (for admin)
  Future<ActivationResult> deleteRequest(String requestId) async {
    try {
      final tableExists = await _ensureTableExists();
      if (!tableExists) {
        return ActivationResult(success: false, error: 'Tabel tidak ditemukan');
      }

      await _supabase
          .from('doctor_activation_requests')
          .delete()
          .eq('id', requestId);

      return ActivationResult(
        success: true,
        message: 'Request berhasil dihapus',
      );
    } catch (e, stackTrace) {
      dev.log(
        'Error deleting request: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'DOCTOR_ACTIVATION',
      );

      return ActivationResult(
        success: false,
        error: 'Gagal menghapus request: ${e.toString()}',
      );
    }
  }

  // Check if user has active doctor request
  Future<bool> hasActiveRequest(String userId) async {
    try {
      final tableExists = await _ensureTableExists();
      if (!tableExists) return false;

      final response = await _supabase
          .from('doctor_activation_requests')
          .select()
          .eq('user_id', userId)
          .or('status.eq.pending,status.eq.approved')
          .maybeSingle();

      return response != null;
    } catch (e) {
      dev.log('Error checking active request: $e', name: 'DOCTOR_ACTIVATION');
      return false;
    }
  }

  // Get expired requests
  Future<List<Map<String, dynamic>>> getExpiredRequests() async {
    try {
      final tableExists = await _ensureTableExists();
      if (!tableExists) return [];

      final now = DateTime.now().toIso8601String();

      // Cari request yang expired (expires_at < sekarang dan status masih approved)
      final response = await _supabase
          .from('doctor_activation_requests')
          .select()
          .eq('status', 'approved')
          .lt('expires_at', now);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      dev.log('Error getting expired requests: $e', name: 'DOCTOR_ACTIVATION');
      return [];
    }
  }

  // Auto-expire old approved requests
  Future<void> autoExpireOldRequests() async {
    try {
      final expiredRequests = await getExpiredRequests();

      for (final request in expiredRequests) {
        await _supabase
            .from('doctor_activation_requests')
            .update({
              'status': 'expired',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', request['id']);
      }

      if (expiredRequests.isNotEmpty) {
        dev.log(
          'Auto-expired ${expiredRequests.length} requests',
          name: 'DOCTOR_ACTIVATION',
        );
      }
    } catch (e) {
      dev.log('Error auto-expiring requests: $e', name: 'DOCTOR_ACTIVATION');
    }
  }
}

class ActivationResult {
  final bool success;
  final String? error;
  final String? message;
  final String? requestId;

  ActivationResult({
    required this.success,
    this.error,
    this.message,
    this.requestId,
  });
}
