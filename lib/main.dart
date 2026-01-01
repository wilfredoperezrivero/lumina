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

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

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

    debugPrint('=== AUTH REDIRECT ===');
    debugPrint('URL: ${uri.toString()}');

    // Handle password recovery flow
    if (AuthService.isRecoveryRedirect(uri)) {
      initialRoute = AppRoutes.resetPassword;
      debugPrint('Recovery redirect detected');
    }

    // Check if fragment contains access_token (implicit flow)
    if (AuthService.hasAuthTokens(uri)) {
      debugPrint('Auth tokens detected in URL');
      // Supabase should have auto-handled this during initialize
      final session = AuthService.currentSession();
      if (session != null) {
        debugPrint('Session established: ${session.user.email}');
      }
    }

    // Try to complete auth from URL (handles invite, signup, magiclink with token param)
    final authCompleted = await AuthService.maybeCompleteAuth(uri);
    debugPrint('Auth completed via maybeCompleteAuth: $authCompleted');
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
          }
          // Complete any other auth flows
          await AuthService.maybeCompleteAuth(uri);
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
