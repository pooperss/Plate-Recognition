import 'package:flutter/material.dart';

class RectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final double edgeLength =
        15; // Adjust this value for the length of the edges
    final double offset = 5;

    // Top left
    canvas.drawLine(Offset(0, offset), Offset(edgeLength, offset), paint);
    canvas.drawLine(Offset(0, offset), Offset(0, offset + edgeLength), paint);

    // Top right
    canvas.drawLine(Offset(size.width, offset),
        Offset(size.width - edgeLength, offset), paint);
    canvas.drawLine(Offset(size.width, offset),
        Offset(size.width, offset + edgeLength), paint);

    // Bottom left
    canvas.drawLine(Offset(0, size.height - offset),
        Offset(edgeLength, size.height - offset), paint);
    canvas.drawLine(Offset(0, size.height - offset),
        Offset(0, size.height - offset - edgeLength), paint);

    // Bottom right
    canvas.drawLine(Offset(size.width, size.height - offset),
        Offset(size.width - edgeLength, size.height - offset), paint);
    canvas.drawLine(Offset(size.width, size.height - offset),
        Offset(size.width, size.height - offset - edgeLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
