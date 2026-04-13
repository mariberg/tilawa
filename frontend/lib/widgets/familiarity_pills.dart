// Familiarity selection pills (New, Somewhat familiar, Well known).
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FamiliarityPills extends StatefulWidget {
  final ValueChanged<String>? onChanged;

  const FamiliarityPills({super.key, this.onChanged});

  @override
  State<FamiliarityPills> createState() => _FamiliarityPillsState();
}

class _FamiliarityPillsState extends State<FamiliarityPills> {
  int _selected = -1;

  static const _options = ['New', 'Somewhat familiar', 'Well known'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_options.length, (i) {
        final isSelected = _selected == i;
        return Padding(
          padding: EdgeInsets.only(right: i < _options.length - 1 ? 8 : 0),
          child: GestureDetector(
            onTap: () {
              setState(() => _selected = i);
              widget.onChanged?.call(_options[i]);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1,
                ),
              ),
              child: Text(
                _options[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFF7A776F),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
