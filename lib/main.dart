import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/auth/login.dart';
import 'pages/admin/dashboard.dart';
import 'pages/family/dashboard.dart';
import 'pages/invitee/add_message.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://honbdlyinaybyojfiihu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhvbmJkbHlpbmF5YnlvamZpaWh1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEwNzk0NDksImV4cCI6MjA2NjY1NTQ0OX0.MIBhPKFoXJcNdg6gb5AfqOvDeMMqY1UCr42lMPpblyI',
  );
  runApp(const ProviderScope(child: LuminaApp()));
}

class LuminaApp extends ConsumerWidget {
  const LuminaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Lumina',
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/login',
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
      path: '/family/dashboard',
      builder: (context, state) => FamilyDashboardPage(),
    ),
    GoRoute(
      path: '/invitee/message',
      builder: (context, state) => AddMessagePage(),
    ),
  ],
  redirect: (context, state) {
    final user = AuthService.currentUser();
    if (user == null && state.uri.path != '/login') {
      return '/login';
    }
    if (user != null && state.uri.path == '/login') {
      final role = AuthService.currentUserRole();
      if (role == 'admin') return '/admin/dashboard';
      if (role == 'family') return '/family/dashboard';
      if (role == 'invitee') return '/invitee/message';
      // Default fallback if role is not set
      return '/family/dashboard';
    }
    return null;
  },
  refreshListenable: AuthService.authStateChanges(),
);
