import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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
      final upload = await storage.from('media').uploadBinary(path, bytes);
      final publicUrl = storage.from('media').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  static Future<void> submitMessage({
    required String capsuleId,
    String? text,
    String? audioUrl,
    String? videoUrl,
  }) async {
    await Supabase.instance.client.from('messages').insert({
      'capsule_id': capsuleId,
      'content_text': text,
      'content_audio_url': audioUrl,
      'content_video_url': videoUrl,
      'submitted_at': DateTime.now().toIso8601String(),
    });
  }
}
