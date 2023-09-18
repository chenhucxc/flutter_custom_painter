import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_custom_painter/entities/custom_point.dart';
import 'package:flutter_custom_painter/utils/spatial_relation_util.dart';

class LineSegmentIconPainter extends CustomPainter {
  LineSegmentIconPainter({
    required this.offsetStart,
    required this.offsetEnd,
    this.paintColor = const Color(0xFF34C759),
    this.endRadius = 4.5,
    this.imageIcon,
    this.imageMargin = 30,
    this.imageSize = 28,
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

  final ui.Image? imageIcon;
  final double imageMargin;
  final double imageSize;

  @override
  void paint(Canvas canvas, Size size) {
    // 裁剪画布为Size大小，使其不会超出区域显示
    canvas.clipRect(Offset.zero & size);
    // 平移画布 中心点
    canvas.translate(size.width / 2, size.height / 2);

    if (offsetStart.value == Offset.zero && offsetEnd.value == Offset.zero) {
      return;
    }

    linePaint
      ..color = paintColor
      ..strokeWidth = 3.0;

    var lineStart = offsetStart.value;
    var lineEnd = offsetEnd.value;
    // 需要放在线段绘制的前面，否则因为icon的大小会影响线段的点击事件
    var closeIcon = imageIcon;
    if (null != closeIcon) {
      var startPoint = Point(x: lineStart.dx, y: lineStart.dy);
      var endPoint = Point(x: lineEnd.dx, y: lineEnd.dy);
      var offsetIcon = _updateIconOffsetByLineSegment(startPoint, endPoint);
      canvas.drawImage(closeIcon, offsetIcon, linePaint);
    }

    // line segment
    canvas.drawLine(lineStart, lineEnd, linePaint);

    // circle dot
    canvas.drawCircle(lineStart, endRadius, linePaint);
    canvas.drawCircle(lineEnd, endRadius, linePaint);
  }

  @override
  bool shouldRepaint(LineSegmentIconPainter oldDelegate) {
    return oldDelegate.offsetStart != offsetStart ||
        oldDelegate.offsetEnd != offsetEnd ||
        oldDelegate.paintColor != paintColor ||
        oldDelegate.endRadius != endRadius;
  }

  Offset _updateIconOffsetByLineSegment(Point pointA, Point pointB) {
    var high = imageMargin;
    var iconRadius = imageSize / 2;
    // 由图片自身大小得出偏移量
    var tmpIconOffset = Offset(iconRadius, iconRadius);
    // 通过三角形边长和2个点的坐标求出第三个点的坐标
    var lineAB = SpatialRelationUtil.getDistanceFromAB(pointA, pointB);
    var lineBC = sqrt(pow(lineAB / 2, 2) + pow(high, 2));
    var retPointBot = SpatialRelationUtil.getTrianglePoint(pointA, pointB, lineAB, lineBC, lineBC, isFirst: true);
    var iconOffset = Offset(retPointBot.getX - tmpIconOffset.dx, retPointBot.getY - tmpIconOffset.dy);
    return iconOffset;
  }
}
