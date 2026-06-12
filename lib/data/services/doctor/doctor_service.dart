// lib/data/services/doctor/doctor_service.dart
import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorServiceProvider = Provider((ref) => DoctorService());

class DoctorService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all verified doctors (role = 'doctor')
  Future<List<DoctorModel>> getAllDoctors() async {
    try {
      // First get profiles with role 'doctor'
      final response = await _supabase
          .from('profiles')
          .select('''
            user_id,
            full_name,
            avatar_url,
            role,
            created_at
          ''')
          .eq('role', 'doctor')
          .order('full_name');

      final doctors = <DoctorModel>[];
      
      for (var profile in response) {
        final userId = profile['user_id'].toString();
        
        // Then get doctor profile if exists
        final doctorProfile = await _getDoctorProfile(userId);
        
        doctors.add(DoctorModel.fromJson({
          ...profile,
          'doctor_profile': doctorProfile,
        }));
      }
      
      return doctors;
    } catch (e) {
      dev.log('Error getting doctors: $e', name: 'DOCTOR_SERVICE');
      return [];
    }
  }

  // Get doctor profile by user_id
  Future<Map<String, dynamic>?> _getDoctorProfile(String userId) async {
    try {
      final response = await _supabase
          .from('doctor_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      dev.log('Error getting doctor profile: $e', name: 'DOCTOR_SERVICE');
      return null;
    }
  }

  // Get doctor by ID
  Future<DoctorModel?> getDoctorById(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('''
            user_id,
            full_name,
            avatar_url,
            role,
            created_at
          ''')
          .eq('user_id', userId)
          .eq('role', 'doctor')
          .maybeSingle();

      if (response == null) return null;
      
      final doctorProfile = await _getDoctorProfile(userId);
      
      return DoctorModel.fromJson({
        ...response,
        'doctor_profile': doctorProfile,
      });
    } catch (e) {
      dev.log('Error getting doctor by ID: $e', name: 'DOCTOR_SERVICE');
      return null;
    }
  }

  // Search doctors by name or specialization
  Future<List<DoctorModel>> searchDoctors(String query) async {
    try {
      // Search by name in profiles
      var profilesQuery = _supabase
          .from('profiles')
          .select('''
            user_id,
            full_name,
            avatar_url,
            role,
            created_at
          ''')
          .eq('role', 'doctor');

      if (query.isNotEmpty) {
        profilesQuery = profilesQuery.ilike('full_name', '%$query%');
      }

      final response = await profilesQuery;
      
      final doctors = <DoctorModel>[];
      for (var profile in response) {
        final userId = profile['user_id'].toString();
        final doctorProfile = await _getDoctorProfile(userId);
        
        // Also search in specialization if query matches
        if (query.isNotEmpty && doctorProfile != null) {
          final specialization = doctorProfile['specialization'] as String? ?? '';
          if (specialization.toLowerCase().contains(query.toLowerCase()) ||
              profile['full_name'].toString().toLowerCase().contains(query.toLowerCase())) {
            doctors.add(DoctorModel.fromJson({
              ...profile,
              'doctor_profile': doctorProfile,
            }));
          }
        } else if (query.isEmpty) {
          doctors.add(DoctorModel.fromJson({
            ...profile,
            'doctor_profile': doctorProfile,
          }));
        }
      }
      
      return doctors;
    } catch (e) {
      dev.log('Error searching doctors: $e', name: 'DOCTOR_SERVICE');
      return [];
    }
  }

  // Update doctor profile
  Future<bool> updateDoctorProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
    String? specialization,
    String? experience,
    String? education,
    String? hospital,
    String? consultationFee,
    String? bio,
    List<String>? availableDays,
    String? startTime,
    String? endTime,
    bool? isAvailable,
  }) async {
    try {
      // 1. Update Profile (Full Name & Avatar)
      if (fullName != null || avatarUrl != null) {
        final profileUpdate = <String, dynamic>{};
        if (fullName != null) profileUpdate['full_name'] = fullName;
        if (avatarUrl != null) profileUpdate['avatar_url'] = avatarUrl;
        
        await _supabase
            .from('profiles')
            .update(profileUpdate)
            .eq('user_id', userId);
      }

      // 2. Update Doctor Profile
      final existing = await _supabase
          .from('doctor_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (specialization != null) updateData['specialization'] = specialization;
      if (experience != null) updateData['experience'] = experience;
      if (education != null) updateData['education'] = education;
      if (hospital != null) updateData['hospital'] = hospital;
      if (consultationFee != null) updateData['consultation_fee'] = consultationFee;
      if (bio != null) updateData['bio'] = bio;
      if (availableDays != null) updateData['available_days'] = availableDays;
      if (startTime != null) updateData['start_time'] = startTime;
      if (endTime != null) updateData['end_time'] = endTime;
      if (isAvailable != null) updateData['is_available'] = isAvailable;

      if (existing == null) {
        // Create new doctor profile
        await _supabase.from('doctor_profiles').insert({
          'user_id': userId,
          ...updateData,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Update existing
        await _supabase
            .from('doctor_profiles')
            .update(updateData)
            .eq('user_id', userId);
      }

      return true;
    } catch (e) {
      dev.log('Error updating doctor profile: $e', name: 'DOCTOR_SERVICE');
      return false;
    }
  }

  // Add new doctor manually
  Future<bool> addDoctor({
    required String fullName,
    required String specialization,
    String? experience,
    String? education,
    String? hospital,
    required String consultationFee,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      // Generate a unique ID for the manual doctor
      final userId = 'manual_doctor_${DateTime.now().microsecondsSinceEpoch}';
      
      // 1. Create Profile
      await _supabase.from('profiles').insert({
        'user_id': userId,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'role': 'doctor',
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. Create Doctor Profile
      await _supabase.from('doctor_profiles').insert({
        'user_id': userId,
        'specialization': specialization,
        'experience': experience,
        'education': education,
        'hospital': hospital,
        'consultation_fee': consultationFee,
        'bio': bio,
        'is_available': true,
        'rating': 0.0,
        'total_sessions': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      dev.log('Error adding doctor: $e', name: 'DOCTOR_SERVICE');
      return false;
    }
  }

  // Delete doctor
  Future<bool> deleteDoctor(String userId) async {
    try {
      // 1. Delete doctor profile first (FK constraint)
      await _supabase.from('doctor_profiles').delete().eq('user_id', userId);
      
      // 2. Delete profile
      await _supabase.from('profiles').delete().eq('user_id', userId);
      
      return true;
    } catch (e) {
      dev.log('Error deleting doctor: $e', name: 'DOCTOR_SERVICE');
      return false;
    }
  }

  // Get doctor's consultation sessions
  Future<List<Map<String, dynamic>>> getDoctorSessions(String doctorId) async {
    try {
      final response = await _supabase
          .from('consultation_sessions')
          .select('''
            *,
            patient:profiles!consultation_sessions_patient_id_fkey(
              user_id,
              full_name,
              avatar_url
            )
          ''')
          .eq('doctor_id', doctorId)
          .order('scheduled_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      dev.log('Error getting doctor sessions: $e', name: 'DOCTOR_SERVICE');
      return [];
    }
  }

  // Check if user is a doctor
  Future<bool> isUserDoctor(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();
      
      return response != null && response['role'] == 'doctor';
    } catch (e) {
      return false;
    }
  }

  // Create consultation session
  Future<bool> createConsultationSession({
    required String doctorId,
    required String patientId,
    required DateTime scheduledAt,
    String? notes,
  }) async {
    try {
      await _supabase.from('consultation_sessions').insert({
        'doctor_id': doctorId,
        'patient_id': patientId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'status': 'scheduled',
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      dev.log('Error creating consultation session: $e', name: 'DOCTOR_SERVICE');
      return false;
    }
  }

  // Update consultation session status
  Future<bool> updateSessionStatus({
    required String sessionId,
    required String status,
  }) async {
    try {
      await _supabase
          .from('consultation_sessions')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);
      
      return true;
    } catch (e) {
      dev.log('Error updating session status: $e', name: 'DOCTOR_SERVICE');
      return false;
    }
  }
}

// Doctor Model
class DoctorModel {
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String role;
  final DateTime createdAt;
  final DoctorProfile? doctorProfile;

  DoctorModel({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    required this.createdAt,
    this.doctorProfile,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    final profileData = json['doctor_profile'] as Map<String, dynamic>?;
    
    return DoctorModel(
      userId: json['user_id'].toString(),
      fullName: json['full_name'] ?? 'Doctor',
      avatarUrl: json['avatar_url'],
      role: json['role'] ?? 'doctor',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      doctorProfile: profileData != null ? DoctorProfile.fromJson(profileData) : null,
    );
  }

  String get displayName {
    final nameParts = fullName.split(' ');
    if (nameParts.length > 1) {
      return 'Dr. ${nameParts.last}';
    }
    return 'Dr. $fullName';
  }
  
  String get specialization => doctorProfile?.specialization ?? 'General Practitioner';
  String get experience => doctorProfile?.experience != null 
      ? '${doctorProfile!.experience} years' 
      : 'Not specified';
  String get consultationFee => doctorProfile?.consultationFee ?? 'Rp 200.000';
  bool get isAvailable => doctorProfile?.isAvailable ?? true;
  double get rating => doctorProfile?.rating ?? 0.0;
}

class DoctorProfile {
  final String userId;
  final String? specialization;
  final String? experience;
  final String? education;
  final String? hospital;
  final String? consultationFee;
  final String? bio;
  final List<String>? availableDays;
  final String? startTime;
  final String? endTime;
  final double rating;
  final int totalSessions;
  final bool isAvailable;

  DoctorProfile({
    required this.userId,
    this.specialization,
    this.experience,
    this.education,
    this.hospital,
    this.consultationFee,
    this.bio,
    this.availableDays,
    this.startTime,
    this.endTime,
    this.rating = 0.0,
    this.totalSessions = 0,
    this.isAvailable = true,
  });

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      userId: json['user_id'].toString(),
      specialization: json['specialization'],
      experience: json['experience']?.toString(),
      education: json['education'],
      hospital: json['hospital'],
      consultationFee: json['consultation_fee'],
      bio: json['bio'],
      availableDays: json['available_days'] != null 
          ? List<String>.from(json['available_days']) 
          : null,
      startTime: json['start_time'],
      endTime: json['end_time'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalSessions: json['total_sessions'] ?? 0,
      isAvailable: json['is_available'] ?? true,
    );
  }
}