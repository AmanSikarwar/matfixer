import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:matfixer/suggestions/suggestions.dart';

import '../gemini_api_key.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: WelcomePage());
  }
}

class WelcomePage extends StatelessWidget {
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
                                  builder: (context) => ChatPage(),
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

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chat with AI')),
    body: LlmChatView(
      provider: GeminiProvider(
        model: GenerativeModel(model: 'gemini-2.0-flash', apiKey: geminiApiKey),
      ),
    ),
  );
}
