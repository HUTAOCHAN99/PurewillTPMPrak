// lib/ui/admin/manage_doctors_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/data/services/doctor/doctor_service.dart';
import 'package:purewill/ui/admin/add_edit_doctor_screen.dart';

class ManageDoctorsScreen extends ConsumerStatefulWidget {
  const ManageDoctorsScreen({super.key});

  @override
  ConsumerState<ManageDoctorsScreen> createState() => _ManageDoctorsScreenState();
}

class _ManageDoctorsScreenState extends ConsumerState<ManageDoctorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteDoctor(DoctorModel doctor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Dokter'),
        content: Text('Apakah Anda yakin ingin menghapus ${doctor.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(doctorServiceProvider).deleteDoctor(doctor.userId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dokter berhasil dihapus')),
          );
          setState(() {}); // Refresh list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus dokter'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorService = ref.watch(doctorServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Doctors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari dokter...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<DoctorModel>>(
              future: doctorService.getAllDoctors(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var doctors = snapshot.data ?? [];
                if (_searchQuery.isNotEmpty) {
                  doctors = doctors
                      .where((d) =>
                          d.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          d.specialization.toLowerCase().contains(_searchQuery.toLowerCase()))
                      .toList();
                }

                if (doctors.isEmpty) {
                  return const Center(child: Text('Tidak ada dokter ditemukan'));
                }

                return ListView.builder(
                  itemCount: doctors.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final doctor = doctors[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: doctor.avatarUrl != null
                              ? NetworkImage(doctor.avatarUrl!)
                              : null,
                          child: doctor.avatarUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(doctor.fullName),
                        subtitle: Text(doctor.specialization),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddEditDoctorScreen(doctor: doctor),
                                  ),
                                );
                                if (result == true) setState(() {});
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteDoctor(doctor),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditDoctorScreen(),
            ),
          );
          if (result == true) setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
