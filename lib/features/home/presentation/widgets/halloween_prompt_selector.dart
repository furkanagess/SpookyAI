import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/halloween_prompt_data.dart';
import '../../../../core/services/halloween_prompt_provider.dart';

class HalloweenPromptSelector extends StatefulWidget {
  final Function(String setting, String lighting, String effect)
  onSelectionChanged;
  final String? initialSetting;
  final String? initialLighting;
  final String? initialEffect;

  const HalloweenPromptSelector({
    super.key,
    required this.onSelectionChanged,
    this.initialSetting,
    this.initialLighting,
    this.initialEffect,
  });

  @override
  State<HalloweenPromptSelector> createState() =>
      _HalloweenPromptSelectorState();
}

class _HalloweenPromptSelectorState extends State<HalloweenPromptSelector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HalloweenPromptProvider>().initialize(
        initialSetting: widget.initialSetting,
        initialLighting: widget.initialLighting,
        initialEffect: widget.initialEffect,
      );
      _notifyParent();
    });
  }

  void _notifyParent() {
    final provider = context.read<HalloweenPromptProvider>();
    widget.onSelectionChanged(
      provider.selectedSetting,
      provider.selectedLighting,
      provider.selectedEffect,
    );
  }

  void _selectRandom() {
    context.read<HalloweenPromptProvider>().selectRandom();
    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HalloweenPromptProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1D162B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with randomize button
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_fix_high,
                      color: Color(0xFFB25AFF),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Halloween Prompt Elements',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _selectRandom,
                      icon: const Icon(Icons.shuffle, size: 16),
                      label: const Text('Randomize'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFB25AFF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // SETTING Section
              _buildSection(
                title: 'SETTING',
                subtitle: '(rasgele seç)',
                options: HalloweenPromptData.settings,
                selectedOption: provider.selectedSetting,
                onOptionSelected: (option) {
                  provider.updateSetting(option);
                  _notifyParent();
                },
                icon: Icons.location_on_outlined,
                color: const Color(0xFFB25AFF),
              ),

              // LIGHTING Section
              _buildSection(
                title: 'LIGHTING',
                subtitle: '(rasgele seç)',
                options: HalloweenPromptData.lighting,
                selectedOption: provider.selectedLighting,
                onOptionSelected: (option) {
                  provider.updateLighting(option);
                  _notifyParent();
                },
                icon: Icons.light_mode_outlined,
                color: const Color(0xFFF59E0B),
              ),

              // EFFECTS Section
              _buildSection(
                title: 'EFFECTS',
                subtitle: '(rasgele seç)',
                options: HalloweenPromptData.effects,
                selectedOption: provider.selectedEffect,
                onOptionSelected: (option) {
                  provider.updateEffect(option);
                  _notifyParent();
                },
                icon: Icons.auto_awesome,
                color: const Color(0xFF06B6D4),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<String> options,
    required String selectedOption,
    required Function(String) onOptionSelected,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Options List
          ...options.map((option) {
            final isSelected = option == selectedOption;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onOptionSelected(option),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : Colors.white.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? color.withOpacity(0.1)
                          : Colors.white.withOpacity(0.03),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                            color: isSelected ? color : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '• $option',
                            style: TextStyle(
                              color: isSelected
                                  ? color
                                  : Colors.white.withOpacity(0.8),
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
