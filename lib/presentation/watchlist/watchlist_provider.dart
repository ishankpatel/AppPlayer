import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/watchlist_store.dart';
import '../../data/models/media_item.dart';

final watchlistStoreProvider = Provider<WatchlistStore>((ref) {
  return WatchlistStore();
});

class WatchlistNotifier extends AsyncNotifier<List<WatchlistRecord>> {
  WatchlistStore get _store => ref.read(watchlistStoreProvider);

  @override
  Future<List<WatchlistRecord>> build() async {
    ref.keepAlive();
    return _store.load();
  }

  bool contains(MediaItem item) {
    final list = state.value ?? const <WatchlistRecord>[];
    final key = '${item.mediaType.name}:${item.tmdbId}';
    return list.any((r) => r.key == key);
  }

  bool containsKey(int tmdbId, MediaType type) {
    final list = state.value ?? const <WatchlistRecord>[];
    final key = '${type.name}:$tmdbId';
    return list.any((r) => r.key == key);
  }

  Future<void> add(MediaItem item) async {
    final current = [...(state.value ?? const <WatchlistRecord>[])];
    final key = '${item.mediaType.name}:${item.tmdbId}';
    if (current.any((r) => r.key == key)) return;
    final record = WatchlistRecord.fromMedia(item);
    current.insert(0, record);
    state = AsyncValue.data(current);
    await _store.save(current);
  }

  Future<void> remove(MediaItem item) async {
    final current = [...(state.value ?? const <WatchlistRecord>[])];
    final key = '${item.mediaType.name}:${item.tmdbId}';
    current.removeWhere((r) => r.key == key);
    state = AsyncValue.data(current);
    await _store.save(current);
  }

  Future<bool> toggle(MediaItem item) async {
    if (contains(item)) {
      await remove(item);
      return false;
    }
    await add(item);
    return true;
  }

  Future<void> clear() async {
    state = const AsyncValue.data([]);
    await _store.save(const []);
  }
}

final watchlistProvider =
    AsyncNotifierProvider<WatchlistNotifier, List<WatchlistRecord>>(
  WatchlistNotifier.new,
);

/// Convenience: returns whether `tmdbId/type` is currently saved. Updates
/// automatically when the watchlist changes because it watches the underlying
/// async value.
final isInWatchlistProvider =
    Provider.family<bool, ({int tmdbId, MediaType mediaType})>((ref, key) {
  final async = ref.watch(watchlistProvider);
  return async.maybeWhen(
    data: (records) => records.any(
      (r) => r.tmdbId == key.tmdbId && r.mediaType == key.mediaType,
    ),
    orElse: () => false,
  );
});
