import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_custom_painter/entities/custom_point.dart';
import 'package:flutter_custom_painter/entities/rectangle_bean.dart';
import 'package:flutter_custom_painter/utils/spatial_relation_util.dart';

class RectangleWithIconPainter extends CustomPainter {
  RectangleWithIconPainter({
    required this.rectangleNotifier,
    this.paintColor = const Color(0xFF34C759),
    this.endRadius = 4.5,
    this.imageIcon,
    this.imageMargin = 30,
    this.imageSize = 28,
    this.iconOffsetChanged,
    Listenable? repaint,
  }) : super(repaint: repaint) {
    linePaint
      ..color = paintColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.square
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;
  }

  final ValueNotifier<RectangleBean> rectangleNotifier;
  final linePaint = Paint();
  final Color paintColor;
  final double endRadius;

  final ui.Image? imageIcon;
  final double imageMargin;
  final double imageSize;
  final Function(Offset)? iconOffsetChanged;

  @override
  void paint(Canvas canvas, Size size) {
    // 裁剪画布为Size大小，使其不会超出区域显示
    canvas.clipRect(Offset.zero & size);
    // 平移画布 中心点
    canvas.translate(size.width / 2, size.height / 2);

    linePaint
      ..color = paintColor
      ..strokeWidth = 3.0;

    var offsets = rectangleNotifier.value.offsets ?? [];
    if (offsets.length != 4) return;

    var topLeft = offsets[0];
    var topRight = offsets[1];
    var bottomRight = offsets[2];
    var bottomLeft = offsets[3];

    if (topLeft == Offset.zero && topRight == Offset.zero && bottomRight == Offset.zero && bottomLeft == Offset.zero) {
      return;
    }

    // line segment
    linePaint.style = PaintingStyle.stroke;
    canvas.drawLine(topLeft, topRight, linePaint);
    canvas.drawLine(topRight, bottomRight, linePaint);
    canvas.drawLine(bottomRight, bottomLeft, linePaint);
    canvas.drawLine(bottomLeft, topLeft, linePaint);

    // circle dot
    linePaint.style = PaintingStyle.fill;
    canvas.drawCircle(topLeft, endRadius, linePaint);
    canvas.drawCircle(topRight, endRadius, linePaint);
    canvas.drawCircle(bottomLeft, endRadius, linePaint);
    canvas.drawCircle(bottomRight, endRadius, linePaint);

    var closeIcon = imageIcon;
    if (null != closeIcon) {
      var startPoint = Point.translateFromOffset(bottomLeft);
      var endPoint = Point.translateFromOffset(bottomRight);
      var offsetIcon = _updateIconOffsetByLineSegment(startPoint, endPoint);
      canvas.drawImage(closeIcon, offsetIcon, linePaint);
      iconOffsetChanged?.call(offsetIcon);
    }
  }

  @override
  bool shouldRepaint(RectangleWithIconPainter oldDelegate) {
    return oldDelegate.paintColor != paintColor || oldDelegate.endRadius != endRadius;
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
