class UserPrompt {
  final String id;
  final String title;
  final String prompt;
  final String category;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final int usageCount;

  const UserPrompt({
    required this.id,
    required this.title,
    required this.prompt,
    required this.category,
    this.tags = const [],
    required this.createdAt,
    this.lastUsedAt,
    this.usageCount = 0,
  });

  UserPrompt copyWith({
    String? id,
    String? title,
    String? prompt,
    String? category,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    int? usageCount,
  }) {
    return UserPrompt(
      id: id ?? this.id,
      title: title ?? this.title,
      prompt: prompt ?? this.prompt,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'prompt': prompt,
      'category': category,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'usageCount': usageCount,
    };
  }

  factory UserPrompt.fromJson(Map<String, dynamic> json) {
    return UserPrompt(
      id: json['id'] as String,
      title: json['title'] as String,
      prompt: json['prompt'] as String,
      category: json['category'] as String,
      tags: List<String>.from(json['tags'] as List? ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
      usageCount: json['usageCount'] as int? ?? 0,
    );
  }
}

