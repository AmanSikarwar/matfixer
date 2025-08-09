import 'package:flutter/material.dart';
import 'package:matfixer/screens/admin/admin_dashboard.dart';
import 'package:matfixer/screens/auth_page.dart';
import 'package:matfixer/welcome_page.dart';
import 'package:matfixer/screens/auth_wrapper.dart';

Map<String, WidgetBuilder> getAppRoutes() {
  return {
    '/': (context) => const AuthWrapper(),
    '/welcome': (context) => WelcomePage(),
    '/admin/dashboard': (context) => const AdminDashboard(),
    '/auth': (context) => const AuthPage(), // Add route for auth screen
  };
}
