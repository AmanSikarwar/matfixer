import 'package:flutter/material.dart';
import 'package:matfixer/chat_page.dart';
import 'package:matfixer/gemini_api_key.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  String? _geminiApiKey;
  late final SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      _geminiApiKey = prefs.getString('gemini_api_key') ?? geminiApiKey;
    });
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
                            onPressed: () async {
                              final url = Uri.parse(
                                'https://github.com/AmanSikarwar/matfixer',
                              );
                              if (await canLaunchUrl(url)) {
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                throw 'Could not launch $url';
                              }
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
                    Center(
                      child: SizedBox(
                        width: 1000,
                        child: Padding(
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
                                    'What is Agentic AI for MATLAB?',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Agentic AI for MATLAB is an intelligent assistant designed to support users in code generation, debugging, data visualization, and algorithm development within MATLAB. '
                                    'By understanding natural language inputs, it can automate repetitive tasks, suggest optimized solutions, and help users learn MATLAB more effectively.',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'Key Capabilities:',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '- Generate MATLAB scripts/functions from plain English\n'
                                    '- Suggest corrections and optimizations for MATLAB code\n'
                                    '- Visualize data and simulation results on request\n'
                                    '- Explain MATLAB functions, syntax, and concepts interactively\n'
                                    '- Integrate with Simulink and toolboxes for enhanced workflows',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'Whether you\'re a beginner learning MATLAB or an expert seeking automation, Agentic AI enhances productivity by serving as a smart co-pilot in your MATLAB environment.',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
