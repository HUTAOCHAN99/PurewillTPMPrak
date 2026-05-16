import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageSaverService {
  
  // Cek dan minta izin storage
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status.isDenied) {
        final result = await Permission.storage.request();
        return result.isGranted;
      } else if (status.isPermanentlyDenied) {
        // Buka settings jika izin ditolak permanen
        await openAppSettings();
        return false;
      }
      return status.isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.photos.status;
      if (status.isDenied) {
        final result = await Permission.photos.request();
        return result.isGranted;
      }
      return status.isGranted;
    }
    return true;
  }

  // Simpan gambar ke galeri
  Future<bool> saveImageToGallery(String imageUrl, {String? albumName}) async {
    try {
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        return false;
      }

      final result = await GallerySaver.saveImage(
        imageUrl,
        albumName: albumName ?? 'PureWill Community',
      );

      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Simpan gambar ke direktori app
  Future<File?> saveImageLocally(String imageUrl) async {
    try {
      final response = await HttpClient().getUrl(Uri.parse(imageUrl));
      final result = await response.close();
      final bytes = await consolidateHttpClientResponseBytes(result);
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'community_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      return null;
    }
  }

  Future<Directory> getApplicationDocumentsDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await getTemporaryDirectory();
    }
    return Directory.current;
  }
}