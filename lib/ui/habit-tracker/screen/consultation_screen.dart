// lib/ui/habit-tracker/screen/consultation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/ui/habit-tracker/screen/doctor_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purewill/ui/habit-tracker/providers/chat_providers.dart';
import 'package:purewill/ui/habit-tracker/widget/clean_bottom_navigation_bar.dart';
import 'package:purewill/ui/habit-tracker/screen/home_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/habit_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/nofap_screen.dart';
import 'package:purewill/ui/habit-tracker/screen/community_selection_screen.dart';
import 'package:purewill/data/services/doctor/doctor_service.dart';
import 'chatbot_screen.dart';

class ConsultationScreen extends ConsumerStatefulWidget {
  const ConsultationScreen({super.key});

  @override
  ConsumerState<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends ConsumerState<ConsultationScreen> {
  int _currentIndex = 4;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Chatbot';
  String _searchQuery = '';
  
  // Loading state untuk mengambil nama user
  bool _isLoadingName = true;
  String? _userName;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Chatbot', 'icon': Icons.chat_bubble_outline},
    {'name': 'Dokter', 'icon': Icons.medical_services},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    try {
      final displayName = await ref.read(currentDisplayNameProvider.future);
      setState(() {
        _userName = displayName;
        _isLoadingName = false;
      });
      print('✅ Loaded user name: $displayName');
    } catch (e) {
      print('❌ Error loading user name: $e');
      setState(() {
        _isLoadingName = false;
      });
    }
  }

  void _onNavBarTap(int index) {
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HabitScreen()),
      );
    } else if (index == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const NoFapScreen()),
      );
    } else if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const CommunitySelectionScreen(),
        ),
      );
    } else if (index == 4) {
      return;
    }
  }

  void _openChatBot() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatBotScreen(
          userName: _userName,
        ),
      ),
    );
  }

  void _showAllDoctors(List<DoctorModel> doctors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                child: const Text(
                  'Semua Dokter',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    return _buildDoctorListItem(doctors[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToDoctorDetail(DoctorModel doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorDetailScreen(doctor: doctor),
      ),
    );
  }

  Future<void> _startConsultation(DoctorModel doctor) async {
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
            const Text('Apakah Anda ingin memulai konsultasi?'),
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
            child: const Text('Mulai Konsultasi'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Memulai konsultasi dengan ${doctor.displayName}...'),
          backgroundColor: const Color(0xFF00BFA5),
        ),
      );
      // Navigate to consultation page or show coming soon
      await Future.delayed(const Duration(seconds: 1));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fitur konsultasi akan segera tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildDoctorCard(DoctorModel doctor) {
    return GestureDetector(
      onTap: () => _navigateToDoctorDetail(doctor),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: doctor.avatarUrl != null
                    ? Image.network(
                        doctor.avatarUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF00BFA5).withOpacity(0.1),
                            child: const Icon(
                              Icons.medical_services,
                              size: 40,
                              color: Color(0xFF00BFA5),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: const Color(0xFF00BFA5).withOpacity(0.1),
                        child: const Icon(
                          Icons.medical_services,
                          size: 40,
                          color: Color(0xFF00BFA5),
                        ),
                      ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialization,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          doctor.rating > 0 ? doctor.rating.toString() : 'New',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: doctor.isAvailable ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorListItem(DoctorModel doctor) {
    return GestureDetector(
      onTap: () => _navigateToDoctorDetail(doctor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5).withOpacity(0.1),
                ),
                child: doctor.avatarUrl != null
                    ? Image.network(
                        doctor.avatarUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.medical_services,
                            size: 40,
                            color: Color(0xFF00BFA5),
                          );
                        },
                      )
                    : const Icon(
                        Icons.medical_services,
                        size: 40,
                        color: Color(0xFF00BFA5),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.specialization,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            doctor.rating > 0 ? doctor.rating.toString() : 'New',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.work_history,
                            color: Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(doctor.experience),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    doctor.consultationFee,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF00BFA5),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.message_outlined,
                color: Color(0xFF00BFA5),
              ),
              onPressed: () => _startConsultation(doctor),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // App Bar
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Konsultasi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (!_isLoadingName && _userName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFA5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Hi, ${_userName!.split(' ').first}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF00BFA5),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.black87,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),

          // Search Bar (only show for Dokter category)
          if (_selectedCategory == 'Dokter')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari dokter...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),

          // Categories
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['name'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category['name'] as String;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00BFA5)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          category['icon'] as IconData,
                          color: isSelected ? Colors.white : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category['name'] as String,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Konten
          Expanded(
            child: _selectedCategory == 'Chatbot'
                ? _buildChatbotContent()
                : _buildDoctorContent(),
          ),
        ],
      ),

      bottomNavigationBar: CleanBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  Widget _buildChatbotContent() {
    if (_isLoadingName) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
            ),
            SizedBox(height: 16),
            Text(
              'Memuat data user...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner dengan sapaan personal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _userName != null 
                    ? 'Halo ${_userName!.split(' ').first}! 👋'
                    : 'Konsultasi dengan AI',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tanyakan apapun tentang kesehatan mental Anda. Dapatkan respons cepat dan informatif 24/7.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _openChatBot,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF00BFA5),
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
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Keuntungan Chatbot
          const Text(
            'Keuntungan Konsultasi dengan AI',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildAdvantageCard(
            icon: Icons.access_time,
            title: '24/7 Tersedia',
            description: 'Konsultasi kapan saja, di mana saja tanpa perlu menunggu',
          ),
          const SizedBox(height: 12),
          _buildAdvantageCard(
            icon: Icons.speed,
            title: 'Respons Cepat',
            description: 'Dapatkan jawaban instan untuk pertanyaan Anda',
          ),
          const SizedBox(height: 12),
          _buildAdvantageCard(
            icon: Icons.security,
            title: 'Privasi Terjaga',
            description: 'Semua percakapan bersifat rahasia dan aman',
          ),
          const SizedBox(height: 12),
          _buildAdvantageCard(
            icon: Icons.psychology,
            title: 'Pengetahuan Medis',
            description: 'Dibekali pengetahuan kesehatan mental terkini',
          ),

          const SizedBox(height: 20),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber[700]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Catatan: AI bukan pengganti tenaga medis profesional. Untuk kondisi darurat, segera hubungi dokter atau layanan kesehatan terdekat.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorContent() {
    final doctorService = ref.watch(doctorServiceProvider);
    
    return FutureBuilder<List<DoctorModel>>(
      future: doctorService.getAllDoctors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
                ),
                SizedBox(height: 16),
                Text('Memuat daftar dokter...'),
              ],
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFA5),
                  ),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }
        
        var doctors = snapshot.data ?? [];
        
        // Filter berdasarkan search query
        if (_searchQuery.isNotEmpty) {
          doctors = doctors.where((doctor) {
            return doctor.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                doctor.specialization.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }
        
        if (doctors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchQuery.isNotEmpty ? Icons.search_off : Icons.medical_services_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty 
                    ? 'Tidak ada dokter yang cocok dengan "$_searchQuery"'
                    : 'Belum ada dokter terdaftar',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty
                    ? 'Coba dengan kata kunci lain'
                    : 'Silakan coba lagi nanti',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        // Filter top doctors (with rating > 0)
        final topDoctors = doctors.where((d) => d.rating > 0).toList();
        final topDoctorsToShow = topDoctors.isEmpty ? doctors.take(5).toList() : topDoctors.take(5).toList();
        
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Doctors Section
                if (topDoctorsToShow.isNotEmpty && _searchQuery.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Top Dokter',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showAllDoctors(doctors),
                          child: const Text(
                            'Lihat semua',
                            style: TextStyle(
                              color: Color(0xFF00BFA5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(
                    height: 240,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 20),
                      itemCount: topDoctorsToShow.length,
                      itemBuilder: (context, index) {
                        final doctor = topDoctorsToShow[index];
                        return _buildDoctorCard(doctor);
                      },
                    ),
                  ),
                ],
                
                // All Doctors Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _searchQuery.isNotEmpty ? 'Hasil Pencarian' : 'Semua Dokter',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${doctors.length} dokter',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                
                // All Doctors List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = doctors[index];
                    return _buildDoctorListItem(doctor);
                  },
                ),
                
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdvantageCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF00BFA5), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}