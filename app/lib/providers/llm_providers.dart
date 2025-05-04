import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:matfixer/providers/fast_api_llm_provider.dart';

/// Enum representing different LLM provider options
enum LlmProviderType {
  agent1('Agent 1'),
  agent1Advanced('Agent 1 Advanced');

  final String displayName;
  const LlmProviderType(this.displayName);
}

/// Factory for creating LLM providers
class LlmProviderFactory {
  /// Create a new LLM provider based on the type
  static LlmProvider createProvider(
    LlmProviderType type, {
    required Iterable<ChatMessage> history,
    String? apiKey,
  }) {
    switch (type) {
      case LlmProviderType.agent1:
        return FastApiLlmProvider(
          baseUrl: 'http://172.18.40.104:8002',
          history: history,
        );
      case LlmProviderType.agent1Advanced:
        return FastApiLlmProvider(
          baseUrl: 'http://172.18.40.104:8000',
          history: history,
        );
    }
  }
}
