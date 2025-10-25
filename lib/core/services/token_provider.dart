import 'package:flutter/foundation.dart';
import 'token_service.dart';

class TokenProvider extends ChangeNotifier {
  double _balance = 0.0;
  bool _isLoading = false;

  double get balance => _balance;
  bool get isLoading => _isLoading;

  Future<void> loadBalance() async {
    _isLoading = true;
    notifyListeners();

    try {
      _balance = await TokenService.getBalance();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBalance() async {
    await loadBalance();
  }

  Future<bool> consumeOne() async {
    final success = await TokenService.consumeOne();
    if (success) {
      await refreshBalance();
    }
    return success;
  }

  Future<bool> consumeTokens(double amount) async {
    final success = await TokenService.consumeTokens(amount);
    if (success) {
      await refreshBalance();
    }
    return success;
  }

  Future<void> refundOne() async {
    await TokenService.refundOne();
    await refreshBalance();
  }

  Future<void> addTokens(double amount) async {
    await TokenService.addTokens(amount);
    await refreshBalance();
  }

  bool get isLowBalance => _balance < 1.0;
}
