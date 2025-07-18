import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordPage extends StatefulWidget {
  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _submit() async {
    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a new password';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      await AuthService.changePassword(_passwordController.text);
      setState(() {
        _successMessage = 'Password changed successfully!';
        _isLoading = false;
      });
      await Future.delayed(Duration(seconds: 2));
      if (mounted) context.go('/login');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to change password: \\${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Enter your new password',
                  style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: 24),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                onSubmitted: (_) => _submit(),
              ),
              SizedBox(height: 16),
              if (_errorMessage != null)
                Text(_errorMessage!, style: TextStyle(color: Colors.red)),
              if (_successMessage != null)
                Text(_successMessage!, style: TextStyle(color: Colors.green)),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Change Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
