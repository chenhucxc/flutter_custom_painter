import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_custom_painter/entities/custom_point.dart';

class SpatialRelationUtil {
  /// 返回一个点是否在一个多边形区域内
  /// @param points 多边形坐标点列表
  /// @param point   待判断点
  /// @return true 多边形包含这个点,false 多边形未包含这个点
  static bool isPolygonContainsPoint(List<Point> points, Point point) {
    int nCross = 0;
    for (int i = 0; i < points.length; i++) {
      Point p1 = points[i];
      Point p2 = points[(i + 1) % points.length];
      // 取多边形任意一个边, 做点point的水平延长线,求解与当前边的交点个数
      // p1 p2是水平线段,要么没有交点,要么有无限个交点
      if (p1.getY == p2.getY) continue;

      // point 在p1 p2 底部 --> 无交点
      if (point.getY < min(p1.getY, p2.getY)) continue;

      // point 在p1 p2 顶部 --> 无交点
      if (point.getY >= max(p1.getY, p2.getY)) continue;

      // 求解 point点水平线与当前p1p2边的交点的 X 坐标
      double x = (point.getY - p1.getY) * (p2.getX - p1.getX) / (p2.getY - p1.getY) + p1.getX;
      if (x > point.getX) {
        nCross++; // 只统计单边交点
      }
    }
    // 单边交点为偶数，点在多边形之外 ---
    return (nCross % 2 == 1);
  }

  /// 叉乘的方向性
  static double getCross(Point pointA, Point pointB, Point point) {
    var crossValue = (pointB.x - pointA.x) * (point.y - pointA.y) - (point.x - pointA.x) * (pointB.y - pointA.y);
    return crossValue;
  }

  /// 只需要判断该点是否在上下两条边和左右两条边之间就行
  /// 利用叉乘的方向性，来判断夹角是否超过了180度
  /// TODO 测试验证后发现此方法无效。。。
  static bool isPointInRectangle(List<Point> points, Point point) {
    var size = points.length;
    if (size != 4) return false;
    var p1 = points[0];
    var p2 = points[1];
    var p3 = points[2];
    var p4 = points[3];
    var retH = getCross(p1, p2, point) * getCross(p3, p4, point) >= 0;
    var retV = getCross(p2, p3, point) * getCross(p4, p1, point) >= 0;
    return retH && retV;
  }

  /// 返回一个点是否在一个多边形边界上
  /// @param points 多边形坐标点列表
  /// @param point  待判断点
  /// @return true  点在多边形边上,false 点不在多边形边上。
  static bool isPointInPolygonBoundary(List<Point> points, Point point) {
    for (int i = 0; i < points.length; i++) {
      Point p1 = points[i];
      Point p2 = points[(i + 1) % points.length];
      // 取多边形任意一个边,做点point的水平延长线,求解与当前边的交点个数

      // point 在p1 p2 底部 --> 无交点
      if (point.getY < min(p1.getY, p2.getY)) continue;

      // point 在p1 p2 顶部 --> 无交点
      if (point.getY > max(p1.getY, p2.getY)) continue;

      // p1 p2是水平线段,要么没有交点,要么有无限个交点
      if (p1.getY == p2.getY) {
        double minX = min(p1.getX, p2.getX);
        double maxX = max(p1.getX, p2.getX);

        // point在水平线段p1 p2上,直接return true
        if ((point.getY == p1.getY) && (point.getX >= minX && point.getX <= maxX)) {
          return true;
        }
      } else {
        // 求解交点
        double x = (point.getY - p1.getY) * (p2.getX - p1.getX) / (p2.getY - p1.getY) + p1.getX;
        if (x == point.getX) {
          return true; // 当x=point.x时,说明point在p1p2线段上
        }
      }
    }
    return false;
  }

  /// 点是否在线段上
  static bool isPointInPolygon(Point pointStart, Point pointEnding, Point point, {double lineHeight = 3.0}) {
    var lineDistance = getDistanceFromAB(pointStart, pointEnding);
    var toStartDistance = getDistanceFromAB(pointStart, point);
    var toEndingDistance = getDistanceFromAB(pointEnding, point);
    var sumDistance = toStartDistance + toEndingDistance;
    if (sumDistance < lineDistance + lineHeight && sumDistance > lineDistance) {
      return true;
    }
    return false;
  }

  /// 以线段中点画圆来设置点击范围
  static bool isPointInPolygonCenterRange(Point pointStart, Point pointEnding, Point point, {double radius = 10.0}) {
    var ret = false;
    ret = isPointInPolygon(pointStart, pointEnding, point, lineHeight: radius);
    if (ret) return true;
    var middlePointDx = (pointStart.x + pointEnding.x) / 2;
    var middlePointDy = (pointStart.y + pointEnding.y) / 2;
    var middlePoint = Point(x: middlePointDx, y: middlePointDy);
    var lineDistance = getDistanceFromAB(pointStart, pointEnding);
    var tmpRadius = lineDistance / 3 * 2;
    var finalRadius = radius;
    if (radius > tmpRadius) {
      finalRadius = tmpRadius;
    } else if (tmpRadius > 3 * radius) {
      finalRadius = 3 * radius;
    }
    //print('isPointInPolygonCenterRange->finalRadius=$finalRadius');
    return isPointInCircle(middlePoint, finalRadius, point);
  }

  /// 判断点位是否在圆中
  static bool isPointInCircle(Point centerPoint, double radius, Point point) {
    var distanceX = (centerPoint.getX - point.getX).abs();
    var distanceY = (centerPoint.getY - point.getY).abs();
    var distance = sqrt(pow(distanceX, 2) + pow(distanceY, 2));
    if (distance <= radius) {
      return true;
    }
    return false;
  }

  static Point getTrianglePoint(Point pointA, Point pointB, double ab, double bc, double ca, {bool isFirst = false}) {
    //double dy = pointB.y - pointA.y;
    //double dx = pointB.x - pointA.x;
    // 计算边AC和AB的夹角θ->theta = arccos[(b^2 + c^2 - a^) / 2bc]
    double tmpValue = (ca * ca + ab * ab - bc * bc) / (2 * ca * ab);

    // AB的方位角
    var angleAB = -getAngle(pointA, pointB) + 180; // 转为屏幕坐标系角度(x轴右侧顺时针为正向角度)
    angleAB = angleAB * (pi / 180);
    // A点对应BC边的角度
    var angleBC = acos(tmpValue);
    // AC的方位角
    var angleAC = angleAB - angleBC;
    var pointC = Point();
    pointC.x = pointA.getX + ca * sin(angleAC);
    pointC.y = pointA.getY + ca * cos(angleAC);
    //print('getTrianglePoint->C1 = pos(${pointC.getX}, ${pointC.getY})');

    if (isFirst) {
      return pointC;
    }

    angleAC = angleAB + angleBC;
    pointC.x = pointA.getX + ca * sin(angleAC);
    pointC.y = pointA.getY + ca * cos(angleAC);
    //print('getTrianglePoint->C2 = pos(${pointC.getX}, ${pointC.getY})');
    return pointC;
  }

  // 计算向量AB与Y轴正方向夹角，角度范围0~360
  static double getAngle(Point pointA, Point pointB) {
    var x = (pointA.getX - pointB.getX).abs();
    var y = (pointA.getY - pointB.getY).abs();
    var z = sqrt(pow(x, 2) + pow(y, 2));
    var cos = y / z;
    // 用反三角函数求弧度
    var radian = acos(cos);
    // 将弧度转换成角度
    var angle = (180 / (pi / radian)).floor();
    if (pointB.getX > pointA.getX && pointB.getY > pointA.getY) {
      // 鼠标在第四象限
      angle = 180 - angle;
    }
    if (pointB.getX == pointA.getX && pointB.getY > pointA.getY) {
      // 鼠标在y轴负方向上
      angle = 180;
    }
    if (pointB.getX > pointA.getX && pointB.getY == pointA.getY) {
      // 鼠标在x轴正方向上
      angle = 90;
    }
    if (pointB.getX < pointA.getX && pointB.getY > pointA.getY) {
      // 鼠标在第三象限
      angle = 180 + angle;
    }
    if (pointB.getX < pointA.getX && pointB.getY == pointA.getY) {
      // 鼠标在x轴负方向
      angle = 270;
    }
    if (pointB.getX < pointA.getX && pointB.getY < pointA.getY) {
      // 鼠标在第二象限
      angle = 360 - angle;
    }
    return angle.toDouble();
  }

  static double getDistanceFromAB(Point pointA, Point pointB) {
    var x = (pointA.getX - pointB.getX).abs();
    var y = (pointA.getY - pointB.getY).abs();
    return sqrt(pow(x, 2) + pow(y, 2));
  }

  static double getDistanceFromTwoOffset(Offset pointA, Offset pointB) {
    var x = (pointA.dx - pointB.dx).abs();
    var y = (pointA.dy - pointB.dy).abs();
    return sqrt(pow(x, 2) + pow(y, 2));
  }
}
