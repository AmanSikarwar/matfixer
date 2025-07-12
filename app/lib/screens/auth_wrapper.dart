import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:matfixer/models/user_model.dart';
import 'package:matfixer/services/auth_service.dart';
import 'package:matfixer/welcome_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isSigningIn = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          UserModel? user = snapshot.data;

          if (user == null) {
            // If no user is logged in and not already signing in anonymously,
            // automatically sign in anonymously
            if (!_isSigningIn) {
              _isSigningIn = true;
              Future.microtask(() async {
                try {
                  await _authService.signInAnonymously();
                } catch (e, stackTrace) {
                  log('Error signing in anonymously: $e');
                  log('Stack trace: $stackTrace');
                  if (mounted) {
                    setState(() => _isSigningIn = false);
                  }
                }
              });
            }

            return _isSigningIn
                ? const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [CircularProgressIndicator()],
                    ),
                  ),
                )
                : WelcomePage();
          } else {
            // Navigate to Admin Dashboard if user is admin
            return _authService.isAdmin() ? const WelcomePage() : WelcomePage();
          }
        }

        // Show loading indicator while connection state is in progress
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
