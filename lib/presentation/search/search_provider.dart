import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/media_item.dart';
import '../../providers.dart';

class SearchResult {
  const SearchResult({
    required this.query,
    required this.items,
  });

  final String query;
  final List<MediaItem> items;

  static const empty = SearchResult(query: '', items: []);
}

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) {
    state = value;
  }
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

/// 300ms debounced live search across TMDB.searchMulti + Cinemeta searchAll
/// (movie + series). Results are deduped by `${type}:${tmdbId}`.
final liveSearchProvider = FutureProvider<SearchResult>((ref) async {
  final raw = ref.watch(searchQueryProvider).trim();
  if (raw.length < 2) return SearchResult.empty;

  // Debounce: any new query during this 300ms window cancels and restarts.
  var cancelled = false;
  ref.onDispose(() => cancelled = true);
  await Future<void>.delayed(const Duration(milliseconds: 300));
  if (cancelled) return SearchResult.empty;

  final tmdb = ref.read(tmdbRemoteProvider);
  final cinemeta = ref.read(cinemetaRemoteProvider);

  final results = await Future.wait([
    tmdb.searchMulti(query: raw).catchError((_) => const <MediaItem>[]),
    cinemeta
        .searchAll(query: raw, mediaType: MediaType.movie)
        .catchError((_) => const <MediaItem>[]),
    cinemeta
        .searchAll(query: raw, mediaType: MediaType.tv)
        .catchError((_) => const <MediaItem>[]),
  ]);

  if (cancelled) return SearchResult.empty;

  final seen = <String>{};
  final merged = <MediaItem>[];
  for (final list in results) {
    for (final item in list) {
      final key = '${item.mediaType.name}:${item.tmdbId}';
      if (seen.add(key)) merged.add(item);
    }
  }

  // Local sample fallback for offline/rate-limited cases.
  if (merged.isEmpty) {
    final lower = raw.toLowerCase();
    for (final item in MediaItem.samples) {
      final haystack = [
        item.title,
        item.genre,
        item.releaseYear,
        item.mediaTypeLabel,
        ...item.tags,
      ].join(' ').toLowerCase();
      if (haystack.contains(lower)) merged.add(item);
    }
  }

  return SearchResult(query: raw, items: merged);
});
