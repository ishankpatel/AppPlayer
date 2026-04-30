import '../datasources/supabase_sync.dart';
import '../models/media_item.dart';

class SyncRepository {
  SyncRepository(this._remote);

  final SupabaseSyncDataSource _remote;

  Future<void> addToWatchlist(MediaItem item, String userId) {
    return _remote.upsertWatchlist(item, userId);
  }

  Future<void> addFavorite(MediaItem item, String userId) {
    return _remote.upsertFavorite(item, userId);
  }

  Future<void> syncContinueWatching({
    required int tmdbId,
    required String mediaType,
    required String title,
    required int positionSeconds,
    required int durationSeconds,
    String? posterPath,
    int? seasonNumber,
    int? episodeNumber,
  }) {
    return _remote.upsertContinueWatching(
      tmdbId: tmdbId,
      mediaType: mediaType,
      title: title,
      positionSeconds: positionSeconds,
      durationSeconds: durationSeconds,
      posterPath: posterPath,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
  }

  Future<bool> startCloudSession() {
    return _remote.startAnonymousSession();
  }

  bool get hasCloudSession => _remote.hasSession;
}
