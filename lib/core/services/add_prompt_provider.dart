import 'package:flutter/foundation.dart';
import '../../features/home/data/models/user_prompt.dart';
import '../../features/home/data/services/user_prompt_service.dart';

class AddPromptProvider extends ChangeNotifier {
  // State variables
  bool _isLoading = false;
  String _title = '';
  String _prompt = '';
  UserPrompt? _existingPrompt;

  // Getters
  bool get isLoading => _isLoading;
  String get title => _title;
  String get prompt => _prompt;
  UserPrompt? get existingPrompt => _existingPrompt;

  // Initialize the provider
  void initialize(UserPrompt? existingPrompt) {
    _existingPrompt = existingPrompt;
    if (existingPrompt != null) {
      _title = existingPrompt.title;
      _prompt = existingPrompt.prompt;
    } else {
      _title = '';
      _prompt = '';
    }
    notifyListeners();
  }

  // Update title
  void updateTitle(String title) {
    _title = title;
    notifyListeners();
  }

  // Update prompt
  void updatePrompt(String prompt) {
    _prompt = prompt;
    notifyListeners();
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Save prompt
  Future<UserPrompt?> savePrompt() async {
    if (_title.trim().isEmpty || _prompt.trim().isEmpty) {
      return null;
    }

    setLoading(true);

    try {
      final UserPrompt userPrompt = UserPrompt(
        id: _existingPrompt?.id ?? '',
        title: _title.trim(),
        prompt: _prompt.trim(),
        category: 'Custom',
        tags: const [],
        createdAt: _existingPrompt?.createdAt ?? DateTime.now(),
        usageCount: _existingPrompt?.usageCount ?? 0,
        lastUsedAt: _existingPrompt?.lastUsedAt,
      );

      await UserPromptService.saveUserPrompt(userPrompt);

      debugPrint('AddPromptProvider: Prompt saved successfully');
      return userPrompt;
    } catch (e) {
      debugPrint('AddPromptProvider: Error saving prompt: $e');
      return null;
    } finally {
      setLoading(false);
    }
  }

  // Validate form
  String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a title';
    }
    return null;
  }

  String? validatePrompt(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a prompt';
    }
    if (value.trim().length < 10) {
      return 'Prompt should be at least 10 characters';
    }
    return null;
  }

  // Check if form is valid
  bool get isFormValid {
    return _title.trim().isNotEmpty &&
        _prompt.trim().isNotEmpty &&
        _prompt.trim().length >= 10;
  }

  // Reset form
  void resetForm() {
    _title = '';
    _prompt = '';
    _existingPrompt = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
