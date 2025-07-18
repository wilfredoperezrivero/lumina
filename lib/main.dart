import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/auth/login.dart';
import 'pages/admin/dashboard.dart';
import 'pages/admin/create_capsule.dart';
import 'pages/admin/list_capsules.dart';
import 'services/auth_service.dart';
import 'pages/auth/reset_password.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://honbdlyinaybyojfiihu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhvbmJkbHlpbmF5YnlvamZpaWh1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEwNzk0NDksImV4cCI6MjA2NjY1NTQ0OX0.MIBhPKFoXJcNdg6gb5AfqOvDeMMqY1UCr42lMPpblyI',
  );
  // Listen for incoming links for password reset
  final initialLink = await getInitialLink();
  if (initialLink != null && initialLink.contains('type=recovery')) {
    runApp(
        const ProviderScope(child: LuminaApp(initialRoute: '/reset-password')));
    return;
  }
  runApp(const ProviderScope(child: LuminaApp()));
}

class LuminaApp extends ConsumerWidget {
  final String? initialRoute;
  const LuminaApp({super.key, this.initialRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Lumina',
      routerConfig: _router(initialRoute),
    );
  }
}

GoRouter _router([String? initialRoute]) => GoRouter(
      initialLocation: initialRoute ?? '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginPage(),
        ),
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => AdminDashboardPage(),
        ),
        GoRoute(
          path: '/admin/create_capsule',
          builder: (context, state) => CreateCapsulePage(),
        ),
        GoRoute(
          path: '/admin/list_capsules',
          builder: (context, state) => ListCapsulesPage(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => ResetPasswordPage(),
        ),
      ],
      redirect: (context, state) {
        final user = AuthService.currentUser();
        final isLoginRoute = state.uri.path == '/login';

        if (user == null && !isLoginRoute) {
          return '/login';
        }

        if (user != null && isLoginRoute) {
          return '/admin/dashboard';
        }

        return null;
      },
      refreshListenable: AuthService.authStateChanges(),
    );
