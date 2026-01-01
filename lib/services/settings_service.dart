import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/settings.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class SettingsService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get settings for the current admin user
  static Future<Settings?> getAdminSettings() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _client
        .from('admins')
        .select()
        .eq('admin_id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return Settings.fromJson(response);
  }

  // Create or update admin settings
  static Future<Settings> saveAdminSettings(Settings settings) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if settings already exist for this admin
    final existingSettings = await _client
        .from('admins')
        .select()
        .eq('admin_id', user.id)
        .maybeSingle();

    if (existingSettings != null) {
      // Update existing settings
      final response = await _client
          .from('admins')
          .update(settings.toJson())
          .eq('admin_id', user.id)
          .select()
          .single();

      return Settings.fromJson(response);
    } else {
      // Create new settings
      final newSettings = settings.copyWith(
        adminId: user.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final response = await _client
          .from('admins')
          .insert(newSettings.toJson())
          .select()
          .single();

      return Settings.fromJson(response);
    }
  }

  // Update specific fields in admin settings
  static Future<Settings> updateAdminSettings(
      Map<String, dynamic> updates) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Add updated_at timestamp
    updates['updated_at'] = DateTime.now().toIso8601String();

    final response = await _client
        .from('admins')
        .update(updates)
        .eq('admin_id', user.id)
        .select()
        .single();

    return Settings.fromJson(response);
  }

  // Upload logo image to Supabase storage
  static Future<String> uploadLogoImage(Uint8List imageBytes) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Convert image to optimized PNG format
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Failed to decode image');

    // Resize if too large (max 512px on longest side, maintaining aspect ratio)
    final resizedImage = image.width > 512 || image.height > 512
        ? img.copyResize(
            image,
            width: image.width > image.height ? 512 : null,
            height: image.height > image.width ? 512 : null,
            interpolation: img.Interpolation.linear,
          )
        : image;

    // Encode as PNG with optimization
    final pngBytes = Uint8List.fromList(img.encodePng(resizedImage));

    // Generate filename with timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = 'logos/${user.id}_$timestamp.png';

    await _client.storage.from('media').uploadBinary(filePath, pngBytes);

    // Get public URL
    final publicUrl = _client.storage.from('media').getPublicUrl(filePath);

    return publicUrl;
  }

  // Delete logo image from storage
  static Future<void> deleteLogoImage(String imagePath) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client.storage.from('media').remove([imagePath]);
  }
}
