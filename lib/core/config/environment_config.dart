import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized configuration for environment variables
class EnvironmentConfig {
  /// FAL AI API Key for image generation
  static String? get falAiApiKey => dotenv.env['FAL_AI_API_KEY'];

  /// Stability AI API Key
  static String? get stabilityApiKey => dotenv.env['STABILITY_API_KEY'];

  /// Check if FAL AI API key is available
  static bool get isFalAiKeyAvailable =>
      falAiApiKey != null && falAiApiKey!.isNotEmpty;

  /// Check if Stability AI API key is available
  static bool get isStabilityKeyAvailable =>
      stabilityApiKey != null && stabilityApiKey!.isNotEmpty;

  /// Get all missing required API keys
  static List<String> getMissingApiKeys() {
    final missing = <String>[];

    if (!isFalAiKeyAvailable) {
      missing.add('FAL_AI_API_KEY');
    }

    return missing;
  }

  /// Validate all required API keys
  static bool validateApiKeys() {
    return getMissingApiKeys().isEmpty;
  }
}
