import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/capsule.dart';
import 'auth_service.dart';

class CapsuleService {
  static final _supabase = Supabase.instance.client;

  // Create a new capsule
  static Future<Capsule> createCapsule({
    required String name,
    String? dateOfBirth,
    String? dateOfDeath,
    String? language,
    String? image,
    required String adminId,
    String? familyId,
    DateTime? expiresAt,
    String? finalVideoUrl,
    String? status,
    String? familyEmail,
    DateTime? createdAt,
    DateTime? scheduledDate,
  }) async {
    final response = await _supabase
        .from('capsules')
        .insert({
          'name': name,
          if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
          if (dateOfDeath != null) 'date_of_death': dateOfDeath,
          if (language != null) 'language': language,
          if (image != null) 'image': image,
          'admin_id': adminId,
          if (familyId != null) 'family_id': familyId,
          if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
          if (finalVideoUrl != null) 'final_video_url': finalVideoUrl,
          'status': status ?? 'active',
          if (familyEmail != null) 'family_email': familyEmail,
          if (createdAt != null) 'created_at': createdAt.toIso8601String(),
          if (scheduledDate != null)
            'scheduled_date': scheduledDate.toIso8601String(),
        })
        .select()
        .single();

    return Capsule.fromJson(response);
  }

  // Get all capsules created by current user
  static Future<List<Capsule>> getUserCapsules() async {
    final user = AuthService.currentUser();
    if (user == null) throw Exception('User not authenticated');

    final response =
        await _supabase.from('capsules').select().eq('admin_id', user.id);

    final List data = response as List;
    return data
        .map((json) => Capsule.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Update capsule
  static Future<Capsule> updateCapsule({
    required String capsuleId,
    String? name,
    String? dateOfBirth,
    String? dateOfDeath,
    String? language,
    DateTime? scheduledDate,
  }) async {
    final user = AuthService.currentUser();
    if (user == null) throw Exception('User not authenticated');

    // Verify the capsule belongs to this user
    final capsule = await _supabase
        .from('capsules')
        .select()
        .eq('id', capsuleId)
        .eq('admin_id', user.id)
        .single();

    if (capsule == null) throw Exception('Capsule not found or access denied');

    final updateData = <String, dynamic>{};
    if (name != null) updateData['name'] = name;
    if (dateOfBirth != null) updateData['date_of_birth'] = dateOfBirth;
    if (dateOfDeath != null) updateData['date_of_death'] = dateOfDeath;
    if (language != null) updateData['language'] = language;
    if (scheduledDate != null)
      updateData['scheduled_date'] = scheduledDate.toIso8601String();

    final response = await _supabase
        .from('capsules')
        .update(updateData)
        .eq('id', capsuleId)
        .select()
        .single();

    return Capsule.fromJson(response);
  }
}
