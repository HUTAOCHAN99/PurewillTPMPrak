// lib/ui/habit-tracker/screen/doctor_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purewill/data/services/doctor/doctor_service.dart';

class DoctorDetailScreen extends StatelessWidget {
  final DoctorModel doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(doctor.displayName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and basic info
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: doctor.avatarUrl != null
                            ? NetworkImage(doctor.avatarUrl!)
                            : null,
                        child: doctor.avatarUrl == null
                            ? const Icon(
                                Icons.medical_services,
                                size: 60,
                                color: Color(0xFF00BFA5),
                              )
                            : null,
                      ),
                      if (doctor.isAvailable)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    doctor.displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    doctor.specialization,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        doctor.rating > 0 ? doctor.rating.toStringAsFixed(1) : 'New',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: doctor.isAvailable ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        doctor.isAvailable ? 'Tersedia' : 'Tidak Tersedia',
                        style: TextStyle(
                          color: doctor.isAvailable ? Colors.green[300] : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Details section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Profesional',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoTile(
                    Icons.work_history,
                    'Pengalaman',
                    doctor.experience,
                  ),
                  const Divider(),
                  _buildInfoTile(
                    Icons.school,
                    'Pendidikan',
                    doctor.doctorProfile?.education ?? 'Informasi belum tersedia',
                  ),
                  const Divider(),
                  _buildInfoTile(
                    Icons.local_hospital,
                    'Rumah Sakit / Praktek',
                    doctor.doctorProfile?.hospital ?? 'Informasi belum tersedia',
                  ),
                  const Divider(),
                  _buildInfoTile(
                    Icons.attach_money,
                    'Biaya Konsultasi',
                    doctor.consultationFee,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  if (doctor.doctorProfile?.bio != null && doctor.doctorProfile!.bio!.isNotEmpty) ...[
                    const Text(
                      'Biografi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      doctor.doctorProfile!.bio!,
                      style: const TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  if (doctor.doctorProfile?.availableDays != null && doctor.doctorProfile!.availableDays!.isNotEmpty) ...[
                    const Text(
                      'Jadwal Praktik',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: doctor.doctorProfile!.availableDays!.map((day) {
                        return Chip(
                          label: Text(_translateDay(day)),
                          backgroundColor: const Color(0xFF00BFA5).withOpacity(0.1),
                          labelStyle: const TextStyle(
                            color: Color(0xFF00BFA5),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    if (doctor.doctorProfile?.startTime != null &&
                        doctor.doctorProfile?.endTime != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 20, color: Color(0xFF00BFA5)),
                            const SizedBox(width: 8),
                            Text(
                              'Jam Praktik: ${doctor.doctorProfile!.startTime} - ${doctor.doctorProfile!.endTime}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Rating and sessions info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          Icons.star,
                          doctor.rating > 0 ? doctor.rating.toStringAsFixed(1) : '0',
                          'Rating',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        _buildStatItem(
                          Icons.people,
                          doctor.doctorProfile?.totalSessions.toString() ?? '0',
                          'Pasien',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        _buildStatItem(
                          Icons.work_history,
                          doctor.experience,
                          'Pengalaman',
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Consultation button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: doctor.isAvailable
                          ? () => _startConsultation(context)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BFA5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Mulai Konsultasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Konsultasi dengan dokter terverifikasi. Untuk kondisi darurat, segera hubungi layanan kesehatan terdekat.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
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

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: const Color(0xFF00BFA5)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00BFA5), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  String _translateDay(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return 'Senin';
      case 'tuesday':
        return 'Selasa';
      case 'wednesday':
        return 'Rabu';
      case 'thursday':
        return 'Kamis';
      case 'friday':
        return 'Jumat';
      case 'saturday':
        return 'Sabtu';
      case 'sunday':
        return 'Minggu';
      default:
        return day;
    }
  }

  Future<void> _startConsultation(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konsultasi dengan ${doctor.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spesialisasi: ${doctor.specialization}'),
            const SizedBox(height: 8),
            Text('Biaya: ${doctor.consultationFee}'),
            const SizedBox(height: 8),
            const Divider(),
            const Text(
              'Informasi Konsultasi:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Konsultasi dilakukan secara online'),
            const Text('• Durasi konsultasi 30 menit'),
            const Text('• Dapatkan resep dan saran medis'),
            const SizedBox(height: 16),
            const Text(
              'Apakah Anda ingin melanjutkan?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
            ),
            child: const Text('Ya, Mulai'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
          ),
        ),
      );

      // Simulate consultation setup
      await Future.delayed(const Duration(seconds: 2));

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konsultasi dengan ${doctor.displayName} akan segera dimulai'),
            backgroundColor: const Color(0xFF00BFA5),
            duration: const Duration(seconds: 3),
          ),
        );
        
        // TODO: Navigate to actual consultation screen
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => ConsultationRoomScreen(doctor: doctor),
        //   ),
        // );
      }
    }
  }
}