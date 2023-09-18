import 'package:flutter/material.dart';

class LineSegmentPainter extends CustomPainter {
  LineSegmentPainter({
    required this.offsetStart,
    required this.offsetEnd,
    this.paintColor = const Color(0xFF34C759),
    this.endRadius = 4.5,
    Listenable? repaint,
  }) : super(repaint: repaint) {
    linePaint
      ..color = paintColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.square
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;
  }

  final linePaint = Paint();
  final ValueNotifier<Offset> offsetStart;
  final ValueNotifier<Offset> offsetEnd;
  final Color paintColor;
  final double endRadius;

  @override
  void paint(Canvas canvas, Size size) {
    // 裁剪画布为Size大小，使其不会超出区域显示
    canvas.clipRect(Offset.zero & size);
    // 平移画布 中心点
    canvas.translate(size.width / 2, size.height / 2);

    if (offsetStart.value == Offset.zero && offsetEnd.value == Offset.zero) {
      return;
    }

    var lineStart = offsetStart.value;
    var lineEnd = offsetEnd.value;

    linePaint
      ..color = paintColor
      ..strokeWidth = 3.0;
    // line segment
    canvas.drawLine(lineStart, lineEnd, linePaint);

    // circle dot
    canvas.drawCircle(lineStart, endRadius, linePaint);
    canvas.drawCircle(lineEnd, endRadius, linePaint);
  }

  @override
  bool shouldRepaint(LineSegmentPainter oldDelegate) {
    return oldDelegate.offsetStart != offsetStart ||
        oldDelegate.offsetEnd != offsetEnd ||
        oldDelegate.paintColor != paintColor ||
        oldDelegate.endRadius != endRadius;
  }
}
