import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/auth_service.dart';
import '../../router.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _gdprAccepted = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthAndRedirect();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Check if user is already authenticated and redirect to appropriate dashboard
  void _checkAuthAndRedirect() {
    if (!AuthService.isAuthenticated()) return;

    final role = AuthService.getCurrentUserRole();
    if (role == null) return;

    // Use microtask to avoid navigating during build
    Future.microtask(() {
      if (!mounted) return;
      switch (role) {
        case UserRole.admin:
          context.go(AppRoutes.adminDashboard);
          break;
        case UserRole.family:
          context.go(AppRoutes.familyCapsule);
          break;
      }
    });
  }

  /// Handle login form submission
  Future<void> _handleLogin() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.signIn(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      final role = AuthService.resolveUserRole(user);

      setState(() => _isLoading = false);

      if (role == null) {
        // User has no role assigned
        setState(() {
          _errorMessage = 'Your account has no role assigned. Please contact support.';
        });
        await AuthService.signOut();
        return;
      }

      // Navigate based on role
      switch (role) {
        case UserRole.admin:
          context.go(AppRoutes.adminDashboard);
          break;
        case UserRole.family:
          context.go(AppRoutes.familyCapsule);
          break;
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _parseLoginError(e.toString());
      });
    }
  }

  /// Parse error messages into user-friendly text
  String _parseLoginError(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password. Please check your credentials.';
    }
    if (error.contains('Email not confirmed')) {
      return 'Please confirm your email address before logging in.';
    }
    if (error.contains('400')) {
      return 'Login error. Please verify your email or try again.';
    }
    if (error.contains('network') || error.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }
    return 'Login failed. Please try again.';
  }

  /// Show password reset dialog
  Future<void> _showPasswordResetDialog() async {
    final resetEmailController = TextEditingController(text: _emailController.text);
    bool isSending = false;
    String? dialogError;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter your email to receive a password reset link.'),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !isSending,
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 12),
                Text(
                  dialogError!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSending
                  ? null
                  : () async {
                      final email = resetEmailController.text.trim();
                      if (email.isEmpty) {
                        setDialogState(() => dialogError = 'Please enter your email');
                        return;
                      }

                      setDialogState(() {
                        isSending = true;
                        dialogError = null;
                      });

                      try {
                        await AuthService.sendPasswordResetEmail(email);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password reset email sent! Check your inbox.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isSending = false;
                          dialogError = 'Failed to send reset email. Please try again.';
                        });
                      }
                    },
              child: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send'),
            ),
          ],
        ),
      ),
    );

    resetEmailController.dispose();
  }

  /// Open privacy policy URL
  Future<void> _openPrivacyPolicy() async {
    final url = Uri.parse('https://luminamemorials.com/en/privacy-policy');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/logo.png',
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'Welcome to Lumina Memorials',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (_gdprAccepted && !_isLoading) {
                          _handleLogin();
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Forgot password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showPasswordResetDialog,
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // GDPR checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _gdprAccepted,
                          onChanged: (value) {
                            setState(() => _gdprAccepted = value ?? false);
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _openPrivacyPolicy,
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodyMedium,
                                children: [
                                  const TextSpan(text: 'I accept the '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const TextSpan(text: ' and consent to data processing (GDPR)'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Error message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_errorMessage != null) const SizedBox(height: 16),

                    // Login button
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: (_isLoading || !_gdprAccepted) ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Login'),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('New user?'),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.register),
                          child: Text(
                            'Create Account',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Divider
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('OR', style: TextStyle(color: Colors.grey)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Family login link
                    OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.familyLogin),
                      icon: const Icon(Icons.family_restroom),
                      label: const Text('Family Login (Magic Link)'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
