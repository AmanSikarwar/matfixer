import 'package:matfixer/models/feature_model.dart';

final List<Feature> features = [
  Feature(
    icon: 'assets/rag_logo.png',
    title: 'Smart Error Diagnosis',
    description:
        'Leverages RAG and LLM to detect,, and suggest changes for MATLAB code errors.',
  ),
  Feature(
    icon: 'assets/context_logo.png',
    title: 'Context-Aware Suggestions',
    description:
        'Analyzes surrounding code to offer relevant completions, fixes, and examples.',
  ),
  Feature(
    icon: 'assets/autocorrect_logo.png',
    title: 'MATLAB Syntax Autocorrect',
    description:
        'Automatically detects and corrects common syntax issues in MATLAB code.',
  ),
  Feature(
    icon: 'assets/citation_logo.png',
    title: 'Citations for Sources',
    description:
        'Generates references for retrieved content from documentation or forums.',
  ),
  Feature(
    icon: 'assets/document_logo.png', // Forum and docs
    title: 'Forum & Docs Integration',
    description:
        'Connects to MathWorks docs, Stack Overflow, and custom sources for enriched answers.',
  ),
  Feature(
    icon: 'assets/database_logo.png', // Custom Knowledge Base Support
    title: 'Custom Knowledge Base Support',
    description: 'Lets you plug in organization-specific MATLAB help and FAQs.',
  ),
];
