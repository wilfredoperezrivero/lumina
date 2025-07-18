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

  static Future<void> deleteCapsule(String capsuleId) async {
    final user = AuthService.currentUser();
    if (user == null) throw Exception('User not authenticated');
    await _supabase
        .from('capsules')
        .delete()
        .eq('id', capsuleId)
        .eq('admin_id', user.id);
  }
}
