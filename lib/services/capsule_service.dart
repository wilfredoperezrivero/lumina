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
    try {
      print('DEBUG: CapsuleService.createCapsule called with:');
      print('DEBUG: name: $name');
      print('DEBUG: adminId: $adminId');
      print('DEBUG: familyId: $familyId');

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

      print('DEBUG: Database response: $response');
      if (response == null) {
        throw Exception('No response from database when creating capsule');
      }

      print('DEBUG: Creating Capsule.fromJson with response');
      final capsule = Capsule.fromJson(response);
      print('DEBUG: Capsule created successfully: ${capsule.id}');
      return capsule;
    } catch (e) {
      print('DEBUG: Error in createCapsule: $e');
      throw Exception('Failed to create capsule: ${e.toString()}');
    }
  }

  // Get all capsules for the current user (admin or family)
  static Future<List<Capsule>> getCapsules() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check user role
    final userRole = user.userMetadata?['role'] ?? 'admin';

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

  // Get paginated capsules for the current user (admin or family)
  static Future<List<Capsule>> getCapsulesPaginated({
    required int page,
    required int pageSize,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check user role
    final userRole = user.userMetadata?['role'] ?? 'admin';

    final offset = page * pageSize;

    if (userRole == 'admin') {
      // Admin can see all their capsules
      final response = await _supabase
          .from('capsules')
          .select()
          .eq('admin_id', user.id)
          .order('created_at', ascending: false)
          .range(offset, offset + pageSize - 1);

      return response.map((json) => Capsule.fromJson(json)).toList();
    } else {
      // Family can only see their assigned capsule
      final response = await _supabase
          .from('capsules')
          .select()
          .eq('family_id', user.id)
          .order('created_at', ascending: false)
          .range(offset, offset + pageSize - 1);

      return response.map((json) => Capsule.fromJson(json)).toList();
    }
  }

  // Get total count of capsules for the current user
  static Future<int> getCapsulesCount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check user role
    final userRole = user.userMetadata?['role'] ?? 'admin';

    if (userRole == 'admin') {
      // Admin can see all their capsules
      final response =
          await _supabase.from('capsules').select('*').eq('admin_id', user.id);

      return response.length;
    } else {
      // Family can only see their assigned capsule
      final response =
          await _supabase.from('capsules').select('*').eq('family_id', user.id);

      return response.length;
    }
  }

  // Close capsule and generate video
  static Future<void> closeCapsuleAndGenerateVideo(String capsuleId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Call the database function that closes the capsule and adds job to queue
      await _supabase.rpc('close_capsule_and_generate_video', params: {
        'capsule_id': capsuleId,
      });
    } catch (e) {
      throw Exception(
          'Failed to close capsule and generate video: ${e.toString()}');
    }
  }

  // Generate video for a capsule (legacy method - kept for backward compatibility)
  static Future<void> generateVideo(String capsuleId) async {
    // Use the new method
    await closeCapsuleAndGenerateVideo(capsuleId);
  }

  // Get capsule by ID (public access)
  static Future<Capsule> getCapsuleById(String capsuleId) async {
    final response =
        await _supabase.from('capsules').select().eq('id', capsuleId).single();

    if (response == null) throw Exception('Capsule not found');
    return Capsule.fromJson(response);
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
