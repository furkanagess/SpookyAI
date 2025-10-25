import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  TokenService._();
  static const String _kTokenKey = 'user_tokens_v2';
  static const String _kInitKey = 'user_tokens_initialized_v2';
  static const String _kTrialGrantedKey = 'trial_granted_once_v2';
  static const double initialTokens = 3.0;

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();
  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  // Note: On iOS, secure storage (Keychain) persists across reinstalls;
  // on Android, data is removed on uninstall, so preventing reinstall-abuse
  // robustly would require a backend. This client-side guard still stops
  // repeat grants within the same device lifecycle and on iOS across reinstalls.

  static Future<double> getBalance() async {
    final prefs = await _prefs();
    // One-time trial grant: check secure flag to avoid abuse on reinstall
    final trialGranted = await _secure.read(key: _kTrialGrantedKey);
    if (!(prefs.getBool(_kInitKey) ?? false)) {
      // First launch in this install. Decide whether to grant free tokens.
      if (trialGranted == 'yes') {
        // Trial already granted previously on this device; start with 0
        await prefs.setDouble(_kTokenKey, 0.0);
      } else {
        // First ever grant on this device → grant and mark in secure storage
        await prefs.setDouble(_kTokenKey, initialTokens);
        await _secure.write(key: _kTrialGrantedKey, value: 'yes');
      }
      await prefs.setBool(_kInitKey, true);
    }
    return prefs.getDouble(_kTokenKey) ?? 0.0;
  }

  static Future<void> addTokens(double amount) async {
    final prefs = await _prefs();
    final current = await getBalance();
    final newBalance = current + amount;
    await prefs.setDouble(_kTokenKey, newBalance);
  }

  static Future<bool> consumeOne() async {
    final prefs = await _prefs();
    final current = await getBalance();
    if (current <= 0) return false;
    await prefs.setDouble(_kTokenKey, current - 1.0);
    return true;
  }

  static Future<bool> consumeTokens(double amount) async {
    final prefs = await _prefs();
    final current = await getBalance();
    if (current < amount) return false;
    await prefs.setDouble(_kTokenKey, current - amount);
    return true;
  }

  static Future<void> refundOne() async {
    await addTokens(1.0);
  }

  /// Grant monthly premium tokens (20 tokens)
  static Future<void> grantMonthlyPremiumTokens() async {
    await addTokens(20.0);
  }

  /// Check if user can claim monthly tokens
  static Future<bool> canClaimMonthlyTokens() async {
    final lastClaimStr = await _secure.read(key: 'last_monthly_token_claim');

    if (lastClaimStr == null) return true;

    final lastClaim = DateTime.parse(lastClaimStr);
    final now = DateTime.now();
    final daysSinceLastClaim = now.difference(lastClaim).inDays;

    return daysSinceLastClaim >= 30;
  }

  /// Mark monthly tokens as claimed
  static Future<void> markMonthlyTokensClaimed() async {
    await _secure.write(
      key: 'last_monthly_token_claim',
      value: DateTime.now().toIso8601String(),
    );
  }
}
