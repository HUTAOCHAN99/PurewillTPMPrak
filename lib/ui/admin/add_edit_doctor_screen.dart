// lib/ui/admin/add_edit_doctor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/data/services/doctor/doctor_service.dart';

class AddEditDoctorScreen extends ConsumerStatefulWidget {
  final DoctorModel? doctor;

  const AddEditDoctorScreen({super.key, this.doctor});

  @override
  ConsumerState<AddEditDoctorScreen> createState() => _AddEditDoctorScreenState();
}

class _AddEditDoctorScreenState extends ConsumerState<AddEditDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _specializationController;
  late TextEditingController _experienceController;
  late TextEditingController _educationController;
  late TextEditingController _hospitalController;
  late TextEditingController _feeController;
  late TextEditingController _bioController;
  late TextEditingController _avatarUrlController;
  bool _isAvailable = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.doctor?.fullName ?? '');
    _specializationController = TextEditingController(text: widget.doctor?.specialization ?? '');
    _experienceController = TextEditingController(text: widget.doctor?.doctorProfile?.experience ?? '');
    _educationController = TextEditingController(text: widget.doctor?.doctorProfile?.education ?? '');
    _hospitalController = TextEditingController(text: widget.doctor?.doctorProfile?.hospital ?? '');
    _feeController = TextEditingController(text: widget.doctor?.doctorProfile?.consultationFee ?? 'Rp 200.000');
    _bioController = TextEditingController(text: widget.doctor?.doctorProfile?.bio ?? '');
    _avatarUrlController = TextEditingController(text: widget.doctor?.avatarUrl ?? '');
    _isAvailable = widget.doctor?.doctorProfile?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    _hospitalController.dispose();
    _feeController.dispose();
    _bioController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final service = ref.read(doctorServiceProvider);
    bool success;

    if (widget.doctor == null) {
      // Add new
      success = await service.addDoctor(
        fullName: _nameController.text,
        specialization: _specializationController.text,
        experience: _experienceController.text,
        education: _educationController.text,
        hospital: _hospitalController.text,
        consultationFee: _feeController.text,
        bio: _bioController.text,
        avatarUrl: _avatarUrlController.text.isEmpty ? null : _avatarUrlController.text,
      );
    } else {
      // Edit existing
      success = await service.updateDoctorProfile(
        userId: widget.doctor!.userId,
        fullName: _nameController.text,
        specialization: _specializationController.text,
        experience: _experienceController.text,
        education: _educationController.text,
        hospital: _hospitalController.text,
        consultationFee: _feeController.text,
        bio: _bioController.text,
        avatarUrl: _avatarUrlController.text.isEmpty ? null : _avatarUrlController.text,
        isAvailable: _isAvailable,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.doctor == null ? 'Dokter berhasil ditambahkan' : 'Dokter berhasil diperbarui')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan data dokter'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.doctor != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Dokter' : 'Tambah Dokter'),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Nama harus diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _specializationController,
                      decoration: const InputDecoration(
                        labelText: 'Spesialisasi',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.medical_services),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Spesialisasi harus diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _experienceController,
                      decoration: const InputDecoration(
                        labelText: 'Pengalaman (Tahun)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _educationController,
                      decoration: const InputDecoration(
                        labelText: 'Pendidikan',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _hospitalController,
                      decoration: const InputDecoration(
                        labelText: 'Rumah Sakit',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_hospital),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _feeController,
                      decoration: const InputDecoration(
                        labelText: 'Biaya Konsultasi',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payments),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _avatarUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL Foto Profil',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.image),
                        hintText: 'https://...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio / Deskripsi',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    if (isEdit)
                      SwitchListTile(
                        title: const Text('Tersedia'),
                        value: _isAvailable,
                        onChanged: (value) {
                          setState(() {
                            _isAvailable = value;
                          });
                        },
                      ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF00BFA5),
                      ),
                      child: Text(
                        isEdit ? 'SIMPAN PERUBAHAN' : 'TAMBAH DOKTER',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
