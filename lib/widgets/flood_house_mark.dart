import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FloodHouseMark extends StatelessWidget {
  const FloodHouseMark({super.key, required this.size, this.light = false});

  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final foreground = light ? Colors.white : AppColors.navy;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: light ? Colors.white.withValues(alpha: .1) : AppColors.tealPale,
        borderRadius: BorderRadius.circular(size * .31),
        border: light
            ? Border.all(color: Colors.white.withValues(alpha: .2))
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.house_rounded, size: size * .57, color: foreground),
          Positioned(
            bottom: size * .15,
            child: Icon(
              Icons.water,
              size: size * .43,
              color: light ? const Color(0xFF8DE1D6) : AppColors.teal,
            ),
          ),
        ],
      ),
    );
  }
}
