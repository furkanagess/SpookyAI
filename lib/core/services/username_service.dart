import 'package:shared_preferences/shared_preferences.dart';

class UsernameService {
  static const String _usernameKey = 'custom_username';
  static const String _defaultUsername = 'Spooky Creator';

  /// Get the current username
  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey) ?? _defaultUsername;
  }

  /// Set a custom username
  static Future<bool> setUsername(String username) async {
    if (username.trim().isEmpty) {
      return false;
    }
    
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_usernameKey, username.trim());
  }

  /// Reset to default username
  static Future<bool> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_usernameKey);
  }

  /// Check if username is custom (not default)
  static Future<bool> isCustomUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString(_usernameKey);
    return currentUsername != null && currentUsername != _defaultUsername;
  }
}
