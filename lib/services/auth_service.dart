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

  /// Extracts the auth-related parameters from a [Uri] that Supabase uses when
  /// redirecting back to the application.
  ///
  /// Supabase can return parameters either in the query string or the hash
  /// fragment, depending on the flow (email confirmations typically use the
  /// query string while magic links use the hash). This helper consolidates
  /// those values into a single map.
  static Map<String, String> _collectAuthParams(Uri uri) {
    final params = <String, String>{};

    void addParams(Map<String, String> source) {
      source.forEach((key, value) {
        if (value.isEmpty) return;
        params.putIfAbsent(key, () => value);
      });
    }

    addParams(uri.queryParameters);
    addParams(_parseFragmentParameters(uri.fragment));

    return params;
  }

  /// Parses a hash fragment (the part after '#') into key/value pairs while
  /// safely ignoring non-query fragments such as `#/login`.
  static Map<String, String> _parseFragmentParameters(String fragment) {
    if (fragment.isEmpty) return <String, String>{};

    // Remove any leading slash GoRouter might add (e.g. '#/login').
    final trimmed = fragment.startsWith('/') ? fragment.substring(1) : fragment;

    // Some redirects include a path segment before the query (e.g. 'callback?').
    final queryPortion = trimmed.contains('?')
        ? trimmed.substring(trimmed.indexOf('?') + 1)
        : trimmed;

    if (!queryPortion.contains('=')) return <String, String>{};

    try {
      return Uri.splitQueryString(queryPortion);
    } catch (_) {
      return <String, String>{};
    }
  }

  /// Determines whether the provided [uri] represents a Supabase signup
  /// confirmation redirect (i.e. the user clicked the confirm-email link).
  static bool isSignupRedirect(Uri uri) {
    final params = _collectAuthParams(uri);
    final type = params['type'];
    final token = params['token'] ?? params['token_hash'];
    return type == 'signup' && token != null && token.isNotEmpty;
  }

  /// Attempts to complete a Supabase email-signup confirmation flow by
  /// exchanging the provided redirect parameters for an authenticated session.
  ///
  /// Returns `true` if Supabase responds with a valid session.
  static Future<bool> maybeCompleteSignup(Uri uri) async {
    if (!isSignupRedirect(uri)) {
      return false;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && !session.isExpired) {
      return false; // Already authenticated.
    }

    final params = _collectAuthParams(uri);
    final token = params['token'] ?? params['token_hash'];
    final email = params['email'];

    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.signup,
        token: token,
        email: email,
      );
      return response.session != null;
    } catch (error) {
      debugPrint('Failed to complete signup verification: $error');
      return false;
    }
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
