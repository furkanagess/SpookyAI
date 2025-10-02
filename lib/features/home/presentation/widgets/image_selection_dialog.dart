import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/profile_provider.dart';

class ImageSelectionDialog extends StatefulWidget {
  final List<Map<String, dynamic>> images;
  final String title;
  final String subtitle;

  const ImageSelectionDialog({
    super.key,
    required this.images,
    required this.title,
    required this.subtitle,
  });

  @override
  State<ImageSelectionDialog> createState() => _ImageSelectionDialogState();
}

class _ImageSelectionDialogState extends State<ImageSelectionDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1D162B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF8C7BA6),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF8C7BA6)),

            // Images Grid
            Flexible(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: widget.images.length,
                itemBuilder: (context, index) {
                  final provider = context.watch<ProfileProvider>();
                  final image = widget.images[index];
                  final imageBytes = image['bytes'] as Uint8List;
                  final isSelected = provider.selectedImageIndex == index;

                  return GestureDetector(
                    onTap: () {
                      context.read<ProfileProvider>().setSelectedImageIndex(
                        index,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF6A00)
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: const Color(0xFFFF6A00).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Image.memory(
                              imageBytes,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),

                            // Selection overlay
                            if (isSelected)
                              Container(
                                color: const Color(0xFFFF6A00).withOpacity(0.3),
                                child: const Center(
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),

                            // Image info overlay
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        image['prompt'] ?? 'Generated Image',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (image['createdAt'] != null)
                                      Text(
                                        _formatDate(image['createdAt']),
                                        style: const TextStyle(
                                          color: Color(0xFF8C7BA6),
                                          fontSize: 8,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF8C7BA6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFF8C7BA6)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Consumer<ProfileProvider>(
                      builder: (context, provider, _) => ElevatedButton(
                        onPressed: provider.selectedImageIndex != null
                            ? () => Navigator.of(
                                context,
                              ).pop(widget.images[provider.selectedImageIndex!])
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6A00),
                          disabledBackgroundColor: const Color(0xFF8C7BA6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Select',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
