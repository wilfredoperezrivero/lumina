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
import 'models/capsule.dart';

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
          path: '/',
          builder: (context, state) => LoginPage(),
        ),
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
          builder: (context, state) =>
              EditCapsulePage(capsule: state.extra as Capsule),
        ),
        GoRoute(
          path: '/admin/capsule_details',
          builder: (context, state) =>
              CapsuleDetailsPage(capsule: state.extra as Capsule),
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
        // Catch-all route for invalid paths (like JWT tokens)
        GoRoute(
          path: '/:path*',
          builder: (context, state) {
            // Extract the unmatched path as a plain string so we can inspect it.
            final path = state.pathParameters['path'] ?? '';
            // If this looks like a JWT token or auth fragment, redirect to login
            if (path.contains('access_token') ||
                path.contains('token_type') ||
                path.contains('eyJ')) {
              return LoginPage();
            }
            // Otherwise show a 404 page
            return Scaffold(
              appBar: AppBar(title: Text('Page Not Found')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text('Page not found', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text('The requested page does not exist'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      child: Text('Go to Login'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
      redirect: (context, state) {
        // 1️⃣ Magic-link guard – pause redirects while Supabase fragment is present or token query exists
        final fragment = Uri.base.fragment;
        final fullUrl = Uri.base.toString();

        // Check if the URL contains auth tokens anywhere
        if (fragment.contains('access_token') ||
            fragment.contains('token_type=bearer') ||
            fullUrl.contains('access_token=') ||
            fullUrl.contains('token_type=bearer') ||
            (state.uri.queryParameters['type'] == 'magiclink' &&
                state.uri.queryParameters.containsKey('token'))) {
          return null; // wait for Supabase to store session and reload redirects
        }

        // 2️⃣ Handle case where fragment contains auth tokens but no valid route
        if (fragment.isNotEmpty && !fragment.startsWith('/')) {
          // This is likely an auth fragment, let Supabase handle it
          return null;
        }

        // 3️⃣ Handle the specific case where GoRouter tries to route the entire JWT
        if (state.uri.path.contains('access_token=') ||
            state.uri.path.contains('token_type=bearer')) {
          // This is an auth token in the path, not a valid route
          return null;
        }

        // 4️⃣ Handle the case where the entire path is a JWT token
        if (state.uri.path.startsWith('access_token=') ||
            state.uri.path.startsWith('eyJ')) {
          // This is a JWT token being treated as a path
          return null;
        }

        // 5️⃣ Emergency guard for any URL that looks like it contains auth tokens
        final currentPath = state.uri.path;
        final currentFragment = state.uri.fragment;
        if (currentPath.contains('access_token') ||
            currentPath.contains('token_type') ||
            currentPath.contains('expires_at') ||
            currentPath.contains('refresh_token') ||
            currentFragment.contains('access_token') ||
            currentFragment.contains('token_type') ||
            currentFragment.contains('expires_at') ||
            currentFragment.contains('refresh_token')) {
          return null; // Let Supabase handle this
        }

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

        // Handle authenticated users
        if (isAuthenticated) {
          final userRole = user.userMetadata?['role'] ?? 'admin';

          // If on login page, redirect based on role
          if (isLoginRoute) {
            return userRole == 'admin' ? '/admin/dashboard' : '/family/capsule';
          }

          // Role-based access control for protected routes
          final isAdminRoute = state.uri.path.startsWith('/admin');
          final isFamilyRoute = state.uri.path.startsWith('/family');

          if (userRole == 'admin' && !isAdminRoute) {
            return '/admin/dashboard';
          }
          if (userRole == 'family' && !isFamilyRoute) {
            return '/family/capsule';
          }
        }

        return null;
      },
      refreshListenable: AuthService.authStateChanges(),
    );
