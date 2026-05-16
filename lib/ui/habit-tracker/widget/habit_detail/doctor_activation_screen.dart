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

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingRequest();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingRequest() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Cek apakah tabel ada dengan query sederhana
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

      // Jika tabel ada, cek request existing
      final response = await _supabase
          .from('doctor_activation_requests')
          .select()
          .eq('user_id', user.id)
          .or('status.eq.pending,status.eq.approved')
          .maybeSingle();

      if (mounted) {
        if (response != null) {
          setState(() {
            _tableExists = true;
            if (response['status'] == 'pending') {
              _step = 2; // Menunggu admin
              _successMessage = 'Request Anda sedang ditinjau oleh admin.';
            } else if (response['status'] == 'approved') {
              _step = 3; // Masukkan OTP
              _successMessage = 'Request Anda telah disetujui! Masukkan OTP yang dikirim ke email.';
            }
            _initialCheckComplete = true;
          });
        } else {
          setState(() {
            _tableExists = true;
            _step = 1;
            _initialCheckComplete = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initialCheckComplete = true;
        });
      }
      debugPrint('Error checking existing request: $e');
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
    if (otp.length != 8) {
      setState(() {
        _errorMessage = 'OTP harus 8 digit angka';
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
        
        // Tunggu sebentar lalu kembali
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
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

  // Helper function untuk opacity (kompatibel dengan Flutter terbaru)
  Color _withOpacity(Color color, double opacity) {
    return color.withAlpha((opacity * 255).round());
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepCircle(1, 'Request'),
        _buildStepLine(),
        _buildStepCircle(2, 'Admin Review'),
        _buildStepLine(),
        _buildStepCircle(3, 'Verify OTP'),
      ],
    );
  }

  Widget _buildStepCircle(int stepNumber, String label) {
    bool isActive = _step >= stepNumber;
    bool isCurrent = _step == stepNumber;
    
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? Colors.green : Colors.grey[300],
            shape: BoxShape.circle,
            border: isCurrent 
                ? Border.all(color: Colors.green, width: 2)
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
            color: isActive ? Colors.green : Colors.grey[600],
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
        title: const Text('Aktivasi Akun Doctor'),
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

  Widget _buildTableNotFoundScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivasi Akun Doctor'),
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
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Loading screen untuk initial check
    if (!_initialCheckComplete) {
      return _buildLoadingScreen();
    }

    // Tampilkan error jika tabel tidak ada
    if (!_tableExists) {
      return _buildTableNotFoundScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivasi Akun Doctor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            _buildStepIndicator(),
            
            const SizedBox(height: 32),
            
            // Konten berdasarkan step
            if (_step == 1) _buildStep1Content(),
            if (_step == 2) _buildStep2Content(),
            if (_step == 3) _buildStep3Content(),
            
            const SizedBox(height: 24),
            
            // Pesan error/success
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _withOpacity(Colors.red, 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _withOpacity(Colors.red, 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (_successMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _withOpacity(Colors.green, 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _withOpacity(Colors.green, 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
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
          'Request Doctor Account Activation',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Untuk mengaktifkan akun dokter, Anda perlu mengirim request terlebih dahulu. Admin akan meninjau permintaan Anda dan mengirimkan OTP verifikasi jika disetujui.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Informasi akun
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
              Text(
                'Akun Anda',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
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
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSendingRequest ? null : _sendActivationRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
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
          Icons.hourglass_top,
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
            'Request aktivasi Anda sedang ditinjau oleh admin. Anda akan menerima email dengan OTP verifikasi jika request disetujui.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(height: 32),
        const CircularProgressIndicator(
          color: Colors.green,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              // Refresh status
              _checkExistingRequest();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Refresh Status'),
          ),
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
          'Masukkan 8 digit kode OTP yang dikirim ke email Anda:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        
        const SizedBox(height: 24),
        
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 8,
          decoration: InputDecoration(
            hintText: '12345678',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.lock),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          style: const TextStyle(
            fontSize: 18,
            letterSpacing: 8,
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
              backgroundColor: Colors.green,
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
                    'Verifikasi & Aktifkan Akun',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              // Resend OTP atau kembali ke step 1
              setState(() {
                _step = 1;
                _otpController.clear();
                _errorMessage = '';
                _successMessage = '';
              });
            },
            child: const Text(
              'Request Ulang',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ),
      ],
    );
  }
}