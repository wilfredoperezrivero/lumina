import 'package:supabase_flutter/supabase_flutter.dart';

class CreditsService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Get available credits for the current admin
  static Future<int> getAvailableCredits() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      // Get credits from admins table
      final response = await _supabase
          .from('admins')
          .select('credits')
          .eq('admin_id', user.id)
          .maybeSingle();

      return response?['credits'] ?? 0;
    } catch (e) {
      print('Error getting credits: $e');
      return 0;
    }
  }

  /// Check if admin has enough credits to create a capsule
  static Future<bool> hasEnoughCredits({int required = 1}) async {
    final available = await getAvailableCredits();
    return available >= required;
  }

  /// Validate credits before capsule creation
  static Future<void> validateCreditsBeforeCreation() async {
    final hasCredits = await hasEnoughCredits();
    if (!hasCredits) {
      throw Exception('Insufficient credits. Please purchase more packs.');
    }
  }
}
