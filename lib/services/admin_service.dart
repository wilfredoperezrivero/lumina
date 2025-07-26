import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>?> getCurrentAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('admins')
          .select()
          .eq('admin_id', user.id)
          .single();

      return response;
    } catch (e) {
      print('Error fetching admin data: $e');
      return null;
    }
  }

  static Future<String?> getCurrentAdminName() async {
    final admin = await getCurrentAdmin();
    return admin?['name'];
  }

  static Future<String?> getCurrentAdminEmail() async {
    final admin = await getCurrentAdmin();
    return admin?['email'];
  }
}
