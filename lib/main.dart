import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'pages/auth/login.dart';
import 'pages/admin/dashboard.dart';
import 'pages/family/dashboard.dart';
import 'pages/invitee/add_message.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  runApp(const LuminaApp());
}

class LuminaApp extends StatelessWidget {
  const LuminaApp({super.key});

  @override
  Widget build(BuildContext context) {
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
    if (user != null) {
      final role = AuthService.currentUserRole();
      if (role == 'admin') return '/admin/dashboard';
      if (role == 'family') return '/family/dashboard';
      if (role == 'invitee') return '/invitee/message';
    }
    return null;
  },
);
