import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/prompt_input_provider.dart';

class PromptInputWidget extends StatefulWidget {
  const PromptInputWidget({
    super.key,
    required this.onPromptChanged,
    required this.hintText,
    this.initialText,
  });

  final Function(String) onPromptChanged;
  final String hintText;
  final String? initialText;

  @override
  State<PromptInputWidget> createState() => _PromptInputWidgetState();
}

class _PromptInputWidgetState extends State<PromptInputWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _controller.text = widget.initialText!;
    }
    _controller.addListener(() {
      context.read<PromptInputProvider>().updateText(_controller.text);
      widget.onPromptChanged(_controller.text);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromptInputProvider>().initialize(widget.initialText);
    });
  }

  @override
  void didUpdateWidget(covariant PromptInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != null &&
        widget.initialText != oldWidget.initialText) {
      if (_controller.text != widget.initialText) {
        _controller.text = widget.initialText!;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PromptInputProvider>(
      builder: (context, provider, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1D162B), const Color(0xFF2A1F3D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: provider.isOverLimit
                  ? Colors.red.withOpacity(0.6)
                  : Colors.white.withOpacity(0.15),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: provider.isOverLimit
                    ? Colors.red.withOpacity(0.2)
                    : const Color(0xFFB25AFF).withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with gradient background
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFB25AFF).withOpacity(0.1),
                      const Color(0xFF8B5CF6).withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB25AFF), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB25AFF).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_fix_high_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Describe Your Vision',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'The more detailed, the better the result',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB25AFF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: provider.isOverLimit
                            ? Colors.red.withOpacity(0.2)
                            : const Color(0xFF2A1F3D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: provider.isOverLimit
                              ? Colors.red.withOpacity(0.5)
                              : Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${provider.characterCount}/500',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: provider.isOverLimit
                              ? Colors.red
                              : const Color(0xFFB25AFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Text input area
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: TextField(
                  controller: _controller,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 500,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 16,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                  ),
                  keyboardAppearance: Brightness.dark,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  onEditingComplete: () => FocusScope.of(context).unfocus(),
                  scrollPadding: const EdgeInsets.only(bottom: 220),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
