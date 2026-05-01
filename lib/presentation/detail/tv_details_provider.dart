import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/media_item.dart';
import '../../providers.dart';

class TvSeasonSummary {
  const TvSeasonSummary({
    required this.seasonNumber,
    required this.name,
    required this.episodeCount,
    this.airDate,
    this.posterPath,
    this.overview = '',
  });

  final int seasonNumber;
  final String name;
  final int episodeCount;
  final String? airDate;
  final String? posterPath;
  final String overview;

  factory TvSeasonSummary.fromTmdb(Map<String, dynamic> json) {
    return TvSeasonSummary(
      seasonNumber: (json['season_number'] as num? ?? 1).toInt(),
      name: (json['name'] as String?) ?? 'Season',
      episodeCount: (json['episode_count'] as num? ?? 0).toInt(),
      airDate: json['air_date'] as String?,
      posterPath: json['poster_path'] as String?,
      overview: (json['overview'] as String?) ?? '',
    );
  }

  factory TvSeasonSummary.fromEpisodeGroup(
    int seasonNumber,
    List<Map<String, dynamic>> episodes,
  ) {
    final firstAirDates =
        episodes
            .map((episode) => episode['firstAired'] as String?)
            .where((value) => value != null && value.isNotEmpty)
            .cast<String>()
            .toList()
          ..sort();
    return TvSeasonSummary(
      seasonNumber: seasonNumber,
      name: seasonNumber == 0 ? 'Specials' : 'Season $seasonNumber',
      episodeCount: episodes.length,
      airDate: firstAirDates.isEmpty ? null : firstAirDates.first,
    );
  }
}

class TvDetails {
  const TvDetails({
    required this.tmdbId,
    required this.name,
    required this.overview,
    required this.seasons,
    this.numberOfEpisodes = 0,
    this.numberOfSeasons = 0,
    this.posterPath,
    this.backdropPath,
    this.firstAirDate,
    this.lastAirDate,
    this.tagline = '',
    this.status = '',
    this.genres = const [],
    this.networks = const [],
  });

  final int tmdbId;
  final String name;
  final String overview;
  final List<TvSeasonSummary> seasons;
  final int numberOfEpisodes;
  final int numberOfSeasons;
  final String? posterPath;
  final String? backdropPath;
  final String? firstAirDate;
  final String? lastAirDate;
  final String tagline;
  final String status;
  final List<String> genres;
  final List<String> networks;

  factory TvDetails.fromTmdb(Map<String, dynamic> json) {
    final seasons = ((json['seasons'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((s) => (s['season_number'] as num? ?? 0).toInt() >= 1)
        .map(TvSeasonSummary.fromTmdb)
        .toList();
    return TvDetails(
      tmdbId: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? 'Untitled',
      overview: (json['overview'] as String?) ?? '',
      seasons: seasons,
      numberOfEpisodes: (json['number_of_episodes'] as num? ?? 0).toInt(),
      numberOfSeasons: (json['number_of_seasons'] as num? ?? 0).toInt(),
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      firstAirDate: json['first_air_date'] as String?,
      lastAirDate: json['last_air_date'] as String?,
      tagline: (json['tagline'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      genres: ((json['genres'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((g) => (g['name'] as String?) ?? '')
          .where((s) => s.isNotEmpty)
          .toList(),
      networks: ((json['networks'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((g) => (g['name'] as String?) ?? '')
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }

  factory TvDetails.fromCinemeta(MediaItem item, Map<String, dynamic> json) {
    final videos = ((json['videos'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final video in videos) {
      final season = (video['season'] as num? ?? 0).toInt();
      if (season < 1) continue;
      grouped.putIfAbsent(season, () => <Map<String, dynamic>>[]).add(video);
    }
    final seasons =
        grouped.entries
            .map(
              (entry) =>
                  TvSeasonSummary.fromEpisodeGroup(entry.key, entry.value),
            )
            .toList()
          ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));
    return TvDetails(
      tmdbId: item.tmdbId,
      name: (json['name'] as String?) ?? item.title,
      overview:
          (json['description'] as String?) ??
          (json['overview'] as String?) ??
          item.overview,
      seasons: seasons,
      numberOfEpisodes: seasons.fold<int>(
        0,
        (sum, season) => sum + season.episodeCount,
      ),
      numberOfSeasons: seasons.length,
      posterPath: json['poster'] as String? ?? item.posterPath,
      backdropPath: json['background'] as String? ?? item.backdropPath,
      firstAirDate: json['released'] as String?,
      status: (json['status'] as String?) ?? '',
      genres: ((json['genres'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
    );
  }
}

class EpisodeDetails {
  const EpisodeDetails({
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    required this.overview,
    this.airDate,
    this.runtimeMinutes,
    this.stillPath,
    this.voteAverage = 0,
  });

  final int seasonNumber;
  final int episodeNumber;
  final String title;
  final String overview;
  final String? airDate;
  final int? runtimeMinutes;
  final String? stillPath;
  final double voteAverage;

  String get label => 'S$seasonNumber E$episodeNumber';
  String get runtimeLabel => runtimeMinutes == null ? '' : '${runtimeMinutes}m';

  factory EpisodeDetails.fromTmdb(Map<String, dynamic> json) {
    return EpisodeDetails(
      seasonNumber: (json['season_number'] as num? ?? 1).toInt(),
      episodeNumber: (json['episode_number'] as num? ?? 1).toInt(),
      title: (json['name'] as String?) ?? 'Episode',
      overview: (json['overview'] as String?) ?? '',
      airDate: json['air_date'] as String?,
      runtimeMinutes: (json['runtime'] as num?)?.toInt(),
      stillPath: json['still_path'] as String?,
      voteAverage: ((json['vote_average'] ?? 0) as num).toDouble(),
    );
  }

  factory EpisodeDetails.fromCinemeta(Map<String, dynamic> json) {
    return EpisodeDetails(
      seasonNumber: (json['season'] as num? ?? 1).toInt(),
      episodeNumber: (json['number'] as num? ?? json['episode'] as num? ?? 1)
          .toInt(),
      title: (json['name'] as String?) ?? 'Episode',
      overview:
          (json['overview'] as String?) ??
          (json['description'] as String?) ??
          '',
      airDate: json['firstAired'] as String? ?? json['released'] as String?,
      runtimeMinutes: null,
      stillPath: json['thumbnail'] as String?,
      voteAverage: double.tryParse((json['rating'] ?? '').toString()) ?? 0,
    );
  }
}

/// Cached per tvId — survives navigation. Only fetched once.
final tvDetailsProvider = FutureProvider.family<TvDetails?, int>((
  ref,
  tvId,
) async {
  ref.keepAlive();
  final tmdb = ref.read(tmdbRemoteProvider);
  if (!tmdb.isConfigured) return null;
  final raw = await tmdb.tvDetails(tvId);
  if (raw == null) return null;
  return TvDetails.fromTmdb(raw);
});

class TvDetailsKey {
  const TvDetailsKey({
    required this.tmdbId,
    required this.title,
    this.imdbId,
    this.mediaType = MediaType.tv,
    this.overview = '',
    this.posterPath,
    this.backdropPath,
  });

  final int tmdbId;
  final String title;
  final String? imdbId;
  final MediaType mediaType;
  final String overview;
  final String? posterPath;
  final String? backdropPath;

  factory TvDetailsKey.fromMedia(MediaItem media) {
    return TvDetailsKey(
      tmdbId: media.tmdbId,
      title: media.title,
      imdbId: media.imdbId,
      mediaType: media.mediaType,
      overview: media.overview,
      posterPath: media.posterPath,
      backdropPath: media.backdropPath,
    );
  }

  MediaItem get fallbackItem {
    return MediaItem(
      tmdbId: tmdbId,
      title: title,
      mediaType: mediaType,
      genre: 'Series',
      releaseYear: '',
      overview: overview,
      voteAverage: 0,
      posterPath: posterPath,
      backdropPath: backdropPath,
      imdbId: imdbId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TvDetailsKey &&
        tmdbId == other.tmdbId &&
        imdbId == other.imdbId &&
        mediaType == other.mediaType;
  }

  @override
  int get hashCode => Object.hash(tmdbId, imdbId, mediaType);
}

final tvDetailsForMediaProvider =
    FutureProvider.family<TvDetails?, TvDetailsKey>((ref, key) async {
      ref.keepAlive();
      final tmdb = ref.read(tmdbRemoteProvider);
      if (tmdb.isConfigured) {
        final raw = await tmdb.tvDetails(key.tmdbId);
        if (raw != null) return TvDetails.fromTmdb(raw);
      }

      final imdbId = key.imdbId ?? '';
      if (imdbId.isEmpty) return null;
      final raw = await ref
          .read(cinemetaRemoteProvider)
          .meta(imdbId: imdbId, mediaType: MediaType.tv);
      if (raw == null) return null;
      return TvDetails.fromCinemeta(key.fallbackItem, raw);
    });

class SeasonKey {
  const SeasonKey(this.tvId, this.seasonNumber, {this.imdbId});
  final int tvId;
  final int seasonNumber;
  final String? imdbId;

  @override
  bool operator ==(Object other) =>
      other is SeasonKey &&
      tvId == other.tvId &&
      seasonNumber == other.seasonNumber &&
      imdbId == other.imdbId;

  @override
  int get hashCode => Object.hash(tvId, seasonNumber, imdbId);
}

final tvSeasonProvider = FutureProvider.family<List<EpisodeDetails>, SeasonKey>(
  (ref, key) async {
    ref.keepAlive();
    final tmdb = ref.read(tmdbRemoteProvider);
    if (tmdb.isConfigured) {
      final raw = await tmdb.tvSeason(key.tvId, key.seasonNumber);
      if (raw != null) {
        final episodes = (raw['episodes'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(EpisodeDetails.fromTmdb)
            .toList();
        if (episodes.isNotEmpty) return episodes;
      }
    }

    final imdbId = key.imdbId ?? '';
    if (imdbId.isEmpty) return const [];
    final raw = await ref
        .read(cinemetaRemoteProvider)
        .meta(imdbId: imdbId, mediaType: MediaType.tv);
    if (raw == null) return const [];
    final episodes =
        ((raw['videos'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .where((episode) {
              final season = (episode['season'] as num? ?? 0).toInt();
              return season == key.seasonNumber;
            })
            .map(EpisodeDetails.fromCinemeta)
            .toList()
          ..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
    return episodes;
  },
);

/// Overall detail bundle (movie/tv). Used to fetch richer overview/runtime
/// text when the seed item only has minimal data.
final mediaDetailsProvider =
    FutureProvider.family<Map<String, dynamic>?, MediaItem>((ref, item) async {
      ref.keepAlive();
      final tmdb = ref.read(tmdbRemoteProvider);
      if (!tmdb.isConfigured) return null;
      return tmdb.details(tmdbId: item.tmdbId, mediaType: item.mediaType);
    });
