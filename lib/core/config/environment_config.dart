import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized configuration for environment variables
class EnvironmentConfig {
  /// FAL AI API Key for image generation
  static String? get falAiApiKey {
    // First try to get from environment variables
    final envKey = dotenv.env['FAL_AI_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }

    // Fallback to hardcoded key for development (remove in production)
    return '03e8751f-6291-4402-9b16-4e4114658277:f6836d66a4e0d75c9325178efa778a76';
  }

  /// Check if FAL AI API key is available
  static bool get isFalAiKeyAvailable =>
      falAiApiKey != null && falAiApiKey!.isNotEmpty;

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
