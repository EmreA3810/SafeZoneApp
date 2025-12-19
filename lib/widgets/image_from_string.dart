import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/image_utils.dart';

class ImageFromString extends StatelessWidget {
  final String src;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ImageFromString({
    Key? key,
    required this.src,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  }) : super(key: key);

  bool get _isNetwork =>
      src.startsWith('http://') || src.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (_isNetwork) {
      return CachedNetworkImage(
        imageUrl: src,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.error),
        ),
      );
    }

    // Base64 image branch (with normalization and simple validation)
    if (ImageUtils.isLikelyBase64(src)) {
      try {
        final Uint8List bytes = ImageUtils.base64ToBytes(src);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        );
      } catch (e) {
        // Fallthrough to error box below
      }
    }

    // Unknown or invalid content
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.error),
    );
  }
}
