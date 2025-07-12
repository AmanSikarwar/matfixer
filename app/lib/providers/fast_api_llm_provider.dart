import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';

/// An implementation of LlmProvider that connects to a FastAPI backend
class FastApiLlmProvider extends LlmProvider with ChangeNotifier {
  FastApiLlmProvider({
    required this.baseUrl,
    String? sessionId,
    Iterable<ChatMessage>? history,
  }) : _sessionId = sessionId ?? _generateSessionId(),
       _history = history?.toList() ?? [];

  final String baseUrl;
  final String _sessionId;
  final List<ChatMessage> _history;

  static String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  Stream<String> generateStream(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) async* {
    final requestBody = jsonEncode({
      'prompt': prompt,
      'attachments':
          attachments.map((a) {
            return {
              'type': a is ImageFileAttachment ? 'image' : 'text',
              'data': a.toString(),
            };
          }).toList(),
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to generate: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final fullResponse = data['response'];

      // Return the full response as a single yield
      yield fullResponse;
    } catch (e) {
      log('Error generating response: $e');
    }
  }

  @override
  Stream<String> sendMessageStream(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) async* {
    final userMessage = ChatMessage.user(prompt, attachments);
    _history.add(userMessage);
    notifyListeners();

    final requestBody = jsonEncode({
      'prompt': prompt,
      'attachments':
          attachments.map((a) {
            return {
              'type': a is ImageFileAttachment ? 'image' : 'text',
              'data': a.toString(),
            };
          }).toList(),
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-message?session_id=$_sessionId'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send message: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final fullResponse = data['response'];

      // Create and add LLM message with the full response
      final llmMessage = ChatMessage(
        attachments: attachments,
        origin: MessageOrigin.llm,
        text: fullResponse,
      );
      _history.add(llmMessage);
      notifyListeners();

      // Return the full response as a single yield
      yield fullResponse;
    } catch (e) {
      log('Error sending message: $e');
    }
  }

  @override
  Iterable<ChatMessage> get history => _history;

  @override
  set history(Iterable<ChatMessage> history) {
    _history.clear();
    _history.addAll(history);
    _updateHistoryOnServer();
    notifyListeners();
  }

  Future<void> _updateHistoryOnServer() async {
    try {
      final historyData =
          _history.map((message) {
            return {
              'role': message.origin.isUser ? 'user' : 'llm',
              'content': message.text,
              'attachments': [],
            };
          }).toList();

      await http.put(
        Uri.parse('$baseUrl/history/$_sessionId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(historyData),
      );
    } catch (e) {
      log('Error updating history: $e');
    }
  }
}
