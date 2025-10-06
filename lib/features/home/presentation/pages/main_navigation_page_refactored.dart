import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/saved_images_provider.dart';
import '../../../../core/services/token_provider.dart';
import '../../../../core/services/main_navigation_provider.dart';
import '../../../../core/widgets/token_display_widget.dart';

import '../../../../core/services/stability_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_metrics.dart';
import 'purchase_page.dart';
import 'photos_page.dart';
import 'prompts_page.dart';
import 'profile_page.dart';
import '../../domain/generation_mode.dart';
import '../widgets/prompt_input_widget.dart';
import '../widgets/generation_progress_dialog.dart';
import '../widgets/paywall_dialog.dart';
import '../../../../core/models/paywall_service.dart';

class MainNavigationPageRefactored extends StatefulWidget {
  const MainNavigationPageRefactored({super.key});

  @override
  State<MainNavigationPageRefactored> createState() =>
      _MainNavigationPageRefactoredState();
}

class _MainNavigationPageRefactoredState
    extends State<MainNavigationPageRefactored>
    with TickerProviderStateMixin {
  late final StabilityService _stability;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _premiumBannerController;
  late Animation<double> _premiumBannerAnimation;

  // Page controller for better performance
  final PageController _pageController = PageController();
  late Animation<Offset> _slideAnimation;

  // Page keys for better performance
  final List<GlobalKey<State<StatefulWidget>>> _pageKeys = [
    GlobalKey<State<StatefulWidget>>(),
    GlobalKey<State<StatefulWidget>>(),
    GlobalKey<State<StatefulWidget>>(),
    GlobalKey<State<StatefulWidget>>(),
  ];

  @override
  void initState() {
    super.initState();
    _stability = StabilityService();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _premiumBannerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _premiumBannerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _premiumBannerController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();

    // Show one-time paywall after first main screen frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Ensure premium status is up-to-date so the premium banner can appear
      try {
        await context.read<MainNavigationProvider>().refreshPremiumStatus();
      } catch (_) {}
      final shown = await PaywallService.isPaywallShown();
      if (!shown) {
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => PaywallDialog(
            onBuy: () => Navigator.of(ctx).pop(),
            onRestore: () => Navigator.of(ctx).pop(),
          ),
        );
        await PaywallService.markPaywallShown();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _premiumBannerController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _showGenerationConfirmationDialog() async {
    final provider = context.read<MainNavigationProvider>();

    if (provider.prompt.isEmpty) {
      NotificationService.warning(
        context,
        message: 'Please enter a prompt to generate an image.',
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1D162B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6A00), Color(0xFF9C27B0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6A00).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_fix_high_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Confirm Image Generation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  'Are you sure you want to generate an image with this prompt?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Prompt display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1F3D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF6A00).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.edit_note_rounded,
                            color: Color(0xFFFF6A00),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Your Prompt:',
                            style: TextStyle(
                              color: Color(0xFFFF6A00),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.prompt,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6A00),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Generate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      await _generateImage();
    }
  }

  Future<void> _generateImage() async {
    final tokenProvider = context.read<TokenProvider>();

    // Check if user has tokens before starting
    await tokenProvider.loadBalance();
    if (tokenProvider.balance < 1) {
      if (!mounted) return;
      NotificationService.error(
        context,
        message: NotificationService.outOfTokens,
        actionLabel: 'Buy Tokens',
        onAction: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PurchasePage()));
        },
      );
      return;
    }

    final provider = context.read<MainNavigationProvider>();
    provider.setGenerating(true);

    bool isCancelled = false;
    final progress = showGenerationProgressDialog(
      context,
      onCancel: () {
        isCancelled = true;
        provider.setGenerating(false);
      },
    );

    try {
      Uint8List resultBytes;

      // Create cancellation callback
      Future<void> checkCancellation() async {
        if (isCancelled) {
          throw Exception('Generation cancelled by user');
        }
      }

      // Standard text-to-image only
      resultBytes = await _stability.generateImageBytes(
        prompt: provider.prompt,
        onCancel: checkCancellation,
      );

      // Check if generation was cancelled
      if (isCancelled) {
        try {
          progress.close();
        } catch (_) {}
        provider.setGenerating(false);
        return;
      }

      // Consume token only after successful generation
      await tokenProvider.consumeOne();

      if (!mounted) return;
      provider.addGeneratedImage(resultBytes);

      try {
        progress.setProgress(1.0);
        progress.close();
      } catch (_) {}

      await _showResultDialog(resultBytes);
      if (mounted) {
        NotificationService.success(
          context,
          message: NotificationService.imageGenerated,
        );
      }
    } catch (e) {
      if (!mounted) return;
      try {
        progress.close();
      } catch (_) {}

      // Only show error if not cancelled
      if (!isCancelled &&
          e.toString() != 'Exception: Generation cancelled by user') {
        NotificationService.error(
          context,
          message: NotificationService.generationFailed,
        );
      }
    } finally {
      if (mounted && !isCancelled) {
        provider.setGenerating(false);
      }
    }
  }

  Future<void> _showResultDialog(Uint8List imageBytes) async {
    final provider = context.read<MainNavigationProvider>();

    return showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1D162B),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Prompt info
                    if (provider.prompt.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A1F3D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Prompt:',
                              style: TextStyle(
                                color: Color(0xFFFF6A00),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              provider.prompt,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            label: const Text('Close'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await _saveImage(imageBytes);
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('Save'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6A00),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveImage(Uint8List imageBytes) async {
    final provider = context.read<MainNavigationProvider>();

    try {
      await context.read<SavedImagesProvider>().addSavedImage(
        imageBytes: imageBytes,
        prompt: provider.prompt,
        isImageToImage: false,
        originalImagePath: null,
      );

      if (mounted) {
        NotificationService.success(
          context,
          message: NotificationService.imageSaved,
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.error(
          context,
          message: NotificationService.saveFailed,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MainNavigationProvider>(
      builder: (context, provider, child) {
        // Start/stop premium banner animation based on premium status
        if (provider.isPremium) {
          if (!_premiumBannerController.isAnimating) {
            _premiumBannerController.repeat(period: const Duration(seconds: 3));
          }
        } else {
          if (_premiumBannerController.isAnimating) {
            _premiumBannerController.stop();
            _premiumBannerController.reset();
          }
        }
        return Scaffold(
          body: IndexedStack(
            index: provider.currentIndex,
            children: [
              _buildGenerateTab(provider),
              PhotosPage(
                key: _pageKeys[1],
                onNavigateToGenerate: () {
                  provider.setCurrentIndex(0);
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              PromptsPage(
                key: _pageKeys[2],
                onPromptSelected: (prompt) {
                  provider.updatePrompt(prompt);
                  provider.setCurrentIndex(0); // Navigate to generate tab
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              ProfilePage(key: _pageKeys[3]),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF0F0B1A).withOpacity(0.8),
                  const Color(0xFF0F0B1A).withOpacity(0.95),
                ],
              ),
            ),
            child: Row(
              children: [
                // Generate Button
                Expanded(
                  child: _buildNavButton(
                    index: 0,
                    icon: Icons.auto_fix_high,
                    label: 'Generate',
                    provider: provider,
                  ),
                ),
                // Photos Button
                Expanded(
                  child: _buildNavButton(
                    index: 1,
                    icon: Icons.photo_library_outlined,
                    label: 'Photos',
                    provider: provider,
                  ),
                ),
                // Prompts Button
                Expanded(
                  child: _buildNavButton(
                    index: 2,
                    icon: Icons.lightbulb_outline,
                    label: 'Prompts',
                    provider: provider,
                  ),
                ),
                // Profile Button
                Expanded(
                  child: _buildNavButton(
                    index: 3,
                    icon: Icons.person_outline,
                    label: 'Profile',
                    provider: provider,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      key: const ValueKey('premium_banner'),
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6A00), Color(0xFFFF8A00), Color(0xFFFFA500)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6A00).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Premium star icon with animation
          AnimatedBuilder(
            animation: _premiumBannerAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _premiumBannerAnimation.value * 2 * 3.14159,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(
                      0.2 + (_premiumBannerAnimation.value * 0.1),
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 12),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          // Premium text
          const Text(
            'Premium Member',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          // Sparkle effect with animation
          AnimatedBuilder(
            animation: _premiumBannerAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (_premiumBannerAnimation.value * 0.4),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(
                      0.2 + (_premiumBannerAnimation.value * 0.2),
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateTab(MainNavigationProvider provider) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6A00), Color(0xFF9C27B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_fix_high_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'SpookyAI',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F0B1A),
        elevation: 0,
        toolbarHeight: AppMetrics.toolbarHeight,
        actions: [
          // Token Purchase Button
          TokenDisplayWidget(
            onTap: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PurchasePage()));
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(provider.isPremium ? 40 : 0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, -1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: provider.isPremium
                ? _buildPremiumBanner()
                : const SizedBox.shrink(),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Subtle background decorations
          Positioned(
            top: 24,
            left: -8,
            child: Opacity(
              opacity: 0.08,
              child: Text('🕸️', style: TextStyle(fontSize: 72)),
            ),
          ),
          Positioned(
            bottom: 100,
            right: 16,
            child: Opacity(
              opacity: 0.08,
              child: Text('🎃', style: TextStyle(fontSize: 72)),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Main content area
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bottomInset = MediaQuery.of(
                          context,
                        ).viewInsets.bottom;
                        return SingleChildScrollView(
                          physics: bottomInset > 0
                              ? const BouncingScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            80 + bottomInset, // Extra space for fixed button
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - bottomInset,
                            ),
                            child: Column(
                              children: [
                                // Welcome section with Halloween title
                                Container(
                                  height: 44,
                                  margin: const EdgeInsets.fromLTRB(
                                    0,
                                    12,
                                    0,
                                    12,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF6A00),
                                        Color(0xFF9C27B0),
                                      ],
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.auto_fix_high_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Happy Halloween! Get spooky with your edits',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Image upload area with optimized positioning
                                ClipRect(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    height: 0,
                                    child: AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                      opacity: 0.0,
                                      child: const SizedBox.shrink(),
                                    ),
                                  ),
                                ),

                                // Spacing
                                const SizedBox(height: 8),
                                // Prompt input
                                PromptInputWidget(
                                  onPromptChanged: (prompt) {
                                    provider.updatePrompt(prompt);
                                  },
                                  hintText: 'Describe your Halloween scene...',
                                  initialText: provider.prompt,
                                ),
                                const SizedBox(height: 16),

                                // Fixed Mode selector row
                                _buildCompactModeSelector(provider),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Generate button (fixed at bottom, above home indicator/keyboard)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              minimum: EdgeInsets.only(left: 0, right: 0, bottom: 8),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        !provider.isGenerating && provider.prompt.isNotEmpty
                        ? _showGenerationConfirmationDialog
                        : null,
                    icon: provider.isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_fix_high),
                    label: Text(
                      provider.isGenerating
                          ? 'Generating...'
                          : 'Generate Image',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          !provider.isGenerating && provider.prompt.isNotEmpty
                          ? const Color(0xFFFF6A00)
                          : const Color(0xFF4B5563),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactModeSelector(MainNavigationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1D162B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image to Image Mode (Coming Soon)
          Expanded(
            child: _buildModeCard(
              mode: GenerationMode.image,
              icon: Icons.image_rounded,
              title: 'Image to Image',
              subtitle: 'Coming Soon',
              gradient: const LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              provider: provider,
              isDisabled: true,
            ),
          ),
          const SizedBox(width: 6),
          // Text to Image Mode
          Expanded(
            child: _buildModeCard(
              mode: GenerationMode.text,
              icon: Icons.text_fields_rounded,
              title: 'Text to Image',
              subtitle: null,
              gradient: const LinearGradient(
                colors: [Color(0xFFB25AFF), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              provider: provider,
              isDisabled: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required GenerationMode mode,
    required IconData icon,
    required String title,
    String? subtitle,
    required Gradient gradient,
    required MainNavigationProvider provider,
    required bool isDisabled,
  }) {
    final isSelected = provider.activeMode == mode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : () => provider.switchMode(mode),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: isSelected && !isDisabled ? gradient : null,
            color: isSelected && !isDisabled
                ? null
                : (isDisabled
                      ? Colors.grey.withOpacity(0.2)
                      : Colors.transparent),
            border: Border.all(
              color: isSelected && !isDisabled
                  ? Colors.white.withOpacity(0.2)
                  : Colors.transparent,
              width: 1,
            ),
            boxShadow: isSelected && !isDisabled
                ? [
                    BoxShadow(
                      color: gradient.colors.first.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected && !isDisabled
                      ? Colors.white.withOpacity(0.15)
                      : (isDisabled
                            ? Colors.grey.withOpacity(0.3)
                            : gradient.colors.first.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isDisabled
                      ? Colors.grey.withOpacity(0.6)
                      : (isSelected ? Colors.white : gradient.colors.first),
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),

              // Title and subtitle
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDisabled
                            ? Colors.grey.withOpacity(0.6)
                            : (isSelected ? Colors.white : Colors.white),
                        letterSpacing: -0.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDisabled
                              ? Colors.grey.withOpacity(0.5)
                              : Colors.white.withOpacity(0.7),
                          letterSpacing: -0.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required int index,
    required IconData icon,
    required String label,
    required MainNavigationProvider provider,
  }) {
    final isSelected = provider.currentIndex == index;

    return GestureDetector(
      onTap: () {
        provider.setCurrentIndex(index);
      },
      child: Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF6A00)
              : const Color(0xFF1D162B).withOpacity(0.9),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF6A00).withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6A00).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF8C7BA6),
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF8C7BA6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
