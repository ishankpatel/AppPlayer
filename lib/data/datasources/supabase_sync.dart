import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/media_item.dart';

class SupabaseSyncDataSource {
  SupabaseSyncDataSource({required this.enabled});

  final bool enabled;

  SupabaseClient? get _client {
    if (!enabled) return null;
    return Supabase.instance.client;
  }

  Future<void> upsertWatchlist(MediaItem item, String userId) async {
    final client = _client;
    if (client == null) return;

    await client.from('watchlist').upsert({
      'user_id': userId,
      'tmdb_id': item.tmdbId,
      'media_type': item.mediaType.name,
      'title': item.title,
      'poster_path': item.posterPath,
      'backdrop_path': item.backdropPath,
    });
  }

  Future<void> upsertFavorite(MediaItem item, String userId) async {
    final client = _client;
    if (client == null) return;

    await client.from('favorites').upsert({
      'user_id': userId,
      'tmdb_id': item.tmdbId,
      'media_type': item.mediaType.name,
      'title': item.title,
      'poster_path': item.posterPath,
      'backdrop_path': item.backdropPath,
    });
  }

  Future<void> upsertContinueWatching({
    required int tmdbId,
    required String mediaType,
    required String title,
    required int positionSeconds,
    required int durationSeconds,
    String? posterPath,
    int? seasonNumber,
    int? episodeNumber,
    String? episodeTitle,
  }) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;

    await client.from('continue_watching').upsert({
      'user_id': userId,
      'tmdb_id': tmdbId,
      'media_type': mediaType,
      'title': title,
      'poster_path': posterPath,
      'season_number': seasonNumber,
      'episode_number': episodeNumber,
      'episode_title': episodeTitle,
      'position_seconds': positionSeconds,
      'duration_seconds': durationSeconds,
      'last_watched_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<bool> startAnonymousSession() async {
    final client = _client;
    if (client == null) return false;
    if (client.auth.currentUser != null) return true;
    await client.auth.signInAnonymously();
    return client.auth.currentUser != null;
  }

  bool get hasSession => _client?.auth.currentUser != null;
}
