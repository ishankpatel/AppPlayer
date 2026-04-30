import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/media_item.dart';
import 'media_card.dart';

class ContentRow extends StatefulWidget {
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
  State<ContentRow> createState() => _ContentRowState();
}

class _ContentRowState extends State<ContentRow> {
  final _controller = ScrollController();
  late List<MediaItem> _items;
  int _page = 1;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _emptyPageStrikes = 0;

  @override
  void initState() {
    super.initState();
    _items = _dedupe(widget.items);
    _controller.addListener(_maybeLoadMore);
  }

  @override
  void didUpdateWidget(covariant ContentRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title || oldWidget.items != widget.items) {
      _items = _dedupe(widget.items);
      _page = 1;
      _hasMore = true;
      _loadingMore = false;
      _emptyPageStrikes = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (widget.onLoadMore == null || _loadingMore || !_hasMore) return;
    if (!_controller.hasClients) return;
    if (_controller.position.extentAfter > 760) return;
    _loadMore();
  }

  Future<void> _loadMore() async {
    final loader = widget.onLoadMore;
    if (loader == null) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final nextItems = await loader(nextPage);
      if (!mounted) return;
      final merged = _dedupe([..._items, ...nextItems]);
      final addedItems = merged.length > _items.length;
      setState(() {
        _page = nextPage;
        _loadingMore = false;
        _emptyPageStrikes = addedItems ? 0 : _emptyPageStrikes + 1;
        _hasMore = nextItems.isNotEmpty && _emptyPageStrikes < 2;
        _items = merged;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _hasMore = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(34, 0, 34, 12),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 9),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.gold,
                  size: 20,
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    _hasMore
                        ? '${_items.length} loaded'
                        : '${_items.length} titles',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 204,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              controller: _controller,
              itemCount: _items.length + (_hasMore ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                if (index >= _items.length) {
                  return _LoadMoreCard(
                    loading: _loadingMore,
                    onTap: _loadingMore ? null : _loadMore,
                  );
                }
                final item = _items[index];
                return MediaCard(
                  item: item,
                  onTap: () => context.push('/detail', extra: item),
                );
              },
            ),
          ),
        ],
      ),
    );
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
