import 'package:flutter/material.dart';
import 'package:matfixer/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final bool adminOnly;

  const LoginScreen({super.key, this.adminOnly = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  String email = '';
  String password = '';
  String error = '';
  bool isAdminLogin = false;

  @override
  void initState() {
    super.initState();
    // If adminOnly is true, force isAdminLogin to true
    if (widget.adminOnly) {
      isAdminLogin = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MatFixer Login')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Only show toggle if not adminOnly
              if (!widget.adminOnly)
                SwitchListTile(
                  title: Text(isAdminLogin ? 'Admin Login' : 'Normal User'),
                  value: isAdminLogin,
                  onChanged: (value) {
                    setState(() {
                      isAdminLogin = value;
                    });
                  },
                ),
              const SizedBox(height: 20),

              if (isAdminLogin)
                // Admin login form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        'Admin Login',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (val) => val!.isEmpty ? 'Enter an email' : null,
                        onChanged: (val) {
                          setState(() => email = val);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator:
                            (val) =>
                                val!.length < 6
                                    ? 'Password must be 6+ chars long'
                                    : null,
                        onChanged: (val) {
                          setState(() => password = val);
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            try {
                              await _auth.signInWithEmailAndPassword(
                                email,
                                password,
                              );
                            } catch (e) {
                              setState(() => error = e.toString());
                            }
                          }
                        },
                        child: const Text('Sign In as Admin'),
                      ),
                    ],
                  ),
                )
              else
                // Normal user button for anonymous login
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () async {
                    try {
                      await _auth.signInAnonymously();
                    } catch (e) {
                      setState(() => error = e.toString());
                    }
                  },
                  child: const Text('Continue as Normal User'),
                ),

              const SizedBox(height: 12),
              Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 14.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
