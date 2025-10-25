import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/saved_images_provider.dart';
import '../../../../core/services/token_provider.dart';
import '../../../../core/services/main_navigation_provider.dart';
import '../../../../core/widgets/token_display_widget.dart';

import '../../../../core/services/fal_ai_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_metrics.dart';
import '../../../../core/utils/prompt_builder.dart';
import 'purchase_page.dart';
import 'photos_page.dart';
import 'prompts_page.dart';
import 'profile_page.dart';
import '../../domain/generation_mode.dart';
import '../../domain/generated_image_result.dart';
import '../widgets/prompt_input_widget.dart';
import '../widgets/image_upload_widget.dart';
import '../widgets/generation_progress_dialog.dart';
import '../widgets/paywall_dialog.dart';
import '../widgets/no_tokens_dialog.dart';
import '../widgets/low_balance_dialog.dart';
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

  Future<void> _showFalAiGenerationConfirmationDialog() async {
    final provider = context.read<MainNavigationProvider>();

    if (provider.prompt.isEmpty) {
      NotificationService.warning(
        context,
        message: 'Please enter a prompt to generate an image.',
      );
      return;
    }

    // Require an uploaded image when in Image-to-Image mode
    if (provider.activeMode == GenerationMode.image &&
        provider.uploadedImage == null) {
      NotificationService.warning(
        context,
        message: 'Please upload an image for Image-to-Image generation.',
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
                      colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9C27B0).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Confirm FAL AI Generation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                const Text(
                  'Generate image using FAL AI FLUX Schnell model with ultra-fast processing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF8C7BA6),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF8C7BA6),
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
                          backgroundColor: const Color(0xFF9C27B0),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Generate',
                          style: TextStyle(
                            color: Colors.white,
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
      await _generateFalAiImage();
    }
  }

  Future<void> _generateImage() async {
    final tokenProvider = context.read<TokenProvider>();

    // Check if user has tokens before starting
    await tokenProvider.loadBalance();
    if (tokenProvider.balance < 1) {
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => const NoTokensDialog(),
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

      // Use FAL AI FLUX Schnell for text-to-image generation with enhanced configuration
      final result = await FalAiService.generateImage(
        prompt: PromptBuilder.buildTextToImagePrompt(provider.prompt),
        numInferenceSteps: 4, // FLUX Schnell default
        numImages: 1,
        imageSize: 'square_hd', // FLUX Schnell default
        guidanceScale: 6.0, // FLUX Schnell default
        enableSafetyChecker: true,
        outputFormat: 'jpeg', // FLUX Schnell default
        syncMode: false,
        isCancelled: () => isCancelled, // Pass cancellation check
        style: FluxSchnellStyle.realistic, // Enhanced style support
        quality: FluxSchnellQuality.balanced, // Enhanced quality support
      );

      if (result.images.isEmpty) {
        throw Exception('No images generated');
      }

      // Download the image from URL
      final imageUrl = result.images.first.url;
      final imageResponse = await http.get(Uri.parse(imageUrl));
      if (imageResponse.statusCode != 200) {
        throw Exception('Failed to download generated image');
      }
      resultBytes = imageResponse.bodyBytes;

      // Check if generation was cancelled
      if (isCancelled) {
        try {
          progress.close();
        } catch (_) {}
        provider.setGenerating(false);
        return;
      }

      // Consume 1 token for text-to-image generation
      await tokenProvider.consumeTokens(1);

      // Check for low balance after token consumption
      if (tokenProvider.isLowBalance) {
        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => const LowBalanceDialog(),
        );
      }

      var generatedResult = GeneratedImageResult(
        imageBytes: resultBytes,
        prompt: provider.prompt,
        source: GeneratedImageSource.fal,
        generatedAt: DateTime.now(),
      );

      if (!mounted) return;
      provider.addGeneratedImage(generatedResult);

      try {
        progress.setProgress(1.0);
        progress.close();
      } catch (_) {}

      await _showResultDialog(generatedResult);

      // Clear prompt after successful generation
      provider.updatePrompt('');

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
          e.toString() != 'Exception: Generation cancelled by user' &&
          !e.toString().contains('Generation cancelled by user')) {
        String errorMessage = NotificationService.generationFailed;

        // Provide specific error messages
        if (e.toString().contains('timeout')) {
          errorMessage =
              'Generation took too long. Please try again with a shorter prompt.';
        } else if (e.toString().contains('Missing FAL AI API key')) {
          errorMessage =
              'FAL AI API key is missing. Please check your configuration.';
        } else if (e.toString().contains('FAL AI error')) {
          errorMessage = 'FAL AI service error. Please try again.';
        } else if (e.toString().contains('405')) {
          errorMessage = 'API endpoint error. Please try again.';
        }

        NotificationService.error(context, message: errorMessage);
      }
    } finally {
      if (mounted && !isCancelled) {
        provider.setGenerating(false);
      }
    }
  }

  Future<void> _generateFalAiImage() async {
    await _generateFalAiNewFlow();
  }

  // New, isolated FAL flow: minimal errors, always try to show the image
  Future<void> _generateFalAiNewFlow() async {
    print('🎃 FAL: Starting generation flow');
    final tokenProvider = context.read<TokenProvider>();
    final provider = context.read<MainNavigationProvider>();

    await tokenProvider.loadBalance();

    // Check token requirements based on generation mode
    final bool useImg2Img =
        provider.activeMode == GenerationMode.image &&
        provider.uploadedImage != null;
    final double requiredTokens = useImg2Img
        ? 2.0
        : 1.0; // 2 tokens for image-to-image, 1 token for text-to-image

    if (tokenProvider.balance < requiredTokens) {
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => const NoTokensDialog(),
      );
      return;
    }

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
      final bool useImg2Img =
          provider.activeMode == GenerationMode.image &&
          provider.uploadedImage != null;
      print(
        '🎃 FAL: Mode => ' +
            (useImg2Img ? 'image-to-image' : 'text-to-image') +
            ', prompt: ${provider.prompt}',
      );

      final result = useImg2Img
          ? await FalAiService.generateImageFromImage(
              prompt: PromptBuilder.buildImageToImagePrompt(provider.prompt),
              imageBytes: provider.uploadedImage!,
              imageStrength:
                  0.8, // From screenshot - higher strength for scene composition
              numInferenceSteps: 4, // From screenshot
              guidanceScale: 6.0, // From screenshot
              enableSafetyChecker: true, // From screenshot
              outputFormat: 'jpeg', // From screenshot
            )
          : await FalAiService.generateImage(
              prompt: PromptBuilder.buildTextToImagePrompt(provider.prompt),
              numInferenceSteps: 4,
              numImages: 1,
              imageSize: 'square_hd',
              guidanceScale: 6.0,
              enableSafetyChecker: true,
              outputFormat: 'jpeg',
              syncMode: false,
            );
      print('🎃 FAL: API returned ${result.images.length} images');

      if (isCancelled) {
        try {
          progress.close();
        } catch (_) {}
        provider.setGenerating(false);
        return;
      }

      if (result.images.isEmpty) {
        // Graceful: just end silently
        print('🎃 FAL: No images returned, ending');
        try {
          progress.close();
        } catch (_) {}
        provider.setGenerating(false);
        return;
      }

      final String imageUrl = result.images.first.url;
      print('🎃 FAL: Image URL: $imageUrl');
      Uint8List? bytes;
      try {
        // Prefer bytes for uniform UI
        print('🎃 FAL: Attempting to fetch bytes from URL');
        bytes = await FalAiService.fetchImageBytes(imageUrl);
        print('🎃 FAL: Successfully fetched ${bytes.length} bytes');
      } catch (e) {
        print('🎃 FAL: fetchImageBytes failed: $e');
      }
      // Secondary attempt: download to file then read bytes
      if (bytes == null) {
        try {
          print('🎃 FAL: Attempting downloadAndSaveImage fallback');
          final imagePath = await FalAiService.downloadAndSaveImage(imageUrl);
          final imageFile = File(imagePath);
          bytes = await imageFile.readAsBytes();
          print('🎃 FAL: Successfully got bytes from file: ${bytes.length}');
        } catch (e) {
          print('🎃 FAL: downloadAndSaveImage failed: $e');
        }
      }

      GeneratedImageResult? generationResult;
      if (bytes != null) {
        generationResult = GeneratedImageResult(
          imageBytes: bytes,
          prompt: provider.prompt,
          source: GeneratedImageSource.fal,
          generatedAt: DateTime.now(),
          remoteUrl: imageUrl,
        );
      }

      if (!mounted) return;

      try {
        progress.setProgress(1.0);
        progress.close();
      } catch (_) {}

      GeneratedImageResult? finalizedResult = generationResult;
      if (finalizedResult != null) {
        print('🎃 FAL: Displaying image with bytes');
        // Consume tokens based on generation mode
        final double tokensToConsume = useImg2Img
            ? 2.0
            : 1.0; // 2 tokens for image-to-image, 1 token for text-to-image
        await tokenProvider.consumeTokens(tokensToConsume);

        // Check for low balance after token consumption
        if (tokenProvider.isLowBalance) {
          if (!mounted) return;
          await showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => const LowBalanceDialog(),
          );
        }

        provider.addGeneratedImage(finalizedResult);
        await _showResultDialog(finalizedResult);

        // Clear prompt and uploaded image after successful generation
        provider.updatePrompt('');
        provider.removeUploadedImage();

        if (mounted) {
          NotificationService.success(
            context,
            message: NotificationService.imageGenerated,
          );
        }
      } else {
        print('🎃 FAL: Could not get bytes, showing network image as fallback');
        // Final fallback: show network image in dialog
        // Consume tokens based on generation mode
        final double tokensToConsume = useImg2Img
            ? 2.0
            : 1.0; // 2 tokens for image-to-image, 1 token for text-to-image
        await tokenProvider.consumeTokens(tokensToConsume);

        // Check for low balance after token consumption
        if (tokenProvider.isLowBalance) {
          if (!mounted) return;
          await showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => const LowBalanceDialog(),
          );
        }

        await showDialog<void>(
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
                    child: Container(
                      width: 280,
                      height: 280,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: 280,
                        height: 280,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 280,
                            height: 280,
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 280,
                            height: 280,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error, color: Colors.red),
                                  Text('Failed to load image'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );

        // Clear prompt and uploaded image after successful generation
        provider.updatePrompt('');
        provider.removeUploadedImage();

        if (mounted) {
          NotificationService.success(
            context,
            message: NotificationService.imageGenerated,
          );
        }
      }
    } catch (e) {
      // Swallow service errors in new flow; show nothing rather than error
      print('🎃 FAL: Generation failed: $e');
      try {
        progress.close();
      } catch (_) {}
    } finally {
      if (mounted && !isCancelled) {
        provider.setGenerating(false);
      }
    }
  }

  Future<void> _showResultDialog(
    GeneratedImageResult result, {
    Future<GeneratedImageResult?>? initialPersistFuture,
  }) async {
    GeneratedImageResult currentResult = result;
    bool isPersisted = result.isPersisted;
    bool isSaving = false;
    bool initialAttached = false;

    void attachPersistFuture(
      Future<GeneratedImageResult?> future,
      StateSetter setState,
    ) {
      setState(() {
        isSaving = true;
      });
      future
          .then((updated) {
            if (updated != null) {
              setState(() {
                currentResult = updated;
                isPersisted = updated.isPersisted;
              });
            }
          })
          .catchError((_) {})
          .whenComplete(() {
            setState(() {
              isSaving = false;
            });
          });
    }

    return showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (!initialAttached && initialPersistFuture != null) {
              initialAttached = true;
              attachPersistFuture(initialPersistFuture, setState);
            }

            return Dialog(
              backgroundColor: const Color(0xFF1D162B),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Container(
                      width: 280,
                      height: 280,
                      child: Image.memory(
                        currentResult.imageBytes,
                        fit: BoxFit.cover,
                        width: 280,
                        height: 280,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
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
                                'Prompt',
                                style: TextStyle(
                                  color: Color(0xFFFF6A00),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currentResult.prompt,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Action buttons
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(Icons.close),
                                    label: const Text('Close'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: isPersisted || isSaving
                                        ? null
                                        : () {
                                            final future =
                                                _persistGeneratedImage(
                                                  currentResult,
                                                  showSuccessNotification: true,
                                                );
                                            attachPersistFuture(
                                              future,
                                              setState,
                                            );
                                          },
                                    icon: isSaving
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Icon(
                                            isPersisted
                                                ? Icons.check
                                                : Icons.download,
                                          ),
                                    label: Text(isPersisted ? 'Saved' : 'Save'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF6A00),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      await _shareGeneratedImage(currentResult);
                                    },
                                    icon: const Icon(Icons.share),
                                    label: const Text('Share'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                      backgroundColor: const Color(
                                        0xFF2A1F3D,
                                      ).withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              ],
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
      },
    );
  }

  Future<GeneratedImageResult?> _persistGeneratedImage(
    GeneratedImageResult result, {
    bool showSuccessNotification = true,
  }) async {
    if (!mounted) return null;
    final navigationProvider = context.read<MainNavigationProvider>();

    if (result.isPersisted) {
      if (showSuccessNotification) {
        NotificationService.info(
          context,
          message: 'Image is already saved in your gallery.',
        );
      }
      return result;
    }

    try {
      await context.read<SavedImagesProvider>().addSavedImage(
        imageBytes: result.imageBytes,
        prompt: result.prompt,
        isImageToImage: false,
        originalImagePath: null,
      );
      final updated = navigationProvider.markImagePersisted(result);
      if (showSuccessNotification) {
        NotificationService.success(
          context,
          message: NotificationService.imageSaved,
        );
      }
      return updated;
    } catch (e) {
      debugPrint('Failed to persist generated image: $e');
      if (showSuccessNotification) {
        NotificationService.error(
          context,
          message: NotificationService.saveFailed,
        );
      }
    }
    return null;
  }

  Future<void> _shareGeneratedImage(GeneratedImageResult result) async {
    try {
      final directory = await getTemporaryDirectory();
      final fileName =
          'ghostface_${result.generatedAt.millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(result.imageBytes, flush: true);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: result.prompt.isNotEmpty ? 'Prompt: ${result.prompt}' : null);
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        context,
        message: 'Failed to share image. Please try again.',
      );
    }
  }

  // _buildGeneratedImageCard removed

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
          resizeToAvoidBottomInset: false,
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
      resizeToAvoidBottomInset: false,
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
          // Help Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showHelpDialog,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6A00), Color(0xFF9C27B0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
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
                  child: const Icon(
                    Icons.help_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
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

                                // Image upload area (visible only in image-to-image mode)
                                if (provider.activeMode == GenerationMode.image)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: ImageUploadWidget(
                                      uploadedImage: provider.uploadedImage,
                                      onImageSelected: (bytes) {
                                        provider.setUploadedImage(bytes);
                                      },
                                      onImageRemoved: () {
                                        provider.removeUploadedImage();
                                      },
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
                                // Latest Creations removed
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

          // Generate buttons (fixed at bottom, above home indicator)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              minimum: const EdgeInsets.only(left: 0, right: 0, bottom: 8),
              child: _buildGenerateButtons(provider),
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
            child: Stack(
              children: [
                _buildModeCard(
                  mode: GenerationMode.image,
                  icon: Icons.image_rounded,
                  title: 'Image to Image',
                  subtitle: null,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  provider: provider,
                  isDisabled: false,
                ),
              ],
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1D162B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6A00), Color(0xFF9C27B0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_fix_high,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'How to Use SpookyAI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Content
              const Text(
                'Create amazing Halloween images with AI! Here\'s how to get the best results:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Tips
              _buildHelpTip(
                icon: Icons.text_fields,
                title: 'Write Detailed Prompts',
                description:
                    'Be specific about what you want. Instead of "scary", try "spooky haunted mansion with glowing windows and fog"',
              ),
              const SizedBox(height: 16),

              _buildHelpTip(
                icon: Icons.auto_awesome,
                title: 'Use Ready-Made Prompts',
                description:
                    'For better results, use the pre-made prompts in the Prompts section. They\'re optimized for Halloween themes!',
              ),
              const SizedBox(height: 16),

              _buildHelpTip(
                icon: Icons.image,
                title: 'Image-to-Image Mode',
                description:
                    'Upload your photo and transform it into a Halloween character. Perfect for creating spooky versions of yourself!',
              ),
              const SizedBox(height: 16),

              _buildHelpTip(
                icon: Icons.local_fire_department,
                title: 'Token System',
                description:
                    'Text-to-image costs 1 token, Image-to-image costs 2 tokens. Watch ads to earn free tokens!',
              ),
              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6A00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Got it!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpTip({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6A00).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFFF6A00), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButtons(MainNavigationProvider provider) {
    if (provider.activeMode == GenerationMode.image) {
      // Image to Image Mode - Show FAL AI Generate Button
      return Consumer<TokenProvider>(
        builder: (context, tokenProvider, child) {
          final hasTokens =
              tokenProvider.balance >= 2.0; // 2 tokens for image-to-image
          final hasImage =
              provider.uploadedImage !=
              null; // Image required for image-to-image
          final canGenerate =
              !provider.isGenerating &&
              provider.prompt.isNotEmpty &&
              hasTokens &&
              hasImage;

          return FilledButton.icon(
            onPressed: canGenerate
                ? _showFalAiGenerationConfirmationDialog
                : null,
            icon: provider.isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.psychology),
            label: Text(
              provider.isGenerating
                  ? 'Generating...'
                  : !hasTokens
                  ? 'Token Required (2 Tokens)'
                  : 'Generate Image (2 Tokens)',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: canGenerate
                  ? const Color(0xFF9C27B0)
                  : const Color(0xFF4B5563),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          );
        },
      );
    } else {
      // Text to Image Mode - Show Regular Generate Button
      return Consumer<TokenProvider>(
        builder: (context, tokenProvider, child) {
          final hasTokens =
              tokenProvider.balance >= 1.0; // 1 token for text-to-image
          final canGenerate =
              !provider.isGenerating && provider.prompt.isNotEmpty && hasTokens;

          return FilledButton.icon(
            onPressed: canGenerate ? _showGenerationConfirmationDialog : null,
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
                  : !hasTokens
                  ? 'Token Required (1 Token)'
                  : 'Generate Image (1 Token)',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: canGenerate
                  ? const Color(0xFFFF6A00)
                  : const Color(0xFF4B5563),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          );
        },
      );
    }
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
          height: 64, // Fixed height for both buttons
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
                        fontSize: subtitle != null
                            ? 12
                            : 14, // Smaller title for buttons with subtitle
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
                          fontSize: 9, // Smaller subtitle text
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
