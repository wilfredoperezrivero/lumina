import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  static User? currentUser() => Supabase.instance.client.auth.currentUser;

  static Future<User> signIn(String email, String password) async {
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user ?? Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('Authentication succeeded without user context');
    }

    return user;
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

  static ChangeNotifier authStateChanges() {
    return _AuthStateNotifier();
  }

  /// Safely resolve the current role for a Supabase [User].
  /// Falls back to app_metadata, then the provided [fallbackRole].
  static String resolveUserRole(User? user, {String fallbackRole = 'admin'}) {
    if (user == null) return fallbackRole;

    final metadataRole = user.userMetadata?['role'];
    if (metadataRole is String && metadataRole.isNotEmpty) {
      return metadataRole;
    }

    final appMetadataRole = user.appMetadata['role'];
    if (appMetadataRole is String && appMetadataRole.isNotEmpty) {
      return appMetadataRole;
    }
    if (appMetadataRole is List && appMetadataRole.isNotEmpty) {
      final firstValue = appMetadataRole.first;
      if (firstValue is String && firstValue.isNotEmpty) {
        return firstValue;
      }
    }

    return fallbackRole;
  }
}

class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }
}
