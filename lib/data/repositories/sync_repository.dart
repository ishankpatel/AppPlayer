import '../datasources/supabase_sync.dart';
import '../models/media_item.dart';

class SyncRepository {
  SyncRepository(this._remote);

  final SupabaseSyncDataSource _remote;

  Future<void> addToWatchlist(MediaItem item, String userId) {
    return _remote.upsertWatchlist(item, userId);
  }

  Future<void> removeFromWatchlist(MediaItem item, String userId) {
    return _remote.deleteWatchlist(
      tmdbId: item.tmdbId,
      mediaType: item.mediaType.name,
      userId: userId,
    );
  }

  Future<List<Map<String, dynamic>>> watchlistFor(String userId) {
    return _remote.watchlistFor(userId);
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
    String? preferredSubtitleLang,
    String? preferredAudioLang,
    String? backdropPath,
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
      preferredSubtitleLang: preferredSubtitleLang,
      preferredAudioLang: preferredAudioLang,
      backdropPath: backdropPath,
    );
  }

  Future<List<Map<String, dynamic>>> continueWatchingFor(String userId) {
    return _remote.continueWatchingFor(userId);
  }

  Future<Map<String, dynamic>?> currentProfile() {
    return _remote.currentProfile();
  }

  Future<void> syncProfilePreferences({
    String? preferredSubtitleLang,
    String? preferredAudioLang,
  }) {
    return _remote.upsertProfilePreferences(
      preferredSubtitleLang: preferredSubtitleLang,
      preferredAudioLang: preferredAudioLang,
    );
  }

  Future<bool> startCloudSession() {
    return _remote.startAnonymousSession();
  }

  Future<bool> startHouseholdSession({
    required String email,
    required String password,
  }) {
    return _remote.startHouseholdSession(email: email, password: password);
  }

  bool get hasCloudSession => _remote.hasSession;

  String? get currentUserId => _remote.currentUserId;
}
