import 'dart:ui';

/// 自定义offset的扩展方法
extension OffsetToJson on Offset {
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['x'] = dx;
    map['y'] = dy;
    return map;
  }
}

/// 自定义list<offset>的扩展方法
extension OffsetsToJson on List<Offset> {
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (isNotEmpty) {
      map['points'] = this.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class RectangleBean {
  RectangleBean({
    this.selectIndex = -1,
    this.offsets = const [],
  });

  int? selectIndex;
  List<Offset>? offsets;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['selectIndex'] = selectIndex;
    if (offsets != null) {
      map['points'] = offsets?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
