import 'dart:io';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  final SupabaseClient _supabase;
  final String _bucketName = 'communities';
  final ImagePicker _imagePicker = ImagePicker();

  ImageService() : _supabase = Supabase.instance.client;

  // ============ IMAGE UPLOAD ============

  Future<String?> uploadImage(File imageFile, String userId) async {
    try {
      // Validasi USER
      if (userId.isEmpty) {
        return null;
      }

      // Validasi FILE
      final fileExists = await imageFile.exists();
      if (!fileExists) {
        return null;
      }

      // CEK FILE SIZE
      final fileSize = await imageFile.length();
      if (fileSize == 0) {
        return null;
      }

      // Batas 20MB untuk safety
      if (fileSize > 20 * 1024 * 1024) {
        return null;
      }

      // CEK BUCKET 'communities'
      try {
        final buckets = await _supabase.storage.listBuckets();
        final bucketExists = buckets.any((bucket) => bucket.name == _bucketName);
        
        if (!bucketExists) {
          return null;
        }
      } catch (e) {
        return null;
      }

      // GENERATE FILENAME
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = Random().nextInt(10000);
      final originalPath = imageFile.path;
      
      String extension = 'jpg';
      if (originalPath.toLowerCase().endsWith('.png')) {
        extension = 'png';
      } else if (originalPath.toLowerCase().endsWith('.jpeg')) {
        extension = 'jpeg';
      } else if (originalPath.toLowerCase().endsWith('.gif')) {
        extension = 'gif';
      } else if (originalPath.toLowerCase().endsWith('.webp')) {
        extension = 'webp';
      } else if (originalPath.toLowerCase().endsWith('.heic') || 
                 originalPath.toLowerCase().endsWith('.heif')) {
        extension = 'jpg';
      }
      
      final fileName = 'post_${userId}_${timestamp}_$random.$extension';

      // READ FILE BYTES
      final bytes = await imageFile.readAsBytes();

      // UPLOAD KE BUCKET 'communities'
      const maxRetries = 2;
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          final uploadResult = await _supabase.storage
              .from(_bucketName)
              .uploadBinary(
                fileName,
                bytes,
                fileOptions: FileOptions(
                  contentType: _getMimeType(extension),
                  upsert: true,
                  cacheControl: '3600',
                ),
              );
          break;
        } catch (e) {
          if (attempt == maxRetries) {
            rethrow;
          }
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      // GET PUBLIC URL
      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(fileName);
      
      // VALIDASI URL PATTERN (harus mengandung /communities/)
      if (!publicUrl.contains('/communities/')) {
        return null;
      }

      return publicUrl;

    } catch (e) {
      return null;
    }
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  // ============ IMAGE PICKER METHODS ============

  Future<XFile?> pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: null,
        maxHeight: null,
        imageQuality: 100,
      );
      return image;
    } catch (e) {
      return null;
    }
  }

  Future<XFile?> takePhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: null,
        maxHeight: null,
        imageQuality: 100,
      );
      return image;
    } catch (e) {
      return null;
    }
  }

  // ============ UTILITY FUNCTIONS ============

  bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    
    return url.contains('supabase.co/storage/v1/object/public/communities/') &&
           url.startsWith('https://') &&
           !url.contains('base64');
  }

  Future<bool> deleteImage(String imageUrl) async {
    try {
      if (!isValidImageUrl(imageUrl)) {
        return false;
      }

      // Extract filename from URL
      final parts = imageUrl.split('/');
      final fileName = parts.last.split('?').first;
      
      await _supabase.storage
          .from(_bucketName)
          .remove([fileName]);
      
      return true;
    } catch (e) {
      return false;
    }
  }
}