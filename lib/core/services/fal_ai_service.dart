import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import '../config/environment_config.dart';

/// FLUX Schnell Style Options
enum FluxSchnellStyle {
  realistic('realistic', 'Photorealistic style'),
  artistic('artistic', 'Artistic style'),
  cinematic('cinematic', 'Cinematic style'),
  digital('digital', 'Digital art style'),
  painting('painting', 'Painting style'),
  sketch('sketch', 'Sketch style'),
  anime('anime', 'Anime style'),
  cartoon('cartoon', 'Cartoon style'),
  fantasy('fantasy', 'Fantasy style'),
  horror('horror', 'Horror style'),
  sciFi('sci-fi', 'Science fiction style'),
  vintage('vintage', 'Vintage style'),
  modern('modern', 'Modern style'),
  abstract('abstract', 'Abstract style'),
  minimalist('minimalist', 'Minimalist style');

  const FluxSchnellStyle(this.value, this.description);
  final String value;
  final String description;
}

/// FLUX Schnell Quality Options
enum FluxSchnellQuality {
  fast('fast', 'Fast generation, lower quality'),
  balanced('balanced', 'Balanced speed and quality'),
  high('high', 'High quality, slower generation'),
  ultra('ultra', 'Ultra high quality, slowest generation');

  const FluxSchnellQuality(this.value, this.description);
  final String value;
  final String description;
}

class FalAiService {
  // FAL AI FLUX Schnell - Text to Image Model
  static const String _baseUrl = 'https://queue.fal.run/fal-ai/flux/schnell';
  static const String _i2iBaseUrl =
      'https://queue.fal.run/fal-ai/image-editing/scene-composition';

  // FLUX Schnell Model Configuration
  static const Map<String, dynamic> _fluxSchnellConfig = {
    'model': 'fal-ai/flux/schnell',
    'description': 'Fast text-to-image generation with high quality',
    'maxSteps': 4,
    'defaultSteps': 4,
    'supportedSizes': ['square_hd', 'portrait_4_3', 'landscape_16_9'],
    'defaultSize': 'square_hd',
    'guidanceScale': 6.0,
    'outputFormats': ['jpeg', 'png'],
    'defaultFormat': 'jpeg',
  };

  /// Get API key from environment variables
  static String get _apiKey {
    final apiKey = EnvironmentConfig.falAiApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw FalAiException(
        'FAL_AI_API_KEY not found in environment variables. '
        'Please add FAL_AI_API_KEY to your .env file.',
      );
    }
    return apiKey;
  }

  /// Get FLUX Schnell model configuration
  static Map<String, dynamic> get fluxSchnellConfig => _fluxSchnellConfig;

  /// Get supported styles for FLUX Schnell
  static List<FluxSchnellStyle> get supportedStyles => FluxSchnellStyle.values;

  /// Get supported quality levels for FLUX Schnell
  static List<FluxSchnellQuality> get supportedQualities =>
      FluxSchnellQuality.values;

  /// Get model information
  static String get modelInfo =>
      'FLUX Schnell - Fast text-to-image generation with high quality';

  /// Check if FLUX Schnell is available
  static bool get isFluxSchnellAvailable => true;

  /// Generate image using FAL AI FLUX Schnell model with enhanced configuration
  static Future<FalAiResult> generateImage({
    required String prompt,
    int numInferenceSteps = 4, // FLUX Schnell default
    int numImages = 1,
    String imageSize = 'square_hd', // FLUX Schnell default
    double guidanceScale = 6.0, // FLUX Schnell default
    int? seed,
    bool enableSafetyChecker = true,
    String outputFormat = 'jpeg', // FLUX Schnell default
    bool syncMode = false,
    bool Function()? isCancelled,
    FluxSchnellStyle? style, // Enhanced style support
    FluxSchnellQuality? quality, // Enhanced quality support
  }) async {
    try {
      // Validate prompt
      final String trimmedPrompt = prompt.trim();
      if (trimmedPrompt.isEmpty) {
        throw FalAiException('Prompt cannot be empty');
      }

      // Enhance prompt with FLUX Schnell optimizations
      final String enhancedPrompt = _enhancePromptForFluxSchnell(
        trimmedPrompt,
        style: style,
        quality: quality,
      );

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
          'prompt': enhancedPrompt, // Use enhanced prompt
          'num_inference_steps': numInferenceSteps,
          'num_images': numImages,
          'image_size': normalizedImageSize,
          'guidance_scale': guidanceScale,
          'output_format': outputFormat,
          'sync_mode': syncMode,
          if (seed != null) 'seed': seed,
          'enable_safety_checker': enableSafetyChecker,
          // FLUX Schnell specific parameters
          'model': 'fal-ai/flux/schnell',
          'style': style?.value ?? 'realistic',
          'quality': quality?.value ?? 'balanced',
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

      // Log successful submission
      debugPrint('🎃 FAL: Text-to-image generation submitted successfully');
      debugPrint('🎃 FAL: Response status: ${submitResponse.statusCode}');
      debugPrint('🎃 FAL: Response body: ${submitResponse.body}');

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

      // Poll for results with improved error handling
      for (var i = 0; i < 30; i++) {
        debugPrint('🎃 FAL: Polling attempt ${i + 1}/30');

        // Check for cancellation
        if (isCancelled != null && isCancelled()) {
          debugPrint('🎃 FAL: Generation cancelled by user');
          throw FalAiException('Generation cancelled by user');
        }

        await Future.delayed(const Duration(seconds: 1));

        try {
          final statusResponse = await http.get(
            Uri.parse(statusUrl),
            headers: {'Authorization': 'Key $_apiKey'},
          );

          if (statusResponse.statusCode != 200) {
            debugPrint(
              '🎃 FAL: Status check failed: ${statusResponse.statusCode} - ${statusResponse.body}',
            );
            throw FalAiException(
              'Failed to get status: ${statusResponse.statusCode} - ${statusResponse.body}',
            );
          }

          final statusData = jsonDecode(statusResponse.body);
          final status = statusData['status'] as String?;

          debugPrint('🎃 FAL: Status: $status');

          if (status == 'COMPLETED' ||
              status == 'completed' ||
              status == 'DONE') {
            debugPrint('🎃 FAL: Generation completed, fetching result...');

            // Get the final result - use status URL for result
            final resultResponse = await http.get(
              Uri.parse(statusUrl), // Use status URL instead of result URL
              headers: {'Authorization': 'Key $_apiKey'},
            );

            if (resultResponse.statusCode != 200) {
              debugPrint(
                '🎃 FAL: Result fetch failed: ${resultResponse.statusCode} - ${resultResponse.body}',
              );
              throw FalAiException(
                'Failed to get result: ${resultResponse.statusCode} - ${resultResponse.body}',
              );
            }

            final resultData = jsonDecode(resultResponse.body);
            debugPrint('🎃 FAL: Result data received successfully');

            // FLUX Schnell specific response parsing
            final result = await FalAiResult.fromFluxSchnellJson(
              resultData,
              enhancedPrompt,
            );
            debugPrint('🎃 FAL: Parsed result: ${result.images.length} images');
            return result;
          } else if (status == 'FAILED' ||
              status == 'failed' ||
              status == 'ERROR') {
            final error = statusData['error'] ?? 'Unknown error';
            debugPrint('🎃 FAL: Generation failed: $error');
            throw FalAiException('Generation failed: $error');
          }
        } catch (e) {
          debugPrint('🎃 FAL: Polling error: $e');
          if (i == 29) {
            // Last attempt
            rethrow;
          }
          // Continue to next attempt
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

  /// Generate image-from-image using FAL AI Scene Composition model
  static Future<FalAiResult> generateImageFromImage({
    required String prompt,
    required Uint8List imageBytes,
    double imageStrength =
        0.8, // From screenshot - higher strength for scene composition
    int numInferenceSteps = 4, // From screenshot
    double guidanceScale = 6.0, // From screenshot
    int? seed,
    bool enableSafetyChecker = true, // From screenshot
    String outputFormat = 'jpeg', // From screenshot
  }) async {
    try {
      final String trimmedPrompt = prompt.trim();
      if (trimmedPrompt.isEmpty) {
        throw FalAiException('Prompt cannot be empty');
      }

      // Convert image bytes to base64 Data URI
      final String base64Image = base64Encode(imageBytes);

      // Determine MIME type based on image content
      final String mimeType = _detectMimeType(imageBytes);

      final String dataUri = 'data:$mimeType;base64,$base64Image';

      // Enhance prompt to focus on face preservation and Halloween theme
      final String enhancedPrompt = _enhancePromptForFacePreservation(
        trimmedPrompt,
      );

      // Submit the generation request using the new API structure
      final submitResponse = await http.post(
        Uri.parse(_i2iBaseUrl),
        headers: {
          'Authorization': 'Key $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'image_url': dataUri,
          'prompt': enhancedPrompt,
          'strength': imageStrength.clamp(0.0, 1.0),
          'num_inference_steps': numInferenceSteps,
          'guidance_scale': guidanceScale,
          'num_images': 1,
          'output_format': outputFormat,
          if (seed != null) 'seed': seed,
          'enable_safety_checker': enableSafetyChecker,
        }),
      );

      if (submitResponse.statusCode ~/ 100 != 2) {
        throw FalAiException(
          'Failed to submit img2img: ${submitResponse.statusCode} - ${submitResponse.body}',
        );
      }

      final submitData =
          jsonDecode(submitResponse.body) as Map<String, dynamic>;

      // Check if we have a direct response (sync mode)
      if (submitData.containsKey('images') ||
          submitData.containsKey('output')) {
        return FalAiResult.fromJson(submitData);
      }

      // Get status and response URLs for async processing
      final String? statusUrl = submitData['status_url'] as String?;
      final String? responseUrl = submitData['response_url'] as String?;

      if (statusUrl == null || responseUrl == null) {
        throw FalAiException(
          'No status_url or response_url provided by server',
        );
      }

      // Poll status until completion
      String status = 'IN_QUEUE';
      int attempt = 0;
      const int maxAttempts = 60; // ~60 seconds timeout

      while (status != 'COMPLETED' && attempt < maxAttempts) {
        await Future.delayed(const Duration(seconds: 1));

        final statusResponse = await http.get(
          Uri.parse('$statusUrl?logs=1'),
          headers: {'Authorization': 'Key $_apiKey'},
        );

        if (statusResponse.statusCode ~/ 100 != 2) {
          throw FalAiException(
            'Failed to get status: ${statusResponse.statusCode} - ${statusResponse.body}',
          );
        }

        final statusData =
            jsonDecode(statusResponse.body) as Map<String, dynamic>;
        status = statusData['status'] as String? ?? status;

        // Handle logs if available (optional)
        if (statusData['logs'] != null) {
          final logs = statusData['logs'] as List;
          final logMessages = logs
              .map((e) => e['message'] as String?)
              .whereType<String>()
              .join('\n');
          print('FAL AI Logs: $logMessages');
        }

        // Check for failure status
        if (status == 'FAILED' || status == 'failed' || status == 'ERROR') {
          final error = statusData['error'] ?? 'Unknown error';
          throw FalAiException('Generation failed: $error');
        }

        attempt++;
      }

      if (status != 'COMPLETED') {
        throw FalAiException('Generation timeout - took too long');
      }

      // Get the final result
      final resultResponse = await http.get(
        Uri.parse(responseUrl),
        headers: {'Authorization': 'Key $_apiKey'},
      );

      if (resultResponse.statusCode ~/ 100 != 2) {
        throw FalAiException(
          'Failed to get result: ${resultResponse.statusCode} - ${resultResponse.body}',
        );
      }

      final resultData =
          jsonDecode(resultResponse.body) as Map<String, dynamic>;
      return FalAiResult.fromJson(resultData);
    } catch (e) {
      if (e is FalAiException) {
        rethrow;
      }
      throw FalAiException('Error generating image from image: $e');
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

  /// Base structure for all image-to-image generations
  static const String _baseImageToImageStructure =
      'IDENTICAL FACE, EXACT SAME PERSON, PRESERVE FACE COMPLETELY, KEEP ORIGINAL FACE, MAINTAIN FACE IDENTITY, SAME FACIAL FEATURES, high quality, realistic, portrait, professional photography, detailed, cinematic';

  /// Base structure specifically for face transformation prompts
  /// This ensures the AI focuses only on the user's face and ignores background/other elements
  static const String _faceTransformationBaseStructure =
      'FOCUS ONLY ON FACE, TRANSFORM ONLY THE PERSON\'S FACE, KEEP ORIGINAL FACIAL STRUCTURE, PRESERVE FACE IDENTITY, MAINTAIN FACIAL FEATURES, SAME PERSON, IDENTICAL FACE, EXACT SAME PERSON, high quality, realistic, portrait, professional photography, detailed, cinematic';

  /// Enhance prompt for Recraft V3 model with base structure + user prompt
  static String _enhancePromptForFacePreservation(String originalPrompt) {
    // Combine base structure with user prompt
    final enhancedPrompt = '$_baseImageToImageStructure, $originalPrompt';

    // Ensure prompt is under 1000 characters
    if (enhancedPrompt.length > 1000) {
      return enhancedPrompt.substring(0, 997) + '...';
    }

    return enhancedPrompt;
  }

  /// Enhance prompt specifically for face transformation prompts
  /// This ensures the AI focuses only on the user's face and ignores background/other elements
  static String _enhancePromptForFaceTransformation(String originalPrompt) {
    // Combine face transformation base structure with user prompt
    final enhancedPrompt = '$_faceTransformationBaseStructure, $originalPrompt';

    // Ensure prompt is under 1000 characters
    if (enhancedPrompt.length > 1000) {
      return enhancedPrompt.substring(0, 997) + '...';
    }

    return enhancedPrompt;
  }

  /// Generate image from image specifically for face transformation prompts
  /// This function uses the face transformation base structure to focus only on the user's face
  static Future<FalAiResult> generateFaceTransformation({
    required String prompt,
    required Uint8List imageBytes,
    double imageStrength =
        0.05, // Ultra low strength for maximum face preservation
    int numInferenceSteps = 30, // Optimal steps for quality
    double guidanceScale = 20.0, // Maximum guidance for face preservation
    int? seed,
    bool enableSafetyChecker = true,
    String outputFormat = 'png',
  }) async {
    try {
      // Convert image to base64 data URI
      final String base64Image = base64Encode(imageBytes);
      final String mimeType = _detectMimeType(imageBytes);
      final String dataUri = 'data:$mimeType;base64,$base64Image';

      // Enhance prompt with face transformation base structure
      final String enhancedPrompt = _enhancePromptForFaceTransformation(prompt);

      // Submit the request
      final submitResponse = await http.post(
        Uri.parse(_i2iBaseUrl),
        headers: {
          'Authorization': 'Key $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'image_url': dataUri,
          'prompt': enhancedPrompt,
          'strength': imageStrength.clamp(0.0, 1.0),
          'num_inference_steps': numInferenceSteps.clamp(10, 50),
          'guidance_scale': guidanceScale.clamp(1.0, 20.0),
          'num_images': 1,
          'output_format': outputFormat,
          'style': 'realistic_image', // Valid Recraft V3 style parameter
          'aspect_ratio': '1:1', // Square aspect ratio for better results
          'image_size': 'square_hd', // Valid Recraft V3 image size parameter
          'negative_prompt':
              'blurry, distorted, ugly, bad anatomy, extra limbs, mutated, low quality, cartoon, drawing, painting, watermark, text, deformed face, asymmetric face, multiple faces, background, surroundings, environment',
          if (seed != null) 'seed': seed,
          'enable_safety_checker': enableSafetyChecker,
        }),
      );

      if (submitResponse.statusCode ~/ 100 != 2) {
        throw FalAiException(
          'Failed to submit request: ${submitResponse.statusCode} ${submitResponse.body}',
        );
      }

      final submitData = jsonDecode(submitResponse.body);
      final String statusUrl = submitData['status_url'] as String;
      final String resultUrl = submitData['response_url'] as String;

      // Poll for completion
      int attempts = 0;
      const int maxAttempts = 60; // 60 seconds timeout
      const Duration pollInterval = Duration(seconds: 1);

      while (attempts < maxAttempts) {
        await Future.delayed(pollInterval);
        attempts++;

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
          final images = resultData['images'] as List?;

          if (images == null || images.isEmpty) {
            throw FalAiException('No images in result');
          }

          final imageData = images.first as Map<String, dynamic>;
          final imageUrl = imageData['url'] as String?;

          if (imageUrl == null) {
            throw FalAiException('No image URL in result');
          }

          // Download the image
          final imageResponse = await http.get(Uri.parse(imageUrl));
          if (imageResponse.statusCode != 200) {
            throw FalAiException(
              'Failed to download image: ${imageResponse.statusCode}',
            );
          }

          return FalAiResult(
            images: [FalAiImage(url: imageUrl, contentType: 'image/png')],
            prompt: enhancedPrompt,
            metadata: {'seed': seed, 'model': 'recraft-v3-face-transformation'},
          );
        } else if (status == 'FAILED' || status == 'failed') {
          final error = statusData['error'] as String? ?? 'Unknown error';
          throw FalAiException('Generation failed: $error');
        }
      }

      throw FalAiException('Generation timed out after ${maxAttempts} seconds');
    } catch (e) {
      if (e is FalAiException) rethrow;
      throw FalAiException('Error in face transformation: $e');
    }
  }

  /// Detect MIME type from image bytes
  static String _detectMimeType(Uint8List imageBytes) {
    if (imageBytes.length < 4) return 'image/jpeg';

    // Check for PNG signature
    if (imageBytes[0] == 0x89 &&
        imageBytes[1] == 0x50 &&
        imageBytes[2] == 0x4E &&
        imageBytes[3] == 0x47) {
      return 'image/png';
    }

    // Check for JPEG signature
    if (imageBytes[0] == 0xFF && imageBytes[1] == 0xD8) {
      return 'image/jpeg';
    }

    // Check for WebP signature
    if (imageBytes.length >= 12 &&
        imageBytes[0] == 0x52 &&
        imageBytes[1] == 0x49 &&
        imageBytes[2] == 0x46 &&
        imageBytes[3] == 0x46 &&
        imageBytes[8] == 0x57 &&
        imageBytes[9] == 0x45 &&
        imageBytes[10] == 0x42 &&
        imageBytes[11] == 0x50) {
      return 'image/webp';
    }

    // Default to JPEG if we can't detect
    return 'image/jpeg';
  }

  /// Map various size inputs (like '1024x1024' or '1:1') to FAL-supported values
  /// Enhance prompt for FLUX Schnell model with style and quality optimizations
  static String _enhancePromptForFluxSchnell(
    String prompt, {
    FluxSchnellStyle? style,
    FluxSchnellQuality? quality,
  }) {
    debugPrint('🎃 FLUX: Enhancing prompt for FLUX Schnell');
    debugPrint('🎃 FLUX: Original prompt: $prompt');
    debugPrint('🎃 FLUX: Style: ${style?.value ?? 'realistic'}');
    debugPrint('🎃 FLUX: Quality: ${quality?.value ?? 'balanced'}');

    // Base FLUX Schnell enhancements
    final List<String> enhancements = [
      'high quality',
      'detailed',
      'sharp focus',
      'professional',
    ];

    // Add style-specific enhancements
    if (style != null) {
      switch (style) {
        case FluxSchnellStyle.realistic:
          enhancements.addAll([
            'photorealistic',
            'lifelike',
            'natural lighting',
          ]);
          break;
        case FluxSchnellStyle.artistic:
          enhancements.addAll(['artistic', 'creative', 'expressive']);
          break;
        case FluxSchnellStyle.cinematic:
          enhancements.addAll([
            'cinematic',
            'dramatic lighting',
            'movie quality',
          ]);
          break;
        case FluxSchnellStyle.digital:
          enhancements.addAll(['digital art', 'clean', 'modern']);
          break;
        case FluxSchnellStyle.painting:
          enhancements.addAll(['painted', 'brush strokes', 'artistic']);
          break;
        case FluxSchnellStyle.sketch:
          enhancements.addAll(['sketch', 'line art', 'drawn']);
          break;
        case FluxSchnellStyle.anime:
          enhancements.addAll(['anime style', 'manga', 'japanese art']);
          break;
        case FluxSchnellStyle.cartoon:
          enhancements.addAll(['cartoon', 'animated', 'colorful']);
          break;
        case FluxSchnellStyle.fantasy:
          enhancements.addAll(['fantasy', 'magical', 'enchanted']);
          break;
        case FluxSchnellStyle.horror:
          enhancements.addAll(['horror', 'dark', 'scary', 'atmospheric']);
          break;
        case FluxSchnellStyle.sciFi:
          enhancements.addAll(['sci-fi', 'futuristic', 'cyberpunk']);
          break;
        case FluxSchnellStyle.vintage:
          enhancements.addAll(['vintage', 'retro', 'classic']);
          break;
        case FluxSchnellStyle.modern:
          enhancements.addAll(['modern', 'contemporary', 'sleek']);
          break;
        case FluxSchnellStyle.abstract:
          enhancements.addAll(['abstract', 'artistic', 'creative']);
          break;
        case FluxSchnellStyle.minimalist:
          enhancements.addAll(['minimalist', 'simple', 'clean']);
          break;
      }
    }

    // Add quality-specific enhancements
    if (quality != null) {
      switch (quality) {
        case FluxSchnellQuality.fast:
          enhancements.addAll(['fast generation', 'efficient']);
          break;
        case FluxSchnellQuality.balanced:
          enhancements.addAll(['balanced quality', 'optimized']);
          break;
        case FluxSchnellQuality.high:
          enhancements.addAll(['high quality', 'detailed', 'premium']);
          break;
        case FluxSchnellQuality.ultra:
          enhancements.addAll(['ultra high quality', 'masterpiece', 'perfect']);
          break;
      }
    }

    // Combine prompt with enhancements
    final String enhancedPrompt = '$prompt, ${enhancements.join(', ')}';

    debugPrint('🎃 FLUX: Enhanced prompt: $enhancedPrompt');

    // Ensure prompt is under 1000 characters
    if (enhancedPrompt.length > 1000) {
      final String truncatedPrompt = enhancedPrompt.substring(0, 997) + '...';
      debugPrint('🎃 FLUX: Truncated prompt: $truncatedPrompt');
      return truncatedPrompt;
    }

    return enhancedPrompt;
  }

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
    debugPrint('🎃 FAL: Parsing result JSON: ${json.keys}');

    // Handle different response formats
    List<dynamic> imagesList = [];

    if (json.containsKey('images')) {
      imagesList = json['images'] as List;
      debugPrint('🎃 FAL: Found images in response: ${imagesList.length}');
    } else if (json.containsKey('output')) {
      imagesList = json['output'] as List;
      debugPrint('🎃 FAL: Found output in response: ${imagesList.length}');
    } else if (json.containsKey('data') && json['data'] is Map) {
      final data = json['data'] as Map;
      if (data.containsKey('images')) {
        imagesList = data['images'] as List? ?? [];
        debugPrint('🎃 FAL: Found images in data: ${imagesList.length}');
      } else if (data.containsKey('output')) {
        imagesList = data['output'] as List? ?? [];
        debugPrint('🎃 FAL: Found output in data: ${imagesList.length}');
      } else {
        debugPrint('🎃 FAL: No images found in data');
        imagesList = [];
      }
    } else {
      debugPrint('🎃 FAL: No images found in response');
      imagesList = [];
    }

    if (imagesList.isEmpty) {
      debugPrint('🎃 FAL: WARNING - No images in response!');
      debugPrint('🎃 FAL: Full response: $json');
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

  /// FLUX Schnell specific response parsing
  static Future<FalAiResult> fromFluxSchnellJson(
    Map<String, dynamic> json,
    String prompt,
  ) async {
    debugPrint('🎃 FLUX: Parsing FLUX Schnell response');
    debugPrint('🎃 FLUX: Response keys: ${json.keys.toList()}');

    // FLUX Schnell response structure is different
    List<Map<String, dynamic>> images = [];

    // Format 1: Direct images array
    if (json.containsKey('images') && json['images'] is List) {
      final imagesList = json['images'] as List;
      debugPrint('🎃 FLUX: Found images array with ${imagesList.length} items');

      for (final imageData in imagesList) {
        if (imageData is Map<String, dynamic>) {
          images.add(imageData);
        }
      }
    }
    // Format 2: Nested in data/images
    else if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      final data = json['data'] as Map<String, dynamic>;
      if (data.containsKey('images') && data['images'] is List) {
        final imagesList = data['images'] as List;
        debugPrint(
          '🎃 FLUX: Found nested images array with ${imagesList.length} items',
        );

        for (final imageData in imagesList) {
          if (imageData is Map<String, dynamic>) {
            images.add(imageData);
          }
        }
      }
    }
    // Format 3: Single image in data
    else if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      final data = json['data'] as Map<String, dynamic>;
      if (data.containsKey('url') || data.containsKey('image_url')) {
        debugPrint('🎃 FLUX: Found single image in data');
        images.add(data);
      }
    }
    // Format 4: Direct URL fields
    else if (json.containsKey('url')) {
      debugPrint('🎃 FLUX: Found direct URL field');
      images.add({
        'url': json['url'],
        'content_type': json['content_type'] ?? 'image/jpeg',
      });
    } else if (json.containsKey('image_url')) {
      debugPrint('🎃 FLUX: Found direct image_url field');
      images.add({
        'url': json['image_url'],
        'content_type': json['content_type'] ?? 'image/jpeg',
      });
    }
    // Format 5: Response URL that needs to be fetched
    else if (json.containsKey('response_url')) {
      debugPrint('🎃 FLUX: Found response_url, fetching actual result...');
      final responseUrl = json['response_url'] as String;

      try {
        // Fetch the actual result from response_url
        final apiKey =
            EnvironmentConfig.falAiApiKey ??
            '03e8751f-6291-4402-9b16-4e4114658277:f6836d66a4e0d75c9325178efa778a76';
        final response = await http.get(
          Uri.parse(responseUrl),
          headers: {'Authorization': 'Key $apiKey'},
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          debugPrint(
            '🎃 FLUX: Response URL data: ${responseData.keys.toList()}',
          );

          // Recursively parse the response
          final nestedResult = await FalAiResult.fromFluxSchnellJson(
            responseData,
            prompt,
          );
          return nestedResult;
        } else {
          debugPrint(
            '🎃 FLUX: Failed to fetch response_url: ${response.statusCode}',
          );
        }
      } catch (e) {
        debugPrint('🎃 FLUX: Error fetching response_url: $e');
      }
    }

    debugPrint('🎃 FLUX: Parsed ${images.length} images');

    if (images.isEmpty) {
      debugPrint('🎃 FLUX: No images found in response');
      debugPrint('🎃 FLUX: WARNING - No images in response!');
      debugPrint('🎃 FLUX: Full response: $json');

      // Try to find any URL-like fields in the response
      final allKeys = json.keys.toList();
      debugPrint('🎃 FLUX: Available keys: $allKeys');

      // Look for any field that might contain a URL
      for (final key in allKeys) {
        final value = json[key];
        if (value is String &&
            (value.startsWith('http') || value.startsWith('https'))) {
          debugPrint('🎃 FLUX: Found potential URL in field $key: $value');
          images.add({'url': value, 'content_type': 'image/jpeg'});
          break;
        }
      }
    }

    if (images.isEmpty) {
      throw FalAiException(
        'No images found in FLUX Schnell response. '
        'Response structure: ${json.keys.toList()}',
      );
    }

    // Convert to FalAiImage objects
    final falImages = images.map((imageData) {
      final url =
          imageData['url'] as String? ??
          imageData['image_url'] as String? ??
          imageData['src'] as String?;

      if (url == null) {
        throw FalAiException('No URL found in image data: $imageData');
      }

      return FalAiImage(
        url: url,
        contentType:
            imageData['content_type'] as String? ??
            imageData['contentType'] as String? ??
            'image/jpeg',
      );
    }).toList();

    return FalAiResult(
      images: falImages,
      prompt: prompt,
      metadata: {
        'model': 'fal-ai/flux/schnell',
        'response_format': 'flux_schnell',
        'parsed_images': images.length,
      },
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
    debugPrint('🎃 FAL: Parsing image JSON: ${json.keys}');

    String resolvedUrl = '';
    if (json['url'] is String) {
      resolvedUrl = json['url'] as String;
      debugPrint('🎃 FAL: Found URL: $resolvedUrl');
    } else if (json['image'] is String) {
      resolvedUrl = json['image'] as String;
      debugPrint('🎃 FAL: Found image string: $resolvedUrl');
    } else if (json['image'] is Map) {
      final imageMap = json['image'] as Map;
      if (imageMap['url'] is String) {
        resolvedUrl = imageMap['url'] as String;
        debugPrint('🎃 FAL: Found URL in image map: $resolvedUrl');
      }
    }

    if (resolvedUrl.isEmpty) {
      debugPrint('🎃 FAL: WARNING - No URL found in image data!');
      debugPrint('🎃 FAL: Image JSON: $json');
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
