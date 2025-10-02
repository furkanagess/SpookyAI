import 'package:shared_preferences/shared_preferences.dart';

class PaywallService {
  PaywallService._();

  static const String _paywallShownKey = 'paywall_shown_v1';

  static Future<bool> isPaywallShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_paywallShownKey) ?? false;
  }

  static Future<void> markPaywallShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_paywallShownKey, true);
  }
}
