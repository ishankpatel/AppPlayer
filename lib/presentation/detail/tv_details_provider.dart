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
}

/// Cached per tvId — survives navigation. Only fetched once.
final tvDetailsProvider =
    FutureProvider.family<TvDetails?, int>((ref, tvId) async {
  ref.keepAlive();
  final tmdb = ref.read(tmdbRemoteProvider);
  if (!tmdb.isConfigured) return null;
  final raw = await tmdb.tvDetails(tvId);
  if (raw == null) return null;
  return TvDetails.fromTmdb(raw);
});

class SeasonKey {
  const SeasonKey(this.tvId, this.seasonNumber);
  final int tvId;
  final int seasonNumber;

  @override
  bool operator ==(Object other) =>
      other is SeasonKey &&
      tvId == other.tvId &&
      seasonNumber == other.seasonNumber;

  @override
  int get hashCode => Object.hash(tvId, seasonNumber);
}

final tvSeasonProvider =
    FutureProvider.family<List<EpisodeDetails>, SeasonKey>((ref, key) async {
  ref.keepAlive();
  final tmdb = ref.read(tmdbRemoteProvider);
  if (!tmdb.isConfigured) return const [];
  final raw = await tmdb.tvSeason(key.tvId, key.seasonNumber);
  if (raw == null) return const [];
  final episodes = (raw['episodes'] as List? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(EpisodeDetails.fromTmdb)
      .toList();
  return episodes;
});

/// Overall detail bundle (movie/tv). Used to fetch richer overview/runtime
/// text when the seed item only has minimal data.
final mediaDetailsProvider =
    FutureProvider.family<Map<String, dynamic>?, MediaItem>((ref, item) async {
  ref.keepAlive();
  final tmdb = ref.read(tmdbRemoteProvider);
  if (!tmdb.isConfigured) return null;
  return tmdb.details(tmdbId: item.tmdbId, mediaType: item.mediaType);
});
