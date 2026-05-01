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
    final cache = ref.watch(rowCacheProvider);
    final entry = cache[widget.title] ??
        RowCacheEntry(items: _dedupe(widget.items));
    final items = entry.items.isEmpty ? _dedupe(widget.items) : entry.items;
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(34, 0, 34, 12),
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
            height: 204,
            child: ShaderMask(
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
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 34),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                controller: _controller,
                itemCount: items.length + (entry.hasMore ? 1 : 0),
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  if (index >= items.length) {
                    return _LoadMoreCard(
                      loading: entry.loading,
                      onTap: entry.loading ? null : _loadMore,
                    );
                  }
                  final item = items[index];
                  return MediaCard(
                    item: item,
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

class _LoadMoreCard extends StatelessWidget {
  const _LoadMoreCard({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 286,
        height: 161,
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
