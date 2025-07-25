import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/settings.dart';
import 'dart:typed_data';

class SettingsService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get settings for the current admin user
  static Future<Settings?> getAdminSettings() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response =
        await _client.from('admins').select().eq('admin_id', user.id).single();

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
  static Future<String> uploadLogoImage(
      Uint8List imageBytes, String fileName) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final filePath = 'logos/${user.id}/$fileName';

    await _client.storage
        .from('admin-assets')
        .uploadBinary(filePath, imageBytes);

    // Get public URL
    final publicUrl =
        _client.storage.from('admin-assets').getPublicUrl(filePath);

    return publicUrl;
  }

  // Delete logo image from storage
  static Future<void> deleteLogoImage(String imagePath) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client.storage.from('admin-assets').remove([imagePath]);
  }
}
