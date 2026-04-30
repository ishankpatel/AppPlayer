import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/media_item.dart';
import '../../common/smart_network_image.dart';

class HeroBanner extends StatelessWidget {
  const HeroBanner({
    required this.item,
    required this.onPlay,
    required this.onMoreInfo,
    super.key,
  });

  final MediaItem item;
  final VoidCallback onPlay;
  final VoidCallback onMoreInfo;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final height = size.width < 720
        ? 620.0
        : (size.height * 0.72).clamp(560.0, 720.0).toDouble();

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Backdrop(item: item),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFA060607),
                  Color(0xB0060607),
                  Color(0x14060607),
                ],
                stops: [0, 0.44, 1],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.ink, Color(0x00060607)],
                stops: [0, 0.46],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(34, 0, 34, 66),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.isNew) const _Badge('New Release'),
                        if (item.isNew) const SizedBox(width: 10),
                        _Badge(
                          item.mediaType == MediaType.tv
                              ? 'Binge-ready series'
                              : 'Cinema-ready movie',
                          subdued: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 0.96,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MetaText(item.releaseYear),
                        const _Dot(),
                        _MetaText(item.runtimeLabel ?? item.mediaTypeLabel),
                        const _Dot(),
                        _MetaText(item.genre),
                        const _Dot(),
                        _MetaText(
                          'TMDB ${item.voteAverage.toStringAsFixed(1)}',
                          accent: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.overview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.text.withValues(alpha: 0.76),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: onPlay,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Play'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onMoreInfo,
                          icon: const Icon(Icons.info_outline_rounded),
                          label: const Text('More Info'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('My List'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(right: 56, bottom: 66, child: _Poster(item: item)),
        ],
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final url = item.backdropUrl ?? item.posterUrl;
    if (url == null) {
      return _HeroFallback(item: item);
    }

    return SmartNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      fallback: _HeroFallback(item: item),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final palettes = const [
      [Color(0xFF581C1C), Color(0xFF111111), Color(0xFF1F2937)],
      [Color(0xFF0F3A3A), Color(0xFF09090B), Color(0xFF7F1D1D)],
      [Color(0xFF1D2D50), Color(0xFF0A0A0B), Color(0xFF451A03)],
      [Color(0xFF3F1231), Color(0xFF09090B), Color(0xFF064E3B)],
    ];
    final palette = palettes[item.title.hashCode.abs() % palettes.length];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -90,
            top: 70,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(190),
                border: Border.all(color: Colors.white10, width: 34),
              ),
            ),
          ),
          Positioned(
            right: 120,
            bottom: 118,
            child: Text(
              item.title.toUpperCase(),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.12),
                fontSize: 74,
                height: 0.92,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 920 || item.posterUrl == null) {
      return const SizedBox.shrink();
    }
    return Container(
      width: 168,
      height: 252,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0xAA000000),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SmartNetworkImage(
        imageUrl: item.posterUrl!,
        fit: BoxFit.cover,
        fallback: _HeroFallback(item: item),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, {this.subdued = false});

  final String label;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: subdued ? Colors.white.withValues(alpha: 0.12) : AppColors.gold,
        borderRadius: BorderRadius.circular(5),
        border: subdued ? Border.all(color: Colors.white24) : null,
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: subdued ? AppColors.text : AppColors.ink,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText(this.value, {this.accent = false});

  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: TextStyle(
        color: accent ? AppColors.gold : AppColors.text.withValues(alpha: 0.7),
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
