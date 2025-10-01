class PromptCategory {
  final String id;
  final String name;
  final String icon;
  final String description;
  final List<PromptItem> prompts;

  const PromptCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.prompts,
  });
}

class PromptItem {
  final String id;
  final String title;
  final String prompt;
  final String? imageUrl;
  final int usageCount;
  final bool isPopular;
  final List<String> tags;

  const PromptItem({
    required this.id,
    required this.title,
    required this.prompt,
    this.imageUrl,
    this.usageCount = 0,
    this.isPopular = false,
    this.tags = const [],
  });

  PromptItem copyWith({
    String? id,
    String? title,
    String? prompt,
    String? imageUrl,
    int? usageCount,
    bool? isPopular,
    List<String>? tags,
  }) {
    return PromptItem(
      id: id ?? this.id,
      title: title ?? this.title,
      prompt: prompt ?? this.prompt,
      imageUrl: imageUrl ?? this.imageUrl,
      usageCount: usageCount ?? this.usageCount,
      isPopular: isPopular ?? this.isPopular,
      tags: tags ?? this.tags,
    );
  }
}

