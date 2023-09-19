import 'package:flutter/material.dart';

extension Transfer4Point on Point {
  Offset toOffset() {
    return Offset(x, y);
  }

  Point fromOffset(Offset offset) {
    return Point(x: offset.dx, y: offset.dy);
  }
}

class Point {
  double x = 0.0;
  double y = 0.0;

  Point({this.x = 0.0, this.y = 0.0});

  double get getX => x;

  double get getY => y;

  Point.fromJson(dynamic json) {
    x = json["x"];
    y = json["y"];
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['x'] = x;
    map['y'] = y;
    return map;
  }

  static Point translateFromOffset(Offset offset) {
    return Point(x: offset.dx, y: offset.dy);
  }

  @override
  String toString() {
    return 'Point{x: $x, y: $y}';
  }
}
