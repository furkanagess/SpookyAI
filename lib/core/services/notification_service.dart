import 'package:flutter/material.dart';

enum NotificationType { success, error, warning, info }

class AppNotification {
  final String message;
  final NotificationType type;
  final Duration duration;
  final VoidCallback? onAction;
  final String? actionLabel;

  const AppNotification({
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 3),
    this.onAction,
    this.actionLabel,
  });
}

class NotificationService {
  static OverlayEntry? _currentOverlay;
  static bool _isShowing = false;

  // Success Messages
  static const String promptSaved = 'Prompt saved successfully!';
  static const String promptUpdated = 'Prompt updated successfully!';
  static const String promptDeleted = 'Prompt deleted successfully!';
  static const String imageGenerated = 'Image generated successfully!';
  static const String imageSaved = 'Image saved to gallery!';
  static const String imageShared = 'Image shared successfully!';
  static const String tokensAdded = 'Tokens added successfully!';
  static const String purchaseSuccessful = 'Purchase completed successfully!';
  static const String apiKeySaved = 'API key saved successfully!';

  // Error Messages
  static const String networkError =
      'Network error. Please check your connection.';
  static const String apiKeyRequired =
      'Image generation API key is required. Please add your API key.';
  static const String outOfTokens = 'Out of tokens. Purchase more to continue.';
  static const String generationFailed =
      'Image generation failed. Please try again.';
  static const String saveFailed = 'Failed to save image. Please try again.';
  static const String shareFailed = 'Failed to share image. Please try again.';
  static const String purchaseFailed = 'Purchase failed. Please try again.';
  static const String invalidApiKey = 'Invalid API key. Please check your key.';
  static const String promptTooShort =
      'Prompt should be at least 10 characters.';
  static const String titleRequired = 'Please enter a title.';
  static const String promptRequired = 'Please enter a prompt.';
  static const String unknownError =
      'An unexpected error occurred. Please try again.';

  // Warning Messages
  static const String lowTokens = 'You are running low on tokens!';
  static const String apiKeyExpired = 'API key may be expired. Please check.';
  static const String slowConnection =
      'Slow connection detected. Generation may take longer.';

  // Info Messages
  static const String generatingImage = 'Generating your spooky image...';
  static const String processingImage = 'Processing your image...';
  static const String savingImage = 'Saving image to gallery...';
  static const String copyingToClipboard = 'Copied to clipboard!';
  static const String restorePurchases = 'Restoring purchases...';
  static const String welcomeMessage =
      'Welcome to SpookyAI! Start creating spooky images.';

  // Show notification
  static void show(
    BuildContext context, {
    required String message,
    required NotificationType type,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    // Hide current notification if showing
    hide();

    final notification = AppNotification(
      message: message,
      type: type,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );

    _showOverlay(context, notification);
  }

  // Success notification
  static void success(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      message: message,
      type: NotificationType.success,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  // Error notification
  static void error(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      message: message,
      type: NotificationType.error,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  // Warning notification
  static void warning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      message: message,
      type: NotificationType.warning,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  // Info notification
  static void info(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      message: message,
      type: NotificationType.info,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  // Hide current notification
  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
    _isShowing = false;
  }

  // Show overlay notification
  static void _showOverlay(BuildContext context, AppNotification notification) {
    if (_isShowing) return;

    _isShowing = true;

    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: _buildNotificationWidget(context, notification),
        ),
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);

    // Auto hide after duration
    Future.delayed(notification.duration, () {
      hide();
    });
  }

  // Build notification widget
  static Widget _buildNotificationWidget(
    BuildContext context,
    AppNotification notification,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: GestureDetector(
              onTap: hide,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(notification.type),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _getShadowColor(notification.type),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getIconBackgroundColor(notification.type),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIcon(notification.type),
                        color: _getIconColor(notification.type),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Message
                    Expanded(
                      child: Text(
                        notification.message,
                        style: TextStyle(
                          color: _getTextColor(notification.type),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                    // Action button
                    if (notification.onAction != null &&
                        notification.actionLabel != null)
                      TextButton(
                        onPressed: notification.onAction,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          notification.actionLabel!,
                          style: TextStyle(
                            color: _getTextColor(notification.type),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    // Close button
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: hide,
                      child: Icon(
                        Icons.close,
                        color: _getTextColor(
                          notification.type,
                        ).withOpacity(0.7),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Get colors based on notification type
  static Color _getBackgroundColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF1B5E20); // Dark green
      case NotificationType.error:
        return const Color(0xFFB71C1C); // Dark red
      case NotificationType.warning:
        return const Color(0xFFE65100); // Dark orange
      case NotificationType.info:
        return const Color(0xFF0D47A1); // Dark blue
    }
  }

  static Color _getShadowColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF4CAF50).withOpacity(0.3);
      case NotificationType.error:
        return const Color(0xFFF44336).withOpacity(0.3);
      case NotificationType.warning:
        return const Color(0xFFFF9800).withOpacity(0.3);
      case NotificationType.info:
        return const Color(0xFF2196F3).withOpacity(0.3);
    }
  }

  static Color _getIconBackgroundColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF4CAF50);
      case NotificationType.error:
        return const Color(0xFFF44336);
      case NotificationType.warning:
        return const Color(0xFFFF9800);
      case NotificationType.info:
        return const Color(0xFF2196F3);
    }
  }

  static Color _getIconColor(NotificationType type) {
    return Colors.white;
  }

  static Color _getTextColor(NotificationType type) {
    return Colors.white;
  }

  static IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.warning:
        return Icons.warning_outlined;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }
}
