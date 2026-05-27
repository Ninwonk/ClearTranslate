import 'package:dio/dio.dart';

class OpenAICompatibleClient {
  OpenAICompatibleClient({
    required String baseUrl,
    required String apiKey,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                headers: {
                  'Authorization': 'Bearer $apiKey',
                  'Content-Type': 'application/json',
                },
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 60),
              ),
            );

  final Dio _dio;

  Future<String> createChatCompletion({
    required String model,
    required List<Map<String, String>> messages,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/chat/completions',
      data: {
        'model': model,
        'messages': messages,
        'temperature': 0.2,
      },
      cancelToken: cancelToken,
    );

    final data = response.data;
    final choices = data?['choices'];
    if (choices is! List || choices.isEmpty) {
      throw StateError('Provider returned an empty response.');
    }

    final firstChoice = choices.first;
    if (firstChoice is! Map) {
      throw StateError('Provider returned an invalid choice.');
    }

    final message = firstChoice['message'];
    if (message is! Map) {
      throw StateError('Provider returned an invalid message.');
    }

    final content = message['content'];
    if (content is! String || content.trim().isEmpty) {
      throw StateError('Provider returned empty content.');
    }

    return content.trim();
  }
}

