import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../features/home/data/models/prompt_category.dart';
import '../../features/home/data/models/user_prompt.dart';
import '../../features/home/data/services/prompt_service.dart';
import '../../features/home/data/services/user_prompt_service.dart';
import 'premium_service.dart';

class PromptsProvider extends ChangeNotifier {
  // Search state
  List<PromptItem> _searchResults = [];
  List<UserPrompt> _userPromptSearchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';

  // User prompts state
  List<UserPrompt> _userPrompts = [];

  // Premium status
  bool _isPremium = false;
  StreamSubscription<bool>? _premiumStatusSubscription;

  // Getters
  List<PromptItem> get searchResults => List.unmodifiable(_searchResults);
  List<UserPrompt> get userPromptSearchResults =>
      List.unmodifiable(_userPromptSearchResults);
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  List<UserPrompt> get userPrompts => List.unmodifiable(_userPrompts);
  bool get isPremium => _isPremium;

  PromptsProvider() {
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
            'PromptsProvider: Premium status changed - isPremium: $isPremium',
          );
        }
      },
      onError: (error) {
        debugPrint(
          'PromptsProvider: Error listening to premium status: $error',
        );
      },
    );
  }

  // Load user prompts
  Future<void> loadUserPrompts() async {
    try {
      final userPrompts = await UserPromptService.getUserPrompts();
      _userPrompts = userPrompts;
      notifyListeners();
    } catch (e) {
      debugPrint('PromptsProvider: Error loading user prompts: $e');
    }
  }

  // Search functionality
  Future<void> searchPrompts(String query) async {
    _searchQuery = query;
    _isSearching = query.isNotEmpty;

    if (_isSearching) {
      try {
        final builtInResults = PromptService.searchPrompts(query);
        final userResults = await UserPromptService.searchUserPrompts(query);

        _searchResults = builtInResults;
        _userPromptSearchResults = userResults;
        notifyListeners();
      } catch (e) {
        debugPrint('PromptsProvider: Error searching prompts: $e');
      }
    } else {
      _searchResults.clear();
      _userPromptSearchResults.clear();
      notifyListeners();
    }
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _isSearching = false;
    _searchResults.clear();
    _userPromptSearchResults.clear();
    notifyListeners();
  }

  // Premium prompt check
  bool isPromptPremium(PromptItem prompt) {
    // Make every other prompt premium (50% premium)
    // Use prompt title hash to determine if it's premium
    final hash = prompt.title.hashCode;
    return hash.abs() % 2 == 1; // Every second prompt is premium
  }

  // User prompt operations
  Future<void> updateUserPromptUsage(String promptId) async {
    try {
      await UserPromptService.updatePromptUsage(promptId);
      // Reload user prompts to get updated usage count
      await loadUserPrompts();
    } catch (e) {
      debugPrint('PromptsProvider: Error updating prompt usage: $e');
    }
  }

  Future<void> deleteUserPrompt(String promptId) async {
    try {
      final success = await UserPromptService.deleteUserPrompt(promptId);
      if (success) {
        await loadUserPrompts();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('PromptsProvider: Error deleting user prompt: $e');
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    await loadUserPrompts();
  }

  // Get search results count
  int get totalSearchResults =>
      _searchResults.length + _userPromptSearchResults.length;

  // Check if prompt is locked (premium and user not premium)
  bool isPromptLocked(PromptItem prompt) {
    return isPromptPremium(prompt) && !_isPremium;
  }

  // Get popular prompts
  List<PromptItem> getPopularPrompts() {
    return PromptService.getPopularPrompts();
  }

  // Get all categories
  List<PromptCategory> getAllCategories() {
    return PromptService.getAllCategories();
  }

  // Get category content
  List<PromptItem> getCategoryContent(PromptCategory category) {
    return category.prompts;
  }
}
