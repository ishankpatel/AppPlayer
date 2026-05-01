import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SmartNetworkImage extends StatelessWidget {
  const SmartNetworkImage({
    required this.imageUrl,
    required this.fit,
    required this.fallback,
    this.fadeDuration = const Duration(milliseconds: 360),
    super.key,
  });

  final String imageUrl;
  final BoxFit fit;
  final Widget fallback;
  final Duration fadeDuration;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: fit,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: fadeDuration,
          curve: Curves.easeOut,
          child: child,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
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
}
