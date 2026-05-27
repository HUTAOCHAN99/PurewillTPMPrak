import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kesanController = TextEditingController();
  final _pesanController = TextEditingController();
  
  String _selectedCategory = 'Kuliah';
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Kuliah',
    'Dosen',
    'Materi',
    'Tugas',
    'Platform',
    'Lainnya'
  ];

  @override
  void dispose() {
    _kesanController.dispose();
    _pesanController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true;
    });

    // Simulasi pengiriman data (Anda bisa mengganti dengan API call ke Supabase)
    await Future.delayed(const Duration(seconds: 1));
    
    // Di sini Anda bisa menyimpan ke database
    debugPrint('=== KESAN & PESAN ===');
    debugPrint('Kategori: $_selectedCategory');
    debugPrint('Kesan: ${_kesanController.text}');
    debugPrint('Pesan: ${_pesanController.text}');
    debugPrint('Anonim: $_isAnonymous');
    debugPrint('===================');
    
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Terima Kasih!'),
          ],
        ),
        content: const Text(
          'Kesan dan pesan Anda telah berhasil dikirim.\nTerima kasih atas masukannya untuk mata kuliah Teknologi Pemrograman Mobile!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Kembali ke screen sebelumnya
            },
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    if (_kesanController.text.isEmpty && _pesanController.text.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Form'),
        content: const Text('Apakah Anda yakin ingin menghapus semua yang sudah ditulis?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              _kesanController.clear();
              _pesanController.clear();
              setState(() {
                _selectedCategory = 'Kuliah';
                _isAnonymous = false;
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Form telah direset'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Kesan & Pesan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color.fromRGBO(176, 230, 216, 1),
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            onPressed: _showResetConfirmation,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color.fromRGBO(176, 230, 216, 1), Color(0xFF9DC8B5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.feedback_outlined, size: 32, color: Colors.black54),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teknologi Pemrograman Mobile',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Bagikan kesan dan pesan Anda selama mengikuti mata kuliah ini',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Kategori
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kategori',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _categories.map((category) {
                          final isSelected = _selectedCategory == category;
                          return FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            backgroundColor: Colors.grey[100],
                            selectedColor: const Color.fromRGBO(176, 230, 216, 0.5),
                            checkmarkColor: Colors.green,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black87 : Colors.grey[600],
                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Form Kesan
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.thumb_up_outlined, size: 20, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'Kesan',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Tidak ada batasan',
                              style: TextStyle(fontSize: 10, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _kesanController,
                        maxLines: null,
                        minLines: 4,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: 'Tuliskan kesan Anda selama mengikuti mata kuliah ini...\n\nContoh:\n• Materi yang menarik\n• Dosen yang membimbing dengan baik\n• Pengalaman belajar yang berharga',
                          hintMaxLines: 5,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color.fromRGBO(176, 230, 216, 1), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Silakan tuliskan kesan Anda';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Form Pesan/Saran
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.message_outlined, size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Pesan & Saran',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Tidak ada batasan',
                              style: TextStyle(fontSize: 10, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pesanController,
                        maxLines: null,
                        minLines: 3,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: 'Tuliskan pesan atau saran untuk pengembangan mata kuliah ke depannya...\n\nContoh:\n• Saran materi tambahan\n• Harapan untuk praktikum\n• Masukan untuk pembelajaran',
                          hintMaxLines: 5,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color.fromRGBO(176, 230, 216, 1), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Silakan tuliskan pesan atau saran Anda';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Opsi Anonim
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Kirim sebagai anonim'),
                  subtitle: const Text('Nama Anda tidak akan ditampilkan'),
                  value: _isAnonymous,
                  onChanged: (value) {
                    setState(() {
                      _isAnonymous = value;
                    });
                  },
                  activeColor: const Color.fromRGBO(176, 230, 216, 1),
                  activeTrackColor: const Color.fromRGBO(176, 230, 216, 0.3),
                ),
              ),

              const SizedBox(height: 24),

              // Tombol Submit
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(176, 230, 216, 1),
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send),
                            SizedBox(width: 8),
                            Text(
                              'Kirim Kesan & Pesan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Informasi footer
              Center(
                child: Text(
                  'Terima kasih atas partisipasi Anda dalam meningkatkan kualitas pembelajaran',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}