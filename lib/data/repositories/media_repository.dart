import 'package:drift/drift.dart';

import '../datasources/cinemeta_remote.dart';
import '../datasources/tmdb_remote.dart';
import '../local/local_database.dart';
import '../models/media_item.dart';
import '../models/playback_progress.dart';

const _homeRowTitles = [
  'Top on Netflix',
  'Trending Now',
  'Top Hindi',
  'Hindi Dubbed Hits',
  'New Releases',
  'Action & Thrillers',
  'Sci-Fi Vault',
  'Anime',
  'Series Worth Starting',
];

const _initialRowTitles = [
  ..._homeRowTitles,
  'Top Movies',
  'New Movies',
  'Action Movies',
  'Sci-Fi Movies',
  'Family Night',
  'Top TV Shows',
  'Popular Series',
  'Sci-Fi Series',
  'Action Series',
  'Anime & Animation',
  'Anime Spotlight',
  'Action Anime',
  'New Anime',
  'Bingeable Anime Series',
];

const _fallbackPageSize = 18;
const _fallbackMaxPages = 18;

class HomeFeed {
  const HomeFeed({
    required this.hero,
    required this.continueWatching,
    required this.homeRows,
    required this.movieRows,
    required this.tvRows,
    required this.animeRows,
    required this.myListRows,
  });

  final MediaItem hero;
  final List<MediaItem> continueWatching;
  final List<ContentCategory> homeRows;
  final List<ContentCategory> movieRows;
  final List<ContentCategory> tvRows;
  final List<ContentCategory> animeRows;
  final List<ContentCategory> myListRows;
}

class ContentCategory {
  const ContentCategory({required this.title, required this.items});

  final String title;
  final List<MediaItem> items;
}

class MediaRepository {
  MediaRepository(this._tmdb, this._cinemeta, this._database);

  final TmdbRemoteDataSource _tmdb;
  final CinemetaRemoteDataSource _cinemeta;
  final StreamVaultDatabase _database;

  Future<HomeFeed> homeFeed() async {
    final sample = MediaItem.samples;
    final recentPlayback = await _database.getRecentPlayback();

    try {
      final rowTitles = _initialRowTitles;
      final rowPages = await Future.wait(
        rowTitles.map((title) => loadMoreCategory(title, page: 1)),
      );
      final rowMap = {
        for (var i = 0; i < rowTitles.length; i++) rowTitles[i]: rowPages[i],
      };
      final dynamicItems = rowPages.expand((items) => items).toList();
      final cached = await _database.getCachedMedia();
      final catalog = _dedupe([
        ...dynamicItems,
        ...cached.map(_fromCache),
        ...sample,
      ]);
      final continueWatching = _continueWatching(catalog, recentPlayback);

      return HomeFeed(
        hero: (rowMap['Trending Now']?.isNotEmpty ?? false)
            ? rowMap['Trending Now']!.first.copyWith(isInWatchlist: true)
            : catalog.first.copyWith(isInWatchlist: true),
        continueWatching: continueWatching,
        homeRows: _buildHomeRows(rowMap: rowMap, sample: sample),
        movieRows: _buildMovieRows(rowMap: rowMap, sample: sample),
        tvRows: _buildTvRows(rowMap: rowMap, sample: sample),
        animeRows: _buildAnimeRows(rowMap: rowMap, sample: sample),
        myListRows: _buildMyListRows(sample, continueWatching),
      );
    } catch (_) {
      final cached = await _database.getCachedMedia();
      final cachedItems = cached.map(_fromCache).toList();
      final fallback = cachedItems.isNotEmpty ? cachedItems : sample;
      final continueWatching = _continueWatching(
        _dedupe([...fallback, ...sample]),
        recentPlayback,
      );
      return HomeFeed(
        hero: fallback.first,
        continueWatching: continueWatching,
        homeRows: _buildHomeRows(
          rowMap: _fallbackRowMap(fallback),
          sample: sample,
        ),
        movieRows: _buildMovieRows(
          rowMap: _fallbackRowMap(fallback),
          sample: sample,
        ),
        tvRows: _buildTvRows(rowMap: _fallbackRowMap(fallback), sample: sample),
        animeRows: _buildAnimeRows(
          rowMap: _fallbackRowMap(fallback),
          sample: sample,
        ),
        myListRows: _buildMyListRows(sample, continueWatching),
      );
    }
  }

  Future<List<MediaItem>> loadMoreCategory(
    String title, {
    required int page,
  }) async {
    final items = await _loadCategory(title, page);
    if (items.isNotEmpty) {
      await _cacheMedia(items);
    }
    return _dedupe(items);
  }

  Future<List<MediaItem>> _loadCategory(String title, int page) async {
    if (_tmdb.isConfigured) return _loadTmdbCategory(title, page);

    try {
      final cinemetaItems = await _loadCinemetaCategory(title, page);
      if (cinemetaItems.isNotEmpty) return cinemetaItems;
    } catch (_) {
      // Keep local fallback working when the public metadata service is offline.
    }

    return _fallbackCategory(title, page);
  }

  Future<List<MediaItem>> _loadTmdbCategory(String title, int page) {
    return switch (title) {
      'Trending Now' => _tmdb.trending(page: page),
      'Top Movies' => _tmdb.popularMovies(page: page),
      'Top TV Shows' ||
      'Popular Series' ||
      'Series Worth Starting' => _tmdb.popularTv(page: page),
      'Top on Netflix' => _tmdb.discoverTv(page: page, withNetworks: '213'),
      'Top Hindi' => _tmdb.discoverMovies(
        page: page,
        withOriginalLanguage: 'hi',
        region: 'IN',
      ),
      'Hindi Dubbed Hits' => _tmdb.discoverMovies(
        page: page,
        region: 'IN',
        withGenres: '28|12|53|878',
      ),
      'New Releases' || 'New Movies' => _tmdb.nowPlayingMovies(page: page),
      'Action & Thrillers' ||
      'Action Movies' => _tmdb.discoverMovies(page: page, withGenres: '28|53'),
      'Sci-Fi Vault' ||
      'Sci-Fi Movies' => _tmdb.discoverMovies(page: page, withGenres: '878'),
      'Family Night' => _tmdb.discoverMovies(
        page: page,
        withGenres: '10751|16',
      ),
      'Sci-Fi Series' => _tmdb.discoverTv(page: page, withGenres: '10765'),
      'Action Series' => _tmdb.discoverTv(page: page, withGenres: '10759'),
      'Anime' ||
      'Anime Spotlight' ||
      'Action Anime' ||
      'New Anime' ||
      'Bingeable Anime Series' ||
      'Anime & Animation' => _tmdb.discoverTv(
        page: page,
        withGenres: '16',
        withOriginalLanguage: 'ja',
      ),
      _ => _tmdb.trending(page: page),
    };
  }

  Future<List<MediaItem>> _loadCinemetaCategory(String title, int page) {
    return switch (title) {
      'Top on Netflix' ||
      'Top TV Shows' ||
      'Popular Series' ||
      'Series Worth Starting' => _cinemeta.catalog(
        mediaType: MediaType.tv,
        page: page,
      ),
      'Sci-Fi Series' => _cinemeta.catalog(
        mediaType: MediaType.tv,
        page: page,
        genre: 'Sci-Fi',
      ),
      'Action Series' => _cinemeta.catalog(
        mediaType: MediaType.tv,
        page: page,
        genre: 'Action',
      ),
      'Anime' ||
      'Anime Spotlight' ||
      'Action Anime' ||
      'New Anime' ||
      'Bingeable Anime Series' ||
      'Anime & Animation' => _cinemeta.catalog(
        mediaType: MediaType.tv,
        page: page,
        genre: 'Animation',
      ),
      'Action & Thrillers' || 'Action Movies' => _cinemeta.catalog(
        mediaType: MediaType.movie,
        page: page,
        genre: 'Action',
      ),
      'Sci-Fi Vault' || 'Sci-Fi Movies' => _cinemeta.catalog(
        mediaType: MediaType.movie,
        page: page,
        genre: 'Sci-Fi',
      ),
      'Family Night' => _cinemeta.catalog(
        mediaType: MediaType.movie,
        page: page,
        genre: 'Family',
      ),
      'Top Hindi' || 'Hindi Dubbed Hits' => _loadCinemetaSeedPage(title, page),
      _ => _cinemeta.catalog(mediaType: MediaType.movie, page: page),
    };
  }

  Future<List<MediaItem>> _loadCinemetaSeedPage(String title, int page) async {
    final seeds = _seedPool(title);
    final start = (page - 1).clamp(0, 999) * _fallbackPageSize;
    final selected = [
      for (var i = 0; i < _fallbackPageSize; i++)
        seeds[(start + i) % seeds.length],
    ];
    final resolved = await Future.wait(
      selected.map((seed) {
        return _cinemeta.searchFirst(
          query: seed.title,
          mediaType: seed.mediaType,
        );
      }),
    );
    return resolved.whereType<MediaItem>().toList();
  }

  List<ContentCategory> _buildHomeRows({
    required Map<String, List<MediaItem>> rowMap,
    required List<MediaItem> sample,
  }) {
    return _withoutEmpty([
      ContentCategory(
        title: 'Top on Netflix',
        items: _row(rowMap, 'Top on Netflix', _tag(sample, 'top-netflix')),
      ),
      ContentCategory(
        title: 'Trending Now',
        items: _row(rowMap, 'Trending Now', sample),
      ),
      ContentCategory(
        title: 'Top Hindi',
        items: _row(rowMap, 'Top Hindi', _tag(sample, 'top-hindi')),
      ),
      ContentCategory(
        title: 'Hindi Dubbed Hits',
        items: _row(rowMap, 'Hindi Dubbed Hits', _tag(sample, 'hindi-dubbed')),
      ),
      ContentCategory(
        title: 'New Releases',
        items: _row(rowMap, 'New Releases', _tag(sample, 'new')),
      ),
      ContentCategory(
        title: 'Action & Thrillers',
        items: _row(rowMap, 'Action & Thrillers', [
          ..._tag(sample, 'action'),
          ..._tag(sample, 'thriller'),
        ]),
      ),
      ContentCategory(
        title: 'Sci-Fi Vault',
        items: _row(rowMap, 'Sci-Fi Vault', _tag(sample, 'sci-fi')),
      ),
      ContentCategory(
        title: 'Anime',
        items: _row(rowMap, 'Anime', _tag(sample, 'anime')),
      ),
      ContentCategory(
        title: 'Series Worth Starting',
        items: _row(
          rowMap,
          'Series Worth Starting',
          sample.where((m) => m.mediaType == MediaType.tv),
        ),
      ),
    ]);
  }

  List<ContentCategory> _buildMovieRows({
    required Map<String, List<MediaItem>> rowMap,
    required List<MediaItem> sample,
  }) {
    final sampleMovies = sample.where((m) => m.mediaType == MediaType.movie);
    return _withoutEmpty([
      ContentCategory(
        title: 'Top Movies',
        items: _row(rowMap, 'Top Movies', sampleMovies),
      ),
      ContentCategory(
        title: 'Top Hindi',
        items: _row(rowMap, 'Top Hindi', _tag(sampleMovies, 'top-hindi')),
      ),
      ContentCategory(
        title: 'Hindi Dubbed Hits',
        items: _row(
          rowMap,
          'Hindi Dubbed Hits',
          _tag(sampleMovies, 'hindi-dubbed'),
        ),
      ),
      ContentCategory(
        title: 'New Movies',
        items: _row(rowMap, 'New Movies', _tag(sampleMovies, 'new')),
      ),
      ContentCategory(
        title: 'Action Movies',
        items: _row(rowMap, 'Action Movies', _tag(sampleMovies, 'action')),
      ),
      ContentCategory(
        title: 'Sci-Fi Movies',
        items: _row(rowMap, 'Sci-Fi Movies', _tag(sampleMovies, 'sci-fi')),
      ),
      ContentCategory(
        title: 'Family Night',
        items: _row(rowMap, 'Family Night', _tag(sampleMovies, 'family')),
      ),
    ]);
  }

  List<ContentCategory> _buildTvRows({
    required Map<String, List<MediaItem>> rowMap,
    required List<MediaItem> sample,
  }) {
    final sampleTv = sample.where((m) => m.mediaType == MediaType.tv);
    return _withoutEmpty([
      ContentCategory(
        title: 'Top TV Shows',
        items: _row(rowMap, 'Top TV Shows', sampleTv),
      ),
      ContentCategory(
        title: 'Top on Netflix',
        items: _row(rowMap, 'Top on Netflix', _tag(sampleTv, 'top-netflix')),
      ),
      ContentCategory(
        title: 'Popular Series',
        items: _row(rowMap, 'Popular Series', _tag(sampleTv, 'tv')),
      ),
      ContentCategory(
        title: 'Sci-Fi Series',
        items: _row(rowMap, 'Sci-Fi Series', _tag(sampleTv, 'sci-fi')),
      ),
      ContentCategory(
        title: 'Action Series',
        items: _row(rowMap, 'Action Series', _tag(sampleTv, 'action')),
      ),
      ContentCategory(
        title: 'Anime & Animation',
        items: _row(rowMap, 'Anime & Animation', _tag(sampleTv, 'anime')),
      ),
    ]);
  }

  List<ContentCategory> _buildMyListRows(
    List<MediaItem> sample,
    List<MediaItem> continueWatching,
  ) {
    return _withoutEmpty([
      ContentCategory(
        title: 'My List',
        items: sample.where((m) => m.isInWatchlist || m.isFavorite).toList(),
      ),
      ContentCategory(
        title: 'Favorites',
        items: sample.where((m) => m.isFavorite).toList(),
      ),
      ContentCategory(
        title: 'Saved for Later',
        items: sample.where((m) => m.isInWatchlist).toList(),
      ),
      ContentCategory(title: 'Continue Watching', items: continueWatching),
      ContentCategory(
        title: 'Because You Watched',
        items: _tag(sample, 'top-netflix'),
      ),
    ]);
  }

  List<ContentCategory> _buildAnimeRows({
    required Map<String, List<MediaItem>> rowMap,
    required List<MediaItem> sample,
  }) {
    final anime = _tag(sample, 'anime');
    return _withoutEmpty([
      ContentCategory(
        title: 'Anime Spotlight',
        items: _row(rowMap, 'Anime Spotlight', anime),
      ),
      ContentCategory(
        title: 'Action Anime',
        items: _row(rowMap, 'Action Anime', _tag(anime, 'action')),
      ),
      ContentCategory(
        title: 'New Anime',
        items: _row(rowMap, 'New Anime', _tag(anime, 'new')),
      ),
      ContentCategory(
        title: 'Bingeable Anime Series',
        items: _row(rowMap, 'Bingeable Anime Series', anime.reversed),
      ),
    ]);
  }

  List<MediaItem> _tag(Iterable<MediaItem> items, String tag) {
    return items.where((item) => item.tags.contains(tag)).toList();
  }

  List<MediaItem> _row(
    Map<String, List<MediaItem>> rowMap,
    String title,
    Iterable<MediaItem> fallback,
  ) {
    final items = rowMap[title];
    return _dedupe(items != null && items.isNotEmpty ? items : fallback);
  }

  List<MediaItem> _fallbackCategory(String title, int page) {
    if (page < 1 || page > _fallbackMaxPages) return const [];
    final base = _fallbackBase(title);
    if (base.isEmpty) return _syntheticFallbackPage(title, page);
    final offset = _stableHash(title) % base.length;
    final rotated = [...base.skip(offset), ...base.take(offset)];
    final start = (page - 1) * _fallbackPageSize;
    if (start < rotated.length) {
      return rotated.skip(start).take(_fallbackPageSize).toList();
    }

    return _syntheticFallbackPage(title, page);
  }

  List<MediaItem> _fallbackBase(String title) {
    final sample = MediaItem.samples;
    return switch (title) {
      'Trending Now' => sample,
      'Top Movies' =>
        sample.where((m) => m.mediaType == MediaType.movie).toList(),
      'Top TV Shows' || 'Popular Series' || 'Series Worth Starting' =>
        sample.where((m) => m.mediaType == MediaType.tv).toList(),
      'Top on Netflix' => _tag(sample, 'top-netflix'),
      'Top Hindi' => _tag(sample, 'top-hindi'),
      'Hindi Dubbed Hits' => _tag(sample, 'hindi-dubbed'),
      'New Releases' || 'New Movies' => _tag(sample, 'new'),
      'Action & Thrillers' ||
      'Action Movies' ||
      'Action Series' ||
      'Action Anime' => _tag(sample, 'action'),
      'Sci-Fi Vault' ||
      'Sci-Fi Movies' ||
      'Sci-Fi Series' => _tag(sample, 'sci-fi'),
      'Family Night' => _tag(sample, 'family'),
      'Anime' ||
      'Anime Spotlight' ||
      'New Anime' ||
      'Bingeable Anime Series' ||
      'Anime & Animation' => _tag(sample, 'anime'),
      _ => sample,
    };
  }

  List<MediaItem> _syntheticFallbackPage(String title, int page) {
    final seeds = _seedPool(title);
    final categoryHash = _stableHash(title);
    return List.generate(_fallbackPageSize, (index) {
      final globalIndex = (page - 1) * _fallbackPageSize + index;
      final seed = seeds[(globalIndex + categoryHash) % seeds.length];
      final id = 800000000 + _stableHash('$title-${seed.title}-$globalIndex');
      final isTv = seed.mediaType == MediaType.tv;
      final score = 6.7 + ((_stableHash(seed.title) % 23) / 10);
      return MediaItem(
        tmdbId: id,
        title: seed.title,
        mediaType: seed.mediaType,
        genre: seed.genre,
        releaseYear: seed.releaseYear,
        runtimeLabel: isTv ? 'Series' : '2h 5m',
        voteAverage: score.clamp(6.7, 9.1).toDouble(),
        overview:
            '${seed.title} is part of the local demo catalog. Add a TMDB key to replace fallback rows with live metadata, artwork, cast, trailers, and external IDs.',
        tags: _fallbackTags(title, seed),
        seasons: isTv ? MediaItem.sampleSeasons : const [],
      );
    });
  }

  List<_FallbackSeed> _seedPool(String title) {
    final seen = <String>{};
    final output = <_FallbackSeed>[];
    for (final seed in [..._fallbackSeeds(title), ..._overflowSeeds(title)]) {
      final key = '${seed.mediaType.name}:${seed.title}';
      if (seen.add(key)) output.add(seed);
    }
    return output;
  }

  List<_FallbackSeed> _overflowSeeds(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('netflix')) {
      return [
        ..._seriesFallbackSeeds,
        ..._movieFallbackSeeds,
        ..._actionFallbackSeeds,
        ..._sciFiFallbackSeeds,
        ..._familyFallbackSeeds,
      ];
    }
    if (lower.contains('hindi')) return _hindiFallbackSeeds;
    if (lower.contains('anime')) return _animeFallbackSeeds;
    if (lower.contains('family')) {
      return [..._familyFallbackSeeds, ..._movieFallbackSeeds];
    }
    if (lower.contains('sci-fi')) {
      return [
        ..._sciFiFallbackSeeds,
        ..._seriesFallbackSeeds,
        ..._movieFallbackSeeds,
      ];
    }
    if (lower.contains('action') || lower.contains('thriller')) {
      return [
        ..._actionFallbackSeeds,
        ..._movieFallbackSeeds,
        ..._seriesFallbackSeeds,
      ];
    }
    if (lower.contains('series') || lower.contains('tv')) {
      return [
        ..._seriesFallbackSeeds,
        ..._sciFiFallbackSeeds,
        ..._actionFallbackSeeds,
      ];
    }
    if (lower.contains('movie') || lower.contains('release')) {
      return [
        ..._movieFallbackSeeds,
        ..._actionFallbackSeeds,
        ..._sciFiFallbackSeeds,
      ];
    }
    return _mixedFallbackSeeds;
  }

  List<String> _fallbackTags(String title, _FallbackSeed seed) {
    final tags = <String>{
      if (seed.mediaType == MediaType.tv) 'tv' else 'movies',
      seed.genre.toLowerCase(),
    };
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('hindi')) tags.add('top-hindi');
    if (lowerTitle.contains('dubbed')) tags.add('hindi-dubbed');
    if (lowerTitle.contains('anime')) tags.add('anime');
    if (lowerTitle.contains('sci-fi')) tags.add('sci-fi');
    if (lowerTitle.contains('action')) tags.add('action');
    if (lowerTitle.contains('family')) tags.add('family');
    if (lowerTitle.contains('new')) tags.add('new');
    if (lowerTitle.contains('netflix')) tags.add('top-netflix');
    return tags.toList();
  }

  List<_FallbackSeed> _fallbackSeeds(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('netflix')) return _netflixFallbackSeeds;
    if (lower.contains('hindi')) return _hindiFallbackSeeds;
    if (lower.contains('anime')) return _animeFallbackSeeds;
    if (lower.contains('series') || lower.contains('tv')) {
      return _seriesFallbackSeeds;
    }
    if (lower.contains('family')) return _familyFallbackSeeds;
    if (lower.contains('sci-fi')) return _sciFiFallbackSeeds;
    if (lower.contains('action') || lower.contains('thriller')) {
      return _actionFallbackSeeds;
    }
    if (lower.contains('movie') || lower.contains('release')) {
      return _movieFallbackSeeds;
    }
    return _mixedFallbackSeeds;
  }

  int _stableHash(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x0fffffff;
    }
    return hash;
  }

  Map<String, List<MediaItem>> _fallbackRowMap(List<MediaItem> items) {
    return {
      for (final title in _initialRowTitles)
        title: _fallbackCategory(title, 1).isEmpty
            ? items
            : _fallbackCategory(title, 1),
    };
  }

  List<MediaItem> _continueWatching(
    List<MediaItem> catalog,
    List<PlaybackProgress> recentPlayback,
  ) {
    if (recentPlayback.isEmpty) {
      return catalog.where((item) => item.hasProgress).toList();
    }
    final output = <MediaItem>[];
    for (final progress in recentPlayback) {
      final match = catalog.where(
        (item) =>
            item.tmdbId == progress.tmdbId &&
            item.mediaType.name == progress.mediaType,
      );
      if (match.isEmpty) continue;
      output.add(_withProgress(match.first, progress));
    }
    return _dedupe(output);
  }

  MediaItem _withProgress(MediaItem item, PlaybackProgress progress) {
    final remainingSeconds =
        (progress.durationSeconds - progress.positionSeconds).clamp(0, 86400);
    final minutesLeft = (remainingSeconds / 60).ceil();
    final prefix = item.mediaType == MediaType.tv
        ? 'S${progress.seasonNumber ?? 1} E${progress.episodeNumber ?? 1} - '
        : '';
    return item.copyWith(
      progress: progress.progress,
      seasonEpisodeLabel: '$prefix${minutesLeft}m left',
    );
  }

  List<MediaItem> _dedupe(Iterable<MediaItem> items) {
    final seen = <String>{};
    final output = <MediaItem>[];
    for (final item in items) {
      final key = '${item.mediaType.name}:${item.tmdbId}';
      if (seen.add(key)) output.add(item);
    }
    return output;
  }

  List<ContentCategory> _withoutEmpty(List<ContentCategory> rows) {
    return rows.where((row) => row.items.isNotEmpty).toList();
  }

  Future<void> _cacheMedia(List<MediaItem> items) {
    return _database.upsertCachedMedia(
      items.map((item) {
        return CachedMediaItemsCompanion(
          tmdbId: Value(item.tmdbId),
          mediaType: Value(item.mediaType.name),
          title: Value(item.title),
          genre: Value(item.genre),
          releaseYear: Value(item.releaseYear),
          overview: Value(item.overview),
          voteAverage: Value(item.voteAverage),
          posterPath: Value(item.posterPath),
          backdropPath: Value(item.backdropPath),
        );
      }).toList(),
    );
  }

  MediaItem _fromCache(CachedMediaItem item) {
    return MediaItem(
      tmdbId: item.tmdbId,
      title: item.title,
      mediaType: item.mediaType == 'tv' ? MediaType.tv : MediaType.movie,
      genre: item.genre,
      releaseYear: item.releaseYear,
      overview: item.overview,
      voteAverage: item.voteAverage,
      posterPath: item.posterPath,
      backdropPath: item.backdropPath,
    );
  }
}

class _FallbackSeed {
  const _FallbackSeed(this.title, this.mediaType, this.genre, this.releaseYear);

  final String title;
  final MediaType mediaType;
  final String genre;
  final String releaseYear;
}

const _movieFallbackSeeds = <_FallbackSeed>[
  _FallbackSeed('The Batman', MediaType.movie, 'Action', '2022'),
  _FallbackSeed(
    'Mission: Impossible - Fallout',
    MediaType.movie,
    'Action',
    '2018',
  ),
  _FallbackSeed('Blade Runner 2049', MediaType.movie, 'Sci-Fi', '2017'),
  _FallbackSeed('Mad Max: Fury Road', MediaType.movie, 'Action', '2015'),
  _FallbackSeed('John Wick: Chapter 4', MediaType.movie, 'Action', '2023'),
  _FallbackSeed('Tenet', MediaType.movie, 'Sci-Fi', '2020'),
  _FallbackSeed('The Creator', MediaType.movie, 'Sci-Fi', '2023'),
  _FallbackSeed('Civil War', MediaType.movie, 'Thriller', '2024'),
  _FallbackSeed('A Quiet Place: Day One', MediaType.movie, 'Thriller', '2024'),
  _FallbackSeed(
    'Kingdom of the Planet of the Apes',
    MediaType.movie,
    'Sci-Fi',
    '2024',
  ),
  _FallbackSeed('No Time to Die', MediaType.movie, 'Action', '2021'),
  _FallbackSeed('Bullet Train', MediaType.movie, 'Action', '2022'),
  _FallbackSeed('The Fall Guy', MediaType.movie, 'Action', '2024'),
  _FallbackSeed(
    'Everything Everywhere All at Once',
    MediaType.movie,
    'Adventure',
    '2022',
  ),
  _FallbackSeed('The Martian', MediaType.movie, 'Sci-Fi', '2015'),
  _FallbackSeed('Arrival', MediaType.movie, 'Sci-Fi', '2016'),
  _FallbackSeed('Ford v Ferrari', MediaType.movie, 'Drama', '2019'),
  _FallbackSeed('Whiplash', MediaType.movie, 'Drama', '2014'),
  _FallbackSeed('Knives Out', MediaType.movie, 'Mystery', '2019'),
  _FallbackSeed('Glass Onion', MediaType.movie, 'Mystery', '2022'),
  _FallbackSeed('The Menu', MediaType.movie, 'Thriller', '2022'),
  _FallbackSeed('The Northman', MediaType.movie, 'Adventure', '2022'),
  _FallbackSeed(
    'Dungeons & Dragons: Honor Among Thieves',
    MediaType.movie,
    'Adventure',
    '2023',
  ),
  _FallbackSeed('Wonka', MediaType.movie, 'Family', '2023'),
];

const _seriesFallbackSeeds = <_FallbackSeed>[
  _FallbackSeed('Breaking Bad', MediaType.tv, 'Crime', '2008'),
  _FallbackSeed('Better Call Saul', MediaType.tv, 'Crime', '2015'),
  _FallbackSeed('Dark', MediaType.tv, 'Sci-Fi', '2017'),
  _FallbackSeed('The Crown', MediaType.tv, 'Drama', '2016'),
  _FallbackSeed('The Gentlemen', MediaType.tv, 'Crime', '2024'),
  _FallbackSeed('Fallout', MediaType.tv, 'Sci-Fi', '2024'),
  _FallbackSeed('Severance', MediaType.tv, 'Mystery', '2022'),
  _FallbackSeed('Andor', MediaType.tv, 'Sci-Fi', '2022'),
  _FallbackSeed('The Bear', MediaType.tv, 'Drama', '2022'),
  _FallbackSeed('Slow Horses', MediaType.tv, 'Thriller', '2022'),
  _FallbackSeed('The Night Agent', MediaType.tv, 'Thriller', '2023'),
  _FallbackSeed('The Diplomat', MediaType.tv, 'Drama', '2023'),
  _FallbackSeed('The Witcher', MediaType.tv, 'Fantasy', '2019'),
  _FallbackSeed('The Sandman', MediaType.tv, 'Fantasy', '2022'),
  _FallbackSeed('Foundation', MediaType.tv, 'Sci-Fi', '2021'),
  _FallbackSeed('For All Mankind', MediaType.tv, 'Sci-Fi', '2019'),
  _FallbackSeed('Yellowstone', MediaType.tv, 'Drama', '2018'),
  _FallbackSeed('Sherlock', MediaType.tv, 'Mystery', '2010'),
  _FallbackSeed('True Detective', MediaType.tv, 'Crime', '2014'),
  _FallbackSeed('Mindhunter', MediaType.tv, 'Crime', '2017'),
];

const _animeFallbackSeeds = <_FallbackSeed>[
  _FallbackSeed('Naruto Shippuden', MediaType.tv, 'Anime', '2007'),
  _FallbackSeed('Bleach', MediaType.tv, 'Anime', '2004'),
  _FallbackSeed('Dragon Ball Super', MediaType.tv, 'Anime', '2015'),
  _FallbackSeed('Death Note', MediaType.tv, 'Anime', '2006'),
  _FallbackSeed('Cowboy Bebop', MediaType.tv, 'Anime', '1998'),
  _FallbackSeed(
    'Fullmetal Alchemist: Brotherhood',
    MediaType.tv,
    'Anime',
    '2009',
  ),
  _FallbackSeed('Hunter x Hunter', MediaType.tv, 'Anime', '2011'),
  _FallbackSeed('Mob Psycho 100', MediaType.tv, 'Anime', '2016'),
  _FallbackSeed('Spy x Family', MediaType.tv, 'Anime', '2022'),
  _FallbackSeed('Kaiju No. 8', MediaType.tv, 'Anime', '2024'),
  _FallbackSeed('Delicious in Dungeon', MediaType.tv, 'Anime', '2024'),
  _FallbackSeed('Dandadan', MediaType.tv, 'Anime', '2024'),
  _FallbackSeed('Tokyo Revengers', MediaType.tv, 'Anime', '2021'),
  _FallbackSeed('Black Clover', MediaType.tv, 'Anime', '2017'),
  _FallbackSeed('Haikyu!!', MediaType.tv, 'Anime', '2014'),
  _FallbackSeed('Blue Lock', MediaType.tv, 'Anime', '2022'),
  _FallbackSeed('Your Name', MediaType.movie, 'Anime', '2016'),
  _FallbackSeed('Suzume', MediaType.movie, 'Anime', '2022'),
  _FallbackSeed('A Silent Voice', MediaType.movie, 'Anime', '2016'),
  _FallbackSeed('Weathering With You', MediaType.movie, 'Anime', '2019'),
];

const _hindiFallbackSeeds = <_FallbackSeed>[
  _FallbackSeed('3 Idiots', MediaType.movie, 'Comedy', '2009'),
  _FallbackSeed('PK', MediaType.movie, 'Comedy', '2014'),
  _FallbackSeed('Andhadhun', MediaType.movie, 'Thriller', '2018'),
  _FallbackSeed('Gully Boy', MediaType.movie, 'Drama', '2019'),
  _FallbackSeed('Zindagi Na Milegi Dobara', MediaType.movie, 'Drama', '2011'),
  _FallbackSeed('Bajrangi Bhaijaan', MediaType.movie, 'Drama', '2015'),
  _FallbackSeed('War', MediaType.movie, 'Action', '2019'),
  _FallbackSeed('Brahmastra', MediaType.movie, 'Fantasy', '2022'),
  _FallbackSeed('Bhediya', MediaType.movie, 'Comedy', '2022'),
  _FallbackSeed('Tumbbad', MediaType.movie, 'Horror', '2018'),
  _FallbackSeed('Article 15', MediaType.movie, 'Drama', '2019'),
  _FallbackSeed('Super 30', MediaType.movie, 'Drama', '2019'),
  _FallbackSeed('Sardar Udham', MediaType.movie, 'Drama', '2021'),
  _FallbackSeed('Shershaah', MediaType.movie, 'Drama', '2021'),
  _FallbackSeed('Gangubai Kathiawadi', MediaType.movie, 'Drama', '2022'),
  _FallbackSeed('Bawaal', MediaType.movie, 'Drama', '2023'),
  _FallbackSeed(
    'Rocky Aur Rani Kii Prem Kahaani',
    MediaType.movie,
    'Romance',
    '2023',
  ),
  _FallbackSeed('Fighter', MediaType.movie, 'Action', '2024'),
  _FallbackSeed('Crew', MediaType.movie, 'Comedy', '2024'),
  _FallbackSeed('Laapataa Ladies', MediaType.movie, 'Comedy', '2024'),
];

const _actionFallbackSeeds = <_FallbackSeed>[
  _FallbackSeed('Extraction', MediaType.movie, 'Action', '2020'),
  _FallbackSeed('Extraction 2', MediaType.movie, 'Action', '2023'),
  _FallbackSeed('The Equalizer 3', MediaType.movie, 'Action', '2023'),
  _FallbackSeed('Nobody', MediaType.movie, 'Action', '2021'),
  _FallbackSeed('The Gray Man', MediaType.movie, 'Action', '2022'),
  _FallbackSeed('Top Gun: Maverick', MediaType.movie, 'Action', '2022'),
  _FallbackSeed('The Old Guard', MediaType.movie, 'Action', '2020'),
  _FallbackSeed('Rebel Ridge', MediaType.movie, 'Thriller', '2024'),
  _FallbackSeed('Sicario', MediaType.movie, 'Thriller', '2015'),
  _FallbackSeed('Heat', MediaType.movie, 'Crime', '1995'),
  _FallbackSeed('The Raid 2', MediaType.movie, 'Action', '2014'),
  _FallbackSeed('Atomic Blonde', MediaType.movie, 'Action', '2017'),
  _FallbackSeed('Jack Ryan', MediaType.tv, 'Action', '2018'),
  _FallbackSeed('Lioness', MediaType.tv, 'Thriller', '2023'),
  _FallbackSeed('Bodyguard', MediaType.tv, 'Thriller', '2018'),
  _FallbackSeed('Gangs of London', MediaType.tv, 'Action', '2020'),
];

const _sciFiFallbackSeeds = <_FallbackSeed>[
  _FallbackSeed('Dune', MediaType.movie, 'Sci-Fi', '2021'),
  _FallbackSeed('Inception', MediaType.movie, 'Sci-Fi', '2010'),
  _FallbackSeed('Ex Machina', MediaType.movie, 'Sci-Fi', '2015'),
  _FallbackSeed('Annihilation', MediaType.movie, 'Sci-Fi', '2018'),
  _FallbackSeed('Edge of Tomorrow', MediaType.movie, 'Sci-Fi', '2014'),
  _FallbackSeed('District 9', MediaType.movie, 'Sci-Fi', '2009'),
  _FallbackSeed('Looper', MediaType.movie, 'Sci-Fi', '2012'),
  _FallbackSeed('Children of Men', MediaType.movie, 'Sci-Fi', '2006'),
  _FallbackSeed('The Expanse', MediaType.tv, 'Sci-Fi', '2015'),
  _FallbackSeed('Altered Carbon', MediaType.tv, 'Sci-Fi', '2018'),
  _FallbackSeed('Lost in Space', MediaType.tv, 'Sci-Fi', '2018'),
  _FallbackSeed(
    'Star Trek: Strange New Worlds',
    MediaType.tv,
    'Sci-Fi',
    '2022',
  ),
  _FallbackSeed('Halo', MediaType.tv, 'Sci-Fi', '2022'),
  _FallbackSeed('Raised by Wolves', MediaType.tv, 'Sci-Fi', '2020'),
  _FallbackSeed('Silo', MediaType.tv, 'Sci-Fi', '2023'),
  _FallbackSeed('3 Body Problem', MediaType.tv, 'Sci-Fi', '2024'),
];

const _familyFallbackSeeds = <_FallbackSeed>[
  _FallbackSeed('Moana', MediaType.movie, 'Family', '2016'),
  _FallbackSeed('Encanto', MediaType.movie, 'Family', '2021'),
  _FallbackSeed('Luca', MediaType.movie, 'Family', '2021'),
  _FallbackSeed('Turning Red', MediaType.movie, 'Family', '2022'),
  _FallbackSeed('Soul', MediaType.movie, 'Family', '2020'),
  _FallbackSeed('Coco', MediaType.movie, 'Family', '2017'),
  _FallbackSeed(
    'The Mitchells vs. the Machines',
    MediaType.movie,
    'Family',
    '2021',
  ),
  _FallbackSeed(
    'Puss in Boots: The Last Wish',
    MediaType.movie,
    'Family',
    '2022',
  ),
  _FallbackSeed(
    'Spider-Man: Across the Spider-Verse',
    MediaType.movie,
    'Animation',
    '2023',
  ),
  _FallbackSeed('Elemental', MediaType.movie, 'Family', '2023'),
  _FallbackSeed('Wish', MediaType.movie, 'Family', '2023'),
  _FallbackSeed('Migration', MediaType.movie, 'Family', '2023'),
];

const _netflixFallbackSeeds = <_FallbackSeed>[
  ..._seriesFallbackSeeds,
  ..._movieFallbackSeeds,
  ..._actionFallbackSeeds,
  ..._sciFiFallbackSeeds,
  ..._familyFallbackSeeds,
];

const _mixedFallbackSeeds = <_FallbackSeed>[
  ..._movieFallbackSeeds,
  ..._seriesFallbackSeeds,
  ..._animeFallbackSeeds,
  ..._hindiFallbackSeeds,
];
