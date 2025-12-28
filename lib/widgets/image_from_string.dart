import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/image_utils.dart';

class ImageFromString extends StatelessWidget {
  final String src;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ImageFromString({
    super.key,
    required this.src,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  bool get _isNetwork =>
      src.startsWith('http://') || src.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (_isNetwork) {
      // Use Image.network on web for better compatibility
      if (kIsWeb) {
        return Image.network(
          src,
          fit: fit,
          width: width,
          height: height,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildPlaceholder(context);
          },
          errorBuilder: (context, error, stackTrace) => _buildError(context),
        );
      }
      return CachedNetworkImage(
        imageUrl: src,
        fit: fit,
        width: width,
        height: height,
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
        maxWidthDiskCache: 800,
        maxHeightDiskCache: 800,
        placeholder: (context, url) => _buildPlaceholder(context),
        errorWidget: (context, url, error) => _buildError(context),
      );
    }

    // Base64 image branch (with normalization and simple validation)
    if (ImageUtils.isLikelyBase64(src)) {
      try {
        final bytes = ImageUtils.base64ToBytes(src);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          cacheWidth: width?.toInt(),
          cacheHeight: height?.toInt(),
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        );
      } catch (e) {
        return _buildError(context);
      }
    }

    // Unknown or invalid content
    return _buildError(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.broken_image_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
