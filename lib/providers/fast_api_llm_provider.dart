import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:http/http.dart' as http;

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
            // Convert attachments to the format expected by the API
            return {
              'type': a is ImageFileAttachment ? 'image' : 'text',
              'data':
                  a.toString(), // This would need proper serialization based on attachment type
            };
          }).toList(),
    });

    try {
      final request = http.Request('POST', Uri.parse('$baseUrl/generate'));
      request.headers['Content-Type'] = 'application/json';
      request.body = requestBody;

      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to generate: ${response.statusCode}');
      }

      // Process the event stream
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final dataJson = line.substring(6); // Remove 'data: '
            try {
              final data = jsonDecode(dataJson);
              if (data.containsKey('chunk')) {
                yield data['chunk'];
              }
            } catch (e) {
              log('Error parsing chunk: $e');
            }
          }
        }
      }
    } catch (e) {
      log('Error generating stream: $e');
    }
  }

  @override
  Stream<String> sendMessageStream(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) async* {
    final userMessage = ChatMessage.user(prompt, attachments);
    final llmMessage = ChatMessage.llm();
    _history.addAll([userMessage, llmMessage]);
    notifyListeners();

    final requestBody = jsonEncode({
      'prompt': prompt,
      'attachments':
          attachments.map((a) {
            return {
              'type': a is ImageFileAttachment ? 'image' : 'text',
              'data': a.toString(), // This would need proper serialization
            };
          }).toList(),
    });

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$baseUrl/send-message?session_id=$_sessionId'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = requestBody;

      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to send message: ${response.statusCode}');
      }

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final dataJson = line.substring(6);
            try {
              final data = jsonDecode(dataJson);
              if (data.containsKey('chunk')) {
                final chunkText = data['chunk'];
                llmMessage.append(chunkText);
                yield chunkText;
                notifyListeners();
              }
            } catch (e) {
              log('Error parsing chunk: $e');
            }
          }
        }
      }
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
              'attachments': [], // Simplified
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
