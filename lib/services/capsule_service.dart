import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/capsule.dart';
import 'auth_service.dart';

class CapsuleService {
  static final _supabase = Supabase.instance.client;

  // Create a new capsule
  static Future<Capsule> createCapsule({
    required String name,
    required String description,
    DateTime? scheduledDate,
    Map<String, dynamic>? settings,
  }) async {
    final user = AuthService.currentUser();
    if (user == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('capsules')
        .insert({
          'name': name,
          'description': description,
          'admin_id': user.id,
          'scheduled_date': scheduledDate?.toIso8601String(),
          'status': 'draft',
          'settings': settings ?? {},
        })
        .select()
        .single();

    return Capsule.fromJson(response);
  }

  // Get all capsules created by current user
  static Future<List<Capsule>> getUserCapsules() async {
    final user = AuthService.currentUser();
    if (user == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('capsules')
        .select()
        .eq('admin_id', user.id)
        .order('created_at', ascending: false);

    return response.map((json) => Capsule.fromJson(json)).toList();
  }

  // Update capsule
  static Future<Capsule> updateCapsule({
    required String capsuleId,
    String? name,
    String? description,
    DateTime? scheduledDate,
    Map<String, dynamic>? settings,
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
    if (description != null) updateData['description'] = description;
    if (scheduledDate != null)
      updateData['scheduled_date'] = scheduledDate.toIso8601String();
    if (settings != null) updateData['settings'] = settings;

    final response = await _supabase
        .from('capsules')
        .update(updateData)
        .eq('id', capsuleId)
        .select()
        .single();

    return Capsule.fromJson(response);
  }

  // Delete capsule
  static Future<void> deleteCapsule(String capsuleId) async {
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

    await _supabase.from('capsules').delete().eq('id', capsuleId);
  }

  // Get messages for a capsule
  static Future<List<CapsuleMessage>> getCapsuleMessages(
      String capsuleId) async {
    final user = AuthService.currentUser();
    if (user == null) throw Exception('User not authenticated');

    // Verify access to capsule
    final capsule = await _supabase
        .from('capsules')
        .select()
        .eq('id', capsuleId)
        .eq('admin_id', user.id)
        .single();

    if (capsule == null) throw Exception('Access denied');

    final response = await _supabase
        .from('capsule_messages')
        .select()
        .eq('capsule_id', capsuleId)
        .order('created_at', ascending: false);

    return response.map((json) => CapsuleMessage.fromJson(json)).toList();
  }

  // Submit message to capsule
  static Future<CapsuleMessage> submitMessage({
    required String capsuleId,
    required String message,
    String? mediaUrl,
  }) async {
    final user = AuthService.currentUser();
    if (user == null) throw Exception('User not authenticated');

    // Verify access to capsule
    final capsule = await _supabase
        .from('capsules')
        .select()
        .eq('id', capsuleId)
        .eq('admin_id', user.id)
        .single();

    if (capsule == null) throw Exception('Access denied');

    final response = await _supabase
        .from('capsule_messages')
        .insert({
          'capsule_id': capsuleId,
          'message': message,
          'media_url': mediaUrl,
          'status': 'submitted',
        })
        .select()
        .single();

    return CapsuleMessage.fromJson(response);
  }
}
