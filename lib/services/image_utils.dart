import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageUtils {
  static const int defaultTargetWidth = 800;
  static const int defaultQuality = 80;

  // Compresses image file and returns base64-encoded JPEG bytes.
  // targetWidth: longest side in pixels, quality: 0-100
  static Future<String> compressFileToBase64(
    File file, {
    int targetWidth = defaultTargetWidth,
    int quality = defaultQuality,
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
    return base64Decode(normalizeBase64(base64String));
  }

  // Strip data URI prefixes and whitespace/newlines
  static String normalizeBase64(String value) {
    var s = value.trim();
    // Common data URL prefixes
    const prefixes = [
      'data:image/jpeg;base64,',
      'data:image/jpg;base64,',
      'data:image/png;base64,',
      'data:image/webp;base64,',
    ];
    for (final p in prefixes) {
      if (s.startsWith(p)) {
        s = s.substring(p.length);
        break;
      }
    }
    // Remove any whitespace/newlines that may break decoding
    s = s.replaceAll(RegExp(r'\s'), '');
    return s;
  }

  // Heuristic check for base64 content
  static bool isLikelyBase64(String value) {
    final s = value.trim();
    if (s.startsWith('http://') || s.startsWith('https://')) return false;
    if (s.startsWith('data:image/')) return true;
    // Base64 should only contain A-Z, a-z, 0-9, +, / and = for padding
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/=\s]+$');
    // Avoid very short strings (not images)
    return s.length > 32 && base64Pattern.hasMatch(s);
  }
}
