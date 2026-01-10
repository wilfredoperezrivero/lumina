import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

import 'router.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load();

  // Initialize Supabase - wrap in try-catch to handle expired tokens
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );
  } catch (e) {
    debugPrint('Supabase initialization error (may be expired token): $e');
    // Continue anyway - we'll handle the auth state below
  }

  // Determine initial route based on auth state
  String? initialRoute = await _handleAuthRedirect();

  runApp(
    ProviderScope(
      child: LuminaApp(initialRoute: initialRoute),
    ),
  );
}

/// Handle auth redirects from email links (signup, magic link, invite, recovery)
/// Returns the initial route to navigate to
Future<String?> _handleAuthRedirect() async {
  String? initialRoute;

  if (kIsWeb) {
    // Web: Check Uri.base for auth tokens
    final uri = Uri.base;
    final fullUrl = uri.toString();
    final fragment = uri.fragment;

    debugPrint('=== AUTH REDIRECT ===');
    debugPrint('URL: $fullUrl');
    debugPrint('Fragment: $fragment');

    // Handle password recovery flow
    if (AuthService.isRecoveryRedirect(uri)) {
      initialRoute = AppRoutes.resetPassword;
      debugPrint('Recovery redirect detected');
      return initialRoute;
    }

    // Check for OTP expired error in URL fragment
    if (AuthService.hasOtpExpiredError(uri)) {
      debugPrint('OTP expired error detected in URL - redirecting to family login');
      return AppRoutes.familyLogin;
    }

    // Check if this is a magic link redirect
    // Magic links come with access_token in fragment OR have /family/capsule in the URL
    final hasAuthTokensInUrl = fullUrl.contains('access_token') ||
        fragment.contains('access_token') ||
        fullUrl.contains('token_type=bearer') ||
        fragment.contains('token_type=bearer');

    final hasOtpError = AuthService.hasOtpExpiredError(uri);
    final isFamilyRedirectUrl = fullUrl.contains('/family/capsule') && !hasOtpError;
    final isMagicLinkUrl = hasAuthTokensInUrl || isFamilyRedirectUrl;

    debugPrint('Has auth tokens: $hasAuthTokensInUrl');
    debugPrint('Is family redirect: $isFamilyRedirectUrl');
    debugPrint('Is magic link URL: $isMagicLinkUrl');

    // Check if fragment contains access_token (implicit flow)
    if (hasAuthTokensInUrl) {
      debugPrint('Auth tokens detected in URL');
      // Supabase should have auto-handled this during initialize
      final session = AuthService.currentSession();
      if (session != null) {
        debugPrint('Session established: ${session.user.email}');
      } else {
        debugPrint('No session after token detection - token may be expired');
      }
    }

    // Try to complete auth from URL (handles invite, signup, magiclink with token param)
    try {
      final authCompleted = await AuthService.maybeCompleteAuth(uri);
      debugPrint('Auth completed via maybeCompleteAuth: $authCompleted');
    } catch (e) {
      debugPrint('Auth completion failed (token may be expired): $e');
      // Don't fail - user might already be logged in from a previous session
    }

    // After attempting auth, check if user is now authenticated
    final isAuthenticated = AuthService.isAuthenticated();
    debugPrint('Is authenticated: $isAuthenticated');

    if (isAuthenticated) {
      final role = AuthService.getCurrentUserRole();
      debugPrint('User authenticated with role: $role');

      // Redirect authenticated user to appropriate home
      if (role == UserRole.family) {
        initialRoute = AppRoutes.familyCapsule;
      } else if (role == UserRole.admin) {
        initialRoute = AppRoutes.adminDashboard;
      }
    } else {
      debugPrint('User not authenticated after redirect handling');
      // If this was a magic link URL but auth failed, show family login page
      if (isMagicLinkUrl) {
        debugPrint('Magic link expired or invalid - redirecting to family login');
        initialRoute = AppRoutes.familyLogin;
      }
    }

    debugPrint('Initial route: $initialRoute');
    debugPrint('=== END AUTH REDIRECT ===');
  } else {
    // Mobile: Use uni_links for deep linking
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        final uri = Uri.tryParse(initialLink);
        if (uri != null) {
          // Handle password recovery
          if (AuthService.isRecoveryRedirect(uri)) {
            initialRoute = AppRoutes.resetPassword;
          } else {
            // Complete any other auth flows
            try {
              await AuthService.maybeCompleteAuth(uri);
            } catch (e) {
              debugPrint('Auth completion failed: $e');
            }

            // Check if user is authenticated and set route
            if (AuthService.isAuthenticated()) {
              final role = AuthService.getCurrentUserRole();
              if (role == UserRole.family) {
                initialRoute = AppRoutes.familyCapsule;
              } else if (role == UserRole.admin) {
                initialRoute = AppRoutes.adminDashboard;
              }
            } else {
              // Check if this looks like a magic link URL
              final fullUrl = uri.toString();
              if (fullUrl.contains('access_token') || fullUrl.contains('/family/')) {
                initialRoute = AppRoutes.familyLogin;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error handling deep link: $e');
    }
  }

  return initialRoute;
}

class LuminaApp extends ConsumerWidget {
  final String? initialRoute;

  const LuminaApp({super.key, this.initialRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Lumina Memorials',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      routerConfig: buildRouter(initialRoute),
    );
  }
}
