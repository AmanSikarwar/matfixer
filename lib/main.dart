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

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  String? _geminiApiKey;
  late final SharedPreferences prefs;

  @override
  void initState() async {
    super.initState();
    prefs = await SharedPreferences.getInstance();
    _geminiApiKey = prefs.getString('gemini_api_key');
  }

  void _resetApiKey() {
    setState(() => _geminiApiKey = null);
    prefs.remove('gemini_api_key');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(400),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ), // Faint bottom border
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Image.asset(
                  'assets/matlab_logo.png',
                  fit: BoxFit.contain,
                  height: 50,
                ),
              ),
              Text(
                'MatLabAI',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.code, color: Colors.white, size: 24),
                  label: Text('GitHub', style: TextStyle(color: Colors.white)),
                  style: TextButton.styleFrom(
                    backgroundColor: Color(0xFF9A360B), // Darker MATLAB shade
                    shape: RoundedRectangleBorder(), // Rectangle
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: TextButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    Icons.admin_panel_settings,
                    color: Color(0xFFC24E0F),
                    size: 24,
                  ),
                  label: Text(
                    'Admin',
                    style: TextStyle(color: Color(0xFFC24E0F)),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Gradient (Top to Bottom)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, // Gradient starts from the top
                end: Alignment.bottomCenter, // Gradient ends at the bottom
                colors: [Colors.white, const Color.fromARGB(255, 48, 98, 185)],
              ),
            ),
          ),
          // Centered Content with Scrolling
          SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(60.0),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center content vertically
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 100),
                    Text(
                      'MatLabAI: High-Performance',
                      style: TextStyle(
                        fontSize: 60, // Larger font size
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        textBaseline: TextBaseline.alphabetic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'In-Browser LLM Inference Engine',
                      style: TextStyle(
                        fontSize: 60, // Larger font size
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        textBaseline: TextBaseline.alphabetic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Experience high-performance AI inference right in your browser.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30, // Bigger font size for the subtitle
                        color: const Color.fromARGB(137, 0, 0, 0),
                      ),
                    ),
                    SizedBox(height: 60),
                    Center(
                      child: Wrap(
                        spacing: 20, // Space between buttons
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ChatPage(
                                        geminiApiKey: _geminiApiKey!,
                                        onResetApiKey: _resetApiKey,
                                      ),
                                ),
                              );
                            },

                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black, // Black background
                              foregroundColor: Colors.white, // White text
                              padding: EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 20,
                              ),
                              textStyle: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                            ),
                            child: Text('Get Started >'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Scrollable.ensureVisible(
                                context,
                                alignment: 0.5,
                                duration: Duration(seconds: 1),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              side: BorderSide(
                                color: Colors.black,
                              ), // Optional: border for visibility
                              padding: EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 20,
                              ),
                              textStyle: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                            ),
                            child: Text('Download >'),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 50),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'What is MATLAB?',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'MATLAB (Matrix Laboratory) is a high-level programming language used for numerical computing. '
                                'It is widely used for its ability to manipulate matrices, perform numerical analysis, '
                                'develop algorithms, and visualize data in a variety of fields including engineering, physics, and mathematics.',
                                style: TextStyle(fontSize: 18),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'MATLAB Key Features:',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '- Matrix-based calculations\n'
                                '- Built-in plotting tools\n'
                                '- Extensive libraries for data analysis\n'
                                '- Integration with other programming languages like C/C++, Python, etc.',
                                style: TextStyle(fontSize: 18),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'MATLAB is an essential tool for engineers, scientists, and data analysts looking to develop and prototype algorithms with ease.',
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
