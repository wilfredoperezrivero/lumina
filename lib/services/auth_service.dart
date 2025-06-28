import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static User? currentUser() => Supabase.instance.client.auth.currentUser;

  static Future<void> signIn(String email, String password) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signUp(String email, String password, String role) async {
    final res = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {'role': role},
    );
  }

  static String? currentUserRole() {
    final user = currentUser();
    return user?.userMetadata?['role'];
  }
}