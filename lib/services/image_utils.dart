import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageUtils {
  // Compresses image file and returns base64-encoded JPEG bytes.
  // targetWidth: longest side in pixels, quality: 0-100
  static Future<String> compressFileToBase64(
    File file, {
    int targetWidth = 800,
    int quality = 70,
  }) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: targetWidth,
        minHeight: targetWidth,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        throw Exception('Image compression returned null');
      }

      // result is Uint8List bytes
      return base64Encode(result);
    } catch (e) {
      if (kDebugMode) {
        print('Error compressing image: $e');
      }
      rethrow;
    }
  }

  // Helper to convert base64 string back to bytes
  static Uint8List base64ToBytes(String base64String) {
    return base64Decode(base64String);
  }
}
