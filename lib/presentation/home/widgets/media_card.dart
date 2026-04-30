import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/media_item.dart';
import '../../common/smart_network_image.dart';

class MediaCard extends StatefulWidget {
  const MediaCard({required this.item, required this.onTap, super.key});

  final MediaItem item;
  final VoidCallback onTap;

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final artworkUrl = widget.item.backdropUrl ?? widget.item.posterUrl;

    return FocusableActionDetector(
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      child: MouseRegion(
        onEnter: (_) => setState(() => _focused = true),
        onExit: (_) => setState(() => _focused = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            scale: _focused ? 1.035 : 1,
            child: SizedBox(
              width: 286,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 161,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _focused ? AppColors.gold : Colors.white10,
                        width: _focused ? 1.2 : 0.7,
                      ),
                      boxShadow: [
                        if (_focused)
                          const BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (artworkUrl != null)
                          SmartNetworkImage(
                            imageUrl: artworkUrl,
                            fit: BoxFit.cover,
                            fallback: _ArtworkFallback(item: widget.item),
                          )
                        else
                          _ArtworkFallback(item: widget.item),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Color(0xCC000000), Color(0x00000000)],
                            ),
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0x99000000), Color(0x00000000)],
                              stops: [0, 0.58],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 9,
                          left: 10,
                          child: _MiniBadge(
                            widget.item.mediaType == MediaType.tv
                                ? 'SERIES'
                                : 'MOVIE',
                          ),
                        ),
                        if (widget.item.isFavorite || widget.item.isInWatchlist)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.ink.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                widget.item.isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.bookmark_rounded,
                                size: 16,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                        Positioned(
                          left: 10,
                          right: 54,
                          bottom: 12,
                          child: Text(
                            widget.item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Text(
                        widget.item.releaseYear,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.item.genre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.item.voteAverage.toStringAsFixed(1),
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtworkFallback extends StatelessWidget {
  const _ArtworkFallback({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final palettes = const [
      [Color(0xFF1E3A5F), Color(0xFF101114), Color(0xFF3A1A2E)],
      [Color(0xFF4A0F1F), Color(0xFF151111), Color(0xFF7F1D1D)],
      [Color(0xFF123D3A), Color(0xFF101114), Color(0xFF0F766E)],
      [Color(0xFF3B2F0A), Color(0xFF111111), Color(0xFFB45309)],
      [Color(0xFF172554), Color(0xFF0A0A0B), Color(0xFF4338CA)],
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
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.28),
                  ],
                  stops: const [0, 0.42, 1],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  item.title.toUpperCase(),
                  maxLines: 2,
                  style: TextStyle(
                    color: AppColors.text.withValues(alpha: 0.24),
                    fontSize: 34,
                    height: 0.92,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -26,
            top: -36,
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(66),
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 40,
            child: Text(
              item.genre.toUpperCase(),
              style: TextStyle(
                color: AppColors.text.withValues(alpha: 0.58),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 12,
            child: Container(
              width: 34,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
