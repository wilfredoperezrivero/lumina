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

  // Get all capsules for the current user (admin or family)
  static Future<List<Capsule>> getCapsules() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check user role
    final userRole = user.userMetadata?['role'] ?? 'family';

    if (userRole == 'admin') {
      // Admin can see all their capsules
      final response = await _supabase
          .from('capsules')
          .select()
          .eq('admin_id', user.id)
          .order('created_at', ascending: false);

      return response.map((json) => Capsule.fromJson(json)).toList();
    } else {
      // Family can only see their assigned capsule
      final response = await _supabase
          .from('capsules')
          .select()
          .eq('family_id', user.id)
          .order('created_at', ascending: false);

      return response.map((json) => Capsule.fromJson(json)).toList();
    }
  }

  // Generate video for a capsule
  static Future<void> generateVideo(String capsuleId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Update capsule status to indicate video generation
    await _supabase.from('capsules').update({
      'status': 'generating',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', capsuleId);

    // TODO: Call actual video generation API
    // For now, just simulate the process
    await Future.delayed(Duration(seconds: 2));

    // Update with final video URL (simulated)
    await _supabase.from('capsules').update({
      'status': 'completed',
      'final_video_url': 'https://example.com/videos/$capsuleId.mp4',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', capsuleId);
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
