import 'package:flutter/material.dart';

/// Custom Painter for Podium Design
class PodiumPainter extends CustomPainter {
  final double height;
  final Color platformColor;
  final Color columnColor;

  PodiumPainter({
    required this.height,
    this.platformColor = const Color(0xFF2C2C2C),
    this.columnColor = const Color(0xFFE0E0E0),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw column (light gray/white base)
    paint.color = columnColor;
    final columnRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.3, size.width, size.height * 0.7),
      const Radius.circular(4),
    );
    canvas.drawRRect(columnRect, paint);

    // Draw trapezoidal platform (dark teal/black)
    paint.color = platformColor;
    final path = Path();
    // Top left
    path.moveTo(size.width * 0.1, size.height * 0.3);
    // Top right
    path.lineTo(size.width * 0.9, size.height * 0.3);
    // Bottom right
    path.lineTo(size.width * 0.85, size.height * 0.5);
    // Bottom left
    path.lineTo(size.width * 0.15, size.height * 0.5);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

