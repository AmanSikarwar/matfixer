import 'package:flutter/material.dart';
import 'package:matfixer/chat_page.dart';
import 'package:matfixer/services/feature_grid.dart';
import 'package:matfixer/services/guide.dart';
import 'package:matfixer/services/mywidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:matfixer/services/auth_service.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  String? _geminiApiKey;
  late final SharedPreferences prefs;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
  }

  void _resetApiKey() {
    setState(() => _geminiApiKey = null);
    prefs.remove('gemini_api_key');
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = _authService.isAdmin();

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
                  icon: Icon(Icons.code, color: Colors.white, size: 24),
                  label: Text('GitHub', style: TextStyle(color: Colors.white)),
                  style: TextButton.styleFrom(
                    backgroundColor: Color(0xFF9A360B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              if (true) // Always show the admin button
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: TextButton.icon(
                    onPressed: () {
                      if (_authService.isAdmin()) {
                        Navigator.of(context).pushNamed('/admin/dashboard');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('You are not an admin.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: TextButton.icon(
                  onPressed: () async {
                    await _authService.signOut();
                    if (mounted) {
                      Navigator.of(context).pushReplacementNamed('/auth');
                    }
                  },
                  icon: Icon(Icons.logout, color: Colors.red, size: 24),
                  label: Text('Sign Out', style: TextStyle(color: Colors.red)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
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
                        fontSize:
                            MediaQuery.of(context).size.width *
                            0.045, // Responsive
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        textBaseline: TextBaseline.alphabetic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'In-Browser LLM Inference Engine',
                      style: TextStyle(
                        fontSize:
                            MediaQuery.of(context).size.width *
                            0.045, // Responsive
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
                        fontSize: MediaQuery.of(context).size.width * 0.02,
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
                              padding: EdgeInsets.all(20),
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => InstallationGuideScreen(),
                                ),
                              );
                            },

                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              side: BorderSide(
                                color: Colors.black,
                              ), // Optional: border for visibility
                              padding: EdgeInsets.all(20),
                              textStyle: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                            ),
                            child: Text('User Manual >'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 50),
                    FeatureGrid(),
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
