import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shimmer/shimmer.dart';

class SmartNetworkImage extends StatelessWidget {
  const SmartNetworkImage({
    required this.imageUrl,
    required this.fit,
    required this.fallback,
    this.cacheWidth,
    this.cacheHeight,
    this.enableShimmer = true,
    this.fadeDuration = const Duration(milliseconds: 360),
    super.key,
  });

  final String imageUrl;
  final BoxFit fit;
  final Widget fallback;
  final double? cacheWidth;
  final double? cacheHeight;
  final bool enableShimmer;
  final Duration fadeDuration;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 720;
    final dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 2.0);
    int? scaled(double? value) => value == null ? null : (value * dpr).round();
    final effectiveFadeDuration = compact ? Duration.zero : fadeDuration;

    final resolvedImageUrl = _proxiedImageUrl(imageUrl);

    return Image.network(
      resolvedImageUrl,
      fit: fit,
      cacheWidth: scaled(cacheWidth),
      cacheHeight: scaled(cacheHeight),
      filterQuality: FilterQuality.low,
      gaplessPlayback: true,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || effectiveFadeDuration == Duration.zero) {
          return child;
        }
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: effectiveFadeDuration,
          curve: Curves.easeOut,
          child: child,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        if (compact || !enableShimmer) return fallback;
        return Stack(
          fit: StackFit.expand,
          children: [
            fallback,
            IgnorePointer(
              child: Shimmer.fromColors(
                baseColor: const Color(0x00FFFFFF),
                highlightColor: const Color(0x22FFFFFF),
                period: const Duration(milliseconds: 1500),
                child: Container(color: Colors.white),
              ),
            ),
          ],
        );
      },
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  String _proxiedImageUrl(String url) {
    if (!kIsWeb) return url;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.scheme != 'https') return url;
    const proxiedHosts = {
      'images.metahub.space',
      'static.metahub.space',
      'episodes.metahub.space',
    };
    if (!proxiedHosts.contains(uri.host)) return url;
    return '/api/image?url=${Uri.encodeComponent(url)}';
  }
}
