import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageUtils {
  ImageUtils._(); // Private constructor to prevent instantiation
  
  static const int defaultTargetWidth = 800;
  static const int defaultQuality = 80;
  
  // Cache regex patterns for better performance
  static final _whitespacePattern = RegExp(r'\s');
  static final _base64Pattern = RegExp(r'^[A-Za-z0-9+/=\s]+$');
  
  // Cache common data URL prefixes
  static const _dataPrefixes = [
    'data:image/jpeg;base64,',
    'data:image/jpg;base64,',
    'data:image/png;base64,',
    'data:image/webp;base64,',
  ];

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
    // Check cached prefixes
    for (final p in _dataPrefixes) {
      if (s.startsWith(p)) {
        s = s.substring(p.length);
        break;
      }
    }
    // Remove any whitespace/newlines using cached pattern
    return s.replaceAll(_whitespacePattern, '');
  }

  // Heuristic check for base64 content
  static bool isLikelyBase64(String value) {
    // Early length check before trim
    if (value.length <= 32) return false;
    
    final s = value.trim();
    // Quick protocol checks
    if (s.startsWith('http://') || s.startsWith('https://')) return false;
    if (s.startsWith('data:image/')) return true;
    
    // Use cached pattern for validation
    return _base64Pattern.hasMatch(s);
  }
}
