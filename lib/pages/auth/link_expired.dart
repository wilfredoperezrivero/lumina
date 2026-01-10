import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../router.dart';

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
      appBar: AppBar(
        title: const Text('Login Link Expired'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
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
                  Icon(
                    Icons.link_off,
                    size: 80,
                    color: Colors.orange.shade600,
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Login Link Expired',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'The login link you clicked has expired or has already been used. Login links can only be used once for security reasons.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                      hintText: 'Enter your email to get a new link',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isSending,
                  ),
                  const SizedBox(height: 16),

                  // Message
                  if (_message != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isSuccess ? Colors.green.shade200 : Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isSuccess ? Icons.check_circle : Icons.error_outline,
                            color: _isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _message!,
                              style: TextStyle(
                                color: _isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_message != null) const SizedBox(height: 16),

                  // Request new link button
                  SizedBox(
                    height: 48,
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
                          : const Icon(Icons.send),
                      label: Text(_isSending ? 'Sending...' : 'Send New Login Link'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Go to login button
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('Go to Login Page'),
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
