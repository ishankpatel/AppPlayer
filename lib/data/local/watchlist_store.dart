import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/media_item.dart';

/// Persists My List per device. Supabase sync merges cloud records into this
/// local list when a household session is active.
class WatchlistStore {
  static const _key = 'streamvault_watchlist';

  Future<List<WatchlistRecord>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.trim().isEmpty) return const [];
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(WatchlistRecord.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<WatchlistRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }
}

class WatchlistRecord {
  const WatchlistRecord({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    required this.releaseYear,
    required this.genre,
    required this.voteAverage,
    required this.addedAt,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.tags = const [],
  });

  final int tmdbId;
  final MediaType mediaType;
  final String title;
  final String releaseYear;
  final String genre;
  final double voteAverage;
  final DateTime addedAt;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final List<String> tags;

  factory WatchlistRecord.fromMedia(MediaItem item) {
    return WatchlistRecord(
      tmdbId: item.tmdbId,
      mediaType: item.mediaType,
      title: item.title,
      releaseYear: item.releaseYear,
      genre: item.genre,
      voteAverage: item.voteAverage,
      addedAt: DateTime.now(),
      posterPath: item.posterPath,
      backdropPath: item.backdropPath,
      overview: item.overview,
      tags: item.tags,
    );
  }

  factory WatchlistRecord.fromSupabase(Map<String, dynamic> json) {
    return WatchlistRecord(
      tmdbId: (json['tmdb_id'] as num?)?.toInt() ?? 0,
      mediaType: (json['media_type'] as String? ?? 'movie') == 'tv'
          ? MediaType.tv
          : MediaType.movie,
      title: (json['title'] as String?) ?? 'Untitled',
      releaseYear: '',
      genre: '',
      voteAverage: 0,
      addedAt:
          DateTime.tryParse((json['added_at'] as String?) ?? '') ??
          DateTime.now(),
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
    );
  }

  factory WatchlistRecord.fromJson(Map<String, dynamic> json) {
    return WatchlistRecord(
      tmdbId: (json['tmdbId'] as num?)?.toInt() ?? 0,
      mediaType: (json['mediaType'] as String? ?? 'movie') == 'tv'
          ? MediaType.tv
          : MediaType.movie,
      title: (json['title'] as String?) ?? 'Untitled',
      releaseYear: (json['releaseYear'] as String?) ?? '',
      genre: (json['genre'] as String?) ?? '',
      voteAverage: ((json['voteAverage'] as num?) ?? 0).toDouble(),
      addedAt:
          DateTime.tryParse((json['addedAt'] as String?) ?? '') ??
          DateTime.now(),
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      overview: json['overview'] as String?,
      tags: ((json['tags'] as List?) ?? const []).whereType<String>().toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tmdbId': tmdbId,
      'mediaType': mediaType.name,
      'title': title,
      'releaseYear': releaseYear,
      'genre': genre,
      'voteAverage': voteAverage,
      'addedAt': addedAt.toIso8601String(),
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'overview': overview,
      'tags': tags,
    };
  }

  String get key => '${mediaType.name}:$tmdbId';

  MediaItem toMedia() {
    return MediaItem(
      tmdbId: tmdbId,
      title: title,
      mediaType: mediaType,
      genre: genre.isEmpty
          ? (mediaType == MediaType.tv ? 'Series' : 'Movie')
          : genre,
      releaseYear: releaseYear,
      overview: overview ?? '',
      voteAverage: voteAverage,
      posterPath: posterPath,
      backdropPath: backdropPath,
      tags: tags,
      isInWatchlist: true,
    );
  }
}
