import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';

class FalAiService {
  static const String _apiKey =
      '69588908-0d2b-4880-9169-ba235081cc65:64d6c98bb3e2778e19cc32ff3254353f';
  static const String _baseUrl = 'https://queue.fal.run/fal-ai/flux/schnell';

  /// Generate image using FAL AI FLUX Schnell model
  static Future<FalAiResult> generateImage({
    required String prompt,
    int numInferenceSteps = 4,
    int numImages = 1,
    String imageSize = 'square_hd',
    int? seed,
    bool enableSafetyChecker = true,
  }) async {
    try {
      // Validate prompt
      final String trimmedPrompt = prompt.trim();
      if (trimmedPrompt.isEmpty) {
        throw FalAiException('Prompt cannot be empty');
      }

      // Normalize image size to supported enum values for FAL API
      final String normalizedImageSize = _normalizeImageSize(imageSize);

      // Submit the generation request
      final submitResponse = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Key $_apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'prompt': trimmedPrompt,
          'num_inference_steps': numInferenceSteps,
          'num_images': numImages,
          'image_size': normalizedImageSize,
          if (seed != null) 'seed': seed,
          'enable_safety_checker': enableSafetyChecker,
        }),
      );

      // Accept 200/201 immediate responses and 202 Accepted queued responses
      if (submitResponse.statusCode != 200 &&
          submitResponse.statusCode != 201 &&
          submitResponse.statusCode != 202) {
        throw FalAiException(
          'Failed to submit generation: ${submitResponse.statusCode} - ${submitResponse.body}',
        );
      }

      Map<String, dynamic> submitData = {};
      if (submitResponse.body.isNotEmpty) {
        try {
          submitData = jsonDecode(submitResponse.body) as Map<String, dynamic>;
        } catch (_) {
          // If response is not JSON, proceed with headers-based fallback
        }
      }

      // Check if we have a direct response (sync mode)
      if (submitData.containsKey('images') ||
          submitData.containsKey('output')) {
        return FalAiResult.fromJson(submitData);
      }

      // If async mode, get the request_id and poll for results
      String? requestId = submitData['request_id'] as String?;

      // Some implementations may provide explicit URLs
      String? statusUrl = submitData['status_url'] as String?;
      String? resultUrl = submitData['result_url'] as String?;

      // If body did not include request id, try to infer from Location header
      if (requestId == null) {
        final location = submitResponse.headers['location'];
        if (location != null && location.contains('/requests/')) {
          // Extract the last segment as request id
          final parts = location.split('/');
          requestId = parts.isNotEmpty ? parts.last : null;
          statusUrl ??= location.endsWith('/status')
              ? location
              : '$location/status';
          resultUrl ??= location.endsWith('/status')
              ? location.replaceFirst('/status', '')
              : location;
        }
      }

      if (requestId == null && statusUrl == null && resultUrl == null) {
        throw FalAiException('No request_id or URLs provided by server');
      }

      // Build default URLs if only requestId was provided
      statusUrl ??= '$_baseUrl/requests/$requestId/status';
      resultUrl ??= '$_baseUrl/requests/$requestId';

      for (var i = 0; i < 60; i++) {
        await Future.delayed(const Duration(seconds: 2));

        final statusResponse = await http.get(
          Uri.parse(statusUrl),
          headers: {'Authorization': 'Key $_apiKey'},
        );

        if (statusResponse.statusCode != 200) {
          throw FalAiException(
            'Failed to get status: ${statusResponse.statusCode}',
          );
        }

        final statusData = jsonDecode(statusResponse.body);
        final status = statusData['status'] as String?;

        if (status == 'COMPLETED' ||
            status == 'completed' ||
            status == 'DONE') {
          // Get the final result
          final resultResponse = await http.get(
            Uri.parse(resultUrl),
            headers: {'Authorization': 'Key $_apiKey'},
          );

          if (resultResponse.statusCode != 200) {
            throw FalAiException(
              'Failed to get result: ${resultResponse.statusCode}',
            );
          }

          final resultData = jsonDecode(resultResponse.body);
          return FalAiResult.fromJson(resultData);
        } else if (status == 'FAILED' ||
            status == 'failed' ||
            status == 'ERROR') {
          final error = statusData['error'] ?? 'Unknown error';
          throw FalAiException('Generation failed: $error');
        }
      }

      throw FalAiException('Generation timeout - took too long');
    } catch (e) {
      if (e is FalAiException) {
        rethrow;
      }
      throw FalAiException('Error generating image: $e');
    }
  }

  /// Fetch image bytes directly from URL (no saving, for immediate display)
  static Future<Uint8List> fetchImageBytes(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final headers = {'Authorization': 'Key $_apiKey'};

      // Use authorized request first to support short-lived signed URLs
      http.Response response = await http.get(uri, headers: headers);
      if (response.statusCode != 200) {
        // Retry without auth if the endpoint rejects headers (public CDN)
        response = await http.get(uri);
      }
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      throw FalAiException(
        'Failed to fetch image bytes: ${response.statusCode}',
      );
    } catch (e) {
      throw FalAiException('Error fetching image bytes: $e');
    }
  }

  /// Map various size inputs (like '1024x1024' or '1:1') to FAL-supported values
  static String _normalizeImageSize(String input) {
    final String value = input.trim().toLowerCase();

    // Directly supported values
    const supported = {'square_hd', 'portrait_4_3', 'landscape_16_9'};
    if (supported.contains(value)) return value;

    // Common aliases or dimension strings
    if (value == 'square' || value == '1:1' || value == '1024x1024') {
      return 'square_hd';
    }
    if (value == 'portrait' ||
        value == '3:4' ||
        value == '4:5' ||
        value == '768x1024') {
      return 'portrait_4_3';
    }
    if (value == 'landscape' ||
        value == '16:9' ||
        value == '1024x768' ||
        value == '1920x1080') {
      return 'landscape_16_9';
    }

    // Explicit dimensions are not guaranteed supported; map to closest enum
    // to avoid 422 errors on the FLUX schnell endpoint.

    // Fallback to square to avoid 422 on unsupported values
    return 'square_hd';
  }

  /// Download and save image to device
  static Future<String> downloadAndSaveImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final headers = {'Authorization': 'Key $_apiKey'};

      // Fetch with auth first (handles private URLs)
      http.Response response = await http.get(uri, headers: headers);
      if (response.statusCode != 200) {
        response = await http.get(uri);
      }
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'fal_ai_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        // Best-effort gallery save: do not fail overall flow if this errors
        try {
          await Gal.putImage(file.path);
        } catch (_) {}

        return file.path;
      } else {
        throw FalAiException(
          'Failed to download image: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw FalAiException('Error downloading image: $e');
    }
  }
}

class FalAiResult {
  final List<FalAiImage> images;
  final String prompt;
  final Map<String, dynamic>? metadata;

  FalAiResult({required this.images, required this.prompt, this.metadata});

  factory FalAiResult.fromJson(Map<String, dynamic> json) {
    // Handle different response formats
    List<dynamic> imagesList;

    if (json.containsKey('images')) {
      imagesList = json['images'] as List;
    } else if (json.containsKey('output')) {
      imagesList = json['output'] as List;
    } else if (json.containsKey('data') && json['data'] is Map) {
      final data = json['data'] as Map;
      if (data.containsKey('images')) {
        imagesList = data['images'] as List? ?? [];
      } else if (data.containsKey('output')) {
        imagesList = data['output'] as List? ?? [];
      } else {
        imagesList = [];
      }
    } else {
      imagesList = [];
    }

    return FalAiResult(
      images: imagesList
          .map(
            (image) => FalAiImage.fromJson(
              image is String ? {'url': image} : image as Map<String, dynamic>,
            ),
          )
          .toList(),
      prompt: json['prompt'] ?? '',
      metadata: json['metadata'],
    );
  }
}

class FalAiImage {
  final String url;
  final String contentType;
  final int? width;
  final int? height;

  FalAiImage({
    required this.url,
    required this.contentType,
    this.width,
    this.height,
  });

  factory FalAiImage.fromJson(Map<String, dynamic> json) {
    String resolvedUrl = '';
    if (json['url'] is String) {
      resolvedUrl = json['url'] as String;
    } else if (json['image'] is String) {
      resolvedUrl = json['image'] as String;
    } else if (json['image'] is Map) {
      final imageMap = json['image'] as Map;
      if (imageMap['url'] is String) {
        resolvedUrl = imageMap['url'] as String;
      }
    }

    String resolvedContentType = 'image/png';
    if (json['content_type'] is String) {
      resolvedContentType = json['content_type'] as String;
    } else if (json['mime'] is String) {
      resolvedContentType = json['mime'] as String;
    }

    return FalAiImage(
      url: resolvedUrl,
      contentType: resolvedContentType,
      width: json['width'],
      height: json['height'],
    );
  }
}

class FalAiException implements Exception {
  final String message;

  FalAiException(this.message);

  @override
  String toString() => 'FalAiException: $message';
}
