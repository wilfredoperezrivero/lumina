import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// User roles supported by the application
enum UserRole { admin, family }

/// Authentication service for handling all auth-related operations
class AuthService extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Current User
  // ---------------------------------------------------------------------------

  /// Returns the currently authenticated user, or null if not logged in
  static User? currentUser() => Supabase.instance.client.auth.currentUser;

  /// Returns the current session, or null if not authenticated
  static Session? currentSession() =>
      Supabase.instance.client.auth.currentSession;

  /// Returns true if the user is authenticated with a valid session
  static bool isAuthenticated() {
    final user = currentUser();
    final session = currentSession();
    return user != null && session != null && !session.isExpired;
  }

  // ---------------------------------------------------------------------------
  // Authentication Methods
  // ---------------------------------------------------------------------------

  /// Sign in with email and password
  /// Returns the authenticated User on success
  /// Throws an exception on failure
  static Future<User> signIn(String email, String password) async {
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final user = response.user ?? Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('Authentication succeeded but no user context available');
    }

    return user;
  }

  /// Sign up a new user with email and password
  /// Optional metadata can be provided (e.g., role, name)
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    return await Supabase.instance.client.auth.signUp(
      email: email.trim(),
      password: password,
      data: metadata,
    );
  }

  /// Sign out the current user
  static Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  /// Change the password for the current user
  static Future<void> changePassword(String newPassword) async {
    final user = currentUser();
    if (user == null) throw Exception('User not authenticated');

    await Supabase.instance.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Send a password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    await Supabase.instance.client.auth.resetPasswordForEmail(email.trim());
  }

  /// Send a magic link to the specified email for passwordless login
  /// redirectUrl specifies where to redirect after successful login
  static Future<void> sendMagicLink(String email, {String? redirectUrl}) async {
    await Supabase.instance.client.auth.signInWithOtp(
      email: email.trim(),
      emailRedirectTo: redirectUrl,
    );
  }

  // ---------------------------------------------------------------------------
  // Role Management
  // ---------------------------------------------------------------------------

  /// Resolve the user's role from metadata
  /// Checks userMetadata first, then appMetadata
  /// Returns null if no role is found
  static UserRole? resolveUserRole(User? user) {
    if (user == null) return null;

    // Check userMetadata first (set during signup)
    final metadataRole = user.userMetadata?['role'];
    if (metadataRole is String && metadataRole.isNotEmpty) {
      return _parseRole(metadataRole);
    }

    // Check appMetadata (set by backend/admin)
    final appMetadataRole = user.appMetadata['role'];
    if (appMetadataRole is String && appMetadataRole.isNotEmpty) {
      return _parseRole(appMetadataRole);
    }
    // Handle case where role is stored as array
    if (appMetadataRole is List && appMetadataRole.isNotEmpty) {
      final firstValue = appMetadataRole.first;
      if (firstValue is String && firstValue.isNotEmpty) {
        return _parseRole(firstValue);
      }
    }

    return null;
  }

  /// Parse a string role into UserRole enum
  static UserRole? _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'family':
        return UserRole.family;
      default:
        return null;
    }
  }

  /// Get the current user's role
  static UserRole? getCurrentUserRole() {
    return resolveUserRole(currentUser());
  }

  /// Check if current user is an admin
  static bool isAdmin() => getCurrentUserRole() == UserRole.admin;

  /// Check if current user is a family member
  static bool isFamily() => getCurrentUserRole() == UserRole.family;

  // ---------------------------------------------------------------------------
  // Auth State Changes
  // ---------------------------------------------------------------------------

  /// Returns a ChangeNotifier that notifies when auth state changes
  /// Use this with GoRouter's refreshListenable
  static ChangeNotifier authStateChanges() {
    return _AuthStateNotifier();
  }

  // ---------------------------------------------------------------------------
  // Auth Redirect Handling
  // ---------------------------------------------------------------------------

  /// Collect auth parameters from both query string and hash fragment
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

  /// Parse URL fragment into key/value pairs
  static Map<String, String> _parseFragmentParameters(String fragment) {
    if (fragment.isEmpty) return <String, String>{};

    // Remove leading slash from GoRouter paths
    final trimmed = fragment.startsWith('/') ? fragment.substring(1) : fragment;

    // Extract query portion after '?'
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

  /// Check if URI is a signup confirmation redirect
  static bool isSignupRedirect(Uri uri) {
    final params = _collectAuthParams(uri);
    final type = params['type'];
    final token = params['token'] ?? params['token_hash'];
    return type == 'signup' && token != null && token.isNotEmpty;
  }

  /// Check if URI is a magic link redirect
  static bool isMagicLinkRedirect(Uri uri) {
    final params = _collectAuthParams(uri);
    final type = params['type'];
    final token = params['token'] ?? params['token_hash'];
    return (type == 'magiclink' || type == 'email') &&
        token != null &&
        token.isNotEmpty;
  }

  /// Check if URI is an invite redirect
  static bool isInviteRedirect(Uri uri) {
    final params = _collectAuthParams(uri);
    final type = params['type'];
    final token = params['token'] ?? params['token_hash'];
    return type == 'invite' && token != null && token.isNotEmpty;
  }

  /// Check if URI is a password recovery redirect
  static bool isRecoveryRedirect(Uri uri) {
    final fullUrl = uri.toString();
    return fullUrl.contains('type=recovery');
  }

  /// Check if URI has any auth redirect that needs processing
  static bool isAuthRedirect(Uri uri) {
    return isSignupRedirect(uri) ||
        isMagicLinkRedirect(uri) ||
        isInviteRedirect(uri);
  }

  /// Check if URL contains auth tokens
  static bool hasAuthTokens(Uri uri) {
    final fragment = uri.fragment;
    final fullUrl = uri.toString();
    return fragment.contains('access_token') ||
        fullUrl.contains('access_token=') ||
        fullUrl.contains('token_type=bearer') ||
        fragment.contains('eyJ'); // JWT prefix
  }

  /// Check if URL contains OTP expired error
  static bool hasOtpExpiredError(Uri uri) {
    final fragment = uri.fragment;
    final fullUrl = uri.toString();
    return fragment.contains('error=access_denied') ||
        fragment.contains('error_code=otp_expired') ||
        fragment.contains('otp_expired') ||
        fullUrl.contains('error=access_denied&error_code=otp_expired');
  }

  /// Complete signup verification flow
  static Future<bool> maybeCompleteSignup(Uri uri) async {
    if (!isSignupRedirect(uri)) return false;
    if (isAuthenticated()) return false;

    final params = _collectAuthParams(uri);
    final token = params['token'] ?? params['token_hash'];
    final email = params['email'];

    if (token == null || token.isEmpty) return false;

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

  /// Complete magic link verification flow
  static Future<bool> maybeCompleteMagicLink(Uri uri) async {
    if (!isMagicLinkRedirect(uri)) return false;
    if (isAuthenticated()) return false;

    final params = _collectAuthParams(uri);
    final token = params['token'] ?? params['token_hash'];
    final email = params['email'];
    final type = params['type'];

    if (token == null || token.isEmpty) return false;

    try {
      final otpType = type == 'magiclink' ? OtpType.magiclink : OtpType.email;
      final response = await Supabase.instance.client.auth.verifyOTP(
        type: otpType,
        token: token,
        email: email,
      );
      return response.session != null;
    } catch (error) {
      debugPrint('Failed to complete magic link verification: $error');
      return false;
    }
  }

  /// Complete invite verification flow
  static Future<bool> maybeCompleteInvite(Uri uri) async {
    if (!isInviteRedirect(uri)) return false;
    if (isAuthenticated()) return false;

    final params = _collectAuthParams(uri);
    final token = params['token'] ?? params['token_hash'];
    final email = params['email'];

    if (token == null || token.isEmpty) return false;

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.invite,
        token: token,
        email: email,
      );
      return response.session != null;
    } catch (error) {
      debugPrint('Failed to complete invite verification: $error');
      return false;
    }
  }

  /// Attempt to complete any supported auth redirect flow
  static Future<bool> maybeCompleteAuth(Uri uri) async {
    if (await maybeCompleteSignup(uri)) return true;
    if (await maybeCompleteMagicLink(uri)) return true;
    if (await maybeCompleteInvite(uri)) return true;
    return false;
  }
}

/// Internal notifier that listens to Supabase auth state changes
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }
}
