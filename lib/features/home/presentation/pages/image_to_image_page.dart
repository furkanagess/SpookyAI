import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/fal_ai_service.dart';
import '../../../../core/services/token_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_metrics.dart';
import '../../../../core/widgets/token_display_widget.dart';
import '../widgets/no_tokens_dialog.dart';
import 'prompts_page.dart';
import 'purchase_page.dart';

class ImageToImagePage extends StatefulWidget {
  const ImageToImagePage({super.key});

  @override
  State<ImageToImagePage> createState() => _ImageToImagePageState();
}

class _ImageToImagePageState extends State<ImageToImagePage> {
  final TextEditingController _promptController = TextEditingController();
  Uint8List? _selectedImageBytes;
  bool _isGenerating = false;
  String? _generatedImageUrl;
  String? _errorMessage;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _generateImage() async {
    if (_selectedImageBytes == null || _promptController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please select an image and enter a prompt';
      });
      return;
    }

    final tokenProvider = context.read<TokenProvider>();
    if (tokenProvider.balance < 2.0) {
      // 2 tokens for image-to-image
      _showNoTokensDialog();
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedImageUrl = null;
    });

    try {
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          backgroundColor: Color(0xFF1D162B),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE46ADF)),
              ),
              SizedBox(height: 16),
              Text(
                'Transforming Your Face',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Creating spooky Halloween transformation...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      final result = await FalAiService.generateImageFromImage(
        prompt: _promptController.text.trim(),
        imageBytes: _selectedImageBytes!,
        imageStrength:
            0.8, // From screenshot - higher strength for scene composition
        numInferenceSteps: 4, // From screenshot
        guidanceScale: 6.0, // From screenshot
        enableSafetyChecker: true, // From screenshot
        outputFormat: 'jpeg', // From screenshot
      );

      // Close progress dialog
      if (mounted) Navigator.of(context).pop();

      if (result.images.isNotEmpty) {
        setState(() {
          _generatedImageUrl = result.images.first.url;
        });

        // Deduct 2 tokens for image-to-image
        await tokenProvider.consumeTokens(2);

        // Show success notification
        NotificationService.success(
          context,
          message:
              'Face transformation completed! Your spooky Halloween look is ready!',
        );
      } else {
        setState(() {
          _errorMessage = 'No image was generated';
        });
      }
    } catch (e) {
      // Close progress dialog
      if (mounted) Navigator.of(context).pop();

      setState(() {
        _errorMessage = 'Generation failed: $e';
      });

      NotificationService.error(
        context,
        message: 'Failed to transform your image. Please try again.',
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _showNoTokensDialog() {
    showDialog(context: context, builder: (context) => const NoTokensDialog());
  }

  void _onPromptSelected(String prompt) {
    setState(() {
      _promptController.text = prompt;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1A),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE46ADF), Color(0xFF667eea)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.face_retouching_natural,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Face Transform',
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
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      PromptsPage(onPromptSelected: _onPromptSelected),
                ),
              );
            },
            icon: const Icon(Icons.lightbulb_outline, color: Colors.white),
            tooltip: 'Browse Prompts',
          ),
          TokenDisplayWidget(
            onTap: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PurchasePage()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF352046), Color(0xFF120B25)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.face_retouching_natural,
                    size: 48,
                    color: Color(0xFFE46ADF),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Transform Your Face',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload your photo and transform into spooky Halloween characters while preserving your facial features',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Image Selection Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1D162B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Your Photo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedImageBytes == null)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A1F3D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE46ADF).withOpacity(0.3),
                            style: BorderStyle.solid,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: Color(0xFFE46ADF),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Tap to Select Photo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'JPG, PNG supported',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE46ADF).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _selectedImageBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE46ADF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.photo_library, size: 18),
                          label: const Text('Change Photo'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Prompt Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1D162B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Transformation Prompt',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PromptsPage(
                                onPromptSelected: _onPromptSelected,
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFE46ADF),
                        ),
                        icon: const Icon(Icons.lightbulb_outline, size: 16),
                        label: const Text('Browse'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _promptController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText:
                          'Describe your Halloween transformation...\nExample: "Transform into a mysterious vampire with pale skin and red eyes"',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF2A1F3D),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Generate Button
            ElevatedButton.icon(
              onPressed:
                  (_selectedImageBytes != null &&
                      _promptController.text.trim().isNotEmpty &&
                      !_isGenerating)
                  ? _generateImage
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE46ADF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.auto_fix_high, size: 24),
              label: Text(
                _isGenerating
                    ? 'Transforming...'
                    : 'Transform My Face (2 Tokens)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Error Message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Generated Image
            if (_generatedImageUrl != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D162B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Transformation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _generatedImageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 250,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 250,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A1F3D),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFE46ADF),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 250,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A1F3D),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 48,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(color: Colors.red),
                                  ),
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
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
