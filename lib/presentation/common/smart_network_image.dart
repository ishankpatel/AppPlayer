import 'package:flutter/material.dart';

class SmartNetworkImage extends StatelessWidget {
  const SmartNetworkImage({
    required this.imageUrl,
    required this.fit,
    required this.fallback,
    super.key,
  });

  final String imageUrl;
  final BoxFit fit;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: fit,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return fallback;
      },
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}
