import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppHelpers {
  AppHelpers._();

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 1024;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 600 && width < 1024;
  }

  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 600;
  }

  static int getGridColumnCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  /// Generates optimized image delivery URLs (Cloudinary & Unsplash) with auto format & responsive resolution
  static String optimizeImageUrl(String url, {int width = 600, int height = 400}) {
    if (url.isEmpty) return url;

    // Cloudinary URL optimization
    if (url.contains('res.cloudinary.com')) {
      if (url.contains('/upload/') && !url.contains('w_') && !url.contains('f_auto')) {
        return url.replaceFirst('/upload/', '/upload/c_limit,w_$width,q_auto,f_auto/');
      }
      return url;
    }

    // Unsplash URL optimization
    if (url.contains('images.unsplash.com')) {
      try {
        final uri = Uri.parse(url);
        final queryParams = Map<String, String>.from(uri.queryParameters);
        queryParams['w'] = '$width';
        queryParams['auto'] = 'format';
        queryParams['q'] = '80';
        return uri.replace(queryParameters: queryParams).toString();
      } catch (_) {
        return url;
      }
    }

    return url;
  }

  /// Renders a fast, memory-cached network image with instant placeholder
  static Widget buildCachedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
    int memCacheWidth = 600,
  }) {
    if (imageUrl.isEmpty) {
      final fallback = Container(
        width: width,
        height: height,
        color: const Color(0xFFEFF4F9),
        child: const Icon(Icons.image_outlined, color: Color(0xFF707974), size: 24),
      );
      if (borderRadius != null) return ClipRRect(borderRadius: borderRadius, child: fallback);
      return fallback;
    }

    final optimized = optimizeImageUrl(imageUrl, width: memCacheWidth);

    Widget image = CachedNetworkImage(
      imageUrl: optimized,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: const Duration(milliseconds: 150),
      placeholder: (context, url) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            color: const Color(0xFFEFF4F9),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00696E)),
              ),
            ),
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            width: width,
            height: height,
            color: const Color(0xFFEFF4F9),
            child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF707974), size: 24),
          ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius, child: image);
    }
    return image;
  }

  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFBA1A1A) : const Color(0xFF00696E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
