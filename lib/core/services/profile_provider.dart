import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'avatar_service.dart';
import 'premium_service.dart';
import 'daily_login_service.dart';
import 'username_service.dart';

class ProfileProvider extends ChangeNotifier {
  // Profile state
  Uint8List? _currentAvatar;
  bool _isLoading = true;
  bool _isPremium = false;
  bool _canClaimDailyReward = false;
  String _username = 'Spooky Creator';

  // Transient UI state (e.g., dialogs)
  int? _selectedImageIndex;

  // Stream subscription for premium status
  StreamSubscription<bool>? _premiumStatusSubscription;

  // Getters
  Uint8List? get currentAvatar => _currentAvatar;
  bool get isLoading => _isLoading;
  bool get isPremium => _isPremium;
  bool get canClaimDailyReward => _canClaimDailyReward;
  String get username => _username;
  int? get selectedImageIndex => _selectedImageIndex;

  ProfileProvider() {
    _initializePremiumStatus();
  }

  @override
  void dispose() {
    _premiumStatusSubscription?.cancel();
    super.dispose();
  }

  // Initialize premium status and listen to changes
  Future<void> _initializePremiumStatus() async {
    try {
      final isPremium = await PremiumService.isPremiumUser();
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

  // Listen to premium status changes
  void _listenToPremiumStatusChanges() {
    _premiumStatusSubscription?.cancel();
    _premiumStatusSubscription = PremiumService.premiumStatusStream.listen(
      (isPremium) {
        if (_isPremium != isPremium) {
          _isPremium = isPremium;
          notifyListeners();
          debugPrint(
            'ProfileProvider: Premium status changed - isPremium: $isPremium',
          );
        }
      },
      onError: (error) {
        debugPrint(
          'ProfileProvider: Error listening to premium status: $error',
        );
      },
    );
  }

  // Load all profile data
  Future<void> loadProfileData() async {
    _setLoading(true);

    try {
      // Load avatar
      final avatarBytes = await AvatarService.getCurrentAvatarBytes();

      // Check premium status
      final isPremium = await PremiumService.isPremiumUser();

      // Load daily login data
      final canClaimReward = await DailyLoginService.canClaimDailyReward();

      // Load username
      final username = await UsernameService.getUsername();

      // Update all state at once
      _currentAvatar = avatarBytes;
      _isPremium = isPremium;
      _canClaimDailyReward = canClaimReward;
      _username = username;
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      debugPrint('ProfileProvider: Error loading profile data: $e');
    }
  }

  // Set loading state
  void _setLoading(bool isLoading) {
    if (_isLoading != isLoading) {
      _isLoading = isLoading;
      notifyListeners();
    }
  }

  // Avatar management
  Future<void> setAvatarFromImage(Map<String, dynamic> imageData) async {
    _setLoading(true);

    try {
      final imageId = imageData['id'] as String;
      final imageBytes = imageData['bytes'] as Uint8List;

      final success = await AvatarService.setAvatarFromImage(
        imageBytes,
        imageId,
      );

      if (success) {
        _currentAvatar = imageBytes;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ProfileProvider: Error setting avatar from image: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setDefaultAvatar(Map<String, dynamic> avatarData) async {
    try {
      await AvatarService.setDefaultAvatar(avatarData['name']);
      await AvatarService.removeAvatar(); // Remove custom avatar

      _currentAvatar = null;
      notifyListeners();
    } catch (e) {
      debugPrint('ProfileProvider: Error setting default avatar: $e');
    }
  }

  Future<void> removeAvatar() async {
    try {
      final success = await AvatarService.removeAvatar();

      if (success) {
        _currentAvatar = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ProfileProvider: Error removing avatar: $e');
    }
  }

  // Username management
  Future<void> updateUsername(String newUsername) async {
    try {
      final success = await UsernameService.setUsername(newUsername);
      if (success) {
        _username = newUsername;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ProfileProvider: Error updating username: $e');
    }
  }

  // Daily reward management
  Future<void> claimDailyReward() async {
    if (!_canClaimDailyReward) {
      return;
    }

    try {
      final result = await DailyLoginService.recordDailyLogin();

      if (result.isNewLogin && result.reward > 0) {
        // Update local state immediately to prevent multiple clicks
        _canClaimDailyReward = false;
        notifyListeners();

        // Reload profile data to get updated state
        await loadProfileData();
      }
    } catch (e) {
      debugPrint('ProfileProvider: Error claiming daily reward: $e');
    }
  }

  // Premium demo management
  Future<void> activatePremiumDemo() async {
    try {
      await PremiumService.activatePremiumDemo();
      // Premium status will be updated automatically via stream
    } catch (e) {
      debugPrint('ProfileProvider: Error activating premium demo: $e');
    }
  }

  Future<void> deactivatePremiumDemo() async {
    try {
      await PremiumService.deactivatePremiumDemo();
      // Premium status will be updated automatically via stream
    } catch (e) {
      debugPrint('ProfileProvider: Error deactivating premium demo: $e');
    }
  }

  // Refresh profile data
  Future<void> refreshProfileData() async {
    await loadProfileData();
  }

  // Transient UI state setters
  void setSelectedImageIndex(int? index) {
    if (_selectedImageIndex != index) {
      _selectedImageIndex = index;
      notifyListeners();
    }
  }
}
