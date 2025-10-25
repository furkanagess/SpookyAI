import 'package:package_info_plus/package_info_plus.dart';

class VersionService {
  static String? _version;
  static String? _buildNumber;
  static String? _appName;

  /// Get app version from pubspec.yaml
  static Future<String> getVersion() async {
    if (_version != null) return _version!;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _version = packageInfo.version;
      return _version!;
    } catch (e) {
      // Fallback version if package_info_plus fails
      return '1.1.0';
    }
  }

  /// Get build number from pubspec.yaml
  static Future<String> getBuildNumber() async {
    if (_buildNumber != null) return _buildNumber!;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _buildNumber = packageInfo.buildNumber;
      return _buildNumber!;
    } catch (e) {
      // Fallback build number if package_info_plus fails
      return '15';
    }
  }

  /// Get app name from pubspec.yaml
  static Future<String> getAppName() async {
    if (_appName != null) return _appName!;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appName = packageInfo.appName;
      return _appName!;
    } catch (e) {
      // Fallback app name if package_info_plus fails
      return 'SpookyAI';
    }
  }

  /// Get full version string (version+build)
  static Future<String> getFullVersion() async {
    final version = await getVersion();
    final buildNumber = await getBuildNumber();
    return '$version+$buildNumber';
  }

  /// Get version for display (version only)
  static Future<String> getDisplayVersion() async {
    return await getVersion();
  }

  /// Get build number for display
  static Future<String> getDisplayBuildNumber() async {
    return await getBuildNumber();
  }

  /// Check if this is a debug build
  static bool get isDebug {
    bool debugMode = false;
    assert(debugMode = true);
    return debugMode;
  }

  /// Get version info for about page
  static Future<Map<String, String>> getVersionInfo() async {
    return {
      'appName': await getAppName(),
      'version': await getVersion(),
      'buildNumber': await getBuildNumber(),
      'fullVersion': await getFullVersion(),
      'isDebug': isDebug.toString(),
      'platform': await _getPlatformInfo(),
    };
  }

  /// Get platform information
  static Future<String> _getPlatformInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.packageName}';
    } catch (e) {
      return 'SpookyAI';
    }
  }
}
