import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:matfixer/firebase_options.dart';
import 'package:matfixer/matlab_app_theme.dart';
import 'package:matfixer/screens/auth_wrapper.dart';
import 'package:matfixer/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();
  runApp(App(prefs: prefs));
}

class App extends StatefulWidget {
  static const title = 'MatFixer';

  static final themeMode = ValueNotifier(ThemeMode.light);
  final SharedPreferences prefs;

  const App({super.key, required this.prefs});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) => Provider<AuthService>(
    create: (_) => AuthService(),
    child: ValueListenableBuilder<ThemeMode>(
      valueListenable: App.themeMode,
      builder:
          (context, value, child) => MaterialApp(
            title: App.title,
            theme: MatlabAppTheme.lightTheme(),
            darkTheme: MatlabAppTheme.darkTheme(),
            themeMode: value,
            home: AuthWrapper(),
            debugShowCheckedModeBanner: false,
          ),
    ),
  );
}
