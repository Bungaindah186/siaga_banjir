import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      color: color ?? AppColors.ink,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
  );
}
