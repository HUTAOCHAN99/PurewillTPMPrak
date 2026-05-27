// lib/ui/habit-tracker/widget/habit_detail/doctor_activation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/data/services/doctor/doctor_activation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorActivationScreen extends ConsumerStatefulWidget {
  final String userEmail;
  final String userName;
  
  const DoctorActivationScreen({
    super.key,
    required this.userEmail,
    required this.userName,
  });

  @override
  DoctorActivationScreenState createState() => DoctorActivationScreenState();
}

class DoctorActivationScreenState extends ConsumerState<DoctorActivationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isSendingRequest = false;
  String _errorMessage = '';
  String _successMessage = '';
  int _step = 1; // 1: Request, 2: Wait for admin, 3: Enter OTP
  bool _tableExists = true;
  bool _initialCheckComplete = false;
  bool _isAlreadyDoctor = false;
  String? _currentRequestId;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStatus();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Check if table exists
      try {
        await _supabase
            .from('doctor_activation_requests')
            .select()
            .limit(1);
      } catch (e) {
        if (e.toString().contains('Could not find the table')) {
          if (mounted) {
            setState(() {
              _tableExists = false;
              _initialCheckComplete = true;
            });
          }
          return;
        }
      }

      final service = ref.read(doctorActivationServiceProvider);
      
      // Check if already doctor
      final isDoctor = await service.isUserDoctor(user.id);
      if (isDoctor) {
        if (mounted) {
          setState(() {
            _isAlreadyDoctor = true;
            _initialCheckComplete = true;
          });
        }
        return;
      }
      
      // Check existing request status
      final status = await service.getUserActivationStatus(user.id);
      
      if (mounted) {
        setState(() {
          _tableExists = true;
          if (status == 'pending') {
            _step = 2;
            _successMessage = 'Request Anda sedang ditinjau oleh admin.';
          } else if (status == 'approved') {
            _step = 3;
            _successMessage = 'Request Anda telah disetujui! Masukkan OTP yang diberikan admin.';
          } else {
            _step = 1;
          }
          _initialCheckComplete = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initialCheckComplete = true;
        });
      }
      debugPrint('Error checking status: $e');
    }
  }

  Future<void> _sendActivationRequest() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isSendingRequest = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final result = await ref
          .read(doctorActivationServiceProvider)
          .requestDoctorActivation(
            userId: user.id,
            userEmail: widget.userEmail,
            fullName: widget.userName,
          );

      if (result.success) {
        setState(() {
          _step = 2;
          _currentRequestId = result.requestId;
          _successMessage = result.message ?? 'Request berhasil dikirim!';
        });
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Gagal mengirim request';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSendingRequest = false;
        });
      }
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'OTP harus 6 digit angka';
      });
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final result = await ref
          .read(doctorActivationServiceProvider)
          .verifyDoctorActivationOTP(
            userId: user.id,
            otp: otp,
          );

      if (result.success) {
        setState(() {
          _successMessage = result.message ?? 'Akun dokter berhasil diaktifkan!';
        });
        
        // Wait a moment then go back
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      } else {
        setState(() {
          _errorMessage = result.error ?? 'OTP tidak valid';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshStatus() async {
    await _checkStatus();
  }

  Color _withOpacity(Color color, double opacity) {
    return color.withAlpha((opacity * 255).round());
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepCircle(1, 'Request', _step >= 1),
        _buildStepLine(),
        _buildStepCircle(2, 'Admin Review', _step >= 2),
        _buildStepLine(),
        _buildStepCircle(3, 'Verify OTP', _step >= 3),
      ],
    );
  }

  Widget _buildStepCircle(int stepNumber, String label, bool isActive) {
    bool isCurrent = _step == stepNumber;
    
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF00BFA5) : Colors.grey[300],
            shape: BoxShape.circle,
            border: isCurrent 
                ? Border.all(color: const Color(0xFF00BFA5), width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? const Color(0xFF00BFA5) : Colors.grey[600],
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 40,
      height: 2,
      color: Colors.grey[300],
      margin: const EdgeInsets.only(bottom: 16),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivasi Akun Dokter'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Memuat data...'),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyDoctorScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivasi Akun Dokter'),
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
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              const Text(
                'Akun Anda Sudah Aktif',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Anda sudah terdaftar sebagai dokter.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableNotFoundScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivasi Akun Dokter'),
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
              const Icon(Icons.construction, size: 64, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                'Fitur Sedang Dipersiapkan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sistem aktivasi akun dokter sedang dalam tahap pengembangan.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialCheckComplete) {
      return _buildLoadingScreen();
    }

    if (_isAlreadyDoctor) {
      return _buildAlreadyDoctorScreen();
    }

    if (!_tableExists) {
      return _buildTableNotFoundScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivasi Akun Dokter'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_step == 2)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshStatus,
              tooltip: 'Refresh Status',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            _buildStepIndicator(),
            
            const SizedBox(height: 32),
            
            // Content based on step
            if (_step == 1) _buildStep1Content(),
            if (_step == 2) _buildStep2Content(),
            if (_step == 3) _buildStep3Content(),
            
            const SizedBox(height: 24),
            
            // Error/Success messages
            if (_errorMessage.isNotEmpty)
              _buildMessageBox(_errorMessage, isError: true),
            
            if (_successMessage.isNotEmpty)
              _buildMessageBox(_successMessage, isError: false),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Request Aktivasi Dokter',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Kirim request ke admin untuk mengaktifkan akun dokter Anda. Admin akan meninjau dan memberikan kode OTP jika disetujui.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Account info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informasi Akun',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(widget.userName),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.email, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(widget.userEmail),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Info box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Setelah request disetujui admin, Anda akan menerima kode OTP untuk verifikasi.',
                  style: TextStyle(fontSize: 13, color: Colors.blue[800]),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSendingRequest ? null : _sendActivationRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSendingRequest
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Kirim Request Aktivasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.hourglass_empty,
          size: 80,
          color: Colors.orange,
        ),
        const SizedBox(height: 20),
        const Text(
          'Menunggu Persetujuan Admin',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Request aktivasi Anda sedang ditinjau oleh admin. Anda akan menerima kode OTP dari admin jika request disetujui.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 32),
        const CircularProgressIndicator(
          color: Color(0xFF00BFA5),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: _refreshStatus,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Refresh Status'),
        ),
      ],
    );
  }

  Widget _buildStep3Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verifikasi OTP',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Masukkan 6 digit kode OTP yang diberikan oleh admin:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        
        const SizedBox(height: 24),
        
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '000000',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.lock_outline),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          style: const TextStyle(
            fontSize: 24,
            letterSpacing: 6,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyOTP,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Verifikasi & Aktifkan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBox(String message, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isError ? Colors.red : Colors.green).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isError ? Colors.red : Colors.green).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle,
            color: isError ? Colors.red : Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}