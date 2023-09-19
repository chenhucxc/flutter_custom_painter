import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_custom_painter/entities/custom_point.dart';
import 'package:flutter_custom_painter/painter/line_segment_icon_painter.dart';
import 'package:flutter_custom_painter/utils/common_util.dart';
import 'package:flutter_custom_painter/utils/spatial_relation_util.dart';

class LineSegmentWithIconPage extends StatefulWidget {
  const LineSegmentWithIconPage({super.key});

  @override
  State<LineSegmentWithIconPage> createState() => _LineSegmentWithIconPageState();
}

class _LineSegmentWithIconPageState extends State<LineSegmentWithIconPage> {
  final GlobalKey _globalKey = GlobalKey();

  /// 线段相关的变量
  final double _lineSegmentLength = 60;
  final double _iconSize = 28; // 删除Icon默认大小
  final double _iconMargin = 30; // 图片距离图形的距离

  final _lineStartOffset = ValueNotifier(Offset.zero);
  final _lineEndOffset = ValueNotifier(Offset.zero);
  final _changedOffset = ValueNotifier(0);

  /// 手势
  static const moveAreaOutside = 0;
  static const moveAreaInside = 1;
  int _moveAreaType = moveAreaOutside;
  int _selectedIndex = -1;

  @override
  void initState() {
    _initialCanvas();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("线段"),
      ),
      body: GestureDetector(
        onTapUp: onTapUp,
        onScaleStart: onScaleStart,
        onScaleUpdate: onScaleUpdate,
        onScaleEnd: onScaleEnd,
        child: Stack(
          key: _globalKey,
          children: [
            FutureBuilder<ui.Image>(
                future: CommonUtil.loadAssetsImage('assets/icon_editor_close.png', targetWith: _iconSize.toInt(), targetHeight: _iconSize.toInt()),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    // 图片加载中...
                    return const Text('');
                  }
                  return CustomPaint(
                    foregroundPainter: LineSegmentIconPainter(
                      offsetStart: _lineStartOffset,
                      offsetEnd: _lineEndOffset,
                      imageIcon: snapshot.data,
                      imageMargin: _iconMargin,
                      repaint: _changedOffset,
                    ),
                    child: Container(
                      color: Colors.grey,
                    ),
                  );
                })
          ],
        ),
      ),
    );
  }

  void _initialCanvas({bool isVertical = false}) {
    var lineSegmentLength = _lineSegmentLength;
    if (isVertical) {
      _lineStartOffset.value = Offset(0, -lineSegmentLength / 2);
      var dx = _lineStartOffset.value.dx;
      var dy = _lineStartOffset.value.dy + lineSegmentLength;
      _lineEndOffset.value = Offset(dx, dy);
    } else {
      _lineStartOffset.value = Offset(-lineSegmentLength / 2, 0);
      var dx = _lineStartOffset.value.dx + lineSegmentLength;
      var dy = _lineStartOffset.value.dy;
      _lineEndOffset.value = Offset(dx, dy);
    }
  }

  onTapUp(TapUpDetails details) {}

  onScaleStart(ScaleStartDetails details) {
    if (details.pointerCount == 1) {
      var resizeOffset = _getResizeOffset(details.localFocalPoint);
      var ret = _findTouchRespGraphType(resizeOffset);
      print('onScaleStart->updateOperationType is $ret');
      if (ret >= 0) {
        _moveAreaType = moveAreaInside;
      } else {
        _moveAreaType = moveAreaOutside;
      }
      _selectedIndex = ret;
    }
  }

  onScaleEnd(ScaleEndDetails? details) {
    _moveAreaType = moveAreaOutside;
  }

  onScaleUpdate(ScaleUpdateDetails details) {
    var pointIndex = _selectedIndex;
    var deltaOffset = details.focalPointDelta;
    print('onScaleUpdate->pointIndex=$pointIndex, moveAreaType=$_moveAreaType');
    if (pointIndex >= 0 && _moveAreaType == moveAreaInside) {
      if (0 == pointIndex) {
        _lineStartOffset.value = _lineStartOffset.value.translate(deltaOffset.dx, deltaOffset.dy);
      } else if (1 == pointIndex) {
        _lineEndOffset.value = _lineEndOffset.value.translate(deltaOffset.dx, deltaOffset.dy);
      } else if (2 == pointIndex) {
        var startOffset = _lineStartOffset.value;
        var endOffset = _lineEndOffset.value;
        _lineStartOffset.value = startOffset.translate(deltaOffset.dx, deltaOffset.dy);
        _lineEndOffset.value = endOffset.translate(deltaOffset.dx, deltaOffset.dy);
      }
      _changedOffset.value = DateTime.now().millisecondsSinceEpoch;
    }
  }

  Offset _getResizeOffset(Offset offset) {
    // 减去(_canvasWidth / 2)是因为画布中有平移左上角零点(0, 0)到画布中间的操作
    RenderBox renderBox = _globalKey.currentContext?.findRenderObject() as RenderBox;
    var renderSize = renderBox.size;
    //print('getResizeOffset->width=${renderSize.width}, height=${renderSize.height}');
    var resizeOffset = offset.translate(-renderSize.width / 2, -renderSize.height / 2);
    return resizeOffset;
  }

  /// 通过点击位置匹配对应的图形
  int _findTouchRespGraphType(Offset offset) {
    // 本次点击的坐标点
    var clickPoint = Point.translateFromOffset(offset);

    var startPoint = Point.translateFromOffset(_lineStartOffset.value);
    var endPoint = Point.translateFromOffset(_lineEndOffset.value);
    var ret = _checkTapPointAtArch(startPoint, endPoint, clickPoint, radius: 30);
    if (ret >= 0) {
      return ret;
    }
    ret = _checkTapPointAtSide(startPoint, endPoint, clickPoint);
    if (ret >= 0) {
      return ret;
    }
    print('updateOperationType->不在任何编辑的图形上');
    return -1;
  }

  /// 是否在点上
  int _checkTapPointAtArch(Point start, Point end, Point clickPoint, {double radius = 15.0}) {
    var isClickInner = SpatialRelationUtil.isPointInCircle(start, radius, clickPoint);
    if (isClickInner) {
      return 0;
    }
    isClickInner = SpatialRelationUtil.isPointInCircle(end, radius, clickPoint);
    if (isClickInner) {
      return 1;
    }
    return -1;
  }

  /// 是否在图形的边上
  int _checkTapPointAtSide(Point start, Point end, Point clickPoint, {double radius = 5.0}) {
    var isClickInner = SpatialRelationUtil.isPointInPolygon(start, end, clickPoint, lineHeight: radius);
    if (isClickInner) {
      return 2;
    }
    return -1;
  }
}
