import 'package:flutter/material.dart';

class ReferenceCard extends StatelessWidget {
  const ReferenceCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE0E7E9)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x220B2E3B),
          blurRadius: 3,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

class ReferenceSectionHeading extends StatelessWidget {
  const ReferenceSectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF0B2E3B),
      fontSize: 15,
      fontWeight: FontWeight.w700,
    ),
  );
}

class ReferenceStatusPill extends StatelessWidget {
  const ReferenceStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 3),
        ],
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class ReferenceTab extends StatelessWidget {
  const ReferenceTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showUnread = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showUnread;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      backgroundColor: selected ? const Color(0xFF0B2E3B) : Colors.transparent,
      foregroundColor: selected ? Colors.white : const Color(0xFF0B2E3B),
      side: BorderSide(
        color: const Color(0xFF0B2E3B).withValues(alpha: selected ? 0 : 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      minimumSize: const Size(0, 36),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (showUnread) ...[
          const SizedBox(width: 6),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    ),
  );
}
