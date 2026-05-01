import 'package:drift/drift.dart';

import '../datasources/cinemeta_remote.dart';
import '../datasources/tmdb_remote.dart';
import '../local/local_database.dart';
import '../models/media_item.dart';
import '../models/playback_progress.dart';

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
      final allTitles = _allRowTitles;
      final rowResults = await Future.wait(
        allTitles.map((title) => loadMoreCategory(title, page: 1)),
      );
      final rowMap = {
        for (var i = 0; i < allTitles.length; i++) allTitles[i]: rowResults[i],
      };

      final dynamicItems = rowResults.expand((items) => items).toList();
      final cached = await _database.getCachedMedia();
      final catalog = _dedupe([
        ...dynamicItems,
        ...cached.map(_fromCache),
        ...sample,
      ]);
      final continueWatching = _continueWatching(catalog, recentPlayback);

      final hero = (rowMap[_RowTitles.trendingNow]?.isNotEmpty ?? false)
          ? rowMap[_RowTitles.trendingNow]!.first.copyWith(isInWatchlist: true)
          : catalog.first.copyWith(isInWatchlist: true);

      return HomeFeed(
        hero: hero,
        continueWatching: continueWatching,
        homeRows: _buildSection(
          rowMap: rowMap,
          sample: sample,
          rows: _homeRows,
          reservedIds: {_idKey(hero)},
        ),
        movieRows: _buildSection(
          rowMap: rowMap,
          sample: sample,
          rows: _movieRows,
        ),
        tvRows: _buildSection(rowMap: rowMap, sample: sample, rows: _tvRows),
        animeRows: _buildSection(
          rowMap: rowMap,
          sample: sample,
          rows: _animeRows,
        ),
        myListRows: _buildMyListRows(sample, continueWatching, rowMap),
      );
    } catch (_) {
      final cached = await _database.getCachedMedia();
      final cachedItems = cached.map(_fromCache).toList();
      final fallback = cachedItems.isNotEmpty ? cachedItems : sample;
      final continueWatching = _continueWatching(
        _dedupe([...fallback, ...sample]),
        recentPlayback,
      );
      final fallbackMap = _fallbackRowMap();
      return HomeFeed(
        hero: fallback.first,
        continueWatching: continueWatching,
        homeRows: _buildSection(
          rowMap: fallbackMap,
          sample: sample,
          rows: _homeRows,
        ),
        movieRows: _buildSection(
          rowMap: fallbackMap,
          sample: sample,
          rows: _movieRows,
        ),
        tvRows: _buildSection(
          rowMap: fallbackMap,
          sample: sample,
          rows: _tvRows,
        ),
        animeRows: _buildSection(
          rowMap: fallbackMap,
          sample: sample,
          rows: _animeRows,
        ),
        myListRows: _buildMyListRows(sample, continueWatching, fallbackMap),
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
    if (_tmdb.isConfigured) {
      try {
        final tmdbItems = await _loadTmdbCategory(title, page);
        if (tmdbItems.isNotEmpty) return tmdbItems;
      } catch (_) {
        // continue to cinemeta fallback
      }
    }

    try {
      final cinemetaItems = await _loadCinemetaCategory(title, page);
      if (cinemetaItems.isNotEmpty) return cinemetaItems;
    } catch (_) {
      // local fallback
    }

    return _fallbackCategory(title, page);
  }

  Future<List<MediaItem>> _loadTmdbCategory(String title, int page) {
    final spec = _rowSpecFor(title);
    if (spec != null) return spec.fetch(_tmdb, page);
    return _tmdb.trending(page: page);
  }

  Future<List<MediaItem>> _loadCinemetaCategory(String title, int page) {
    final spec = _rowSpecFor(title);
    final cinemetaSpec = spec?.cinemetaFallback;
    if (cinemetaSpec != null) return cinemetaSpec(_cinemeta, page);
    return _loadCinemetaSeedPage(title, page);
  }

  Future<List<MediaItem>> _loadCinemetaSeedPage(String title, int page) async {
    final seeds = _seedPool(title);
    if (seeds.isEmpty) return const [];
    final start = (page - 1).clamp(0, 999) * _fallbackPageSize;
    final selected = [
      for (var i = 0; i < _fallbackPageSize; i++)
        seeds[(start + i) % seeds.length],
    ];
    final resolved = await Future.wait(
      selected.map((seed) async {
        try {
          final item = await _cinemeta.searchFirst(
            query: seed.title,
            mediaType: seed.mediaType,
          );
          if (item == null) return _seedToMediaItem(title, seed, 0);
          // Augment Cinemeta artwork with curated seed metadata
          final fallbackRating = _ratingFor(seed.title);
          return item.copyWith(
            genre: _shouldOverrideGenre(item.genre) ? seed.genre : item.genre,
            releaseYear: item.releaseYear == 'New' || item.releaseYear.isEmpty
                ? seed.releaseYear
                : item.releaseYear,
            voteAverage: item.voteAverage > 0 ? item.voteAverage : fallbackRating,
            tags: _fallbackTags(title, seed),
          );
        } catch (_) {
          return _seedToMediaItem(title, seed, 0);
        }
      }),
    );
    return resolved.toList();
  }

  bool _shouldOverrideGenre(String genre) {
    final g = genre.toLowerCase();
    return g.isEmpty || g == 'cinema' || g == 'film' || g == 'series' || g == 'drama';
  }

  double _ratingFor(String seedTitle) {
    // Curated rating profile for known popular titles. Returns 7.4-9.0.
    final hash = _stableHash(seedTitle);
    return (7.4 + (hash % 17) / 10).clamp(7.4, 9.0).toDouble();
  }

  MediaItem _seedToMediaItem(String rowTitle, _FallbackSeed seed, int salt) {
    final id = 800000000 + _stableHash('${seed.mediaType.name}-${seed.title}');
    final isTv = seed.mediaType == MediaType.tv;
    return MediaItem(
      tmdbId: id,
      title: seed.title,
      mediaType: seed.mediaType,
      genre: seed.genre,
      releaseYear: seed.releaseYear,
      runtimeLabel: isTv ? 'Series' : '2h 5m',
      voteAverage: _ratingFor(seed.title),
      overview:
          '${seed.title} is part of the StreamVault demo catalog. Add a TMDB key to enable live metadata, artwork, cast, and trailers.',
      tags: _fallbackTags(rowTitle, seed),
      seasons: isTv ? MediaItem.sampleSeasons : const [],
    );
  }

  List<ContentCategory> _buildSection({
    required Map<String, List<MediaItem>> rowMap,
    required List<MediaItem> sample,
    required List<_RowConfig> rows,
    Set<String>? reservedIds,
  }) {
    final seenIds = <String>{...?reservedIds};
    final seenTitles = <String>{};
    final output = <ContentCategory>[];
    bool tryAdd(List<MediaItem> filtered, MediaItem item) {
      final idKey = _idKey(item);
      if (seenIds.contains(idKey)) return false;
      final titleKey = _normalizedTitleKey(item);
      if (seenTitles.contains(titleKey)) return false;
      seenIds.add(idKey);
      seenTitles.add(titleKey);
      filtered.add(item);
      return true;
    }

    for (final row in rows) {
      final rawItems = rowMap[row.title];
      final fallback = row.fallback(sample);
      final source = rawItems != null && rawItems.isNotEmpty
          ? rawItems
          : fallback;
      final filtered = <MediaItem>[];
      for (final item in source) {
        tryAdd(filtered, item);
      }
      // Backfill from fallback for rows that came up short after dedup.
      if (filtered.length < row.minItems) {
        for (final item in fallback) {
          tryAdd(filtered, item);
          if (filtered.length >= row.minItems) break;
        }
      }
      if (filtered.isNotEmpty) {
        output.add(ContentCategory(title: row.title, items: filtered));
      }
    }
    return output;
  }

  String _normalizedTitleKey(MediaItem item) {
    final lower = item.title.toLowerCase();
    final stripped = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '');
    return '${item.mediaType.name}:$stripped';
  }

  List<ContentCategory> _buildMyListRows(
    List<MediaItem> sample,
    List<MediaItem> continueWatching,
    Map<String, List<MediaItem>> rowMap,
  ) {
    final myList = sample
        .where((m) => m.isInWatchlist || m.isFavorite)
        .toList();
    final favorites = sample.where((m) => m.isFavorite).toList();
    final saved = sample.where((m) => m.isInWatchlist).toList();
    final hindiPicks = (rowMap[_RowTitles.topHindi] ?? const []).take(12);
    final animePicks = (rowMap[_RowTitles.animeSpotlight] ?? const []).take(12);
    return _withoutEmpty([
      ContentCategory(title: 'Continue Watching', items: continueWatching),
      ContentCategory(title: 'My List', items: myList),
      ContentCategory(title: 'Favorites', items: favorites),
      ContentCategory(title: 'Saved for Later', items: saved),
      ContentCategory(
        title: 'Because You Like Hindi Cinema',
        items: hindiPicks.toList(),
      ),
      ContentCategory(
        title: 'Anime Recommendations',
        items: animePicks.toList(),
      ),
    ]);
  }

  // --- Row catalog -----------------------------------------------------------

  static const _allRowTitles = <String>[
    _RowTitles.topOnNetflix,
    _RowTitles.trendingNow,
    _RowTitles.topHindi,
    _RowTitles.hindiWebSeries,
    _RowTitles.hindiDubbedHits,
    _RowTitles.tamilTeluguHits,
    _RowTitles.newReleases,
    _RowTitles.actionThrillers,
    _RowTitles.sciFiVault,
    _RowTitles.animeSpotlight,
    _RowTitles.seriesWorthStarting,
    _RowTitles.topMovies,
    _RowTitles.topRatedMovies,
    _RowTitles.acclaimedDramas,
    _RowTitles.bollywoodActionMovies,
    _RowTitles.latestHindiReleases,
    _RowTitles.koreanCinema,
    _RowTitles.comedyMovies,
    _RowTitles.familyNight,
    _RowTitles.horrorPicks,
    _RowTitles.topTvShows,
    _RowTitles.topRatedTv,
    _RowTitles.currentlyAiringTv,
    _RowTitles.koreanDrama,
    _RowTitles.britishTv,
    _RowTitles.crimeMystery,
    _RowTitles.sciFiSeries,
    _RowTitles.actionSeries,
    _RowTitles.animeCurrentlyAiring,
    _RowTitles.shounenAction,
    _RowTitles.sliceOfLifeAnime,
    _RowTitles.fantasyAnime,
    _RowTitles.animeMovies,
    _RowTitles.classicAnime,
    _RowTitles.newSeasonAnime,
  ];

  static final List<_RowConfig> _homeRows = [
    _RowConfig(
      title: _RowTitles.topOnNetflix,
      tags: const ['top-netflix'],
      minItems: 8,
      fetch: (api, page) =>
          api.discoverTv(page: page, withNetworks: '213', voteCountGte: 100),
      cinemetaFallback: (api, page) =>
          api.catalog(mediaType: MediaType.tv, page: page),
    ),
    _RowConfig(
      title: _RowTitles.trendingNow,
      minItems: 8,
      fetch: (api, page) => api.trending(page: page),
      cinemetaFallback: (api, page) =>
          api.catalog(mediaType: MediaType.movie, page: page),
    ),
    _RowConfig(
      title: _RowTitles.topHindi,
      tags: const ['top-hindi'],
      minItems: 8,
      fetch: (api, page) => api.discoverMovies(
        page: page,
        withOriginalLanguage: 'hi',
        region: 'IN',
        voteCountGte: 100,
        sortBy: 'popularity.desc',
      ),
    ),
    _RowConfig(
      title: _RowTitles.hindiWebSeries,
      tags: const ['top-hindi', 'tv'],
      minItems: 6,
      fetch: (api, page) => api.discoverTv(
        page: page,
        withOriginalLanguage: 'hi',
        withOriginCountry: 'IN',
        voteCountGte: 30,
      ),
    ),
    _RowConfig(
      title: _RowTitles.hindiDubbedHits,
      tags: const ['hindi-dubbed'],
      minItems: 8,
      fetch: (api, page) => api.discoverMovies(
        page: page,
        withOriginalLanguage: 'en',
        region: 'IN',
        withGenres: '28|12|878|14',
        voteCountGte: 1500,
        sortBy: 'popularity.desc',
      ),
    ),
    _RowConfig(
      title: _RowTitles.tamilTeluguHits,
      tags: const ['top-hindi'],
      minItems: 6,
      fetch: (api, page) => _fetchSouthIndianHits(api, page),
    ),
    _RowConfig(
      title: _RowTitles.newReleases,
      tags: const ['new'],
      minItems: 8,
      fetch: (api, page) => api.nowPlayingMovies(page: page),
    ),
    _RowConfig(
      title: _RowTitles.actionThrillers,
      tags: const ['action', 'thriller'],
      minItems: 8,
      fetch: (api, page) =>
          api.discoverMovies(page: page, withGenres: '28|53', voteCountGte: 200),
      cinemetaFallback: (api, page) =>
          api.catalog(mediaType: MediaType.movie, page: page, genre: 'Action'),
    ),
    _RowConfig(
      title: _RowTitles.sciFiVault,
      tags: const ['sci-fi'],
      minItems: 8,
      fetch: (api, page) =>
          api.discoverMovies(page: page, withGenres: '878', voteCountGte: 200),
      cinemetaFallback: (api, page) =>
          api.catalog(mediaType: MediaType.movie, page: page, genre: 'Sci-Fi'),
    ),
    _RowConfig(
      title: _RowTitles.animeSpotlight,
      tags: const ['anime'],
      minItems: 8,
      fetch: (api, page) => api.discoverTv(
        page: page,
        withGenres: '16',
        withOriginalLanguage: 'ja',
        withOriginCountry: 'JP',
        voteCountGte: 200,
        sortBy: 'vote_average.desc',
      ),
    ),
    _RowConfig(
      title: _RowTitles.seriesWorthStarting,
      tags: const ['tv'],
      minItems: 8,
      fetch: (api, page) => api.popularTv(page: page),
      cinemetaFallback: (api, page) =>
          api.catalog(mediaType: MediaType.tv, page: page),
    ),
  ];

  static final List<_RowConfig> _movieRows = [
    _RowConfig(
      title: _RowTitles.topMovies,
      minItems: 8,
      fetch: (api, page) => api.popularMovies(page: page),
    ),
    _RowConfig(
      title: _RowTitles.topRatedMovies,
      minItems: 8,
      fetch: (api, page) => api.topRatedMovies(page: page),
    ),
    _RowConfig(
      title: _RowTitles.acclaimedDramas,
      minItems: 8,
      fetch: (api, page) => api.discoverMovies(
        page: page,
        withGenres: '18',
        voteCountGte: 800,
        voteAverageGte: 7.5,
        sortBy: 'vote_average.desc',
      ),
    ),
    _RowConfig(
      title: _RowTitles.bollywoodActionMovies,
      tags: const ['top-hindi', 'action'],
      minItems: 6,
      fetch: (api, page) => api.discoverMovies(
        page: page,
        withGenres: '28|53',
        withOriginalLanguage: 'hi',
        voteCountGte: 30,
      ),
    ),
    _RowConfig(
      title: _RowTitles.latestHindiReleases,
      tags: const ['top-hindi', 'new'],
      minItems: 6,
      fetch: (api, page) => api.discoverMovies(
        page: page,
        withOriginalLanguage: 'hi',
        primaryReleaseDateGte: '2024-01-01',
        sortBy: 'release_date.desc',
      ),
    ),
    _RowConfig(
      title: _RowTitles.koreanCinema,
      minItems: 6,
      fetch: (api, page) => api.discoverMovies(
        page: page,
        withOriginalLanguage: 'ko',
        voteCountGte: 100,
      ),
    ),
    _RowConfig(
      title: _RowTitles.comedyMovies,
      minItems: 8,
      fetch: (api, page) => api.discoverMovies(
        page: page,
        withGenres: '35',
        voteCountGte: 200,
      ),
      cinemetaFallback: (api, page) =>
          api.catalog(mediaType: MediaType.movie, page: page, genre: 'Comedy'),
    ),
    _RowConfig(
      title: _RowTitles.familyNight,
      tags: const ['family'],
      minItems: 8,
      fetch: (api, page) => api.discoverMovies(
        page: page,
        withGenres: '10751',
        voteCountGte: 100,
      ),
      cinemetaFallback: (api, page) =>
          api.catalog(mediaType: MediaType.movie, page: page, genre: 'Family'),
    ),
    _RowConfig(
      title: _RowTitles.horrorPicks,
      minItems: 8,
      fetch: (api, page) => api.discoverMovies(
        page: page,
        withGenres: '27',
        voteCountGte: 200,
      ),
      cinemetaFallback: (api, page) =>
          api.catalog(mediaType: MediaType.movie, page: page, genre: 'Horror'),
    ),
  ];

  static final List<_RowConfig> _tvRows = [
    _RowConfig(
      title: _RowTitles.topTvShows,
      minItems: 8,
      fetch: (api, page) => api.popularTv(page: page),
    ),
    _RowConfig(
      title: _RowTitles.topRatedTv,
      minItems: 8,
      fetch: (api, page) => api.topRatedTv(page: page),
    ),
    _RowConfig(
      title: _RowTitles.currentlyAiringTv,
      minItems: 8,
      fetch: (api, page) => api.onTheAirTv(page: page),
    ),
    _RowConfig(
      title: _RowTitles.koreanDrama,
      minItems: 6,
      fetch: (api, page) => api.discoverTv(
        page: page,
        withOriginalLanguage: 'ko',
        withOriginCountry: 'KR',
        voteCountGte: 50,
      ),
    ),
    _RowConfig(
      title: _RowTitles.britishTv,
      minItems: 6,
      fetch: (api, page) => api.discoverTv(
        page: page,
        withOriginCountry: 'GB',
        withOriginalLanguage: 'en',
        voteCountGte: 100,
      ),
    ),
    _RowConfig(
      title: _RowTitles.crimeMystery,
      minItems: 8,
      fetch: (api, page) => api.discoverTv(
        page: page,
        withGenres: '80|9648',
        voteCountGte: 100,
      ),
    ),
    _RowConfig(
      title: _RowTitles.sciFiSeries,
      tags: const ['sci-fi'],
      minItems: 8,
      fetch: (api, page) => api.discoverTv(
        page: page,
        withGenres: '10765',
        voteCountGte: 100,
      ),
      cinemetaFallback: (api, page) =>
          api.catalog(mediaType: MediaType.tv, page: page, genre: 'Sci-Fi'),
    ),
    _RowConfig(
      title: _RowTitles.actionSeries,
      tags: const ['action'],
      minItems: 8,
      fetch: (api, page) => api.discoverTv(
        page: page,
        withGenres: '10759',
        voteCountGte: 100,
      ),
      cinemetaFallback: (api, page) =>
          api.catalog(mediaType: MediaType.tv, page: page, genre: 'Action'),
    ),
  ];

  static final List<_RowConfig> _animeRows = [
    _RowConfig(
      title: _RowTitles.animeSpotlight,
      tags: const ['anime'],
      minItems: 8,
      fetch: (api, page) => api.discoverTv(
        page: page,
        withGenres: '16',
        withOriginalLanguage: 'ja',
        withOriginCountry: 'JP',
        voteCountGte: 200,
        sortBy: 'vote_average.desc',
      ),
    ),
    _RowConfig(
      title: _RowTitles.animeCurrentlyAiring,
      tags: const ['anime'],
      minItems: 6,
      fetch: (api, page) => api.discoverTv(
        page: page,
        withGenres: '16',
        withOriginalLanguage: 'ja',
        withOriginCountry: 'JP',
        firstAirDateGte: _dateAgo(const Duration(days: 120)),
        sortBy: 'first_air_date.desc',
      ),
    ),
    _RowConfig(
      title: _RowTitles.shounenAction,
      tags: const ['anime', 'action'],
      minItems: 6,
      fetch: (api, page) => api.discoverTv(
        page: page,
        withGenres: '16,10759',
        withOriginalLanguage: 'ja',
        withOriginCountry: 'JP',
        voteCountGte: 80,
      ),
    ),
    _RowConfig(
      title: _RowTitles.sliceOfLifeAnime,
      tags: const ['anime'],
      minItems: 6,
      fetch: (api, page) => api.discoverTv(
        page: page,
        withGenres: '16,18',
        withoutGenres: '10759,10765',
        withOriginalLanguage: 'ja',
        withOriginCountry: 'JP',
        voteCountGte: 80,
        sortBy: 'vote_average.desc',
      ),
    ),
    _RowConfig(
      title: _RowTitles.fantasyAnime,
      tags: const ['anime'],
      minItems: 6,
      fetch: (api, page) => api.discoverTv(
        page: page,
        withGenres: '16,10765',
        withOriginalLanguage: 'ja',
        withOriginCountry: 'JP',
        voteCountGte: 80,
      ),
    ),
    _RowConfig(
      title: _RowTitles.animeMovies,
      tags: const ['anime'],
      minItems: 6,
      fetch: (api, page) => api.discoverMovies(
        page: page,
        withGenres: '16',
        withOriginalLanguage: 'ja',
        withOriginCountry: 'JP',
        voteCountGte: 200,
        sortBy: 'vote_average.desc',
      ),
    ),
    _RowConfig(
      title: _RowTitles.newSeasonAnime,
      tags: const ['anime'],
      minItems: 6,
      fetch: (api, page) => api.discoverTv(
        page: page,
        withGenres: '16',
        withOriginalLanguage: 'ja',
        withOriginCountry: 'JP',
        firstAirDateGte: _dateAgo(const Duration(days: 30)),
      ),
    ),
    _RowConfig(
      title: _RowTitles.classicAnime,
      tags: const ['anime'],
      minItems: 6,
      fetch: (api, page) => api.discoverTv(
        page: page,
        withGenres: '16',
        withOriginalLanguage: 'ja',
        withOriginCountry: 'JP',
        firstAirDateLte: '2010-12-31',
        voteCountGte: 200,
        sortBy: 'vote_average.desc',
      ),
    ),
  ];

  _RowConfig? _rowSpecFor(String title) {
    for (final spec in [
      ..._homeRows,
      ..._movieRows,
      ..._tvRows,
      ..._animeRows,
    ]) {
      if (spec.title == title) return spec;
    }
    return null;
  }

  static Future<List<MediaItem>> _fetchSouthIndianHits(
    TmdbRemoteDataSource api,
    int page,
  ) async {
    final results = await Future.wait([
      api.discoverMovies(
        page: page,
        withOriginalLanguage: 'ta',
        withOriginCountry: 'IN',
        voteCountGte: 30,
        sortBy: 'popularity.desc',
      ),
      api.discoverMovies(
        page: page,
        withOriginalLanguage: 'te',
        withOriginCountry: 'IN',
        voteCountGte: 30,
        sortBy: 'popularity.desc',
      ),
      api.discoverMovies(
        page: page,
        withOriginalLanguage: 'ml',
        withOriginCountry: 'IN',
        voteCountGte: 30,
        sortBy: 'popularity.desc',
      ),
      api.discoverMovies(
        page: page,
        withOriginalLanguage: 'kn',
        withOriginCountry: 'IN',
        voteCountGte: 30,
        sortBy: 'popularity.desc',
      ),
    ]);
    final merged = <int, MediaItem>{};
    for (final list in results) {
      for (final item in list) {
        merged[item.tmdbId] ??= item;
      }
    }
    final sorted = merged.values.toList()
      ..sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
    return sorted;
  }

  static String _dateAgo(Duration d) {
    final past = DateTime.now().subtract(d);
    final y = past.year.toString().padLeft(4, '0');
    final m = past.month.toString().padLeft(2, '0');
    final dd = past.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  // --- Helpers ---------------------------------------------------------------

  Map<String, List<MediaItem>> _fallbackRowMap() {
    return {for (final title in _allRowTitles) title: _fallbackCategory(title, 1)};
  }

  List<MediaItem> _fallbackCategory(String title, int page) {
    if (page < 1 || page > _fallbackMaxPages) return const [];
    // Always prefer the curated seed pool over generic samples to keep the
    // row title and content semantically consistent.
    final synthetic = _syntheticFallbackPage(title, page);
    if (synthetic.isNotEmpty) return synthetic;
    final base = _fallbackBase(title);
    if (base.isEmpty) return const [];
    final offset = _stableHash(title) % base.length;
    final rotated = [...base.skip(offset), ...base.take(offset)];
    final start = (page - 1) * _fallbackPageSize;
    if (start < rotated.length) {
      return rotated.skip(start).take(_fallbackPageSize).toList();
    }
    return const [];
  }

  List<MediaItem> _fallbackBase(String title) {
    final sample = MediaItem.samples;
    final lower = title.toLowerCase();
    if (lower.contains('hindi') || lower.contains('bollywood') || lower.contains('tamil')) {
      return _tag(sample, 'top-hindi');
    }
    if (lower.contains('anime')) return _tag(sample, 'anime');
    if (lower.contains('netflix')) return _tag(sample, 'top-netflix');
    if (lower.contains('family')) return _tag(sample, 'family');
    if (lower.contains('sci-fi') || lower.contains('sci fi')) {
      return _tag(sample, 'sci-fi');
    }
    if (lower.contains('action') || lower.contains('thriller') ||
        lower.contains('shounen')) {
      return _tag(sample, 'action');
    }
    if (lower.contains('series') || lower.contains('tv')) {
      return sample.where((m) => m.mediaType == MediaType.tv).toList();
    }
    if (lower.contains('movie') || lower.contains('release') ||
        lower.contains('cinema') || lower.contains('drama') ||
        lower.contains('comedy') || lower.contains('horror')) {
      return sample.where((m) => m.mediaType == MediaType.movie).toList();
    }
    return sample;
  }

  List<MediaItem> _syntheticFallbackPage(String title, int page) {
    final seeds = _seedPool(title);
    final categoryHash = _stableHash(title);
    if (seeds.isEmpty) return const [];
    final pageSeeds = List.generate(_fallbackPageSize, (index) {
      final globalIndex = (page - 1) * _fallbackPageSize + index;
      return seeds[(globalIndex + categoryHash) % seeds.length];
    });
    // Dedupe within page so a row never repeats the same title locally.
    final seenTitles = <String>{};
    return pageSeeds
        .where((seed) => seenTitles.add('${seed.mediaType.name}:${seed.title.toLowerCase()}'))
        .map((seed) => _seedToMediaItem(title, seed, page))
        .toList();
  }

  List<_FallbackSeed> _seedPool(String title) {
    final seen = <String>{};
    final output = <_FallbackSeed>[];
    final lower = title.toLowerCase();
    Iterable<_FallbackSeed> primary;
    if (lower.contains('netflix')) {
      primary = _netflixFallbackSeeds;
    } else if (lower.contains('hindi web') || lower.contains('hindi series')) {
      primary = _hindiTvSeeds;
    } else if (lower.contains('bollywood') || lower.contains('top hindi') ||
        lower.contains('latest hindi')) {
      primary = _hindiMovieSeeds;
    } else if (lower.contains('hindi dubbed') || lower.contains('dubbed')) {
      primary = _hindiDubbedSeeds;
    } else if (lower.contains('tamil') || lower.contains('telugu')) {
      primary = _tamilTeluguSeeds;
    } else if (lower.contains('korean drama')) {
      primary = _koreanDramaSeeds;
    } else if (lower.contains('korean cinema') || lower.contains('korean')) {
      primary = _koreanCinemaSeeds;
    } else if (lower.contains('british')) {
      primary = _britishTvSeeds;
    } else if (lower.contains('shounen')) {
      primary = _shounenAnimeSeeds;
    } else if (lower.contains('slice') || lower.contains('drama anime')) {
      primary = _sliceOfLifeAnimeSeeds;
    } else if (lower.contains('fantasy anime') || lower.contains('isekai')) {
      primary = _fantasyAnimeSeeds;
    } else if (lower.contains('classic anime')) {
      primary = _classicAnimeSeeds;
    } else if (lower.contains('anime movies')) {
      primary = _animeMoviesSeeds;
    } else if (lower.contains('just released') ||
        lower.contains('new season') ||
        lower.contains('new episodes') ||
        lower.contains('currently airing anime')) {
      primary = _currentAnimeSeeds;
    } else if (lower.contains('anime')) {
      primary = _animeFallbackSeeds;
    } else if (lower.contains('crime') || lower.contains('mystery')) {
      primary = _crimeMysterySeeds;
    } else if (lower.contains('horror')) {
      primary = _horrorSeeds;
    } else if (lower.contains('comedy')) {
      primary = _comedyFallbackSeeds;
    } else if (lower.contains('drama')) {
      primary = _dramaFallbackSeeds;
    } else if (lower.contains('family')) {
      primary = _familyFallbackSeeds;
    } else if (lower.contains('sci-fi') || lower.contains('sci fi')) {
      primary = _sciFiFallbackSeeds;
    } else if (lower.contains('action') || lower.contains('thriller')) {
      primary = _actionFallbackSeeds;
    } else if (lower.contains('top tv') || lower.contains('top rated tv') ||
        lower.contains('currently airing') || lower.contains('series')) {
      primary = _seriesFallbackSeeds;
    } else if (lower.contains('movie') || lower.contains('release') ||
        lower.contains('cinema')) {
      primary = _movieFallbackSeeds;
    } else {
      primary = _mixedFallbackSeeds;
    }

    // Strict pool: never bleed mixed seeds into a typed row. This keeps
    // anime rows pure anime, Bollywood rows pure Bollywood, etc., even when
    // the user paginates deep.
    for (final seed in primary) {
      final key = '${seed.mediaType.name}:${seed.title}';
      if (seen.add(key)) output.add(seed);
    }
    return output;
  }

  List<String> _fallbackTags(String title, _FallbackSeed seed) {
    final tags = <String>{
      if (seed.mediaType == MediaType.tv) 'tv' else 'movies',
      seed.genre.toLowerCase(),
    };
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('hindi') || lowerTitle.contains('bollywood')) {
      tags.add('top-hindi');
    }
    if (lowerTitle.contains('dubbed')) tags.add('hindi-dubbed');
    if (lowerTitle.contains('anime')) tags.add('anime');
    if (lowerTitle.contains('sci-fi')) tags.add('sci-fi');
    if (lowerTitle.contains('action') || lowerTitle.contains('shounen')) {
      tags.add('action');
    }
    if (lowerTitle.contains('family')) tags.add('family');
    if (lowerTitle.contains('new') || lowerTitle.contains('latest') ||
        lowerTitle.contains('currently airing')) {
      tags.add('new');
    }
    if (lowerTitle.contains('netflix')) tags.add('top-netflix');
    return tags.toList();
  }

  int _stableHash(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x0fffffff;
    }
    return hash;
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

  List<MediaItem> _tag(Iterable<MediaItem> items, String tag) {
    return items.where((item) => item.tags.contains(tag)).toList();
  }

  List<MediaItem> _dedupe(Iterable<MediaItem> items) {
    final seen = <String>{};
    final output = <MediaItem>[];
    for (final item in items) {
      final key = _idKey(item);
      if (seen.add(key)) output.add(item);
    }
    return output;
  }

  String _idKey(MediaItem item) => '${item.mediaType.name}:${item.tmdbId}';

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

class _RowTitles {
  static const topOnNetflix = 'Top on Netflix';
  static const trendingNow = 'Trending Now';
  static const topHindi = 'Top Hindi';
  static const hindiWebSeries = 'Hindi Web Series';
  static const hindiDubbedHits = 'Hindi-Dubbed Hollywood';
  static const tamilTeluguHits = 'Tamil & Telugu Hits';
  static const newReleases = 'New Releases';
  static const actionThrillers = 'Action & Thrillers';
  static const sciFiVault = 'Sci-Fi Vault';
  static const animeSpotlight = 'Anime Spotlight';
  static const seriesWorthStarting = 'Series Worth Starting';
  // Movies
  static const topMovies = 'Most Popular Movies';
  static const topRatedMovies = 'Top Rated Movies';
  static const acclaimedDramas = 'Acclaimed Dramas';
  static const bollywoodActionMovies = 'Bollywood Action';
  static const latestHindiReleases = 'Latest Hindi Releases';
  static const koreanCinema = 'Korean Cinema';
  static const comedyMovies = 'Comedy Picks';
  static const familyNight = 'Family Night';
  static const horrorPicks = 'Horror Vault';
  // TV
  static const topTvShows = 'Most Popular Series';
  static const topRatedTv = 'Top Rated Series';
  static const currentlyAiringTv = 'Currently Airing';
  static const koreanDrama = 'Korean Drama';
  static const britishTv = 'British TV';
  static const crimeMystery = 'Crime & Mystery';
  static const sciFiSeries = 'Sci-Fi Series';
  static const actionSeries = 'Action Series';
  // Anime
  static const animeCurrentlyAiring = 'New Episodes This Season';
  static const shounenAction = 'Shounen Action';
  static const sliceOfLifeAnime = 'Slice of Life';
  static const fantasyAnime = 'Fantasy & Isekai';
  static const animeMovies = 'Anime Movies';
  static const newSeasonAnime = 'Just Released Anime';
  static const classicAnime = 'Classic Anime';
}

typedef _TmdbFetcher = Future<List<MediaItem>> Function(
  TmdbRemoteDataSource api,
  int page,
);

typedef _CinemetaFetcher = Future<List<MediaItem>> Function(
  CinemetaRemoteDataSource api,
  int page,
);

class _RowConfig {
  _RowConfig({
    required this.title,
    required this.fetch,
    this.cinemetaFallback,
    this.tags = const [],
    this.minItems = 6,
  });

  final String title;
  final _TmdbFetcher fetch;
  final _CinemetaFetcher? cinemetaFallback;
  final List<String> tags;
  final int minItems;

  List<MediaItem> fallback(List<MediaItem> sample) {
    if (tags.isEmpty) return sample;
    return sample
        .where((item) => tags.any((tag) => item.tags.contains(tag)))
        .toList();
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
  _FallbackSeed('Mission: Impossible - Fallout', MediaType.movie, 'Action', '2018'),
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
  _FallbackSeed('Foundation', MediaType.tv, 'Sci-Fi', '2021'),
  _FallbackSeed('For All Mankind', MediaType.tv, 'Sci-Fi', '2019'),
  _FallbackSeed('Yellowstone', MediaType.tv, 'Drama', '2018'),
  _FallbackSeed('Sherlock', MediaType.tv, 'Mystery', '2010'),
  _FallbackSeed('True Detective', MediaType.tv, 'Crime', '2014'),
  _FallbackSeed('Mindhunter', MediaType.tv, 'Crime', '2017'),
];

const _animeFallbackSeeds = <_FallbackSeed>[
  _FallbackSeed('Frieren: Beyond Journey End', MediaType.tv, 'Anime', '2023'),
  _FallbackSeed('Vinland Saga', MediaType.tv, 'Anime', '2019'),
  _FallbackSeed('Mob Psycho 100', MediaType.tv, 'Anime', '2016'),
  _FallbackSeed('Spy x Family', MediaType.tv, 'Anime', '2022'),
  _FallbackSeed('Demon Slayer', MediaType.tv, 'Anime', '2019'),
  _FallbackSeed('Jujutsu Kaisen', MediaType.tv, 'Anime', '2020'),
  _FallbackSeed('Chainsaw Man', MediaType.tv, 'Anime', '2022'),
  _FallbackSeed('Dandadan', MediaType.tv, 'Anime', '2024'),
  _FallbackSeed('Solo Leveling', MediaType.tv, 'Anime', '2024'),
  _FallbackSeed('Delicious in Dungeon', MediaType.tv, 'Anime', '2024'),
  _FallbackSeed('Apothecary Diaries', MediaType.tv, 'Anime', '2023'),
  _FallbackSeed('Kaiju No. 8', MediaType.tv, 'Anime', '2024'),
];

const _shounenAnimeSeeds = <_FallbackSeed>[
  _FallbackSeed('My Hero Academia', MediaType.tv, 'Anime', '2016'),
  _FallbackSeed('Naruto Shippuden', MediaType.tv, 'Anime', '2007'),
  _FallbackSeed('Bleach: Thousand-Year Blood War', MediaType.tv, 'Anime', '2022'),
  _FallbackSeed('Black Clover', MediaType.tv, 'Anime', '2017'),
  _FallbackSeed('Hunter x Hunter', MediaType.tv, 'Anime', '2011'),
  _FallbackSeed('Demon Slayer', MediaType.tv, 'Anime', '2019'),
  _FallbackSeed('Jujutsu Kaisen', MediaType.tv, 'Anime', '2020'),
  _FallbackSeed('Chainsaw Man', MediaType.tv, 'Anime', '2022'),
  _FallbackSeed('Solo Leveling', MediaType.tv, 'Anime', '2024'),
  _FallbackSeed('Tokyo Revengers', MediaType.tv, 'Anime', '2021'),
  _FallbackSeed('Blue Lock', MediaType.tv, 'Anime', '2022'),
  _FallbackSeed('One Piece', MediaType.tv, 'Anime', '1999'),
];

const _sliceOfLifeAnimeSeeds = <_FallbackSeed>[
  _FallbackSeed('A Silent Voice', MediaType.movie, 'Anime', '2016'),
  _FallbackSeed('Your Lie in April', MediaType.tv, 'Anime', '2014'),
  _FallbackSeed('Violet Evergarden', MediaType.tv, 'Anime', '2018'),
  _FallbackSeed('Anohana', MediaType.tv, 'Anime', '2011'),
  _FallbackSeed('Clannad: After Story', MediaType.tv, 'Anime', '2008'),
  _FallbackSeed('March Comes In Like a Lion', MediaType.tv, 'Anime', '2016'),
  _FallbackSeed('Barakamon', MediaType.tv, 'Anime', '2014'),
  _FallbackSeed('Skip Beat!', MediaType.tv, 'Anime', '2008'),
  _FallbackSeed('Frieren: Beyond Journey End', MediaType.tv, 'Anime', '2023'),
];

const _fantasyAnimeSeeds = <_FallbackSeed>[
  _FallbackSeed('Re: Zero', MediaType.tv, 'Anime', '2016'),
  _FallbackSeed('Mushoku Tensei', MediaType.tv, 'Anime', '2021'),
  _FallbackSeed('Overlord', MediaType.tv, 'Anime', '2015'),
  _FallbackSeed('That Time I Got Reincarnated as a Slime', MediaType.tv, 'Anime', '2018'),
  _FallbackSeed('Konosuba', MediaType.tv, 'Anime', '2016'),
  _FallbackSeed('No Game No Life', MediaType.tv, 'Anime', '2014'),
  _FallbackSeed('Sword Art Online', MediaType.tv, 'Anime', '2012'),
  _FallbackSeed('The Eminence in Shadow', MediaType.tv, 'Anime', '2022'),
  _FallbackSeed('Berserk: Golden Age', MediaType.tv, 'Anime', '2016'),
];

const _classicAnimeSeeds = <_FallbackSeed>[
  _FallbackSeed('Cowboy Bebop', MediaType.tv, 'Anime', '1998'),
  _FallbackSeed('Neon Genesis Evangelion', MediaType.tv, 'Anime', '1995'),
  _FallbackSeed('Dragon Ball Z', MediaType.tv, 'Anime', '1989'),
  _FallbackSeed('Fullmetal Alchemist: Brotherhood', MediaType.tv, 'Anime', '2009'),
  _FallbackSeed('Death Note', MediaType.tv, 'Anime', '2006'),
  _FallbackSeed('Ghost in the Shell: Stand Alone Complex', MediaType.tv, 'Anime', '2002'),
  _FallbackSeed('Trigun', MediaType.tv, 'Anime', '1998'),
  _FallbackSeed('Yu Yu Hakusho', MediaType.tv, 'Anime', '1992'),
  _FallbackSeed('Rurouni Kenshin', MediaType.tv, 'Anime', '1996'),
  _FallbackSeed('Inuyasha', MediaType.tv, 'Anime', '2000'),
];

const _animeMoviesSeeds = <_FallbackSeed>[
  _FallbackSeed('Spirited Away', MediaType.movie, 'Anime', '2001'),
  _FallbackSeed('Princess Mononoke', MediaType.movie, 'Anime', '1997'),
  _FallbackSeed('Your Name', MediaType.movie, 'Anime', '2016'),
  _FallbackSeed('Suzume', MediaType.movie, 'Anime', '2022'),
  _FallbackSeed('A Silent Voice', MediaType.movie, 'Anime', '2016'),
  _FallbackSeed('Weathering With You', MediaType.movie, 'Anime', '2019'),
  _FallbackSeed('The Boy and the Heron', MediaType.movie, 'Anime', '2023'),
  _FallbackSeed('Akira', MediaType.movie, 'Anime', '1988'),
  _FallbackSeed('Demon Slayer: Mugen Train', MediaType.movie, 'Anime', '2020'),
  _FallbackSeed('Jujutsu Kaisen 0', MediaType.movie, 'Anime', '2021'),
  _FallbackSeed('Howl Moving Castle', MediaType.movie, 'Anime', '2004'),
];

const _currentAnimeSeeds = <_FallbackSeed>[
  _FallbackSeed('Solo Leveling Season 2', MediaType.tv, 'Anime', '2025'),
  _FallbackSeed('Dandadan', MediaType.tv, 'Anime', '2024'),
  _FallbackSeed('Wind Breaker', MediaType.tv, 'Anime', '2024'),
  _FallbackSeed('My Hero Academia: Final Season', MediaType.tv, 'Anime', '2025'),
  _FallbackSeed('Bleach: Thousand-Year Blood War Part 3', MediaType.tv, 'Anime', '2024'),
  _FallbackSeed('Mashle: Magic and Muscles 2', MediaType.tv, 'Anime', '2024'),
  _FallbackSeed('The Eminence in Shadow Season 2', MediaType.tv, 'Anime', '2023'),
  _FallbackSeed('Spy x Family Season 3', MediaType.tv, 'Anime', '2025'),
  _FallbackSeed('Mushoku Tensei Season 2', MediaType.tv, 'Anime', '2023'),
  _FallbackSeed('Re: Zero Season 3', MediaType.tv, 'Anime', '2024'),
  _FallbackSeed('Frieren Part 2', MediaType.tv, 'Anime', '2024'),
  _FallbackSeed('Apothecary Diaries Season 2', MediaType.tv, 'Anime', '2025'),
  _FallbackSeed('Kaiju No. 8 Season 2', MediaType.tv, 'Anime', '2025'),
  _FallbackSeed('Delicious in Dungeon Part 2', MediaType.tv, 'Anime', '2024'),
  _FallbackSeed('Blue Lock Season 2', MediaType.tv, 'Anime', '2024'),
  _FallbackSeed('Tokyo Revengers: Final Season', MediaType.tv, 'Anime', '2024'),
];

const _hindiMovieSeeds = <_FallbackSeed>[
  _FallbackSeed('3 Idiots', MediaType.movie, 'Comedy', '2009'),
  _FallbackSeed('PK', MediaType.movie, 'Comedy', '2014'),
  _FallbackSeed('Andhadhun', MediaType.movie, 'Thriller', '2018'),
  _FallbackSeed('Gully Boy', MediaType.movie, 'Drama', '2019'),
  _FallbackSeed('Zindagi Na Milegi Dobara', MediaType.movie, 'Drama', '2011'),
  _FallbackSeed('Article 15', MediaType.movie, 'Drama', '2019'),
  _FallbackSeed('Super 30', MediaType.movie, 'Drama', '2019'),
  _FallbackSeed('Sardar Udham', MediaType.movie, 'Drama', '2021'),
  _FallbackSeed('Shershaah', MediaType.movie, 'Drama', '2021'),
  _FallbackSeed('Tumbbad', MediaType.movie, 'Horror', '2018'),
  _FallbackSeed('Bajrangi Bhaijaan', MediaType.movie, 'Drama', '2015'),
  _FallbackSeed('12th Fail', MediaType.movie, 'Drama', '2023'),
  _FallbackSeed('Maharaja', MediaType.movie, 'Thriller', '2024'),
  _FallbackSeed('Laapataa Ladies', MediaType.movie, 'Comedy', '2024'),
  _FallbackSeed('Stree 2', MediaType.movie, 'Comedy', '2024'),
  _FallbackSeed('Drishyam 2', MediaType.movie, 'Thriller', '2022'),
  _FallbackSeed('Animal', MediaType.movie, 'Action', '2023'),
  _FallbackSeed('Pathaan', MediaType.movie, 'Action', '2023'),
  _FallbackSeed('War', MediaType.movie, 'Action', '2019'),
  _FallbackSeed('Lagaan', MediaType.movie, 'Drama', '2001'),
  _FallbackSeed('Dil Chahta Hai', MediaType.movie, 'Drama', '2001'),
  _FallbackSeed('Rang De Basanti', MediaType.movie, 'Drama', '2006'),
  _FallbackSeed('Munna Bhai M.B.B.S.', MediaType.movie, 'Comedy', '2003'),
  _FallbackSeed('Queen', MediaType.movie, 'Comedy', '2014'),
];

const _hindiTvSeeds = <_FallbackSeed>[
  _FallbackSeed('Sacred Games', MediaType.tv, 'Crime', '2018'),
  _FallbackSeed('Mirzapur', MediaType.tv, 'Crime', '2018'),
  _FallbackSeed('The Family Man', MediaType.tv, 'Thriller', '2019'),
  _FallbackSeed('Scam 1992', MediaType.tv, 'Drama', '2020'),
  _FallbackSeed('Panchayat', MediaType.tv, 'Comedy', '2020'),
  _FallbackSeed('Delhi Crime', MediaType.tv, 'Crime', '2019'),
  _FallbackSeed('Aspirants', MediaType.tv, 'Drama', '2021'),
  _FallbackSeed('Asur', MediaType.tv, 'Thriller', '2020'),
  _FallbackSeed('Made in Heaven', MediaType.tv, 'Drama', '2019'),
  _FallbackSeed('Gullak', MediaType.tv, 'Comedy', '2019'),
  _FallbackSeed('Kota Factory', MediaType.tv, 'Drama', '2019'),
  _FallbackSeed('Paatal Lok', MediaType.tv, 'Crime', '2020'),
  _FallbackSeed('Jamtara', MediaType.tv, 'Crime', '2020'),
  _FallbackSeed('TVF Pitchers', MediaType.tv, 'Drama', '2015'),
  _FallbackSeed('Special Ops', MediaType.tv, 'Thriller', '2020'),
  _FallbackSeed('Farzi', MediaType.tv, 'Crime', '2023'),
  _FallbackSeed('Heeramandi', MediaType.tv, 'Drama', '2024'),
  _FallbackSeed('Aarya', MediaType.tv, 'Crime', '2020'),
];

const _hindiOriginalsSeeds = <_FallbackSeed>[
  ..._hindiMovieSeeds,
  ..._hindiTvSeeds,
];

const _hindiDubbedSeeds = <_FallbackSeed>[
  _FallbackSeed('Avengers: Endgame', MediaType.movie, 'Action', '2019'),
  _FallbackSeed('Avengers: Infinity War', MediaType.movie, 'Action', '2018'),
  _FallbackSeed('Spider-Man: No Way Home', MediaType.movie, 'Action', '2021'),
  _FallbackSeed('The Dark Knight', MediaType.movie, 'Action', '2008'),
  _FallbackSeed('Inception', MediaType.movie, 'Sci-Fi', '2010'),
  _FallbackSeed('Interstellar', MediaType.movie, 'Sci-Fi', '2014'),
  _FallbackSeed('Top Gun: Maverick', MediaType.movie, 'Action', '2022'),
  _FallbackSeed('Fast X', MediaType.movie, 'Action', '2023'),
  _FallbackSeed('John Wick: Chapter 4', MediaType.movie, 'Action', '2023'),
  _FallbackSeed('Mission: Impossible - Dead Reckoning', MediaType.movie, 'Action', '2023'),
  _FallbackSeed('Oppenheimer', MediaType.movie, 'Drama', '2023'),
  _FallbackSeed('Dune: Part Two', MediaType.movie, 'Sci-Fi', '2024'),
  _FallbackSeed('Deadpool & Wolverine', MediaType.movie, 'Action', '2024'),
  _FallbackSeed('Godzilla x Kong', MediaType.movie, 'Action', '2024'),
  _FallbackSeed('Aquaman', MediaType.movie, 'Action', '2018'),
  _FallbackSeed('Black Panther', MediaType.movie, 'Action', '2018'),
  _FallbackSeed('The Lion King (2019)', MediaType.movie, 'Family', '2019'),
  _FallbackSeed('Jurassic World Dominion', MediaType.movie, 'Sci-Fi', '2022'),
];

const _tamilTeluguSeeds = <_FallbackSeed>[
  _FallbackSeed('RRR', MediaType.movie, 'Action', '2022'),
  _FallbackSeed('Vikram', MediaType.movie, 'Action', '2022'),
  _FallbackSeed('Ponniyin Selvan', MediaType.movie, 'Drama', '2022'),
  _FallbackSeed('Kantara', MediaType.movie, 'Thriller', '2022'),
  _FallbackSeed('KGF: Chapter 2', MediaType.movie, 'Action', '2022'),
  _FallbackSeed('Pushpa: The Rise', MediaType.movie, 'Action', '2021'),
  _FallbackSeed('Pushpa 2: The Rule', MediaType.movie, 'Action', '2024'),
  _FallbackSeed('Jailer', MediaType.movie, 'Action', '2023'),
  _FallbackSeed('Leo', MediaType.movie, 'Action', '2023'),
  _FallbackSeed('Salaar', MediaType.movie, 'Action', '2023'),
  _FallbackSeed('Maharaja', MediaType.movie, 'Thriller', '2024'),
  _FallbackSeed('Jawan', MediaType.movie, 'Action', '2023'),
  _FallbackSeed('HanuMan', MediaType.movie, 'Action', '2024'),
  _FallbackSeed('Kalki 2898 AD', MediaType.movie, 'Sci-Fi', '2024'),
  _FallbackSeed('The Goat', MediaType.movie, 'Action', '2024'),
];

const _koreanCinemaSeeds = <_FallbackSeed>[
  _FallbackSeed('Parasite', MediaType.movie, 'Thriller', '2019'),
  _FallbackSeed('Train to Busan', MediaType.movie, 'Horror', '2016'),
  _FallbackSeed('Oldboy', MediaType.movie, 'Thriller', '2003'),
  _FallbackSeed('The Handmaiden', MediaType.movie, 'Drama', '2016'),
  _FallbackSeed('Burning', MediaType.movie, 'Mystery', '2018'),
  _FallbackSeed('Decision to Leave', MediaType.movie, 'Mystery', '2022'),
  _FallbackSeed('A Taxi Driver', MediaType.movie, 'Drama', '2017'),
  _FallbackSeed('Memories of Murder', MediaType.movie, 'Crime', '2003'),
  _FallbackSeed('I Saw the Devil', MediaType.movie, 'Thriller', '2010'),
  _FallbackSeed('The Wailing', MediaType.movie, 'Horror', '2016'),
  _FallbackSeed('Concrete Utopia', MediaType.movie, 'Thriller', '2023'),
  _FallbackSeed('Exhuma', MediaType.movie, 'Horror', '2024'),
];

const _koreanDramaSeeds = <_FallbackSeed>[
  _FallbackSeed('Squid Game', MediaType.tv, 'Thriller', '2021'),
  _FallbackSeed('Crash Landing on You', MediaType.tv, 'Romance', '2019'),
  _FallbackSeed('Hometown Cha-Cha-Cha', MediaType.tv, 'Romance', '2021'),
  _FallbackSeed('Vincenzo', MediaType.tv, 'Crime', '2021'),
  _FallbackSeed('Itaewon Class', MediaType.tv, 'Drama', '2020'),
  _FallbackSeed('My Mister', MediaType.tv, 'Drama', '2018'),
  _FallbackSeed('Kingdom', MediaType.tv, 'Horror', '2019'),
  _FallbackSeed('Sweet Home', MediaType.tv, 'Horror', '2020'),
  _FallbackSeed('Goblin', MediaType.tv, 'Fantasy', '2016'),
  _FallbackSeed('All of Us Are Dead', MediaType.tv, 'Horror', '2022'),
  _FallbackSeed('The Glory', MediaType.tv, 'Drama', '2022'),
  _FallbackSeed('Move to Heaven', MediaType.tv, 'Drama', '2021'),
  _FallbackSeed('Hellbound', MediaType.tv, 'Horror', '2021'),
  _FallbackSeed('Twenty-Five Twenty-One', MediaType.tv, 'Drama', '2022'),
];

const _britishTvSeeds = <_FallbackSeed>[
  _FallbackSeed('Sherlock', MediaType.tv, 'Mystery', '2010'),
  _FallbackSeed('Peaky Blinders', MediaType.tv, 'Crime', '2013'),
  _FallbackSeed('The Crown', MediaType.tv, 'Drama', '2016'),
  _FallbackSeed('Doctor Who', MediaType.tv, 'Sci-Fi', '2005'),
  _FallbackSeed('Black Mirror', MediaType.tv, 'Sci-Fi', '2011'),
  _FallbackSeed('Slow Horses', MediaType.tv, 'Thriller', '2022'),
  _FallbackSeed('The Gentlemen', MediaType.tv, 'Crime', '2024'),
  _FallbackSeed('Top Boy', MediaType.tv, 'Crime', '2011'),
  _FallbackSeed('Line of Duty', MediaType.tv, 'Crime', '2012'),
  _FallbackSeed('Bodyguard', MediaType.tv, 'Thriller', '2018'),
  _FallbackSeed('Happy Valley', MediaType.tv, 'Crime', '2014'),
  _FallbackSeed('I May Destroy You', MediaType.tv, 'Drama', '2020'),
  _FallbackSeed('Fleabag', MediaType.tv, 'Comedy', '2016'),
  _FallbackSeed('The Crown', MediaType.tv, 'Drama', '2016'),
];

const _crimeMysterySeeds = <_FallbackSeed>[
  _FallbackSeed('True Detective', MediaType.tv, 'Crime', '2014'),
  _FallbackSeed('Sherlock', MediaType.tv, 'Mystery', '2010'),
  _FallbackSeed('Mindhunter', MediaType.tv, 'Crime', '2017'),
  _FallbackSeed('Better Call Saul', MediaType.tv, 'Crime', '2015'),
  _FallbackSeed('Breaking Bad', MediaType.tv, 'Crime', '2008'),
  _FallbackSeed('Ozark', MediaType.tv, 'Crime', '2017'),
  _FallbackSeed('Money Heist', MediaType.tv, 'Crime', '2017'),
  _FallbackSeed('The Sinner', MediaType.tv, 'Crime', '2017'),
  _FallbackSeed('Dark', MediaType.tv, 'Mystery', '2017'),
  _FallbackSeed('Severance', MediaType.tv, 'Mystery', '2022'),
  _FallbackSeed('Only Murders in the Building', MediaType.tv, 'Mystery', '2021'),
];

const _comedyFallbackSeeds = <_FallbackSeed>[
  _FallbackSeed('Barbie', MediaType.movie, 'Comedy', '2023'),
  _FallbackSeed('No Hard Feelings', MediaType.movie, 'Comedy', '2023'),
  _FallbackSeed('The Holdovers', MediaType.movie, 'Comedy', '2023'),
  _FallbackSeed('Free Guy', MediaType.movie, 'Comedy', '2021'),
  _FallbackSeed('The Lost City', MediaType.movie, 'Comedy', '2022'),
  _FallbackSeed('Spider-Man: No Way Home', MediaType.movie, 'Action', '2021'),
  _FallbackSeed('Game Night', MediaType.movie, 'Comedy', '2018'),
  _FallbackSeed('The Grand Budapest Hotel', MediaType.movie, 'Comedy', '2014'),
];

const _dramaFallbackSeeds = <_FallbackSeed>[
  _FallbackSeed('Oppenheimer', MediaType.movie, 'Drama', '2023'),
  _FallbackSeed('The Holdovers', MediaType.movie, 'Drama', '2023'),
  _FallbackSeed('Past Lives', MediaType.movie, 'Drama', '2023'),
  _FallbackSeed('Anatomy of a Fall', MediaType.movie, 'Drama', '2023'),
  _FallbackSeed('Killers of the Flower Moon', MediaType.movie, 'Drama', '2023'),
  _FallbackSeed('Whiplash', MediaType.movie, 'Drama', '2014'),
  _FallbackSeed('Manchester by the Sea', MediaType.movie, 'Drama', '2016'),
  _FallbackSeed('Moonlight', MediaType.movie, 'Drama', '2016'),
  _FallbackSeed('La La Land', MediaType.movie, 'Drama', '2016'),
];

const _horrorSeeds = <_FallbackSeed>[
  _FallbackSeed('Hereditary', MediaType.movie, 'Horror', '2018'),
  _FallbackSeed('Midsommar', MediaType.movie, 'Horror', '2019'),
  _FallbackSeed('The Witch', MediaType.movie, 'Horror', '2015'),
  _FallbackSeed('Get Out', MediaType.movie, 'Horror', '2017'),
  _FallbackSeed('Us', MediaType.movie, 'Horror', '2019'),
  _FallbackSeed('Talk to Me', MediaType.movie, 'Horror', '2023'),
  _FallbackSeed('A Quiet Place', MediaType.movie, 'Horror', '2018'),
  _FallbackSeed('It Follows', MediaType.movie, 'Horror', '2014'),
  _FallbackSeed('Smile', MediaType.movie, 'Horror', '2022'),
  _FallbackSeed('The Substance', MediaType.movie, 'Horror', '2024'),
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
  _FallbackSeed('Star Trek: Strange New Worlds', MediaType.tv, 'Sci-Fi', '2022'),
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
  _FallbackSeed('The Mitchells vs. the Machines', MediaType.movie, 'Family', '2021'),
  _FallbackSeed('Puss in Boots: The Last Wish', MediaType.movie, 'Family', '2022'),
  _FallbackSeed('Spider-Man: Across the Spider-Verse', MediaType.movie, 'Animation', '2023'),
  _FallbackSeed('Elemental', MediaType.movie, 'Family', '2023'),
  _FallbackSeed('Wish', MediaType.movie, 'Family', '2023'),
  _FallbackSeed('The Wild Robot', MediaType.movie, 'Family', '2024'),
];

const _netflixFallbackSeeds = <_FallbackSeed>[
  ..._seriesFallbackSeeds,
  ..._actionFallbackSeeds,
  ..._sciFiFallbackSeeds,
  ..._familyFallbackSeeds,
];

const _mixedFallbackSeeds = <_FallbackSeed>[
  ..._movieFallbackSeeds,
  ..._seriesFallbackSeeds,
  ..._animeFallbackSeeds,
  ..._hindiOriginalsSeeds,
];
