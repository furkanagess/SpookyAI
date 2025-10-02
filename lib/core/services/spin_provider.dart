import 'package:flutter/foundation.dart';
import '../services/spin_service.dart';
import '../services/premium_service.dart';

class SpinProvider extends ChangeNotifier {
  // State variables
  bool _isLoading = true;
  bool _isPremium = false;
  int _remainingSpins = 0;
  bool _isSpinning = false;
  SpinResult? _lastResult;

  // Getters
  bool get isLoading => _isLoading;
  bool get isPremium => _isPremium;
  int get remainingSpins => _remainingSpins;
  bool get isSpinning => _isSpinning;
  SpinResult? get lastResult => _lastResult;

  // Initialize the provider
  Future<void> initialize() async {
    await _loadSpinData();
  }

  Future<void> _loadSpinData() async {
    setLoading(true);

    try {
      final isPremium = await PremiumService.isPremiumUser();
      final remainingSpins = await SpinService.getRemainingSpins();

      _isPremium = isPremium;
      _remainingSpins = remainingSpins;
      setLoading(false);

      debugPrint(
        'SpinProvider: Data loaded - isPremium: $isPremium, remainingSpins: $remainingSpins',
      );
    } catch (e) {
      setLoading(false);
      debugPrint('SpinProvider: Error loading spin data: $e');
    }
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set premium status
  void setPremiumStatus(bool isPremium) {
    _isPremium = isPremium;
    notifyListeners();
  }

  // Set remaining spins
  void setRemainingSpins(int spins) {
    _remainingSpins = spins;
    notifyListeners();
  }

  // Set spinning state
  void setSpinning(bool spinning) {
    _isSpinning = spinning;
    notifyListeners();
  }

  // Set last result
  void setLastResult(SpinResult? result) {
    _lastResult = result;
    notifyListeners();
  }

  // Reload data (called after spin completion)
  Future<void> reloadData() async {
    await _loadSpinData();
  }

  // Check if user can spin
  bool get canSpin => _remainingSpins > 0 && _isPremium;

  // Get spin status text
  String get spinStatusText {
    if (_isPremium) {
      return 'Spin the wheel daily to earn free tokens! You have $_remainingSpins spin${_remainingSpins == 1 ? '' : 's'} remaining today.';
    } else {
      return 'Spin the wheel daily to earn free tokens! Upgrade to Premium to unlock this feature.';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
