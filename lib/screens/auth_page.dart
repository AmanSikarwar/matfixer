import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:matfixer/services/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final double _mobileWidth = 600;
  final double _maxFormWidth = 450;

  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _isLoading = false;
  String _error = '';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleFormMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error = '';
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      try {
        if (_isLogin) {
          await _authService.signInWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
        } else {
          await _authService.registerWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
        }
      } catch (e) {
        setState(() {
          _error = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > _mobileWidth;

    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Sign In' : 'Create Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Container(
              width: isDesktop ? _maxFormWidth : double.infinity,
              constraints: BoxConstraints(
                maxWidth: isDesktop ? _maxFormWidth : screenWidth - 32,
              ),
              child: Card(
                elevation: isDesktop ? 4 : 0,
                shape:
                    isDesktop
                        ? RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        )
                        : null,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.auto_fix_high,
                          size: isDesktop ? 100 : 80,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'MatFixer',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isDesktop ? 28 : 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: isDesktop ? 40 : 32),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (!_isLogin && value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirm Password',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_error.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              _error,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: isDesktop ? 20 : 16,
                            ),
                          ),
                          child:
                              _isLoading
                                  ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                    ),
                                  )
                                  : Text(
                                    _isLogin ? 'Sign In' : 'Create Account',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 16 : 14,
                                    ),
                                  ),
                        ),
                        const SizedBox(height: 16),

                        TextButton(
                          onPressed: _toggleFormMode,
                          child: Text(
                            _isLogin
                                ? 'Need an account? Register'
                                : 'Already have an account? Sign In',
                          ),
                        ),

                        if (_isLogin)
                          TextButton(
                            onPressed: () {
                              final emailController = TextEditingController();
                              showDialog(
                                context: context,
                                builder:
                                    (dialogContext) => AlertDialog(
                                      title: const Text('Reset Password'),
                                      content: TextField(
                                        controller: emailController,
                                        decoration: const InputDecoration(
                                          labelText: 'Email',
                                          hintText: 'Enter your email',
                                        ),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(dialogContext),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            if (emailController.text
                                                .trim()
                                                .isNotEmpty) {
                                              try {
                                                Navigator.pop(dialogContext);

                                                final scaffoldContext = context;

                                                await FirebaseAuth.instance
                                                    .sendPasswordResetEmail(
                                                      email:
                                                          emailController.text
                                                              .trim(),
                                                    );

                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    scaffoldContext,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Password reset email sent',
                                                      ),
                                                      backgroundColor:
                                                          Colors.green,
                                                    ),
                                                  );
                                                }
                                              } catch (error) {
                                                final scaffoldContext = context;

                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    scaffoldContext,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Error: ${error.toString()}',
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            } else {
                                              ScaffoldMessenger.of(
                                                dialogContext,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Please enter your email',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                          child: const Text('Reset'),
                                        ),
                                      ],
                                    ),
                              );
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
