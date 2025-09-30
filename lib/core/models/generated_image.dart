import 'dart:typed_data';

/// Model class for generated images with associated metadata
class GeneratedImage {
  final Uint8List imageBytes;
  final String prompt;
  final DateTime createdAt;

  const GeneratedImage({
    required this.imageBytes,
    required this.prompt,
    required this.createdAt,
  });

  /// Creates a copy of this GeneratedImage with updated fields
  GeneratedImage copyWith({
    Uint8List? imageBytes,
    String? prompt,
    DateTime? createdAt,
  }) {
    return GeneratedImage(
      imageBytes: imageBytes ?? this.imageBytes,
      prompt: prompt ?? this.prompt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeneratedImage &&
        other.imageBytes == imageBytes &&
        other.prompt == prompt &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return imageBytes.hashCode ^ prompt.hashCode ^ createdAt.hashCode;
  }
}
