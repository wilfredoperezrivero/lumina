import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';

class MediaUploadService {
  static Future<String?> pickAndUploadFile(
      String capsuleId, String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: (type == 'audio')
          ? FileType.audio
          : (type == 'video' ? FileType.video : FileType.any),
    );
    if (result == null) {
      print('File picking cancelled or failed.');
      return null;
    }
    final file = result.files.first;
    if (file.bytes == null) {
      print(
          'File bytes are null. File may be too large or not loaded into memory.');
      return null;
    }
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final path = 'c/$capsuleId/$fileName';
    final storage = Supabase.instance.client.storage;
    try {
      print('Uploading file to: $path');
      final upload =
          await storage.from('media').uploadBinary(path, file.bytes!);
      print('Upload result: $upload');
      final publicUrl = storage.from('media').getPublicUrl(path);
      print('Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  static Future<String?> uploadRecordedFile(
      String capsuleId, String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final path = 'invitees/$capsuleId/audio/$fileName';
    final storage = Supabase.instance.client.storage;
    try {
      final bytes = await file.readAsBytes();
      await storage.from('media').uploadBinary(path, bytes);
      final publicUrl = storage.from('media').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  static Future<String> uploadImage(
      File file, String fileName, String capsuleId) async {
    final path = 'c/$capsuleId/$fileName';
    final storage = Supabase.instance.client.storage;

    try {
      // Check if file exists
      if (!await file.exists()) {
        throw Exception('File does not exist: ${file.path}');
      }

      // Check file size (limit to 10MB)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception(
            'File too large: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB (max 10MB)');
      }

      print('Uploading image: ${file.path}');
      print('File size: ${(fileSize / 1024).toStringAsFixed(2)}KB');
      print('Upload path: $path');

      final bytes = await file.readAsBytes();
      print('Bytes loaded: ${bytes.length}');

      // Try upload with error details
      try {
        final upload = await storage.from('media').uploadBinary(path, bytes);
        print('Upload successful: $upload');
      } catch (uploadError) {
        print('Supabase upload error: $uploadError');
        throw Exception('Supabase upload failed: $uploadError');
      }

      final publicUrl = storage.from('media').getPublicUrl(path);
      print('Public URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('Image upload error: $e');
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  // Method for web that uploads bytes directly
  static Future<String?> uploadImageBytes(
      Uint8List bytes, String fileName, String capsuleId) async {
    try {
      final path = 'c/$capsuleId/$fileName';
      final storage = Supabase.instance.client.storage;

      print('Uploading image bytes: $fileName');
      print('File size: ${(bytes.length / 1024).toStringAsFixed(2)}KB');
      print('Upload path: $path');

      final upload = await storage.from('media').uploadBinary(path, bytes);
      print('Upload successful: $upload');

      final publicUrl = storage.from('media').getPublicUrl(path);
      print('Public URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('Image bytes upload error: $e');
      return null;
    }
  }

  // Alternative method for web that uses pickAndUploadFile approach
  static Future<String?> uploadImageWeb(String capsuleId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      if (file.bytes == null) {
        throw Exception('Could not read file bytes. File may be too large.');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${file.name}';
      final path = 'c/$capsuleId/$fileName';
      final storage = Supabase.instance.client.storage;

      print('Uploading image via web method: ${file.name}');
      print('File size: ${(file.bytes!.length / 1024).toStringAsFixed(2)}KB');
      print('Upload path: $path');

      final upload =
          await storage.from('media').uploadBinary(path, file.bytes!);
      print('Upload successful: $upload');

      final publicUrl = storage.from('media').getPublicUrl(path);
      print('Public URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('Web image upload error: $e');
      return null;
    }
  }
}
