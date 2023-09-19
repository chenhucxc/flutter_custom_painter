import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_custom_painter/entities/custom_point.dart';
import 'package:flutter_custom_painter/entities/rectangle_bean.dart';
import 'package:flutter_custom_painter/painter/rect_icon_painter.dart';
import 'package:flutter_custom_painter/utils/common_util.dart';
import 'package:flutter_custom_painter/utils/spatial_relation_util.dart';

class RectangleWithIconPage extends StatefulWidget {
  const RectangleWithIconPage({super.key});

  @override
  State<RectangleWithIconPage> createState() => _RectangleWithIconPageState();
}

class _RectangleWithIconPageState extends State<RectangleWithIconPage> {
  final GlobalKey _globalKey = GlobalKey();

  /// 线段相关的变量
  final double _lineSegmentLength = 60;
  final double _iconSize = 28; // 删除Icon默认大小
  final double _iconMargin = 30; // 图片距离图形的距离

  final _offsetsNotifier = ValueNotifier(RectangleBean());
  final _changedOffset = ValueNotifier(0);

  /// 手势
  static const moveAreaOutside = 0;
  static const moveAreaInside = 1;
  int _moveAreaType = moveAreaOutside;
  int _selectedIndex = -1;
  int _selectedSide = -1;

  @override
  void initState() {
    _initialCanvas();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("矩形"),
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
                future: CommonUtil.loadAssetsImage(
                  'assets/icon_editor_close.png',
                  targetWith: _iconSize.toInt(),
                  targetHeight: _iconSize.toInt(),
                ),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    // 图片加载中...
                    return const Text('');
                  }
                  return CustomPaint(
                    foregroundPainter: RectangleWithIconPainter(
                      rectangleNotifier: _offsetsNotifier,
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

  void _initialCanvas() {
    var lineSegmentLength = _lineSegmentLength;
    List<Offset> rectOffsets = [];
    var topLeftOffset = Offset(-lineSegmentLength / 2, -lineSegmentLength / 2);
    var topRightOffset = Offset(lineSegmentLength / 2, -lineSegmentLength / 2);
    var botRightOffset = Offset(lineSegmentLength / 2, lineSegmentLength / 2);
    var botLeftOffset = Offset(-lineSegmentLength / 2, lineSegmentLength / 2);
    // 需要按指定顺序(上左、上右、下右、下左)添加到数组中
    rectOffsets.addAll([topLeftOffset, topRightOffset, botRightOffset, botLeftOffset]);
    _offsetsNotifier.value = RectangleBean(offsets: rectOffsets);
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
    }
  }

  onScaleEnd(ScaleEndDetails? details) {
    _moveAreaType = moveAreaOutside;
    _selectedIndex = -1;
    _selectedSide = -1;
  }

  onScaleUpdate(ScaleUpdateDetails details) {
    var pointIndex = _selectedIndex;
    var deltaOffset = details.focalPointDelta;
    print('onScaleUpdate->pointIndex=$pointIndex, side=$_selectedSide, moveAreaType=$_moveAreaType');
    if (_moveAreaType == moveAreaInside) {
      var offsets = _offsetsNotifier.value.offsets ?? [];
      if (pointIndex >= 0) {
        if (pointIndex >= 0 && _selectedSide < 0) {
          offsets[pointIndex] = offsets[pointIndex].translate(deltaOffset.dx, deltaOffset.dy);
          if (0 == pointIndex) {
            offsets[1] = offsets[1].translate(0, deltaOffset.dy);
            offsets[3] = offsets[3].translate(deltaOffset.dx, 0);
          } else if (1 == pointIndex) {
            offsets[0] = offsets[0].translate(0, deltaOffset.dy);
            offsets[2] = offsets[2].translate(deltaOffset.dx, 0);
          } else if (2 == pointIndex) {
            offsets[1] = offsets[1].translate(deltaOffset.dx, 0);
            offsets[3] = offsets[3].translate(0, deltaOffset.dy);
          } else if (3 == pointIndex) {
            offsets[0] = offsets[0].translate(deltaOffset.dx, 0);
            offsets[2] = offsets[2].translate(0, deltaOffset.dy);
          }
        }
      } else if (_selectedSide >= 0) {
        for (int i = 0; i < offsets.length; i++) {
          offsets[i] = offsets[i].translate(deltaOffset.dx, deltaOffset.dy);
        }
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
    var offsets = _offsetsNotifier.value.offsets ?? [];
    if (offsets.isEmpty) return -1;

    // 本次点击的坐标点
    var clickPoint = Point.translateFromOffset(offset);

    var ret = _checkTapPointAtArch(offsets, clickPoint, radius: 30);
    _selectedIndex = ret;
    if (ret >= 0) {
      return ret;
    }
    ret = _checkTapPointAtSide(offsets, clickPoint);
    _selectedSide = ret;
    if (ret >= 0) {
      return ret;
    }
    var retArea = _checkTapPointAtArea(offsets, clickPoint);
    if (retArea) {
      _selectedSide = 4;
      return 0;
    }
    print('updateOperationType->不在任何编辑的图形上');
    return -1;
  }

  /// 是否在点上
  int _checkTapPointAtArch(List<Offset> offsets, Point clickPoint, {double radius = 15.0}) {
    var ret = -1;
    for (int i = 0; i < offsets.length; i++) {
      var element = offsets[i];
      var isClickInner = SpatialRelationUtil.isPointInCircle(Point.translateFromOffset(element), radius, clickPoint);
      if (isClickInner) {
        ret = i;
        break;
      }
    }
    print('checkTapPointAtArch->find index is $ret');
    return ret;
  }

  /// 是否在图形的边上
  int _checkTapPointAtSide(List<Offset> offsets, Point clickPoint, {double radius = 5.0}) {
    var pointOne = offsets[0];
    var pointTwo = offsets[1];
    var isClickInner = SpatialRelationUtil.isPointInPolygon(
      Point.translateFromOffset(pointOne),
      Point.translateFromOffset(pointTwo),
      clickPoint,
      lineHeight: radius,
    );
    if (isClickInner) return 0;
    var pointThird = offsets[2];
    isClickInner = SpatialRelationUtil.isPointInPolygon(
      Point.translateFromOffset(pointTwo),
      Point.translateFromOffset(pointThird),
      clickPoint,
      lineHeight: radius,
    );
    if (isClickInner) return 1;
    var pointFour = offsets[3];
    isClickInner = SpatialRelationUtil.isPointInPolygon(
      Point.translateFromOffset(pointThird),
      Point.translateFromOffset(pointFour),
      clickPoint,
      lineHeight: radius,
    );
    if (isClickInner) return 2;
    isClickInner = SpatialRelationUtil.isPointInPolygon(
      Point.translateFromOffset(pointFour),
      Point.translateFromOffset(pointOne),
      clickPoint,
      lineHeight: radius,
    );
    if (isClickInner) return 3;
    return -1;
  }

  /// 是否在图形上
  bool _checkTapPointAtArea(List<Offset> offsets, Point clickPoint) {
    var leftTop = offsets[0];
    var rightBottom = offsets[2];
    if (clickPoint.x >= min(leftTop.dx, rightBottom.dx) &&
        clickPoint.x <= max(leftTop.dx, rightBottom.dx) &&
        clickPoint.y >= min(leftTop.dy, rightBottom.dy) &&
        clickPoint.y <= max(leftTop.dy, rightBottom.dy)) {
      return true;
    }
    return false;
  }
}
