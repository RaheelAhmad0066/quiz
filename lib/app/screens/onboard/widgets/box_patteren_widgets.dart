import 'package:afn_test/app/app_widgets/theme/app_themes.dart';
import 'package:flutter/material.dart';

class BoxPatternGraphic extends StatelessWidget {
  final double? size;
  final Color? lineColor;
  
  const BoxPatternGraphic({
    super.key,
    this.size,
    this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    // final double boxSize = size ?? 200;
    final Color color = lineColor ?? AppTheme.accentYellowGreen;
    
    return SizedBox(
      width: 370,
      height: 360,
      child: CustomPaint(
        painter: _BoxPatternPainter(color: color),
      ),
    );
  }
}

class _BoxPatternPainter extends CustomPainter {
  final Color color;
  
  _BoxPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final int numberOfBoxes = 12;
    final double spacing = 16.0;
    final double lineThickness = 2.5;
    final double cornerRadius = 3.0;
    
    for (int i = 0; i < numberOfBoxes; i++) {
      // Calculate box dimensions - har iteration mein smaller
      double boxLeft = i * spacing;
      double boxTop = i * spacing;
      double boxWidth = size.width - (i * spacing * 2);
      double boxHeight = size.height - (i * spacing * 2);
      
      // Skip if box gets too small
      if (boxWidth <= spacing || boxHeight <= spacing) break;
      
      // 3D shading - lighter on top/left, darker on bottom/right
      final double brightness = 1.0 - (i * 0.04);
      final Color baseColor = Color.lerp(
        color,
        Colors.white,
        brightness * 0.3,
      )!;
      
      final Color brightColor = Color.lerp(
        baseColor,
        Colors.white,
        0.5,
      )!;
      
      final Color darkColor = Color.lerp(
        baseColor,
        Colors.black,
        0.25,
      )!;
      
      // Main rectangle
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight),
        Radius.circular(cornerRadius),
      );
      
      // Draw base outline
      final basePaint = Paint()
        ..color = baseColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineThickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      
      canvas.drawRRect(rect, basePaint);
      
      // Top edge - bright
      final topPath = Path()
        ..moveTo(boxLeft + cornerRadius, boxTop)
        ..lineTo(boxLeft + boxWidth - cornerRadius, boxTop);
      
      final topPaint = Paint()
        ..color = brightColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineThickness * 1.2
        ..strokeCap = StrokeCap.round;
      
      canvas.drawPath(topPath, topPaint);
      
      // Left edge - bright
      final leftPath = Path()
        ..moveTo(boxLeft, boxTop + cornerRadius)
        ..lineTo(boxLeft, boxTop + boxHeight - cornerRadius);
      
      final leftPaint = Paint()
        ..color = brightColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineThickness * 1.2
        ..strokeCap = StrokeCap.round;
      
      canvas.drawPath(leftPath, leftPaint);
      
      // Bottom edge - dark
      final bottomPath = Path()
        ..moveTo(boxLeft + cornerRadius, boxTop + boxHeight)
        ..lineTo(boxLeft + boxWidth - cornerRadius, boxTop + boxHeight);
      
      final bottomPaint = Paint()
        ..color = darkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineThickness
        ..strokeCap = StrokeCap.round;
      
      canvas.drawPath(bottomPath, bottomPaint);
      
      // Right edge - dark
      final rightPath = Path()
        ..moveTo(boxLeft + boxWidth, boxTop + cornerRadius)
        ..lineTo(boxLeft + boxWidth, boxTop + boxHeight - cornerRadius);
      
      final rightPaint = Paint()
        ..color = darkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineThickness
        ..strokeCap = StrokeCap.round;
      
      canvas.drawPath(rightPath, rightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
