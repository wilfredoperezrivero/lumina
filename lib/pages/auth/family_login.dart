import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class FamilyLoginPage extends StatefulWidget {
  final String? email;

  const FamilyLoginPage({super.key, this.email});

  @override
  State<FamilyLoginPage> createState() => _FamilyLoginPageState();
}

class _FamilyLoginPageState extends State<FamilyLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendMagicLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
      _isError = false;
    });

    try {
      await AuthService.sendMagicLink(
        _emailController.text,
        redirectUrl: 'https://app.luminamemorials.com/family/capsule',
      );

      setState(() {
        _isLoading = false;
        _message = 'Magic link sent! Check your email and click the link to log in.';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Failed to send magic link. Please try again.';
        _isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: buildAppBar(
        context: context,
        title: 'Family Login',
        onBack: () => context.go('/login'),
      ),
      body: Center(
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
                  // Icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: const Icon(
                        Icons.email_outlined,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Login with Magic Link',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h2,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Enter your email to receive a login link',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySecondary,
                  ),
                  const SizedBox(height: 40),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: AppDecorations.inputDecoration(
                      label: 'Email',
                      prefixIcon: Icons.email_outlined,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enabled: !_isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Send button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendMagicLink,
                      style: primaryButtonStyle,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Send Magic Link',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),

                  // Message
                  if (_message != null) ...[
                    const SizedBox(height: 20),
                    buildAlertContainer(message: _message!, isError: _isError),
                  ],

                  const SizedBox(height: 24),

                  // Info text
                  buildInfoTip(
                    message: 'You will receive an email with a link to log in. The link is valid for 24 hours.',
                    icon: Icons.info_outline_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
