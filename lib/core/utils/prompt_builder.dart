import '../models/halloween_prompt_data.dart';

class PromptBuilder {
  // Image-to-image template
  static const String _imageToImageTemplate =
      '[ENHANCED_USER_PROMPT], transform the input image into a Halloween themed cinematic digital artwork, [SETTING], [LIGHTING], [EFFECTS], film grain, premium digital art style, immersive atmosphere, no text, no watermark';

  // Text-to-image template with enhanced user prompt emphasis
  static const String _textToImageTemplate =
      '[ENHANCED_USER_PROMPT], in a Halloween themed cinematic digital artwork, [SETTING], [LIGHTING], [EFFECTS], film grain, premium digital art style, immersive atmosphere, no text, no watermark';

  // Negative prompt removed intentionally to avoid suppressing background Ghostface
  static const String _negativePrompt = '';

  // COMMENTED OUT: Ghostface Trend templates disabled
  // static const String _ghostfaceTrendImageTemplate =
  //     '[USER_PROMPT], transformed into the viral TikTok ghostface trend style while strictly preserving the subject's real face identity from the input photo (same facial features, expression, skin tone, and hairstyle). Subject lying on a bed with silky pink sheets in a retro styled pink bedroom, holding a vintage corded phone, a large bowl of popcorn nearby, colorful movie and magazine posters on the wall, warm cinematic bedroom lighting. In the background, in the doorway, an eerie shadow reveals a tall mysterious figure wearing the iconic Ghostface mask from the Scream movie, standing silently and slightly blurred for depth. Ultra photorealistic, cinematic photography, highly detailed, immersive atmosphere, no text, no watermark.';

  // static const String _ghostfaceTrendTextTemplate =
  //     '[USER_PROMPT], ultra-photorealistic cinematic composition: foreground subject seated on the right side of the frame on a bed with silky pink satin sheets, facing camera, holding a vintage pink corded phone to the ear, relaxed pose. A large glass bowl of popcorn sits on the bed in front, glossy teen magazines scattered on the pink sheets. The retro-styled pink bedroom walls are covered with colorful 90s movie and celebrity posters. A warm table lamp casts a soft cinematic glow. In the background, through the open doorway on the left, a tall shadowy figure in a black robe wearing the iconic Ghostface mask from the Scream movie stands silently, slightly blurred for depth of field. TikTok ghostface trend style, strongly enforced background Ghostface presence, realistic lighting, shallow depth of field, highly detailed, immersive atmosphere, no text, no watermark';

  /// Builds a Halloween-themed prompt for image-to-image generation
  static String buildImageToImagePrompt(String userPrompt) {
    return _buildPrompt(
      _imageToImageTemplate,
      userPrompt,
      'transform the input image',
    );
  }

  /// Builds a Halloween-themed prompt for image-to-image generation with custom elements
  static String buildImageToImagePromptWithElements(
    String userPrompt, {
    String? setting,
    String? lighting,
    String? effect,
  }) {
    return _buildPromptWithElements(
      _imageToImageTemplate,
      userPrompt,
      'transform the input image',
      setting: setting,
      lighting: lighting,
      effect: effect,
    );
  }

  /// Builds a Halloween-themed prompt for text-to-image generation
  ///
  /// Takes the user's input prompt and combines it with the base Halloween
  /// themed template to create a comprehensive prompt for new image creation.
  static String buildTextToImagePrompt(String userPrompt) {
    return _buildPrompt(
      _textToImageTemplate,
      userPrompt,
      'create a spooky scene',
    );
  }

  // COMMENTED OUT: Ghostface Trend functionality disabled
  // /// Ghostface Trend: Text-to-Image
  // static String buildGhostfaceTrendTextPrompt(String userPrompt) {
  //   final cleanedPrompt = _cleanPrompt(userPrompt);
  //   final prompt = cleanedPrompt.isEmpty
  //       ? 'create a ghostface trend scene'
  //       : cleanedPrompt;
  //   final enforced = _ghostfaceTrendTextTemplate
  //       .replaceAll('[USER_PROMPT]', prompt)
  //       .replaceAll(
  //         'stands silently',
  //         'stands clearly visible and unmistakable as the Ghostface character',
  //       )
  //       .replaceAll(
  //         'slightly blurred for depth of field',
  //         'slightly blurred for depth of field but still clearly recognizable',
  //       );
  //   return enforced;
  // }

  /// Builds a Halloween-themed prompt for text-to-image generation with custom elements
  static String buildTextToImagePromptWithElements(
    String userPrompt, {
    String? setting,
    String? lighting,
    String? effect,
  }) {
    return _buildPromptWithElements(
      _textToImageTemplate,
      userPrompt,
      'create a spooky scene',
      setting: setting,
      lighting: lighting,
      effect: effect,
    );
  }

  /// Helper method to build prompts with random elements
  static String _buildPrompt(
    String template,
    String userPrompt,
    String defaultPrompt,
  ) {
    final randomElements = HalloweenPromptData.getRandomElements();
    return _buildPromptWithElements(
      template,
      userPrompt,
      defaultPrompt,
      setting: randomElements['setting'],
      lighting: randomElements['lighting'],
      effect: randomElements['effect'],
    );
  }

  /// Helper method to build prompts with specific elements
  static String _buildPromptWithElements(
    String template,
    String userPrompt,
    String defaultPrompt, {
    String? setting,
    String? lighting,
    String? effect,
  }) {
    // Use provided elements or get random ones
    final finalSetting = setting ?? HalloweenPromptData.getRandomSetting();
    final finalLighting = lighting ?? HalloweenPromptData.getRandomLighting();
    final finalEffect = effect ?? HalloweenPromptData.getRandomEffect();

    // Enhance the user prompt for better AI model attention
    final enhancedPrompt = _enhanceUserPrompt(userPrompt);
    final prompt = enhancedPrompt.isEmpty ? defaultPrompt : enhancedPrompt;

    // Replace all placeholders
    String finalPrompt = template
        .replaceAll('[USER_PROMPT]', prompt)
        .replaceAll('[ENHANCED_USER_PROMPT]', prompt)
        .replaceAll('[SETTING]', finalSetting)
        .replaceAll('[LIGHTING]', finalLighting)
        .replaceAll('[EFFECTS]', finalEffect);

    return finalPrompt;
  }

  // COMMENTED OUT: Ghostface Trend functionality disabled
  // /// Ghostface Trend: Image-to-Image (transform existing image)
  // static String buildGhostfaceTrendImagePrompt(String userPrompt) {
  //   final cleanedPrompt = _cleanPrompt(userPrompt);
  //   final prompt = cleanedPrompt.isEmpty
  //       ? 'transform the input image into ghostface trend'
  //       : cleanedPrompt;
  //   final enforced = _ghostfaceTrendImageTemplate
  //       .replaceAll('[USER_PROMPT]', prompt)
  //       .replaceAll(
  //         'standing silently',
  //         'standing clearly visible and unmistakable as the Ghostface character',
  //       )
  //       .replaceAll(
  //         'slightly blurred for depth',
  //         'slightly blurred for depth but still clearly recognizable',
  //       );
  //   return enforced;
  // }

  /// Enhances user prompt with weight emphasis techniques
  static String _enhanceUserPrompt(String userPrompt) {
    // Simple enhancement for now - just clean and return
    String cleanedPrompt = userPrompt.trim();

    // If prompt is empty or very short, return default
    if (cleanedPrompt.isEmpty || cleanedPrompt.length < 3) {
      return 'create a spooky scene';
    }

    // Return the original prompt with minimal processing
    return cleanedPrompt;
  }

  /// Gets the negative prompt for both generation modes
  static String getNegativePrompt() {
    return _negativePrompt;
  }

  /// Builds the complete prompt structure for image-to-image generation
  static Map<String, String> buildImageToImagePromptStructure(
    String userPrompt,
  ) {
    return {
      'prompt': buildImageToImagePrompt(userPrompt),
      'negative_prompt': getNegativePrompt(),
    };
  }

  /// Builds the complete prompt structure for text-to-image generation
  static Map<String, String> buildTextToImagePromptStructure(
    String userPrompt,
  ) {
    return {
      'prompt': buildTextToImagePrompt(userPrompt),
      'negative_prompt': getNegativePrompt(),
    };
  }
}
