import 'dart:ui' as ui;

import 'package:flutter/services.dart';

class CommonUtil {
  /// ui image load by assets path
  static Future<ui.Image> loadAssetsImage(String path, {int? targetWith, int? targetHeight}) async {
    // 加载资源文件
    final data = await rootBundle.load(path);
    // 把资源文件转换成Uint8List类型
    final bytes = data.buffer.asUint8List();
    // 解析Uint8List类型的数据图片
    //var retImage = decodeImageFromList(bytes);

    ui.Codec codec = await ui.instantiateImageCodec(bytes, targetWidth: targetWith, targetHeight: targetHeight);
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    var retImage = frameInfo.image;

    return retImage;
  }
}
