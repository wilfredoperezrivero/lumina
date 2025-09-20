import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Pages
import 'pages/auth/login.dart';
import 'pages/auth/reset_password.dart';
import 'pages/public/capsule.dart';

// Admin
import 'pages/admin/dashboard.dart';
import 'pages/admin/create_capsule.dart';
import 'pages/admin/list_capsules.dart';
import 'pages/admin/buy_packs.dart';
import 'pages/admin/settings.dart';
import 'pages/admin/marketing.dart';
import 'pages/admin/edit_capsule.dart';
import 'pages/admin/capsule_details.dart';
import 'pages/admin/register.dart';

// Family
import 'pages/family/family_capsule.dart';
import 'pages/family/family_messages.dart';

import 'models/capsule.dart';
import 'services/auth_service.dart';

/// Builds the application's [GoRouter] with grouped routes and concise redirect logic.
GoRouter buildRouter([String? initialRoute]) {
  bool _looksLikeAuthToken(String input) =>
      input.contains('access_token') ||
      input.contains('token_type') ||
      input.contains('eyJ'); // JWT prefix

  return GoRouter(
    initialLocation: initialRoute ?? '/login',
    routes: [
      // ---------- Public & auth routes ----------
      GoRoute(path: '/', builder: (c, s) => LoginPage()),
      GoRoute(path: '/login', builder: (c, s) => LoginPage()),
      GoRoute(path: '/reset-password', builder: (c, s) => ResetPasswordPage()),
      GoRoute(
        path: '/capsule/:id',
        builder: (c, s) => CapsulePage(capsuleId: s.pathParameters['id']!),
      ),

      // ---------- Admin routes ----------
      GoRoute(
          path: '/admin/dashboard', builder: (c, s) => AdminDashboardPage()),
      GoRoute(
          path: '/admin/create_capsule',
          builder: (c, s) => CreateCapsulePage()),
      GoRoute(
          path: '/admin/list_capsules', builder: (c, s) => ListCapsulesPage()),
      GoRoute(path: '/admin/buy_packs', builder: (c, s) => BuyPacksPage()),
      GoRoute(path: '/admin/settings', builder: (c, s) => SettingsPage()),
      GoRoute(path: '/admin/marketing', builder: (c, s) => MarketingPage()),
      GoRoute(
        path: '/admin/edit-capsule',
        builder: (c, s) => EditCapsulePage(capsule: s.extra as Capsule),
      ),
      GoRoute(
        path: '/admin/capsule_details',
        builder: (c, s) => CapsuleDetailsPage(capsule: s.extra as Capsule),
      ),
      GoRoute(path: '/admin/register', builder: (c, s) => AdminRegisterPage()),

      // ---------- Family routes ----------
      GoRoute(path: '/family/capsule', builder: (c, s) => FamilyCapsulePage()),
      GoRoute(
          path: '/family/messages', builder: (c, s) => FamilyMessagesPage()),

      // ---------- Fallback ----------
      GoRoute(
        path: '/:path*',
        builder: (context, state) {
          final path = state.pathParameters['path'] ?? '';
          final fragment = Uri.base.fragment;
          if (_looksLikeAuthToken(path) || _looksLikeAuthToken(fragment)) {
            return LoginPage();
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: const Center(child: Text('404 – Page Not Found')),
          );
        },
      ),
    ],

    // ------------ Redirect logic ------------
    redirect: (context, state) {
      final fragment = Uri.base.fragment;
      final fullUrl = Uri.base.toString();
      final signupRedirect = AuthService.isSignupRedirect(Uri.base);
      final hasAuthTokens = _looksLikeAuthToken(fragment) ||
          fullUrl.contains('access_token=') ||
          fullUrl.contains('token_type=bearer') ||
          signupRedirect;

      final user = Supabase.instance.client.auth.currentUser;
      final session = Supabase.instance.client.auth.currentSession;
      final isAuthenticated =
          user != null && session != null && !session.isExpired;

      // Wait for Supabase to process magic-link tokens
      if (!isAuthenticated && hasAuthTokens) return null;

      final path = state.uri.path;
      final isLogin = path == '/login' || path == '/';
      final isReset = path == '/reset-password';
      final isPublicCapsule = path.startsWith('/capsule/');

      if (!isAuthenticated && !isLogin && !isReset && !isPublicCapsule) {
        return '/login';
      }

      if (isAuthenticated) {
        final role = AuthService.resolveUserRole(user);
        if (isLogin) {
          return role == 'admin' ? '/admin/dashboard' : '/family/capsule';
        }
        final isAdminRoute = path.startsWith('/admin');
        final isFamilyRoute = path.startsWith('/family');
        if (role == 'admin' && !isAdminRoute) return '/admin/dashboard';
        if (role == 'family' && !isFamilyRoute) return '/family/capsule';
      }
      return null; // no redirect
    },
    refreshListenable: AuthService.authStateChanges(),
  );
}
