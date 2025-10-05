import 'package:flutter/foundation.dart';
import 'package:quick_actions/quick_actions.dart';
import '../utils/platform_utils.dart';

class QuickActionsService {
  QuickActionsService._();

  static final QuickActions _quickActions = const QuickActions();
  static String? _launchShortcutType;

  static String? get launchShortcutType => _launchShortcutType;

  static Future<void> initialize() async {
    // Set up quick actions with platform-specific icons
    await _quickActions.setShortcutItems([
      ShortcutItem(
        type: 'com.spookyai.dontdelete',
        localizedTitle: 'please dont delete me 😢',
        localizedSubtitle: 'I\'m a friendly AI companion',
        icon: PlatformUtils.isAndroid ? 'app_icon' : 'heart',
      ),
    ]);

    // Handle quick action taps
    _quickActions.initialize((String shortcutType) {
      debugPrint('Quick action tapped: $shortcutType');
      _launchShortcutType = shortcutType;
    });
  }

  static void clearLaunchShortcut() {
    _launchShortcutType = null;
  }

  static bool get shouldShowDontDeleteMessage {
    return _launchShortcutType == 'com.spookyai.dontdelete';
  }
}
