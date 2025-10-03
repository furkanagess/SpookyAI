import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../features/home/domain/generation_mode.dart';
import 'premium_service.dart';

class MainNavigationProvider extends ChangeNotifier {
  // Navigation state
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  // Onboarding state
  int _onboardingPageIndex = 0;
  int get onboardingPageIndex => _onboardingPageIndex;

  // Premium status
  bool _isPremium = false;
  bool get isPremium => _isPremium;
  StreamSubscription<bool>? _premiumStatusSubscription;

  // Generation data
  String _prompt = '';
  String get prompt => _prompt;

  Uint8List? _uploadedImage;
  Uint8List? get uploadedImage => _uploadedImage;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  final List<Uint8List> _generatedImages = <Uint8List>[];
  List<Uint8List> get generatedImages => List.unmodifiable(_generatedImages);

  GenerationMode _activeMode = GenerationMode.text;
  GenerationMode get activeMode => _activeMode;

  // Animation controllers state
  bool _isFadeAnimationActive = false;
  bool get isFadeAnimationActive => _isFadeAnimationActive;

  bool _isPremiumBannerAnimationActive = false;
  bool get isPremiumBannerAnimationActive => _isPremiumBannerAnimationActive;

  MainNavigationProvider() {
    _initializePremiumStatus();
  }

  @override
  void dispose() {
    _premiumStatusSubscription?.cancel();
    super.dispose();
  }

  // Navigation methods
  void setCurrentIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  // Onboarding methods
  void setOnboardingPageIndex(int index) {
    if (_onboardingPageIndex != index) {
      _onboardingPageIndex = index;
      notifyListeners();
    }
  }

  // Premium status methods
  Future<void> _initializePremiumStatus() async {
    try {
      // Import here to avoid circular dependency
      final premiumService = await _getPremiumService();
      final isPremium = await premiumService.isPremiumUser();
      if (_isPremium != isPremium) {
        _isPremium = isPremium;
        notifyListeners();
      }
      _listenToPremiumStatusChanges();
    } catch (e) {
      if (_isPremium != false) {
        _isPremium = false;
        notifyListeners();
      }
    }
  }

  void _listenToPremiumStatusChanges() {
    _premiumStatusSubscription?.cancel();
    _premiumStatusSubscription = _getPremiumStatusStream().listen(
      (isPremium) {
        if (_isPremium != isPremium) {
          _isPremium = isPremium;
          notifyListeners();

          // Start banner animation when premium status changes to true
          if (isPremium) {
            _startPremiumBannerAnimation();
          } else {
            _stopPremiumBannerAnimation();
          }
        }
      },
      onError: (error) {
        debugPrint(
          'MainNavigationProvider: Error listening to premium status: $error',
        );
      },
    );
  }

  // Public method to force-refresh premium status (useful after test toggles)
  Future<void> refreshPremiumStatus() async {
    try {
      final premiumService = await _getPremiumService();
      final bool isPremiumNow = await premiumService.isPremiumUser();
      if (_isPremium != isPremiumNow) {
        _isPremium = isPremiumNow;
        notifyListeners();
      }
    } catch (_) {}
  }

  void _startPremiumBannerAnimation() {
    if (!_isPremiumBannerAnimationActive) {
      _isPremiumBannerAnimationActive = true;
      notifyListeners();
    }
  }

  void _stopPremiumBannerAnimation() {
    if (_isPremiumBannerAnimationActive) {
      _isPremiumBannerAnimationActive = false;
      notifyListeners();
    }
  }

  // Prompt methods
  void updatePrompt(String prompt) {
    if (_prompt != prompt) {
      _prompt = prompt;
      notifyListeners();
    }
  }

  // Image methods
  void setUploadedImage(Uint8List? imageBytes) {
    if (_uploadedImage != imageBytes) {
      _uploadedImage = imageBytes;
      // Pre-fill prompt to instruct using the uploaded image
      if (_activeMode == GenerationMode.image && _prompt.trim().isEmpty) {
        _prompt =
            'use this image: detailed transformation to spooky cinematic style';
      }
      notifyListeners();
    }
  }

  void removeUploadedImage() {
    if (_uploadedImage != null) {
      _uploadedImage = null;
      notifyListeners();
    }
  }

  // Generation mode methods
  void switchMode(GenerationMode newMode) {
    if (_activeMode != newMode) {
      _activeMode = newMode;
      if (_activeMode == GenerationMode.text) {
        _uploadedImage = null;
      }
      notifyListeners();
    }
  }

  // Generation methods
  void setGenerating(bool isGenerating) {
    if (_isGenerating != isGenerating) {
      _isGenerating = isGenerating;
      notifyListeners();
    }
  }

  void addGeneratedImage(Uint8List imageBytes) {
    _generatedImages.insert(0, imageBytes);
    notifyListeners();
  }

  void clearGeneratedImages() {
    if (_generatedImages.isNotEmpty) {
      _generatedImages.clear();
      notifyListeners();
    }
  }

  // Animation methods
  void setFadeAnimationActive(bool isActive) {
    if (_isFadeAnimationActive != isActive) {
      _isFadeAnimationActive = isActive;
      notifyListeners();
    }
  }

  // Helper methods for dependency injection
  Future<dynamic> _getPremiumService() async {
    return PremiumService;
  }

  Stream<bool> _getPremiumStatusStream() {
    return PremiumService.premiumStatusStream;
  }
}
