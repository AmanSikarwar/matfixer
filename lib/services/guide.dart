import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:matfixer/data/guide_data.dart';
import 'package:matfixer/models/guide_model.dart'; // Import the model file

class InstallationGuideScreen extends StatelessWidget {
  const InstallationGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Installation Guide')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: installationSteps.length,
        itemBuilder: (context, index) {
          final step = installationSteps[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(step.content, style: Theme.of(context).textTheme.bodyMedium),
                  if (step.code != null && step.language != null) ...[
                    const SizedBox(height: 16),
                    HighlightView(
                      step.code!,
                      language: step.language!,
                      theme: githubTheme,
                      padding: const EdgeInsets.all(12),
                      textStyle: const TextStyle(fontFamily: 'SourceCodePro'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}