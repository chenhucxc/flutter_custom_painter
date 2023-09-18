import 'package:flutter/material.dart';

class Point {
  double x = 0.0;
  double y = 0.0;

  Point({this.x = 0.0, this.y = 0.0});

  double get getX => x;

  double get getY => y;

  static Point translateFromOffset(Offset offset) {
    return Point(x: offset.dx, y: offset.dy);
  }

  @override
  String toString() {
    return 'Point{x: $x, y: $y}';
  }
}