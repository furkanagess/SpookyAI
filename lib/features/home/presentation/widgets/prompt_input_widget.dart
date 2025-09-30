import 'package:flutter/material.dart';

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
  int _characterCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _controller.text = widget.initialText!;
      _characterCount = _controller.text.length;
    }
    _controller.addListener(() {
      setState(() {
        _characterCount = _controller.text.length;
      });
      widget.onPromptChanged(_controller.text);
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1D162B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.edit_note, color: Color(0xFFB25AFF), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Prompt',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  '$_characterCount/500',
                  style: TextStyle(
                    fontSize: 12,
                    color: _characterCount > 500
                        ? Colors.red
                        : const Color(0xFF8C7BA6),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 6,
              maxLength: 500,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFF8C7BA6),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                counterText: '',
              ),
              keyboardAppearance: Brightness.dark,
              textInputAction: TextInputAction.newline,
              scrollPadding: const EdgeInsets.only(bottom: 220),
            ),
          ),
        ],
      ),
    );
  }
}
