import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  static User? currentUser() => Supabase.instance.client.auth.currentUser;

  static Future<void> signIn(String email, String password) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signUp(String email, String password) async {
    final res = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  static Future<void> changePassword(String newPassword) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    await Supabase.instance.client.auth.resetPasswordForEmail(email);
  }

  static Future<User> createUserWithEmail(
    String email,
    String password, {
    String? capsuleTitle,
    String? capsuleDescription,
  }) async {
    final response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {
        'role': 'family',
        if (capsuleTitle != null) 'capsule_title': capsuleTitle,
        if (capsuleDescription != null)
          'capsule_description': capsuleDescription,
      },
    );
    if (response.user == null) {
      throw Exception('Failed to create user');
    }
    return response.user!;
  }

  static ChangeNotifier authStateChanges() {
    return _AuthStateNotifier();
  }
}

class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }
}
