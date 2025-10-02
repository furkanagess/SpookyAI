import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/add_prompt_provider.dart';
import '../../data/models/user_prompt.dart';

class AddPromptDialog extends StatefulWidget {
  final UserPrompt? existingPrompt;
  final Function(UserPrompt)? onPromptSaved;

  const AddPromptDialog({super.key, this.existingPrompt, this.onPromptSaved});

  @override
  State<AddPromptDialog> createState() => _AddPromptDialogState();
}

class _AddPromptDialogState extends State<AddPromptDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddPromptProvider>().initialize(widget.existingPrompt);
      if (widget.existingPrompt != null) {
        final prompt = widget.existingPrompt!;
        _titleController.text = prompt.title;
        _promptController.text = prompt.prompt;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _savePrompt() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AddPromptProvider>();
    provider.updateTitle(_titleController.text);
    provider.updatePrompt(_promptController.text);

    final userPrompt = await provider.savePrompt();

    if (mounted) {
      if (userPrompt != null) {
        Navigator.of(context).pop();
        if (widget.onPromptSaved != null) {
          widget.onPromptSaved!(userPrompt);
        }

        NotificationService.success(
          context,
          message: widget.existingPrompt != null
              ? NotificationService.promptUpdated
              : NotificationService.promptSaved,
        );
      } else {
        NotificationService.error(
          context,
          message: 'Failed to save prompt. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingPrompt != null;

    return Consumer<AddPromptProvider>(
      builder: (context, provider, child) {
        return Dialog(
          backgroundColor: const Color(0xFF1D162B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF8C7BA6), width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6A00), Color(0xFF9C27B0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit : Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Prompt' : 'Add New Prompt',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Color(0xFF8C7BA6)),
                      ),
                    ],
                  ),
                ),

                // Form Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title Field
                          TextFormField(
                            controller: _titleController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Prompt Title',
                              labelStyle: const TextStyle(
                                color: Color(0xFF8C7BA6),
                              ),
                              hintText: 'Enter a descriptive title...',
                              hintStyle: const TextStyle(
                                color: Color(0xFF8C7BA6),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF8C7BA6),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF8C7BA6),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFF6A00),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a title';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Prompt Field
                          TextFormField(
                            controller: _promptController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Prompt Text',
                              labelStyle: const TextStyle(
                                color: Color(0xFF8C7BA6),
                              ),
                              hintText: 'Describe your prompt in detail...',
                              hintStyle: const TextStyle(
                                color: Color(0xFF8C7BA6),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF8C7BA6),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF8C7BA6),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFF6A00),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a prompt';
                              }
                              if (value.trim().length < 10) {
                                return 'Prompt should be at least 10 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFF8C7BA6), width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: provider.isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
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
                        child: ElevatedButton(
                          onPressed: provider.isLoading ? null : _savePrompt,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6A00),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: provider.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  isEditing ? 'Update' : 'Save',
                                  style: const TextStyle(color: Colors.white),
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
      },
    );
  }
}
