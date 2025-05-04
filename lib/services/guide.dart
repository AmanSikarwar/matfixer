import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:matfixer/data/guide_data.dart';
import 'package:matfixer/models/guide_model.dart'; // Import the model file

class InstallationGuideScreen extends StatefulWidget {
  @override
  _InstallationGuideScreenState createState() =>
      _InstallationGuideScreenState();
}

class _InstallationGuideScreenState extends State<InstallationGuideScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installation Guide'),
        backgroundColor: Color.fromARGB(255, 48, 98, 185),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.white,
            child: ListView.builder(
              itemCount: installationSteps.length,  // Using the InstallationStep data
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    installationSteps[index].title,
                    style: const TextStyle(
                      color: Color(0xFF3062B9), // MATLAB blur-like blue
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: _selectedIndex == index,
                  selectedTileColor: Colors.pink,
                  onTap: () => _onItemTapped(index),
                );
              },
            ),
          ),

          // Main Content Area
          Expanded(
            child: Container(
              color: Colors.blue[50], // Light background
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: ListView(
                children: [
                  _SectionTitle(title: installationSteps[_selectedIndex].title),
                  const SizedBox(height: 16),
                  _SectionContent(
                    content: installationSteps[_selectedIndex].content,
                    language: installationSteps[_selectedIndex].language,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Section Title Widget
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }
}

// Code Block Widget with Highlight + Clipboard
class _SectionContent extends StatelessWidget {
  final String content;
  final String language;

  const _SectionContent({required this.content, required this.language});

  void _copyToClipboard(BuildContext context, String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.only(top: 16, left: 16, right: 8, bottom: 8),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 40.0),
              child: IntrinsicWidth(
                child: HighlightView(
                  content,
                  language: language,
                  theme: draculaTheme,
                  padding: const EdgeInsets.all(8),
                  textStyle: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.copy, color: Colors.white),
                tooltip: 'Copy',
                onPressed: () => _copyToClipboard(context, content),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
