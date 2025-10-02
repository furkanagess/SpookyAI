import 'package:flutter/foundation.dart';

class PromptInputProvider extends ChangeNotifier {
  // State variables
  String _text = '';
  int _characterCount = 0;
  int _maxLength = 500;

  // Getters
  String get text => _text;
  int get characterCount => _characterCount;
  int get maxLength => _maxLength;
  int get remainingCharacters => _maxLength - _characterCount;
  bool get isOverLimit => _characterCount > _maxLength;
  double get progressPercentage => _characterCount / _maxLength;

  // Initialize the provider
  void initialize(String? initialText, {int maxLength = 500}) {
    _maxLength = maxLength;
    _text = initialText ?? '';
    _characterCount = _text.length;
    notifyListeners();
  }

  // Update text
  void updateText(String text) {
    _text = text;
    _characterCount = text.length;
    notifyListeners();
  }

  // Clear text
  void clearText() {
    _text = '';
    _characterCount = 0;
    notifyListeners();
  }

  // Set max length
  void setMaxLength(int maxLength) {
    _maxLength = maxLength;
    notifyListeners();
  }

  // Check if text is valid
  bool get isValid {
    return _text.trim().isNotEmpty && !isOverLimit;
  }

  // Get validation message
  String? get validationMessage {
    if (_text.trim().isEmpty) {
      return 'Please enter a prompt';
    }
    if (isOverLimit) {
      return 'Prompt is too long (${_characterCount}/$_maxLength)';
    }
    return null;
  }

  // Get character count color
  String getCharacterCountColor() {
    if (isOverLimit) {
      return 'red';
    } else if (_characterCount > _maxLength * 0.8) {
      return 'orange';
    } else {
      return 'normal';
    }
  }

  // Get progress color
  String getProgressColor() {
    if (isOverLimit) {
      return 'red';
    } else if (_characterCount > _maxLength * 0.8) {
      return 'orange';
    } else {
      return 'green';
    }
  }

  // Reset provider
  void reset() {
    _text = '';
    _characterCount = 0;
    _maxLength = 500;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
