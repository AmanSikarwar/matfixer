import 'package:flutter/material.dart';
import 'package:matfixer/chat_page.dart';
import 'package:matfixer/demo/api_key_page.dart';
import 'package:matfixer/matlab_app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  String? _geminiApiKey;

  @override
  void initState() {
    super.initState();
    _geminiApiKey = widget.prefs.getString('gemini_api_key');
  }

  void _setApiKey(String apiKey) {
    setState(() => _geminiApiKey = apiKey);
    widget.prefs.setString('gemini_api_key', apiKey);
  }

  void _resetApiKey() {
    setState(() => _geminiApiKey = null);
    widget.prefs.remove('gemini_api_key');
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: App.themeMode,
    builder:
        (context, value, child) => MaterialApp(
          title: App.title,
          theme: MatlabAppTheme.lightTheme(),
          darkTheme: MatlabAppTheme.darkTheme(),
          themeMode: value,
          home:
              _geminiApiKey == null
                  ? GeminiApiKeyPage(title: App.title, onApiKey: _setApiKey)
                  : ChatPage(
                    geminiApiKey: _geminiApiKey!,
                    onResetApiKey: _resetApiKey,
                  ),
          debugShowCheckedModeBanner: false,
        ),
  );
}
