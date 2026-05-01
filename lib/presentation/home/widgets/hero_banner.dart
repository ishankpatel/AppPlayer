import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/media_item.dart';
import '../../common/smart_network_image.dart';
import '../../watchlist/watchlist_provider.dart';

class HeroBanner extends StatefulWidget {
  const HeroBanner({
    required this.items,
    required this.onPlay,
    required this.onMoreInfo,
    this.advanceDuration = const Duration(seconds: 9),
    super.key,
  });

  final List<MediaItem> items;
  final void Function(MediaItem item) onPlay;
  final void Function(MediaItem item) onMoreInfo;
  final Duration advanceDuration;

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> with TickerProviderStateMixin {
  late final AnimationController _progress;
  int _index = 0;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _progress =
        AnimationController(vsync: this, duration: widget.advanceDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              _advance(1);
            }
          });
    if (widget.items.length > 1) _progress.forward();
  }

  @override
  void didUpdateWidget(covariant HeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      if (_index >= widget.items.length) _index = 0;
      _restartProgress();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _advance(int delta) {
    if (widget.items.length <= 1) return;
    setState(() {
      _index = (_index + delta) % widget.items.length;
      if (_index < 0) _index += widget.items.length;
    });
    _restartProgress();
  }

  void _restartProgress() {
    if (widget.items.length <= 1) {
      _progress.stop();
      return;
    }
    _progress
      ..reset()
      ..forward();
  }

  void _setHover(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
    if (value) {
      _progress.stop();
    } else if (widget.items.length > 1) {
      _progress.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final size = MediaQuery.sizeOf(context);
    final height = size.width < 720
        ? (size.height * 0.66).clamp(460.0, 560.0).toDouble()
        : (size.height * 0.72).clamp(560.0, 720.0).toDouble();
    final item = widget.items[_index.clamp(0, widget.items.length - 1)];

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 340),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _AnimatedBackdrop(
                key: ValueKey('hero-${item.tmdbId}-${item.mediaType.name}'),
                item: item,
                progress: _progress,
              ),
            ),
            const _HeroScrim(),
            Align(
              alignment: Alignment.bottomLeft,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.04),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _HeroCopy(
                  key: ValueKey('copy-${item.tmdbId}-${item.mediaType.name}'),
                  item: item,
                  onPlay: () => widget.onPlay(item),
                  onMoreInfo: () => widget.onMoreInfo(item),
                ),
              ),
            ),
            Positioned(
              right: 56,
              bottom: 66,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                child: _Poster(
                  key: ValueKey('poster-${item.tmdbId}'),
                  item: item,
                ),
              ),
            ),
            if (widget.items.length > 1)
              Positioned(
                left: 34,
                right: 34,
                bottom: 24,
                child: _HeroIndicator(
                  count: widget.items.length,
                  index: _index,
                  progress: _progress,
                ),
              ),
            if (widget.items.length > 1)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_hovered,
                  child: AnimatedOpacity(
                    opacity: _hovered ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: _HeroNav(
                      onPrev: () => _advance(-1),
                      onNext: () => _advance(1),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroScrim extends StatelessWidget {
  const _HeroScrim();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        // Very soft left wash so the title/copy stays legible without
        // veiling the artwork. Fades to fully transparent before the
        // 50% mark.
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0x99060607),
                  Color(0x33060607),
                  Color(0x00000000),
                ],
                stops: [0, 0.22, 0.48],
              ),
            ),
          ),
        ),
        // Razor-thin bottom blend — only 12% — to soften the seam where
        // the row strip starts. No more dark band across the artwork.
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.ink, Color(0x00060607)],
                stops: [0, 0.12],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCopy extends ConsumerWidget {
  const _HeroCopy({
    required this.item,
    required this.onPlay,
    required this.onMoreInfo,
    super.key,
  });

  final MediaItem item;
  final VoidCallback onPlay;
  final VoidCallback onMoreInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    final saved = ref.watch(
      isInWatchlistProvider((tmdbId: item.tmdbId, mediaType: item.mediaType)),
    );
    final compactFilledStyle = compact
        ? FilledButton.styleFrom(
            minimumSize: const Size(100, 42),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          )
        : null;
    final compactOutlinedStyle = compact
        ? OutlinedButton.styleFrom(
            minimumSize: const Size(96, 42),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          )
        : null;
    final myListStyle = saved
        ? OutlinedButton.styleFrom(
            foregroundColor: AppColors.gold,
            side: const BorderSide(color: AppColors.gold),
            minimumSize: compact ? const Size(88, 42) : null,
            padding: compact
                ? const EdgeInsets.symmetric(horizontal: 12)
                : null,
          )
        : compactOutlinedStyle;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 18 : 34,
        0,
        compact ? 18 : 34,
        compact ? 70 : 90,
      ),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w900,
                height: 0.96,
                letterSpacing: 0,
                fontSize: compact ? 36 : null,
                shadows: const [
                  Shadow(
                    color: Color(0xCC000000),
                    offset: Offset(0, 2),
                    blurRadius: 14,
                  ),
                  Shadow(
                    color: Color(0x66000000),
                    offset: Offset(0, 0),
                    blurRadius: 28,
                  ),
                ],
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
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.text.withValues(alpha: 0.92),
                height: 1.45,
                shadows: const [
                  Shadow(
                    color: Color(0xAA000000),
                    offset: Offset(0, 1),
                    blurRadius: 10,
                  ),
                  Shadow(
                    color: Color(0x66000000),
                    offset: Offset(0, 0),
                    blurRadius: 18,
                  ),
                ],
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
                  style: compactFilledStyle,
                ),
                OutlinedButton.icon(
                  onPressed: onMoreInfo,
                  icon: const Icon(Icons.info_outline_rounded),
                  label: const Text('More Info'),
                  style: compactOutlinedStyle,
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(watchlistProvider.notifier).toggle(item),
                  icon: Icon(saved ? Icons.check_rounded : Icons.add_rounded),
                  label: Text(saved ? 'In My List' : 'My List'),
                  style: myListStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBackdrop extends StatelessWidget {
  const _AnimatedBackdrop({
    required this.item,
    required this.progress,
    super.key,
  });

  final MediaItem item;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final scale = 1.0 + (progress.value * 0.06);
        final shift = progress.value * 12;
        return Transform.translate(
          offset: Offset(-shift, 0),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: _Backdrop(item: item),
    );
  }
}

class _HeroIndicator extends StatelessWidget {
  const _HeroIndicator({
    required this.count,
    required this.index,
    required this.progress,
  });

  final int count;
  final int index;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: i == index ? 36 : 8,
              height: 4,
              decoration: BoxDecoration(
                color: i == index
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(2),
              ),
              child: i == index
                  ? AnimatedBuilder(
                      animation: progress,
                      builder: (context, _) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: progress.value.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}

class _HeroNav extends StatelessWidget {
  const _HeroNav({required this.onPrev, required this.onNext});

  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 12,
          top: 0,
          bottom: 0,
          child: Center(
            child: _HeroNavButton(
              icon: Icons.chevron_left_rounded,
              onTap: onPrev,
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 0,
          bottom: 0,
          child: Center(
            child: _HeroNavButton(
              icon: Icons.chevron_right_rounded,
              onTap: onNext,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroNavButton extends StatelessWidget {
  const _HeroNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.text, size: 26),
        ),
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
    final size = MediaQuery.sizeOf(context);

    return SmartNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      cacheWidth: size.width,
      cacheHeight: (size.height * 0.75).clamp(460.0, 760.0).toDouble(),
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
  const _Poster({required this.item, super.key});

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
        cacheWidth: 168,
        cacheHeight: 252,
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
