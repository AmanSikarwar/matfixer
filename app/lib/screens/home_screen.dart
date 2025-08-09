import 'package:flutter/material.dart';
import 'package:matfixer/services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = _authService.isAdmin();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MatFixer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isAdmin ? Icons.admin_panel_settings : Icons.person,
                size: 80,
                color: isAdmin ? Colors.red : Colors.blue,
              ),
              const SizedBox(height: 20),
              Text(
                isAdmin ? 'Welcome, Admin User!' : 'Welcome, Normal User!',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 20),
              Text(
                isAdmin
                    ? 'You have access to admin features.'
                    : 'You are signed in anonymously.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
