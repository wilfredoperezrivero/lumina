import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/auth_service.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Auth pages
import 'pages/auth/login.dart';
import 'pages/auth/reset_password.dart';

// Admin pages
import 'pages/admin/dashboard.dart';
import 'pages/admin/create_capsule.dart';
import 'pages/admin/list_capsules.dart';
import 'pages/admin/buy_packs.dart';
import 'pages/admin/settings.dart';
import 'pages/admin/marketing.dart';
import 'pages/admin/edit_capsule.dart';
import 'pages/admin/capsule_details.dart';
import 'pages/admin/register.dart';

// Family pages
import 'pages/family/family_capsule.dart';
import 'pages/family/family_messages.dart';
import 'pages/public/capsule.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
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
        // Public routes (no authentication required) - HIGHEST PRIORITY
        GoRoute(
          path: '/capsule/:id',
          builder: (context, state) {
            final capsuleId = state.pathParameters['id']!;
            return CapsulePage(capsuleId: capsuleId);
          },
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginPage(),
        ),
        GoRoute(
          path: '/admin/register',
          builder: (context, state) => AdminRegisterPage(),
        ),
        // Admin routes
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => AdminDashboardPage(),
        ),
        GoRoute(
          path: '/admin/create_capsule',
          builder: (context, state) => CreateCapsulePage(),
        ),
        GoRoute(
          path: '/admin/edit-capsule',
          builder: (context, state) => EditCapsulePage(),
        ),
        GoRoute(
          path: '/admin/capsule_details',
          builder: (context, state) => CapsuleDetailsPage(),
        ),
        GoRoute(
          path: '/admin/list_capsules',
          builder: (context, state) => ListCapsulesPage(),
        ),
        GoRoute(
          path: '/admin/buy_packs',
          builder: (context, state) => BuyPacksPage(),
        ),
        GoRoute(
          path: '/admin/settings',
          builder: (context, state) => SettingsPage(),
        ),
        GoRoute(
          path: '/admin/marketing',
          builder: (context, state) => MarketingPage(),
        ),
        // Family routes
        GoRoute(
          path: '/family/capsule',
          builder: (context, state) => FamilyCapsulePage(),
        ),
        GoRoute(
          path: '/family/messages',
          builder: (context, state) => FamilyMessagesPage(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => ResetPasswordPage(),
        ),
      ],
      redirect: (context, state) {
        final user = Supabase.instance.client.auth.currentUser;
        final session = Supabase.instance.client.auth.currentSession;
        final isAuthenticated =
            user != null && session != null && !session.isExpired;

        final isLoginRoute = state.uri.path == '/login';
        final isResetPasswordRoute = state.uri.path == '/reset-password';
        final isRegisterRoute = state.uri.path == '/admin/register';
        final isPublicCapsuleRoute = state.uri.path.startsWith('/capsule/');

        // PUBLIC ROUTES HAVE ABSOLUTE PRIORITY - NO REDIRECTS
        if (isPublicCapsuleRoute || isRegisterRoute) {
          return null; // Allow access without authentication
        }

        // If not authenticated and not on public routes, redirect to login
        if (!isAuthenticated && !isLoginRoute && !isResetPasswordRoute) {
          return '/login';
        }

        // If authenticated and on login, redirect based on role
        if (isAuthenticated && isLoginRoute) {
          final userRole = user!.userMetadata?['role'] ?? 'admin';
          if (userRole == 'admin') {
            return '/admin/dashboard';
          } else {
            return '/family/capsule';
          }
        }

        // If authenticated, check role-based access
        if (isAuthenticated) {
          final userRole = user!.userMetadata?['role'] ?? 'admin';
          final isAdminRoute = state.uri.path.startsWith('/admin');
          final isFamilyRoute = state.uri.path.startsWith('/family');

          // Admin users can access admin routes
          if (userRole == 'admin' && isAdminRoute) {
            return null;
          }

          // Family users can access family routes
          if (userRole == 'family' && isFamilyRoute) {
            return null;
          }

          // Redirect based on role
          if (userRole == 'admin') {
            return '/admin/dashboard';
          } else {
            return '/family/capsule';
          }
        }

        return null;
      },
      refreshListenable: AuthService.authStateChanges(),
    );
