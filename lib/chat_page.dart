import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:matfixer/gemini_api_key.dart';
import 'package:matfixer/main.dart';
import 'package:matfixer/matlab_chat_theme.dart';

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
