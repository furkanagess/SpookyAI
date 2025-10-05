import 'package:flutter/foundation.dart';

class PlatformUtils {
  PlatformUtils._();

  /// Check if the current platform is Android
  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;

  /// Check if the current platform is iOS
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// Get the current platform name as string
  static String get platformName => defaultTargetPlatform.name;

  /// Check if the current platform is mobile (Android or iOS)
  static bool get isMobile => isAndroid || isIOS;

  /// Get platform-specific identifier
  static String get platformId => isAndroid ? 'android' : 'ios';
}
