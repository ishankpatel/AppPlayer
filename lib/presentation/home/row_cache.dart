import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/media_item.dart';
import '../../providers.dart';

/// Cached pagination state for one row title. Survives tab swaps so the user
/// never sees previously paginated titles disappear.
class RowCacheEntry {
  RowCacheEntry({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.emptyStrikes = 0,
    this.loading = false,
  });

  final List<MediaItem> items;
  final int page;
  final bool hasMore;
  final int emptyStrikes;
  final bool loading;

  RowCacheEntry copyWith({
    List<MediaItem>? items,
    int? page,
    bool? hasMore,
    int? emptyStrikes,
    bool? loading,
  }) {
    return RowCacheEntry(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      emptyStrikes: emptyStrikes ?? this.emptyStrikes,
      loading: loading ?? this.loading,
    );
  }
}

class RowCacheNotifier extends Notifier<Map<String, RowCacheEntry>> {
  @override
  Map<String, RowCacheEntry> build() {
    ref.keepAlive();
    return {};
  }

  RowCacheEntry get(String title, List<MediaItem> initial) {
    final existing = state[title];
    if (existing != null) return existing;
    final fresh = RowCacheEntry(items: _dedupe(initial));
    state = {...state, title: fresh};
    return fresh;
  }

  void replaceItems(String title, List<MediaItem> items) {
    final entry = state[title] ?? RowCacheEntry();
    state = {
      ...state,
      title: entry.copyWith(items: _dedupe(items), page: 1, hasMore: true),
    };
  }

  Future<List<MediaItem>> loadMore(
    String title, {
    required Future<List<MediaItem>> Function(int page) fetcher,
  }) async {
    final entry = state[title] ?? RowCacheEntry();
    if (entry.loading || !entry.hasMore) return entry.items;
    state = {...state, title: entry.copyWith(loading: true)};
    try {
      final nextPage = entry.page + 1;
      final fresh = await fetcher(nextPage);
      final merged = _dedupe([...entry.items, ...fresh]);
      final added = merged.length > entry.items.length;
      final strikes = added ? 0 : entry.emptyStrikes + 1;
      state = {
        ...state,
        title: RowCacheEntry(
          items: merged,
          page: nextPage,
          hasMore: fresh.isNotEmpty && strikes < 2,
          emptyStrikes: strikes,
          loading: false,
        ),
      };
      return merged;
    } catch (_) {
      state = {
        ...state,
        title: entry.copyWith(loading: false, hasMore: false),
      };
      return entry.items;
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
}

final rowCacheProvider =
    NotifierProvider<RowCacheNotifier, Map<String, RowCacheEntry>>(
  RowCacheNotifier.new,
);

/// Helper that wires a row title to the shared cache.
typedef CategoryFetcher = Future<List<MediaItem>> Function(int page);

CategoryFetcher categoryFetcherFor(WidgetRef ref, String title) {
  final repo = ref.read(mediaRepositoryProvider);
  return (page) => repo.loadMoreCategory(title, page: page);
}
