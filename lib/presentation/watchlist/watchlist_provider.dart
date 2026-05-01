import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/watchlist_store.dart';
import '../../data/models/media_item.dart';
import '../../providers.dart';

final watchlistStoreProvider = Provider<WatchlistStore>((ref) {
  return WatchlistStore();
});

class WatchlistNotifier extends AsyncNotifier<List<WatchlistRecord>> {
  WatchlistStore get _store => ref.read(watchlistStoreProvider);

  @override
  Future<List<WatchlistRecord>> build() async {
    ref.keepAlive();
    final local = await _store.load();
    final userId = ref.read(syncRepositoryProvider).currentUserId;
    if (userId == null) return local;

    final cloudRows = await ref
        .read(syncRepositoryProvider)
        .watchlistFor(userId);
    final merged = <String, WatchlistRecord>{
      for (final record in local) record.key: record,
      for (final row in cloudRows)
        WatchlistRecord.fromSupabase(row).key: WatchlistRecord.fromSupabase(
          row,
        ),
    }.values.toList()..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    await _store.save(merged);
    return merged;
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
    final userId = ref.read(syncRepositoryProvider).currentUserId;
    if (userId != null) {
      await ref.read(syncRepositoryProvider).addToWatchlist(item, userId);
    }
  }

  Future<void> remove(MediaItem item) async {
    final current = [...(state.value ?? const <WatchlistRecord>[])];
    final key = '${item.mediaType.name}:${item.tmdbId}';
    current.removeWhere((r) => r.key == key);
    state = AsyncValue.data(current);
    await _store.save(current);
    final userId = ref.read(syncRepositoryProvider).currentUserId;
    if (userId != null) {
      await ref.read(syncRepositoryProvider).removeFromWatchlist(item, userId);
    }
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
