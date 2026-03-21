import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/llm_config.dart';

class LLMService {
  late final Dio _dio;
  final LLMConfig config;

  LLMService(this.config) {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 300),
    ));
  }

  Future<String> generate(String prompt, {String? systemPrompt}) async {
    switch (config.provider) {
      case LLMProvider.minimax:
        return _generateMinimax(prompt, systemPrompt: systemPrompt);
      case LLMProvider.anthropic:
        return _generateAnthropic(prompt, systemPrompt: systemPrompt);
    }
  }

  Future<String> _generateMinimax(String prompt, {String? systemPrompt}) async {
    final messages = <Map<String, String>>[];
    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.add({'role': 'user', 'content': prompt});

    final response = await _dio.post(
      '${config.baseUrl}/v1/chat/completions',
      data: {
        'model': config.modelName,
        'messages': messages,
        'max_tokens': 16000,
        'temperature': 0.3,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
    );

    final data = response.data;
    return data['choices'][0]['message']['content'] as String;
  }

  Future<String> _generateAnthropic(String prompt, {String? systemPrompt}) async {
    final body = <String, dynamic>{
      'model': config.modelName,
      'max_tokens': 16000,
      'temperature': 0.3,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    };
    if (systemPrompt != null) {
      body['system'] = systemPrompt;
    }

    final response = await _dio.post(
      '${config.baseUrl}/v1/messages',
      data: body,
      options: Options(
        headers: {
          'x-api-key': config.apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
      ),
    );

    final data = response.data;
    final content = data['content'] as List;
    final textBlocks = content
        .where((block) => block['type'] == 'text')
        .map((block) => block['text'] as String)
        .toList();
    return textBlocks.join('\n');
  }

  Future<Stream<String>> generateStream(String prompt, {String? systemPrompt}) async {
    switch (config.provider) {
      case LLMProvider.minimax:
        return _streamMinimax(prompt, systemPrompt: systemPrompt);
      case LLMProvider.anthropic:
        return _streamAnthropic(prompt, systemPrompt: systemPrompt);
    }
  }

  Future<Stream<String>> _streamMinimax(String prompt, {String? systemPrompt}) async {
    final messages = <Map<String, String>>[];
    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.add({'role': 'user', 'content': prompt});

    final response = await _dio.post(
      '${config.baseUrl}/v1/chat/completions',
      data: {
        'model': config.modelName,
        'messages': messages,
        'max_tokens': 16000,
        'temperature': 0.3,
        'stream': true,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.stream,
      ),
    );

    final rawStream = (response.data as ResponseBody).stream;
    return rawStream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .where((line) => line.startsWith('data: ') && !line.contains('[DONE]'))
        .map((line) {
      final json = jsonDecode(line.substring(6));
      return json['choices']?[0]?['delta']?['content'] as String? ?? '';
    })
        .where((text) => text.isNotEmpty);
  }

  Future<Stream<String>> _streamAnthropic(String prompt, {String? systemPrompt}) async {
    final body = <String, dynamic>{
      'model': config.modelName,
      'max_tokens': 16000,
      'temperature': 0.3,
      'stream': true,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    };
    if (systemPrompt != null) {
      body['system'] = systemPrompt;
    }

    final response = await _dio.post(
      '${config.baseUrl}/v1/messages',
      data: body,
      options: Options(
        headers: {
          'x-api-key': config.apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.stream,
      ),
    );

    final rawStream = (response.data as ResponseBody).stream;
    return rawStream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .where((line) => line.startsWith('data: '))
        .map((line) {
      final json = jsonDecode(line.substring(6));
      if (json['type'] == 'content_block_delta') {
        return json['delta']?['text'] as String? ?? '';
      }
      return '';
    })
        .where((text) => text.isNotEmpty);
  }

  void dispose() {
    _dio.close();
  }
}
