// Animated dot indicator for keyword card pagination.
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DotIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;

  const DotIndicator({
    super.key,
    required this.count,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == activeIndex;
        return Padding(
          padding: EdgeInsets.only(right: i < count - 1 ? 5 : 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 18 : 5,
            height: 5,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
