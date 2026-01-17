import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../router.dart';
import '../../theme/app_theme.dart';

class LinkExpiredPage extends StatefulWidget {
  final String? email;

  const LinkExpiredPage({super.key, this.email});

  @override
  State<LinkExpiredPage> createState() => _LinkExpiredPageState();
}

class _LinkExpiredPageState extends State<LinkExpiredPage> {
  final _emailController = TextEditingController();
  bool _isSending = false;
  String? _message;
  bool _isSuccess = false;

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

  Future<void> _requestNewLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _message = 'Please enter your email address';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isSending = true;
      _message = null;
    });

    try {
      await AuthService.sendMagicLink(
        email,
        redirectUrl: 'https://app.luminamemorials.com/family/capsule',
      );

      setState(() {
        _isSending = false;
        _message = 'A new login link has been sent to $email. Please check your inbox.';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isSending = false;
        _message = 'Failed to send login link. Please try again or contact support.';
        _isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: buildAppBar(
        context: context,
        title: 'Link Expired',
        showBackButton: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Icon(
                        Icons.link_off_rounded,
                        size: 48,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Login Link Expired',
                    style: AppTextStyles.h2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    'The login link you clicked has expired or has already been used. Login links can only be used once for security reasons.',
                    style: AppTextStyles.bodySecondary,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: AppDecorations.inputDecoration(
                      label: 'Email Address',
                      prefixIcon: Icons.email_outlined,
                      hint: 'Enter your email to get a new link',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isSending,
                  ),
                  const SizedBox(height: 20),

                  // Message
                  if (_message != null) ...[
                    buildAlertContainer(message: _message!, isError: !_isSuccess),
                    const SizedBox(height: 20),
                  ],

                  // Request new link button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _requestNewLink,
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _isSending ? 'Sending...' : 'Send New Login Link',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: primaryButtonStyle,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Go to login button
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: Text(
                      'Go to Login Page',
                      style: TextStyle(color: AppColors.accent),
                    ),
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
