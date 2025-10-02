import 'package:flutter/foundation.dart';
import '../../core/models/halloween_prompt_data.dart';

class HalloweenPromptProvider extends ChangeNotifier {
  // State variables
  String _selectedSetting = '';
  String _selectedLighting = '';
  String _selectedEffect = '';

  // Getters
  String get selectedSetting => _selectedSetting;
  String get selectedLighting => _selectedLighting;
  String get selectedEffect => _selectedEffect;

  // Initialize the provider
  void initialize({
    String? initialSetting,
    String? initialLighting,
    String? initialEffect,
  }) {
    _selectedSetting = initialSetting ?? HalloweenPromptData.getRandomSetting();
    _selectedLighting =
        initialLighting ?? HalloweenPromptData.getRandomLighting();
    _selectedEffect = initialEffect ?? HalloweenPromptData.getRandomEffect();
    notifyListeners();
  }

  // Update setting
  void updateSetting(String setting) {
    _selectedSetting = setting;
    notifyListeners();
  }

  // Update lighting
  void updateLighting(String lighting) {
    _selectedLighting = lighting;
    notifyListeners();
  }

  // Update effect
  void updateEffect(String effect) {
    _selectedEffect = effect;
    notifyListeners();
  }

  // Select random options
  void selectRandom() {
    _selectedSetting = HalloweenPromptData.getRandomSetting();
    _selectedLighting = HalloweenPromptData.getRandomLighting();
    _selectedEffect = HalloweenPromptData.getRandomEffect();
    notifyListeners();
  }

  // Get current selections
  Map<String, String> getCurrentSelections() {
    return {
      'setting': _selectedSetting,
      'lighting': _selectedLighting,
      'effect': _selectedEffect,
    };
  }

  // Check if a setting is selected
  bool isSettingSelected(String setting) {
    return _selectedSetting == setting;
  }

  // Check if a lighting is selected
  bool isLightingSelected(String lighting) {
    return _selectedLighting == lighting;
  }

  // Check if an effect is selected
  bool isEffectSelected(String effect) {
    return _selectedEffect == effect;
  }

  // Reset to random selections
  void resetToRandom() {
    selectRandom();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
