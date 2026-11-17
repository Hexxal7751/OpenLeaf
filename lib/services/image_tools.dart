import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

List<Uint8List> _splitSync(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return [bytes];
  final image = img.bakeOrientation(decoded);
  final half = image.width ~/ 2;
  final left = img.copyCrop(image, x: 0, y: 0, width: half, height: image.height);
  final right = img.copyCrop(
    image,
    x: half,
    y: 0,
    width: image.width - half,
    height: image.height,
  );
  return [
    Uint8List.fromList(img.encodeJpg(left, quality: 92)),
    Uint8List.fromList(img.encodeJpg(right, quality: 92)),
  ];
}

class ImageTools {
  /// Splits a two-page book spread down the middle into [left, right].
  static Future<List<Uint8List>> splitSpread(Uint8List bytes) {
    return compute(_splitSync, bytes);
  }
}
