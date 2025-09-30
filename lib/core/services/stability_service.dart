import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_keys.dart';
import '../utils/prompt_builder.dart';

class StabilityService {
  StabilityService({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  static const String _t2iEndpoint =
      'https://api.stability.ai/v2beta/stable-image/generate/ultra';
  // Ultra model is not exposed on the image-to-image path; correct path has no /ultra
  static const String _i2iEndpoint =
      'https://api.stability.ai/v2beta/stable-image/generate/core';
  final http.Client _http;

  Future<Uint8List> generateImageBytes({required String prompt}) async {
    if (ApiKeys.stability.isEmpty) {
      throw StateError('Missing Stability API key');
    }

    final headers = <String, String>{
      'Authorization': 'Bearer ${ApiKeys.stability}',
      'Accept': 'image/*',
    };

    // Build prompt for text-to-image (negative prompt removed)
    final promptStructure = PromptBuilder.buildTextToImagePromptStructure(
      prompt,
    );
    final halloweenPrompt = promptStructure['prompt']!;

    final request = http.MultipartRequest('POST', Uri.parse(_t2iEndpoint))
      ..headers.addAll(headers)
      ..fields['prompt'] = halloweenPrompt
      ..fields['model'] = 'ultra'
      ..fields['output_format'] = 'png';

    final streamed = await _http.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }

    // Try to parse error JSON for a clearer message
    try {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final message =
          decoded['error']?.toString() ?? decoded['message']?.toString();
      throw Exception(
        'Stability error (${response.statusCode}): ${message ?? 'Unknown error'}',
      );
    } catch (_) {
      throw Exception('Stability error (${response.statusCode})');
    }
  }

  Future<Uint8List> generateImageFromImage({
    required String prompt,
    required Uint8List imageBytes,
    double imageStrength = 0.8,
    int cfgScale = 7,
  }) async {
    if (ApiKeys.stability.isEmpty) {
      throw StateError('Missing Stability API key');
    }

    final headers = <String, String>{
      'Authorization': 'Bearer ${ApiKeys.stability}',
      'Accept': 'image/*',
    };

    // Build prompt for image-to-image (negative prompt removed)
    final promptStructure = PromptBuilder.buildImageToImagePromptStructure(
      prompt,
    );
    final halloweenPrompt = promptStructure['prompt']!;

    final request = http.MultipartRequest('POST', Uri.parse(_i2iEndpoint))
      ..headers.addAll(headers)
      ..fields['prompt'] = halloweenPrompt
      ..fields['output_format'] = 'png'
      ..fields['image_strength'] = imageStrength.toString()
      ..fields['cfg_scale'] = cfgScale.toString()
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'input.jpg',
        ),
      );

    final streamed = await _http.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }

    // Try to parse error JSON for a clearer message
    try {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final message =
          decoded['error']?.toString() ?? decoded['message']?.toString();
      throw Exception(
        'Stability error (${response.statusCode}): ${message ?? 'Unknown error'}',
      );
    } catch (_) {
      throw Exception('Stability error (${response.statusCode})');
    }
  }
}
