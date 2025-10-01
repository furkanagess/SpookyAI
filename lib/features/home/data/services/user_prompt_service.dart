import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_prompt.dart';

class UserPromptService {
  static const String _userPromptsKey = 'user_prompts_v1';
  static const String _nextIdKey = 'user_prompts_next_id_v1';

  static Future<List<UserPrompt>> getUserPrompts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? promptsJson = prefs.getString(_userPromptsKey);

    if (promptsJson == null) {
      return [];
    }

    try {
      final List<dynamic> promptsList = json.decode(promptsJson);
      return promptsList
          .map((json) => UserPrompt.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<String> saveUserPrompt(UserPrompt prompt) async {
    final prefs = await SharedPreferences.getInstance();
    final List<UserPrompt> existingPrompts = await getUserPrompts();

    // Generate new ID if not provided
    String promptId = prompt.id;
    if (promptId.isEmpty) {
      final int nextId = prefs.getInt(_nextIdKey) ?? 1;
      promptId = 'user_prompt_$nextId';
      await prefs.setInt(_nextIdKey, nextId + 1);
    }

    final UserPrompt promptWithId = prompt.copyWith(
      id: promptId,
      createdAt: prompt.createdAt.isAtSameMomentAs(DateTime(1970))
          ? DateTime.now()
          : prompt.createdAt,
    );

    // Remove existing prompt with same ID if updating
    existingPrompts.removeWhere((p) => p.id == promptId);

    // Add new prompt
    existingPrompts.add(promptWithId);

    // Sort by creation date (newest first)
    existingPrompts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Save to SharedPreferences
    final List<Map<String, dynamic>> promptsJson = existingPrompts
        .map((p) => p.toJson())
        .toList();
    await prefs.setString(_userPromptsKey, json.encode(promptsJson));

    return promptId;
  }

  static Future<bool> deleteUserPrompt(String promptId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<UserPrompt> existingPrompts = await getUserPrompts();

    final int initialLength = existingPrompts.length;
    existingPrompts.removeWhere((p) => p.id == promptId);

    if (existingPrompts.length < initialLength) {
      final List<Map<String, dynamic>> promptsJson = existingPrompts
          .map((p) => p.toJson())
          .toList();
      await prefs.setString(_userPromptsKey, json.encode(promptsJson));
      return true;
    }

    return false;
  }

  static Future<bool> updatePromptUsage(String promptId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<UserPrompt> existingPrompts = await getUserPrompts();

    final int index = existingPrompts.indexWhere((p) => p.id == promptId);
    if (index != -1) {
      final UserPrompt updatedPrompt = existingPrompts[index].copyWith(
        usageCount: existingPrompts[index].usageCount + 1,
        lastUsedAt: DateTime.now(),
      );

      existingPrompts[index] = updatedPrompt;

      final List<Map<String, dynamic>> promptsJson = existingPrompts
          .map((p) => p.toJson())
          .toList();
      await prefs.setString(_userPromptsKey, json.encode(promptsJson));

      return true;
    }

    return false;
  }

  static Future<List<UserPrompt>> searchUserPrompts(String query) async {
    if (query.isEmpty) return [];

    final List<UserPrompt> allPrompts = await getUserPrompts();
    final String lowercaseQuery = query.toLowerCase();

    return allPrompts
        .where(
          (prompt) =>
              prompt.title.toLowerCase().contains(lowercaseQuery) ||
              prompt.prompt.toLowerCase().contains(lowercaseQuery),
        )
        .toList();
  }

  static Future<List<UserPrompt>> getUserPromptsByCategory(
    String category,
  ) async {
    final List<UserPrompt> allPrompts = await getUserPrompts();
    return allPrompts.where((prompt) => prompt.category == category).toList();
  }

  static Future<List<UserPrompt>> getMostUsedPrompts({int limit = 10}) async {
    final List<UserPrompt> allPrompts = await getUserPrompts();
    allPrompts.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return allPrompts.take(limit).toList();
  }

  static Future<List<UserPrompt>> getRecentPrompts({int limit = 10}) async {
    final List<UserPrompt> allPrompts = await getUserPrompts();
    allPrompts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allPrompts.take(limit).toList();
  }

  static Future<void> clearAllUserPrompts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userPromptsKey);
    await prefs.remove(_nextIdKey);
  }

  // Get available categories for user prompts
  static List<String> getAvailableCategories() {
    return [
      'Halloween',
      'Fantasy',
      'Horror',
      'Sci-Fi',
      'Nature',
      'Vintage',
      'Portrait',
      'Landscape',
      'Abstract',
      'Custom',
    ];
  }

  // Get suggested tags based on category
  static List<String> getSuggestedTags(String category) {
    switch (category.toLowerCase()) {
      case 'halloween':
        return ['spooky', 'ghost', 'pumpkin', 'scary', 'dark', 'horror'];
      case 'fantasy':
        return ['magic', 'dragon', 'castle', 'wizard', 'enchanted', 'mystical'];
      case 'horror':
        return [
          'terrifying',
          'nightmare',
          'demonic',
          'blood',
          'shadow',
          'evil',
        ];
      case 'sci-fi':
        return [
          'futuristic',
          'robot',
          'space',
          'alien',
          'cyberpunk',
          'technology',
        ];
      case 'nature':
        return ['landscape', 'forest', 'mountain', 'ocean', 'sky', 'natural'];
      case 'vintage':
        return [
          'retro',
          'classic',
          'old',
          'antique',
          'nostalgic',
          'historical',
        ];
      case 'portrait':
        return [
          'character',
          'face',
          'person',
          'expression',
          'close-up',
          'detailed',
        ];
      case 'landscape':
        return ['wide', 'panoramic', 'view', 'horizon', 'scenic', 'beautiful'];
      case 'abstract':
        return [
          'artistic',
          'creative',
          'colorful',
          'pattern',
          'geometric',
          'unique',
        ];
      default:
        return ['custom', 'personal', 'unique', 'creative'];
    }
  }
}
