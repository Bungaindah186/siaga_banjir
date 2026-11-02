import 'package:flutter/material.dart';

class FloodMapIllustration extends StatelessWidget {
  const FloodMapIllustration({
    super.key,
    required this.height,
    required this.caption,
    this.route = false,
  });

  final double height;
  final String caption;
  final bool route;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _IllustrativeMapPainter(route: route)),
          Positioned(
            left: 8,
            right: 8,
            top: 7,
            child: Text(
              caption,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF355C69),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                shadows: [Shadow(color: Colors.white, blurRadius: 4)],
              ),
            ),
          ),
          if (route) ...[
            const Positioned(
              left: 35,
              bottom: 28,
              child: _MapPin(label: 'B', color: Color(0xFFE64A39)),
            ),
            const Positioned(
              right: 45,
              top: 40,
              child: _MapPin(label: 'A', color: Color(0xFF71A900)),
            ),
          ] else ...[
            const Positioned(
              left: 36,
              top: 79,
              child: Icon(
                Icons.location_on,
                color: Color(0xFF22A76E),
                size: 30,
              ),
            ),
            const Positioned(
              right: 27,
              top: 53,
              child: Icon(
                Icons.location_on,
                color: Color(0xFFFFBD1B),
                size: 26,
              ),
            ),
            const Positioned(
              right: 60,
              bottom: 36,
              child: Icon(
                Icons.location_on,
                color: Color(0xFFE74A2B),
                size: 24,
              ),
            ),
          ],
          if (!route)
            const Positioned(
              left: 10,
              bottom: 8,
              child: Text(
                'Padang',
                style: TextStyle(
                  color: Color(0xFF385D6A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(color: Colors.white, blurRadius: 5)],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 12,
    backgroundColor: color,
    child: Text(
      label,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    ),
  );
}

class _IllustrativeMapPainter extends CustomPainter {
  const _IllustrativeMapPainter({this.route = false});
  final bool route;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF4F2E9),
    );
    final road = Paint()
      ..color = const Color(0xFFD6DDE0)
      ..strokeWidth = 1;
    final roadThin = Paint()
      ..color = const Color(0xFFCAD5D9)
      ..strokeWidth = .65;
    for (var i = -size.height; i < size.width + size.height; i += 30) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i - 24, size.height),
        road,
      );
      canvas.drawLine(Offset(i + 13, 0), Offset(i + 39, size.height), roadThin);
    }
    for (var y = 12.0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 19), roadThin);
    }
    final riverPath = Path()
      ..moveTo(size.width * .66, -10)
      ..cubicTo(
        size.width * .53,
        42,
        size.width * .77,
        67,
        size.width * .57,
        101,
      )
      ..cubicTo(
        size.width * .46,
        127,
        size.width * .70,
        148,
        size.width * .54,
        size.height + 10,
      );
    canvas.drawPath(
      riverPath,
      Paint()
        ..color = const Color(0xFF8AD9E7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      riverPath,
      Paint()
        ..color = const Color(0xFFBDEBF1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    if (route) {
      final routePath = Path()
        ..moveTo(size.width * .23, size.height * .77)
        ..cubicTo(
          size.width * .37,
          size.height * .63,
          size.width * .44,
          size.height * .5,
          size.width * .77,
          size.height * .23,
        );
      canvas.drawPath(
        routePath,
        Paint()
          ..color = const Color(0xFF12809A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IllustrativeMapPainter oldDelegate) =>
      oldDelegate.route != route;
}
