import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Auth & Services
import 'services/auth_service.dart';

// Auth Pages
import 'pages/auth/login.dart';
import 'pages/auth/family_login.dart';
import 'pages/auth/reset_password.dart';
import 'pages/auth/link_expired.dart';

// Public Pages (Capsule - no auth required)
import 'pages/public/capsule.dart';

// Admin Pages
import 'pages/admin/dashboard.dart';
import 'pages/admin/create_capsule.dart';
import 'pages/admin/list_capsules.dart';
import 'pages/admin/buy_packs.dart';
import 'pages/admin/settings.dart';
import 'pages/admin/marketing.dart';
import 'pages/admin/edit_capsule.dart';
import 'pages/admin/capsule_details.dart';
import 'pages/admin/register.dart';

// Family Pages
import 'pages/family/family_capsule.dart';
import 'pages/family/family_messages.dart';

// Models
import 'models/capsule.dart';

// -----------------------------------------------------------------------------
// Route Names (for type-safe navigation)
// -----------------------------------------------------------------------------

class AppRoutes {
  // Auth routes
  static const login = '/login';
  static const familyLogin = '/family/login';
  static const register = '/admin/register';
  static const resetPassword = '/reset-password';
  static const linkExpired = '/link-expired';

  // Public routes (capsule - no auth)
  static const capsule = '/capsule/:id';

  // Admin routes
  static const adminDashboard = '/admin/dashboard';
  static const adminCreateCapsule = '/admin/create_capsule';
  static const adminListCapsules = '/admin/list_capsules';
  static const adminBuyPacks = '/admin/buy_packs';
  static const adminSettings = '/admin/settings';
  static const adminMarketing = '/admin/marketing';
  static const adminEditCapsule = '/admin/edit-capsule';
  static const adminCapsuleDetails = '/admin/capsule_details';

  // Family routes
  static const familyCapsule = '/family/capsule';
  static const familyMessages = '/family/messages';
}

// -----------------------------------------------------------------------------
// Router Builder
// -----------------------------------------------------------------------------

/// Builds the application's GoRouter with role-based routing
///
/// Route structure:
/// - Public: /login, /capsule/:id, /reset-password, /admin/register
/// - Admin: /admin/* (requires admin role)
/// - Family: /family/* (requires family role)
GoRouter buildRouter([String? initialRoute]) {
  return GoRouter(
    initialLocation: initialRoute ?? AppRoutes.login,
    debugLogDiagnostics: true,
    refreshListenable: AuthService.authStateChanges(),

    // ---------------------------------------------------------------------------
    // Redirect Logic
    // ---------------------------------------------------------------------------
    redirect: (context, state) {
      final location = state.uri.toString();
      final path = state.uri.path;

      // Check for OTP expired error - redirect to family login
      if (AuthService.hasOtpExpiredError(state.uri)) {
        debugPrint('OTP expired error detected - redirecting to family login');
        return AppRoutes.familyLogin;
      }

      // Handle malformed auth redirect URLs
      if (_isAuthTokenLocation(location)) {
        return location.contains('type=recovery')
            ? AppRoutes.resetPassword
            : AppRoutes.login;
      }

      // Check authentication status
      final isAuthenticated = AuthService.isAuthenticated();
      final userRole = AuthService.getCurrentUserRole();

      // Define route categories
      final isPublicRoute = _isPublicRoute(path);
      final isAdminRoute = path.startsWith('/admin');
      final isFamilyRoute = path.startsWith('/family');
      final isLoginRoute = path == '/login' || path == '/';

      // ----- Unauthenticated users -----
      if (!isAuthenticated) {
        // Allow access to public routes
        if (isPublicRoute) return null;
        // Redirect to login for protected routes
        return AppRoutes.login;
      }

      // ----- Authenticated users -----

      // Allow access to public routes (capsule viewing, password reset)
      if (_isAlwaysAccessible(path)) return null;

      // No role assigned - redirect to login with error handling
      if (userRole == null) {
        if (isLoginRoute) return null;
        return AppRoutes.login;
      }

      // Redirect from login to appropriate dashboard
      if (isLoginRoute) {
        return _getHomeRoute(userRole);
      }

      // Role-based access control
      switch (userRole) {
        case UserRole.admin:
          // Admin trying to access family routes
          if (isFamilyRoute) return AppRoutes.adminDashboard;
          break;
        case UserRole.family:
          // Family trying to access admin routes (except register)
          if (isAdminRoute && path != AppRoutes.register) {
            return AppRoutes.familyCapsule;
          }
          break;
      }

      return null; // Allow navigation
    },

    // ---------------------------------------------------------------------------
    // Routes
    // ---------------------------------------------------------------------------
    routes: [
      // ===== Auth Routes =====
      GoRoute(
        path: '/',
        builder: (context, state) => LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.familyLogin,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return FamilyLoginPage(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => ResetPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.linkExpired,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return LinkExpiredPage(email: email);
        },
      ),

      // ===== Public Routes (Capsule - No Auth Required) =====
      GoRoute(
        path: '/capsule/:id',
        builder: (context, state) {
          final capsuleId = state.pathParameters['id']!;
          return CapsulePage(capsuleId: capsuleId);
        },
      ),

      // ===== Admin Routes =====
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => AdminRegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => AdminDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.adminCreateCapsule,
        builder: (context, state) => CreateCapsulePage(),
      ),
      GoRoute(
        path: AppRoutes.adminListCapsules,
        builder: (context, state) => ListCapsulesPage(),
      ),
      GoRoute(
        path: AppRoutes.adminBuyPacks,
        builder: (context, state) => BuyPacksPage(),
      ),
      GoRoute(
        path: AppRoutes.adminSettings,
        builder: (context, state) => SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.adminMarketing,
        builder: (context, state) => MarketingPage(),
      ),
      GoRoute(
        path: AppRoutes.adminEditCapsule,
        builder: (context, state) {
          final capsule = state.extra as Capsule;
          return EditCapsulePage(capsule: capsule);
        },
      ),
      GoRoute(
        path: AppRoutes.adminCapsuleDetails,
        builder: (context, state) {
          final capsule = state.extra as Capsule;
          return CapsuleDetailsPage(capsule: capsule);
        },
      ),

      // ===== Family Routes =====
      GoRoute(
        path: AppRoutes.familyCapsule,
        builder: (context, state) => FamilyCapsulePage(),
      ),
      GoRoute(
        path: AppRoutes.familyMessages,
        builder: (context, state) => FamilyMessagesPage(),
      ),

      // ===== 404 Fallback =====
      GoRoute(
        path: '/:path(.*)',
        builder: (context, state) {
          final path = state.pathParameters['path'] ?? '';
          final fullUrl = Uri.base.toString();
          final fragment = Uri.base.fragment;

          // Check if this looks like an auth callback with tokens
          final hasAuthTokens = _isAuthTokenLocation(path) ||
              _isAuthTokenLocation(fragment) ||
              fullUrl.contains('access_token');

          if (hasAuthTokens) {
            // If user is authenticated, redirect to their home
            if (AuthService.isAuthenticated()) {
              final role = AuthService.getCurrentUserRole();
              if (role == UserRole.family) {
                // Use a post-frame callback to navigate
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go(AppRoutes.familyCapsule);
                });
              } else if (role == UserRole.admin) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go(AppRoutes.adminDashboard);
                });
              }
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            // Not authenticated - show link expired page
            return const LinkExpiredPage();
          }

          return Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    '404 - Page Not Found',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('The page "/$path" does not exist.'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ],
  );
}

// -----------------------------------------------------------------------------
// Helper Functions
// -----------------------------------------------------------------------------

/// Check if the location contains auth tokens (malformed URL)
bool _isAuthTokenLocation(String location) {
  return location.startsWith('access_token=') ||
      location.contains('token_type=bearer') ||
      location.contains('eyJ'); // JWT prefix
}

/// Check if the path is a public route (no auth required)
bool _isPublicRoute(String path) {
  return path == '/login' ||
      path == '/' ||
      path == AppRoutes.familyLogin ||
      path == AppRoutes.resetPassword ||
      path == AppRoutes.linkExpired ||
      path == AppRoutes.register ||
      path.startsWith('/capsule/');
}

/// Check if the path should always be accessible (even when authenticated)
bool _isAlwaysAccessible(String path) {
  return path == AppRoutes.resetPassword || path.startsWith('/capsule/');
}

/// Get the home route for a given user role
String _getHomeRoute(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return AppRoutes.adminDashboard;
    case UserRole.family:
      return AppRoutes.familyCapsule;
  }
}
