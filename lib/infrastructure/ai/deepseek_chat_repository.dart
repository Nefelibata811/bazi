import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/api_config.dart';
import '../../../domain/services/chat_repository.dart';

class DeepSeekChatRepository implements ChatRepository {
  DeepSeekChatRepository({
    required this.apiKey,
    required this.baseUrl,
  });

  final String apiKey;
  final String baseUrl;

  @override
  Future<Stream<String>> sendMessage({
    required List<ChatMessage> history,
    required String systemPrompt,
  }) async {
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      for (final m in history) m.toJson(),
    ];

    final request =
        http.Request('POST', Uri.parse('$baseUrl/v1/chat/completions'));

    request.headers['Authorization'] = 'Bearer $apiKey';
    request.headers['Content-Type'] = 'application/json';
    request.headers['Accept'] = 'text/event-stream';
    request.body = jsonEncode({
      'model': ApiConfig.deepseekModel,
      'messages': messages,
      'stream': true,
      'temperature': ApiConfig.temperature,
      'max_tokens': ApiConfig.maxTokens,
    });

    final client = http.Client();
    try {
      final response = await client
          .send(request)
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode != 200) {
        final body = await response.stream
            .transform(utf8.decoder)
            .join()
            .timeout(const Duration(seconds: 10));
        client.close();
        final err = jsonDecode(body) as Map<String, dynamic>;
        final msg =
            (err['error'] as Map<String, dynamic>?)?['message'] as String? ??
                '请求失败';
        throw Exception(msg);
      }

      final controller = StreamController<String>(
        onCancel: () => client.close(),
      );

      response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: (sink) {
              sink.close();
              if (!controller.isClosed) {
                controller.addError(
                    TimeoutException('AI 响应超时，请重试'));
              }
            },
          )
          .listen(
        (line) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') {
              controller.close();
              client.close();
              return;
            }
            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final choices = json['choices'] as List<dynamic>?;
              if (choices != null && choices.isNotEmpty) {
                final delta = choices[0]['delta'] as Map<String, dynamic>?;
                final content = delta?['content'] as String?;
                if (content != null && content.isNotEmpty) {
                  controller.add(content);
                }
              }
            } catch (e) {
              debugPrint('SSE 解析异常: $e, 原始数据: $data');
            }
          }
        },
        onError: (e) {
          if (!controller.isClosed) {
            controller.addError(e);
          }
          client.close();
        },
        onDone: () {
          if (!controller.isClosed) controller.close();
          client.close();
        },
        cancelOnError: true,
      );

      return controller.stream;
    } catch (e) {
      client.close();
      rethrow;
    }
  }
}
