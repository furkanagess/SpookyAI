import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../../../core/config/api_keys.dart';
import '../../../../core/services/stability_service.dart';
import '../../../../core/services/token_provider.dart';
import '../../../../core/widgets/token_display_widget.dart';
import '../../../../core/utils/prompt_builder.dart';
import '../../../../core/models/generated_image.dart';
import '../../../../core/services/image_storage_service.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/saved_images_provider.dart';
// import '../../domain/generation_mode.dart'; // COMMENTED OUT: Ghostface module disabled
// import '../widgets/prompt_input_widget.dart'; // COMMENTED OUT: Ghostface module disabled
// import '../widgets/image_upload_widget.dart'; // COMMENTED OUT: Ghostface module disabled
// import '../widgets/halloween_prompt_selector.dart'; // COMMENTED OUT: Ghostface module disabled
import '../widgets/loading_indicator.dart';
import '../widgets/generation_progress_dialog.dart';
// import 'package:flutter/services.dart' show rootBundle; // COMMENTED OUT: Ghostface module disabled

class GenerationPage extends StatefulWidget {
  const GenerationPage({super.key});

  @override
  State<GenerationPage> createState() => _GenerationPageState();
}

class _GenerationPageState extends State<GenerationPage>
    with TickerProviderStateMixin {
  late final StabilityService _stability;
  final PageController _pageController = PageController();

  // Animation controllers
  late AnimationController _modeTransitionController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Generation data
  String _prompt = '';
  Uint8List? _uploadedImage;
  bool _isGenerating = false;
  // Deprecated in favor of persisted _savedImages
  // final List<GeneratedImage> _generatedImages = <GeneratedImage>[];
  List<SavedImage> _savedImages = <SavedImage>[];
  // GenerationMode _activeMode = GenerationMode.text; // COMMENTED OUT: Ghostface module disabled

  // Halloween prompt elements
  String _selectedSetting = '';
  String _selectedLighting = '';
  String _selectedEffect = '';

  // COMMENTED OUT: Ghostface Trend toggle disabled
  // bool _useGhostfaceTrend = false;
  // removed preset image toggle

  @override
  void initState() {
    super.initState();
    _stability = StabilityService();

    // Initialize animation controllers
    _modeTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _loadSavedImages();
  }

  Future<void> _loadSavedImages() async {
    final images = await ImageStorageService.getSavedImages();
    if (mounted) {
      setState(() {
        _savedImages = images;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _modeTransitionController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  bool get _hasStabilityKey => ApiKeys.stability.isNotEmpty;

  // COMMENTED OUT: Unused methods - Ghostface module disabled
  // void _onPromptChanged(String prompt) {
  //   setState(() {
  //     _prompt = prompt;
  //   });
  // }

  // void _onHalloweenElementsChanged(
  //   String setting,
  //   String lighting,
  //   String effect,
  // ) {
  //   setState(() {
  //     _selectedSetting = setting;
  //     _selectedLighting = lighting;
  //     _selectedEffect = effect;
  //   });
  // }

  // void _onImageSelected(Uint8List imageBytes) {
  //   setState(() {
  //     _uploadedImage = imageBytes;
  //   });
  // }

  // void _onImageRemoved() {
  //   setState(() {
  //     _uploadedImage = null;
  //   });
  // }

  // COMMENTED OUT: Unused method - Ghostface module disabled
  // Future<void> _switchMode(GenerationMode newMode) async {
  //   if (_activeMode == newMode) return;

  //   await _modeTransitionController.forward();
  //   setState(() {
  //     _activeMode = newMode;
  //     if (_activeMode == GenerationMode.text) {
  //       _uploadedImage = null;
  //     }
  //   });
  //   await _modeTransitionController.reverse();
  // }

  Future<void> _generateImage() async {
    if (_prompt.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a prompt')));
      return;
    }

    // Check token balance
    final tokenProvider = context.read<TokenProvider>();
    if (tokenProvider.balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No tokens remaining. Please get more tokens to generate images.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    // Show progress dialog
    final progress = showGenerationProgressDialog(context);

    try {
      Uint8List resultBytes;
      String finalPrompt;

      // COMMENTED OUT: Ghostface Trend functionality disabled
      // if (_useGhostfaceTrend && _uploadedImage == null) {
      //   // Ghostface Trend Image-to-Image using preset base image
      //   finalPrompt = PromptBuilder.buildGhostfaceTrendImagePrompt(_prompt);
      //   final Uint8List base = (await rootBundle.load(
      //     'assets/images/ghost_face_trend.png',
      //   )).buffer.asUint8List();
      //   resultBytes = await _stability.generateImageFromImage(
      //     prompt: finalPrompt,
      //     imageBytes: base,
      //   );
      // } else
      if (_uploadedImage != null) {
        // Image-to-image generation
        // COMMENTED OUT: Ghostface Trend functionality disabled
        // finalPrompt = _useGhostfaceTrend
        //     ? PromptBuilder.buildGhostfaceTrendImagePrompt(_prompt)
        //     : PromptBuilder.buildImageToImagePromptWithElements(
        //         _prompt,
        //         setting: _selectedSetting,
        //         lighting: _selectedLighting,
        //         effect: _selectedEffect,
        //       );
        finalPrompt = PromptBuilder.buildImageToImagePromptWithElements(
          _prompt,
          setting: _selectedSetting,
          lighting: _selectedLighting,
          effect: _selectedEffect,
        );
        resultBytes = await _stability.generateImageFromImage(
          prompt: finalPrompt,
          imageBytes: _uploadedImage!,
        );
      } else {
        // Text-to-image generation
        // COMMENTED OUT: Ghostface Trend functionality disabled
        // finalPrompt = _useGhostfaceTrend
        //     ? PromptBuilder.buildGhostfaceTrendTextPrompt(_prompt)
        //     : PromptBuilder.buildTextToImagePromptWithElements(
        //         _prompt,
        //         setting: _selectedSetting,
        //         lighting: _selectedLighting,
        //         effect: _selectedEffect,
        //       );
        finalPrompt = PromptBuilder.buildTextToImagePromptWithElements(
          _prompt,
          setting: _selectedSetting,
          lighting: _selectedLighting,
          effect: _selectedEffect,
        );
        resultBytes = await _stability.generateImageBytes(prompt: finalPrompt);
      }

      if (!mounted) return;

      // Consume one token for successful generation
      final tokenConsumed = await tokenProvider.consumeOne();
      if (!tokenConsumed) {
        // This shouldn't happen as we checked earlier, but just in case
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to consume token. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create GeneratedImage object with metadata
      final generatedImage = GeneratedImage(
        imageBytes: resultBytes,
        prompt: finalPrompt,
        createdAt: DateTime.now(),
      );

      // Persist and notify provider for instant gallery refresh
      await context.read<SavedImagesProvider>().addSavedImage(
        imageBytes: resultBytes,
        prompt: finalPrompt,
        isImageToImage: _uploadedImage != null,
      );

      progress.setProgress(1.0);
      progress.close();
      await _showResultDialog(generatedImage);
    } catch (e) {
      if (!mounted) return;
      // Ensure dialog is closed on error
      try {
        progress.close();
      } catch (_) {}

      // Refund token on failure
      await tokenProvider.refundOne();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Generation failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _showResultDialog(GeneratedImage generatedImage) async {
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
                  generatedImage.imageBytes,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
              // Prompt information section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF2D1B3D),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generated Prompt:',
                      style: TextStyle(
                        color: Color(0xFFB25AFF),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      generatedImage.prompt,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // TODO: Save to gallery
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Image saved to gallery'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Save'),
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('Ghostface Generator'),
          backgroundColor: const Color(0xFF0F0B1A),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Color(0xFFB25AFF),
            tabs: [
              Tab(text: 'Generate'),
              Tab(text: 'My Photos'),
            ],
          ),
          actions: [
            // Token balance indicator
            const TokenBalanceIndicator(),
            if (!_hasStabilityKey)
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Add your Stability API key to start generating',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.warning_amber_rounded),
              ),
          ],
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              TabBarView(
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Create your Ghostface masterpiece',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          // COMMENTED OUT: Ghostface mode switch disabled
                          // Padding(
                          //   padding: const EdgeInsets.symmetric(horizontal: 16),
                          //   child: Container(
                          //     decoration: BoxDecoration(
                          //       color: const Color(0xFF1D162B),
                          //       borderRadius: BorderRadius.circular(12),
                          //       border: Border.all(
                          //         color: Colors.white.withOpacity(0.08),
                          //       ),
                          //     ),
                          //     padding: const EdgeInsets.symmetric(
                          //       horizontal: 12,
                          //       vertical: 10,
                          //     ),
                          //     child: Row(
                          //       children: [
                          //         const Icon(
                          //           Icons.auto_awesome,
                          //           color: Color(0xFFB25AFF),
                          //         ),
                          //         const SizedBox(width: 10),
                          //         Text(
                          //           _useGhostfaceTrend
                          //               ? 'Ghostface Trend'
                          //               : 'Default Prompt',
                          //           style: const TextStyle(
                          //             color: Colors.white,
                          //             fontWeight: FontWeight.w600,
                          //           ),
                          //         ),
                          //         const Spacer(),
                          //         Switch(
                          //           value: _useGhostfaceTrend,
                          //           activeColor: const Color(0xFFB25AFF),
                          //           onChanged: (v) {
                          //             setState(() {
                          //               _useGhostfaceTrend = v;
                          //             });
                          //           },
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          // ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              width: double.infinity,
                              child: Consumer<TokenProvider>(
                                builder: (context, tokenProvider, child) {
                                  return FilledButton.icon(
                                    onPressed:
                                        _hasStabilityKey &&
                                            !_isGenerating &&
                                            tokenProvider.balance > 0
                                        ? _generateImage
                                        : null,
                                    icon: _isGenerating
                                        ? const LoadingIndicator(size: 20)
                                        : const Icon(Icons.auto_fix_high),
                                    label: Text(
                                      _isGenerating
                                          ? 'Generating...'
                                          : tokenProvider.balance <= 0
                                          ? 'No Tokens (${tokenProvider.balance})'
                                          : 'Generate Image (${tokenProvider.balance} tokens)',
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFB25AFF),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildMyPhotosTab(),
                ],
              ),
              if (_isGenerating) const LoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // COMMENTED OUT: Unused method - Ghostface module disabled
  // Widget _buildModeSelectionCards() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: const Color(0xFF1D162B),
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: Colors.white.withOpacity(0.08)),
  //     ),
  //     child: Column(
  //       children: [
  //         // Text to Image Card
  //         _buildModeCard(
  //           mode: GenerationMode.text,
  //           icon: Icons.text_fields_rounded,
  //           title: 'Text to Image',
  //           subtitle: 'Describe your vision',
  //           description: 'Create Ghostface images from text descriptions',
  //           gradient: const LinearGradient(
  //             colors: [Color(0xFFB25AFF), Color(0xFF8B5CF6)],
  //             begin: Alignment.topLeft,
  //             end: Alignment.bottomRight,
  //           ),
  //         ),
  //         Container(height: 1, color: Colors.white.withOpacity(0.08)),
  //         // Image to Image Card
  //         _buildModeCard(
  //           mode: GenerationMode.image,
  //           icon: Icons.image_rounded,
  //           title: 'Image to Image',
  //           subtitle: 'Transform existing photos',
  //           description:
  //               'Upload an image and transform it into Ghostface style',
  //           gradient: const LinearGradient(
  //             colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
  //             begin: Alignment.topLeft,
  //             end: Alignment.bottomRight,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // COMMENTED OUT: Unused method - Ghostface module disabled
  // Widget _buildModeCard({
  //   required GenerationMode mode,
  //   required IconData icon,
  //   required String title,
  //   required String subtitle,
  //   required String description,
  //   required Gradient gradient,
  // }) {
  //   final isSelected = _activeMode == mode;

  //   return Material(
  //     color: Colors.transparent,
  //     child: InkWell(
  //       onTap: () => _switchMode(mode),
  //       borderRadius: BorderRadius.circular(16),
  //       child: AnimatedContainer(
  //         duration: const Duration(milliseconds: 200),
  //         padding: const EdgeInsets.all(20),
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(16),
  //           border: isSelected
  //               ? Border.all(color: const Color(0xFFB25AFF), width: 2)
  //               : null,
  //         ),
  //         child: Row(
  //           children: [
  //             // Icon with gradient background
  //             Container(
  //               width: 48,
  //               height: 48,
  //               decoration: BoxDecoration(
  //                 gradient: gradient,
  //                 borderRadius: BorderRadius.circular(12),
  //                 boxShadow: isSelected
  //                     ? [
  //                         BoxShadow(
  //                           color: gradient.colors.first.withOpacity(0.3),
  //                           blurRadius: 8,
  //                           offset: const Offset(0, 4),
  //                         ),
  //                       ]
  //                     : null,
  //               ),
  //               child: Icon(icon, color: Colors.white, size: 24),
  //             ),
  //             const SizedBox(width: 16),

  //             // Content
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     title,
  //                     style: TextStyle(
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.w600,
  //                       color: isSelected
  //                           ? Colors.white
  //                           : const Color(0xFFE5E7EB),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 4),
  //                   Text(
  //                     subtitle,
  //                     style: TextStyle(
  //                       fontSize: 14,
  //                       color: isSelected
  //                           ? const Color(0xFFB25AFF)
  //                           : const Color(0xFF9CA3AF),
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 6),
  //                   Text(
  //                     description,
  //                     style: const TextStyle(
  //                       fontSize: 12,
  //                       color: Color(0xFF8C7BA6),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),

  //             // Selection indicator
  //             AnimatedContainer(
  //               duration: const Duration(milliseconds: 200),
  //               width: 20,
  //               height: 20,
  //               decoration: BoxDecoration(
  //                 shape: BoxShape.circle,
  //                 border: Border.all(
  //                   color: isSelected
  //                       ? const Color(0xFFB25AFF)
  //                       : const Color(0xFF4B5563),
  //                   width: 2,
  //                 ),
  //               ),
  //               child: isSelected
  //                   ? const Icon(
  //                       Icons.check,
  //                       size: 12,
  //                       color: Color(0xFFB25AFF),
  //                     )
  //                   : null,
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // COMMENTED OUT: Unused method - Ghostface module disabled
  // Widget _buildModeContent() {
  //   switch (_activeMode) {
  //     case GenerationMode.text:
  //       return Column(
  //         key: const ValueKey('text_mode'),
  //         children: [
  //           PromptInputWidget(
  //             onPromptChanged: _onPromptChanged,
  //             hintText: 'Describe your Halloween scene...',
  //           ),
  //           const SizedBox(height: 16),
  //           HalloweenPromptSelector(
  //             onSelectionChanged: _onHalloweenElementsChanged,
  //             initialSetting: _selectedSetting,
  //             initialLighting: _selectedLighting,
  //             initialEffect: _selectedEffect,
  //           ),
  //           const SizedBox(height: 16),
  //           _buildPromptSuggestions(),
  //         ],
  //       );
  //     case GenerationMode.image:
  //       return Column(
  //         key: const ValueKey('image_mode'),
  //         children: [
  //           ImageUploadWidget(
  //             onImageSelected: _onImageSelected,
  //             onImageRemoved: _onImageRemoved,
  //             uploadedImage: _uploadedImage,
  //           ),
  //           const SizedBox(height: 16),
  //           PromptInputWidget(
  //             onPromptChanged: _onPromptChanged,
  //             hintText: 'Describe how to transform into Halloween style...',
  //           ),
  //           const SizedBox(height: 16),
  //           HalloweenPromptSelector(
  //             onSelectionChanged: _onHalloweenElementsChanged,
  //             initialSetting: _selectedSetting,
  //             initialLighting: _selectedLighting,
  //             initialEffect: _selectedEffect,
  //           ),
  //           const SizedBox(height: 16),
  //           _buildTransformationTips(),
  //         ],
  //       );
  //   }
  // }

  // COMMENTED OUT: Unused method - Ghostface module disabled
  // Widget _buildPromptSuggestions() {
  //   final suggestions = [
  //     'Ghostface mask in dark alley',
  //     'Cyberpunk Halloween transformation',
  //     'Horror movie poster style',
  //     'Anime character design',
  //     'Haunted house scene',
  //     'Spooky forest with pumpkins',
  //   ];

  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: const Color(0xFF1D162B),
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: Colors.white.withOpacity(0.08)),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           '🎃 Halloween Prompt Ideas',
  //           style: TextStyle(
  //             fontWeight: FontWeight.w600,
  //             color: Colors.white,
  //             fontSize: 14,
  //           ),
  //         ),
  //         const SizedBox(height: 12),
  //         Wrap(
  //           spacing: 8,
  //           runSpacing: 8,
  //           children: suggestions.map((suggestion) {
  //             return GestureDetector(
  //               onTap: () {
  //                 setState(() {
  //                   _prompt = suggestion;
  //                 });
  //               },
  //               child: Container(
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 12,
  //                   vertical: 6,
  //                 ),
  //                 decoration: BoxDecoration(
  //                   color: const Color(0xFF2D1B3D),
  //                   borderRadius: BorderRadius.circular(16),
  //                   border: Border.all(
  //                     color: const Color(0xFFB25AFF).withOpacity(0.3),
  //                   ),
  //                 ),
  //                 child: Text(
  //                   suggestion,
  //                   style: const TextStyle(
  //                     color: Color(0xFFB25AFF),
  //                     fontSize: 12,
  //                   ),
  //                 ),
  //               ),
  //             );
  //           }).toList(),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // COMMENTED OUT: Unused method - Ghostface module disabled
  // Widget _buildTransformationTips() {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: const Color(0xFF1D162B),
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: Colors.white.withOpacity(0.08)),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           '🎨 Transformation Tips',
  //           style: TextStyle(
  //             fontWeight: FontWeight.w600,
  //             color: Colors.white,
  //             fontSize: 14,
  //           ),
  //         ),
  //         const SizedBox(height: 12),
  //         const _TipItem(
  //           text: 'Upload a clear photo for best Halloween transformation',
  //         ),
  //         const _TipItem(
  //           text:
  //               'Describe specific elements: "ghostly", "pumpkins", "haunted"',
  //         ),
  //         const _TipItem(text: 'Add mood: "spooky", "eerie", "mysterious"'),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildMyPhotosTab() {
    if (_savedImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: Color(0xFF8C7BA6),
            ),
            SizedBox(height: 12),
            Text(
              'No photos yet',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Generate something cool and it will appear here',
              style: TextStyle(color: Color(0xFF8C7BA6)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: _savedImages.length,
        itemBuilder: (context, index) {
          final saved = _savedImages[index];
          return GestureDetector(
            onTap: () async {
              final bytes = await ImageStorageService.getImageBytes(
                saved.filePath,
              );
              if (bytes == null) return;
              final gi = GeneratedImage(
                imageBytes: bytes,
                prompt: saved.prompt,
                createdAt: saved.createdAt,
              );
              await _showResultDialog(gi);
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FutureBuilder<Uint8List?>(
                      future: ImageStorageService.getImageBytes(saved.filePath),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: LoadingIndicator(size: 24),
                          );
                        }
                        return Image.memory(snapshot.data!, fit: BoxFit.cover);
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () {
                      context.read<SavedImagesProvider>().deleteById(saved.id);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// COMMENTED OUT: Unused class - Ghostface module disabled
// class _TipItem extends StatelessWidget {
//   const _TipItem({required this.text});

//   final String text;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 4,
//             height: 4,
//             margin: const EdgeInsets.only(top: 6, right: 8),
//             decoration: const BoxDecoration(
//               color: Color(0xFFB25AFF),
//               shape: BoxShape.circle,
//             ),
//           ),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(color: Color(0xFF8C7BA6), fontSize: 13),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
