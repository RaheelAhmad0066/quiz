import 'package:flutter/material.dart';

/// Custom Painter for Tilted Card Design (like in leaderboard image)
class TiltedCardPainter extends CustomPainter {
  final Color cardColor;
  final double tiltAngle;

  TiltedCardPainter({
    required this.cardColor,
    this.tiltAngle = 0.05, // Small tilt angle
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw card with slight tilt
    paint.color = cardColor;
    final path = Path();
    
    // Create tilted rectangle
    path.moveTo(size.width * tiltAngle, 0); // Top left (shifted right)
    path.lineTo(size.width * (1 - tiltAngle), 0); // Top right (shifted left)
    path.lineTo(size.width, size.height); // Bottom right
    path.lineTo(size.width * tiltAngle * 2, size.height); // Bottom left
    path.close();
    
    canvas.drawPath(path, paint);

    // Add subtle shadow effect
    paint.color = Colors.black.withOpacity(0.1);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! TiltedCardPainter ||
        oldDelegate.cardColor != cardColor ||
        oldDelegate.tiltAngle != tiltAngle;
  }
}

