import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

class AvatarService {
  AvatarService._();

  static const String _avatarKey = 'user_avatar_v1';
  static const String _defaultAvatarKey = 'default_avatar_selected';

  /// Save user avatar from generated image
  static Future<bool> setAvatarFromImage(
    Uint8List imageBytes,
    String imageId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${appDir.path}/avatars');

      // Create avatars directory if it doesn't exist
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }

      // Save image file
      final avatarFile = File('${avatarDir.path}/avatar_$imageId.png');
      await avatarFile.writeAsBytes(imageBytes);

      // Save avatar info to preferences
      final avatarInfo = {
        'imageId': imageId,
        'filePath': avatarFile.path,
        'setAt': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_avatarKey, jsonEncode(avatarInfo));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get current avatar file path
  static Future<String?> getCurrentAvatarPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final avatarInfoStr = prefs.getString(_avatarKey);

      if (avatarInfoStr != null) {
        final avatarInfo = jsonDecode(avatarInfoStr) as Map<String, dynamic>;
        final filePath = avatarInfo['filePath'] as String;

        // Check if file still exists
        final file = File(filePath);
        if (await file.exists()) {
          return filePath;
        } else {
          // File doesn't exist, remove from preferences
          await removeAvatar();
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get current avatar image bytes
  static Future<Uint8List?> getCurrentAvatarBytes() async {
    try {
      final avatarPath = await getCurrentAvatarPath();
      if (avatarPath != null) {
        final file = File(avatarPath);
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if user has a custom avatar
  static Future<bool> hasCustomAvatar() async {
    final avatarPath = await getCurrentAvatarPath();
    return avatarPath != null;
  }

  /// Remove current avatar
  static Future<bool> removeAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final avatarInfoStr = prefs.getString(_avatarKey);

      if (avatarInfoStr != null) {
        final avatarInfo = jsonDecode(avatarInfoStr) as Map<String, dynamic>;
        final filePath = avatarInfo['filePath'] as String;

        // Delete file
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Remove from preferences
      await prefs.remove(_avatarKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get avatar info (when it was set)
  static Future<Map<String, dynamic>?> getAvatarInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final avatarInfoStr = prefs.getString(_avatarKey);

      if (avatarInfoStr != null) {
        return jsonDecode(avatarInfoStr) as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Set default avatar selection
  static Future<void> setDefaultAvatar(String avatarName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultAvatarKey, avatarName);
  }

  /// Get default avatar selection
  static Future<String> getDefaultAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultAvatarKey) ?? 'ghost';
  }

  /// Get list of default avatar options
  static List<Map<String, dynamic>> getDefaultAvatars() {
    return [
      {'name': 'ghost', 'icon': '👻', 'displayName': 'Ghost'},
      {'name': 'pumpkin', 'icon': '🎃', 'displayName': 'Pumpkin'},
      {'name': 'witch', 'icon': '🧙‍♀️', 'displayName': 'Witch'},
      {'name': 'spider', 'icon': '🕷️', 'displayName': 'Spider'},
      {'name': 'bat', 'icon': '🦇', 'displayName': 'Bat'},
      {'name': 'skull', 'icon': '💀', 'displayName': 'Skull'},
    ];
  }
}
