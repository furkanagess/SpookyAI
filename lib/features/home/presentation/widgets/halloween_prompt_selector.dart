import 'package:flutter/material.dart';
import '../../../../core/models/halloween_prompt_data.dart';

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
  late String _selectedSetting;
  late String _selectedLighting;
  late String _selectedEffect;

  @override
  void initState() {
    super.initState();
    _selectedSetting =
        widget.initialSetting ?? HalloweenPromptData.getRandomSetting();
    _selectedLighting =
        widget.initialLighting ?? HalloweenPromptData.getRandomLighting();
    _selectedEffect =
        widget.initialEffect ?? HalloweenPromptData.getRandomEffect();
    _notifyParent();
  }

  void _notifyParent() {
    widget.onSelectionChanged(
      _selectedSetting,
      _selectedLighting,
      _selectedEffect,
    );
  }

  void _selectRandom() {
    setState(() {
      _selectedSetting = HalloweenPromptData.getRandomSetting();
      _selectedLighting = HalloweenPromptData.getRandomLighting();
      _selectedEffect = HalloweenPromptData.getRandomEffect();
    });
    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
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
            selectedOption: _selectedSetting,
            onOptionSelected: (option) {
              setState(() {
                _selectedSetting = option;
              });
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
            selectedOption: _selectedLighting,
            onOptionSelected: (option) {
              setState(() {
                _selectedLighting = option;
              });
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
            selectedOption: _selectedEffect,
            onOptionSelected: (option) {
              setState(() {
                _selectedEffect = option;
              });
              _notifyParent();
            },
            icon: Icons.auto_awesome,
            color: const Color(0xFF06B6D4),
          ),
        ],
      ),
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
