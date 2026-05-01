import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/media_item.dart';
import '../row_cache.dart';
import 'media_card.dart';

class ContentRow extends ConsumerStatefulWidget {
  const ContentRow({
    required this.title,
    required this.items,
    this.onLoadMore,
    super.key,
  });

  final String title;
  final List<MediaItem> items;
  final Future<List<MediaItem>> Function(int nextPage)? onLoadMore;

  @override
  ConsumerState<ContentRow> createState() => _ContentRowState();
}

class _ContentRowState extends ConsumerState<ContentRow> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_maybeLoadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(rowCacheProvider.notifier).get(widget.title, widget.items);
    });
  }

  @override
  void didUpdateWidget(covariant ContentRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(rowCacheProvider.notifier).get(widget.title, widget.items);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    final loader = widget.onLoadMore;
    if (loader == null) return;
    final entry = ref.read(rowCacheProvider)[widget.title];
    if (entry == null || entry.loading || !entry.hasMore) return;
    if (!_controller.hasClients) return;
    if (_controller.position.extentAfter > 760) return;
    _loadMore();
  }

  Future<void> _loadMore() async {
    final loader = widget.onLoadMore;
    if (loader == null) return;
    await ref
        .read(rowCacheProvider.notifier)
        .loadMore(widget.title, fetcher: loader);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 720;
    final horizontalPadding = compact ? 18.0 : 34.0;
    final spacing = compact ? 12.0 : 14.0;
    final cardWidth = compact
        ? (screenWidth * 0.76).clamp(232.0, 286.0).toDouble()
        : 286.0;
    final cardHeight = cardWidth * 9 / 16;
    final rowHeight = cardHeight + (compact ? 42.0 : 43.0);

    final cache = ref.watch(rowCacheProvider);
    final entry =
        cache[widget.title] ?? RowCacheEntry(items: _dedupe(widget.items));
    final items = entry.items.isEmpty ? _dedupe(widget.items) : entry.items;
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 28 : 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              12,
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.gold,
                  size: 20,
                ),
                const Spacer(),
                if (entry.loading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      valueColor: AlwaysStoppedAnimation(AppColors.gold),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: rowHeight,
            child: _EdgeFade(
              enabled: !compact,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                scrollDirection: Axis.horizontal,
                physics: compact
                    ? const ClampingScrollPhysics()
                    : const BouncingScrollPhysics(),
                cacheExtent: cardWidth * 3,
                controller: _controller,
                itemCount: items.length + (entry.hasMore ? 1 : 0),
                separatorBuilder: (context, index) => SizedBox(width: spacing),
                itemBuilder: (context, index) {
                  if (index >= items.length) {
                    return _LoadMoreCard(
                      width: cardWidth,
                      height: cardHeight,
                      loading: entry.loading,
                      onTap: entry.loading ? null : _loadMore,
                    );
                  }
                  final item = items[index];
                  return MediaCard(
                    item: item,
                    width: cardWidth,
                    imageHeight: cardHeight,
                    onTap: () => context.push('/detail', extra: item),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<MediaItem> _dedupe(Iterable<MediaItem> items) {
    final seen = <String>{};
    final output = <MediaItem>[];
    for (final item in items) {
      final key = '${item.mediaType.name}:${item.tmdbId}';
      if (seen.add(key)) output.add(item);
    }
    return output;
  }
}

class _EdgeFade extends StatelessWidget {
  const _EdgeFade({required this.child, required this.enabled});

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0, 0.04, 0.96, 1],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}

class _LoadMoreCard extends StatelessWidget {
  const _LoadMoreCard({
    required this.loading,
    required this.onTap,
    required this.width,
    required this.height,
  });

  final bool loading;
  final VoidCallback? onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: loading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Column(
                  key: ValueKey('more'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.gold,
                      size: 28,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'More titles',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Loaded on demand',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
