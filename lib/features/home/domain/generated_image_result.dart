import 'dart:typed_data';

enum GeneratedImageSource { stability, fal }

class GeneratedImageResult {
  final Uint8List imageBytes;
  final String prompt;
  final GeneratedImageSource source;
  final DateTime generatedAt;
  final String? remoteUrl;
  final bool isPersisted;

  const GeneratedImageResult({
    required this.imageBytes,
    required this.prompt,
    required this.source,
    required this.generatedAt,
    this.remoteUrl,
    this.isPersisted = false,
  });

  GeneratedImageResult copyWith({
    Uint8List? imageBytes,
    String? prompt,
    GeneratedImageSource? source,
    DateTime? generatedAt,
    String? remoteUrl,
    bool? isPersisted,
  }) {
    return GeneratedImageResult(
      imageBytes: imageBytes ?? this.imageBytes,
      prompt: prompt ?? this.prompt,
      source: source ?? this.source,
      generatedAt: generatedAt ?? this.generatedAt,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      isPersisted: isPersisted ?? this.isPersisted,
    );
  }
}
