import 'package:drift/drift.dart';

import '../models/playback_progress.dart';

class CachedMediaItem {
  const CachedMediaItem({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    required this.genre,
    required this.releaseYear,
    required this.overview,
    required this.voteAverage,
    this.posterPath,
    this.backdropPath,
  });

  final int tmdbId;
  final String mediaType;
  final String title;
  final String genre;
  final String releaseYear;
  final String overview;
  final double voteAverage;
  final String? posterPath;
  final String? backdropPath;
}

class CachedMediaItemsCompanion {
  const CachedMediaItemsCompanion({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    required this.genre,
    required this.releaseYear,
    required this.overview,
    required this.voteAverage,
    required this.posterPath,
    required this.backdropPath,
  });

  final Value<int> tmdbId;
  final Value<String> mediaType;
  final Value<String> title;
  final Value<String> genre;
  final Value<String> releaseYear;
  final Value<String> overview;
  final Value<double> voteAverage;
  final Value<String?> posterPath;
  final Value<String?> backdropPath;
}

class StreamVaultDatabase {
  final List<CachedMediaItem> _items = [];
  final List<PlaybackProgress> _playback = [];

  Future<void> upsertCachedMedia(List<CachedMediaItemsCompanion> items) async {
    for (final item in items) {
      final cached = CachedMediaItem(
        tmdbId: item.tmdbId.value,
        mediaType: item.mediaType.value,
        title: item.title.value,
        genre: item.genre.value,
        releaseYear: item.releaseYear.value,
        overview: item.overview.value,
        voteAverage: item.voteAverage.value,
        posterPath: item.posterPath.value,
        backdropPath: item.backdropPath.value,
      );
      _items.removeWhere(
        (existing) =>
            existing.tmdbId == cached.tmdbId &&
            existing.mediaType == cached.mediaType,
      );
      _items.add(cached);
    }
  }

  Future<List<CachedMediaItem>> getCachedMedia() async => List.of(_items);

  Future<void> savePlaybackProgress({
    required int tmdbId,
    required String mediaType,
    required int positionSeconds,
    required int durationSeconds,
    int? seasonNumber,
    int? episodeNumber,
    String? preferredSubtitleLang,
    String? preferredAudioLang,
  }) async {
    _playback.removeWhere(
      (entry) =>
          entry.tmdbId == tmdbId &&
          entry.mediaType == mediaType &&
          entry.seasonNumber == seasonNumber &&
          entry.episodeNumber == episodeNumber,
    );
    _playback.add(
      PlaybackProgress(
        tmdbId: tmdbId,
        mediaType: mediaType,
        positionSeconds: positionSeconds,
        durationSeconds: durationSeconds,
        updatedAt: DateTime.now(),
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
      ),
    );
  }

  Future<List<PlaybackProgress>> getRecentPlayback({int limit = 20}) async {
    final entries = [..._playback]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return entries.take(limit).toList();
  }

  Future<void> close() async {}
}
