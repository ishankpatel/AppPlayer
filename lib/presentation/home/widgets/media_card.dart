import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/media_item.dart';
import '../../common/smart_network_image.dart';
import '../../watchlist/watchlist_provider.dart';

class MediaCard extends ConsumerStatefulWidget {
  const MediaCard({required this.item, required this.onTap, super.key});

  final MediaItem item;
  final VoidCallback onTap;

  @override
  ConsumerState<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends ConsumerState<MediaCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final artworkUrl = widget.item.backdropUrl ?? widget.item.posterUrl;
    final saved = ref.watch(
      isInWatchlistProvider((
        tmdbId: widget.item.tmdbId,
        mediaType: widget.item.mediaType,
      )),
    );

    return FocusableActionDetector(
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _focused = true),
        onExit: (_) => setState(() => _focused = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            scale: _focused ? 1.045 : 1,
            child: SizedBox(
              width: 286,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    height: 161,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _focused
                            ? AppColors.gold
                            : Colors.white.withValues(alpha: 0.08),
                        width: _focused ? 1.4 : 0.7,
                      ),
                      boxShadow: [
                        if (_focused) ...[
                          const BoxShadow(
                            color: Color(0x88000000),
                            blurRadius: 26,
                            offset: Offset(0, 14),
                          ),
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.22),
                            blurRadius: 24,
                            offset: const Offset(0, 0),
                          ),
                        ],
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
                        // Tiny localized darken behind the title strip only —
                        // covers the bottom ~22% so artwork stays vibrant
                        // everywhere else.
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 56,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Color(0xB3000000),
                                  Color(0x00000000),
                                ],
                              ),
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
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => ref
                                .read(watchlistProvider.notifier)
                                .toggle(widget.item),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: saved
                                    ? AppColors.gold
                                    : AppColors.ink.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: saved
                                      ? AppColors.gold
                                      : Colors.white24,
                                  width: 1,
                                ),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  saved
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_add_outlined,
                                  key: ValueKey(saved),
                                  size: 16,
                                  color: saved ? AppColors.ink : AppColors.gold,
                                ),
                              ),
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
                              shadows: [
                                Shadow(
                                  color: Color(0xCC000000),
                                  offset: Offset(0, 1),
                                  blurRadius: 8,
                                ),
                                Shadow(
                                  color: Color(0x66000000),
                                  offset: Offset(0, 0),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: _focused ? 1 : 0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            child: Center(
                              child: AnimatedScale(
                                scale: _focused ? 1 : 0.85,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutBack,
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.gold,
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x55000000),
                                        blurRadius: 18,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: AppColors.ink,
                                    size: 30,
                                  ),
                                ),
                              ),
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
                      if (widget.item.voteAverage > 0) ...[
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.gold,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          widget.item.voteAverage.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
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
