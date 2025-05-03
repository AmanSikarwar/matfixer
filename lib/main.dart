import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:matfixer/demo/api_key_page.dart';
import 'package:matfixer/matlab_app_theme.dart';
import 'package:matfixer/matlab_chat_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../gemini_api_key.dart';

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

class ChatPage extends StatefulWidget {
  const ChatPage({
    required this.geminiApiKey,
    required this.onResetApiKey,
    super.key,
  });

  final String geminiApiKey;
  final VoidCallback onResetApiKey;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
  late final _animationController = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
    lowerBound: 0.25,
    upperBound: 1.0,
  );

  late final _provider = GeminiProvider(
    model: GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: widget.geminiApiKey,
    ),
  );

  void _resetAnimation() {
    _animationController.value = 1.0;
    _animationController.reverse();
  }

  void _onError(BuildContext context, LlmException error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error: ${error.message}')));
  }

  void _onCancel(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chat cancelled')));
  }

  void _clearHistory() {
    _provider.history = [];
    _resetAnimation();
  }

  @override
  void initState() {
    super.initState();
    _resetAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(App.title),
      actions: [
        IconButton(
          onPressed: widget.onResetApiKey,
          tooltip: 'Reset API Key',
          icon: const Icon(Icons.key),
        ),
        IconButton(
          onPressed: _clearHistory,
          tooltip: 'Clear History',
          icon: const Icon(Icons.history),
        ),
        IconButton(
          onPressed:
              () =>
                  App.themeMode.value =
                      App.themeMode.value == ThemeMode.light
                          ? ThemeMode.dark
                          : ThemeMode.light,
          tooltip:
              App.themeMode.value == ThemeMode.light
                  ? 'Dark Mode'
                  : 'Light Mode',
          icon: const Icon(Icons.brightness_4_outlined),
        ),
      ],
    ),
    body: LlmChatView(
      onCancelCallback: _onCancel,
      cancelMessage: 'Request cancelled',
      onErrorCallback: _onError,
      errorMessage: 'An error occurred',
      welcomeMessage: 'Hello and welcome to the MatFixer!',
      style:
          App.themeMode.value == ThemeMode.light
              ? MatlabChatTheme.matlabStyle()
              : MatlabChatTheme.matlabDarkStyle(),
      provider: GeminiProvider(
        model: GenerativeModel(model: 'gemini-2.0-flash', apiKey: geminiApiKey),
      ),
    ),
  );
}
