import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/media_item.dart';
import '../../data/repositories/media_repository.dart';
import '../../providers.dart';

/// Loaded once per app launch and kept alive forever so flipping between
/// tabs (Home/Movies/TV/Anime/Sports/My List) or visiting Settings/Search
/// never re-fetches the catalog.
final homeFeedProvider = FutureProvider<HomeFeed>((ref) async {
  ref.keepAlive();
  return ref.watch(mediaRepositoryProvider).homeFeed();
});

final continueWatchingProvider = FutureProvider<List<MediaItem>>((ref) async {
  final feed = await ref.watch(homeFeedProvider.future);
  final merged = <String, MediaItem>{};
  final userId = ref.read(syncRepositoryProvider).currentUserId;

  if (userId != null) {
    final cloudRows = await ref
        .read(syncRepositoryProvider)
        .continueWatchingFor(userId);
    for (final row in cloudRows) {
      final item = _mediaFromContinueWatching(row);
      if (item != null) {
        merged['${item.mediaType.name}:${item.tmdbId}'] = item;
      }
    }
  }

  for (final item in feed.continueWatching) {
    merged.putIfAbsent('${item.mediaType.name}:${item.tmdbId}', () => item);
  }

  return merged.values.toList();
});

MediaItem? _mediaFromContinueWatching(Map<String, dynamic> row) {
  final tmdbId = (row['tmdb_id'] as num?)?.toInt() ?? 0;
  if (tmdbId <= 0) return null;
  final mediaType = (row['media_type'] as String? ?? 'movie') == 'tv'
      ? MediaType.tv
      : MediaType.movie;
  final position = (row['position_seconds'] as num?)?.toInt() ?? 0;
  final duration = (row['duration_seconds'] as num?)?.toInt() ?? 0;
  final progress = duration <= 0 ? 0.0 : (position / duration).clamp(0.0, 1.0);
  final seasonNumber = (row['season_number'] as num?)?.toInt();
  final episodeNumber = (row['episode_number'] as num?)?.toInt();
  final episodeTitle = row['episode_title'] as String?;
  final label = _resumeLabel(
    mediaType: mediaType,
    durationSeconds: duration,
    positionSeconds: position,
    seasonNumber: seasonNumber,
    episodeNumber: episodeNumber,
    episodeTitle: episodeTitle,
  );

  return MediaItem(
    tmdbId: tmdbId,
    title: row['title'] as String? ?? 'Continue Watching',
    mediaType: mediaType,
    genre: mediaType == MediaType.tv ? 'Series' : 'Movie',
    releaseYear: '',
    overview: '',
    voteAverage: 0,
    posterPath: row['poster_path'] as String?,
    backdropPath: row['backdrop_path'] as String?,
    progress: progress,
    seasonEpisodeLabel: label,
    seasons: mediaType == MediaType.tv ? MediaItem.sampleSeasons : const [],
  );
}

String _resumeLabel({
  required MediaType mediaType,
  required int durationSeconds,
  required int positionSeconds,
  int? seasonNumber,
  int? episodeNumber,
  String? episodeTitle,
}) {
  final remainingMinutes =
      ((durationSeconds - positionSeconds).clamp(0, durationSeconds) / 60)
          .ceil();
  final remaining = remainingMinutes > 0 ? ' - ${remainingMinutes}m left' : '';
  if (mediaType == MediaType.tv &&
      seasonNumber != null &&
      episodeNumber != null) {
    final episode = episodeTitle == null || episodeTitle.isEmpty
        ? 'S$seasonNumber E$episodeNumber'
        : 'S$seasonNumber E$episodeNumber · $episodeTitle';
    return '$episode$remaining';
  }
  return remainingMinutes > 0
      ? '$remainingMinutes minutes left'
      : 'Resume playback';
}
