import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../models/media_item.dart';

class TmdbRemoteDataSource {
  TmdbRemoteDataSource(this._dio);

  final Dio _dio;

  static const _configuredApiKey = String.fromEnvironment('TMDB_API_KEY');

  String get _apiKey => _configuredApiKey;
  bool get isConfigured => _apiKey.isNotEmpty;

  Future<List<MediaItem>> trending({int page = 1}) async {
    if (!isConfigured) return const [];
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.tmdbBaseUrl}/trending/all/week',
      queryParameters: {'api_key': _apiKey, 'page': page},
    );
    return _items(response)
        .where(
          (item) => item['media_type'] == 'movie' || item['media_type'] == 'tv',
        )
        .map(MediaItem.fromTmdb)
        .toList();
  }

  Future<List<MediaItem>> popularMovies({int page = 1}) async {
    return _list(
      path: '/movie/popular',
      queryParameters: {'api_key': _apiKey, 'page': page},
      fallbackType: 'movie',
    );
  }

  Future<List<MediaItem>> topRatedMovies({int page = 1}) async {
    return _list(
      path: '/movie/top_rated',
      queryParameters: {'api_key': _apiKey, 'page': page},
      fallbackType: 'movie',
    );
  }

  Future<List<MediaItem>> upcomingMovies({int page = 1}) async {
    return _list(
      path: '/movie/upcoming',
      queryParameters: {'api_key': _apiKey, 'page': page},
      fallbackType: 'movie',
    );
  }

  Future<List<MediaItem>> popularTv({int page = 1}) async {
    return _list(
      path: '/tv/popular',
      queryParameters: {'api_key': _apiKey, 'page': page},
      fallbackType: 'tv',
    );
  }

  Future<List<MediaItem>> topRatedTv({int page = 1}) async {
    return _list(
      path: '/tv/top_rated',
      queryParameters: {'api_key': _apiKey, 'page': page},
      fallbackType: 'tv',
    );
  }

  Future<List<MediaItem>> onTheAirTv({int page = 1}) async {
    return _list(
      path: '/tv/on_the_air',
      queryParameters: {'api_key': _apiKey, 'page': page},
      fallbackType: 'tv',
    );
  }

  Future<List<MediaItem>> airingTodayTv({int page = 1}) async {
    return _list(
      path: '/tv/airing_today',
      queryParameters: {'api_key': _apiKey, 'page': page},
      fallbackType: 'tv',
    );
  }

  Future<List<MediaItem>> nowPlayingMovies({int page = 1}) async {
    return _list(
      path: '/movie/now_playing',
      queryParameters: {'api_key': _apiKey, 'page': page},
      fallbackType: 'movie',
    );
  }

  Future<List<MediaItem>> discoverMovies({
    int page = 1,
    String? withGenres,
    String? withoutGenres,
    String? withOriginalLanguage,
    String? region,
    String? withOriginCountry,
    String? withKeywords,
    String? withWatchProviders,
    int? voteCountGte,
    double? voteAverageGte,
    String? primaryReleaseDateGte,
    String? primaryReleaseDateLte,
    int? primaryReleaseYear,
    String? withReleaseType,
    String sortBy = 'popularity.desc',
  }) async {
    if (!isConfigured) return const [];
    final queryParameters = <String, dynamic>{
      'api_key': _apiKey,
      'page': page,
      'sort_by': sortBy,
      'include_adult': false,
      'include_video': false,
    };
    _putIf(queryParameters, 'with_genres', withGenres);
    _putIf(queryParameters, 'without_genres', withoutGenres);
    _putIf(queryParameters, 'with_original_language', withOriginalLanguage);
    _putIf(queryParameters, 'region', region);
    _putIf(queryParameters, 'with_origin_country', withOriginCountry);
    _putIf(queryParameters, 'with_keywords', withKeywords);
    _putIf(queryParameters, 'with_watch_providers', withWatchProviders);
    if (withWatchProviders != null) {
      queryParameters['watch_region'] = region ?? 'US';
    }
    _putIf(queryParameters, 'vote_count.gte', voteCountGte);
    _putIf(queryParameters, 'vote_average.gte', voteAverageGte);
    _putIf(queryParameters, 'primary_release_date.gte', primaryReleaseDateGte);
    _putIf(queryParameters, 'primary_release_date.lte', primaryReleaseDateLte);
    _putIf(queryParameters, 'primary_release_year', primaryReleaseYear);
    _putIf(queryParameters, 'with_release_type', withReleaseType);
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.tmdbBaseUrl}/discover/movie',
      queryParameters: queryParameters,
    );
    return _items(
      response,
    ).map((item) => MediaItem.fromTmdb(item, fallbackType: 'movie')).toList();
  }

  Future<List<MediaItem>> discoverTv({
    int page = 1,
    String? withGenres,
    String? withoutGenres,
    String? withOriginalLanguage,
    String? withNetworks,
    String? withOriginCountry,
    String? withKeywords,
    String? withWatchProviders,
    String? watchRegion,
    int? voteCountGte,
    double? voteAverageGte,
    String? firstAirDateGte,
    String? firstAirDateLte,
    int? firstAirDateYear,
    int? withRuntimeGte,
    String sortBy = 'popularity.desc',
  }) async {
    if (!isConfigured) return const [];
    final queryParameters = <String, dynamic>{
      'api_key': _apiKey,
      'page': page,
      'sort_by': sortBy,
      'include_adult': false,
    };
    _putIf(queryParameters, 'with_genres', withGenres);
    _putIf(queryParameters, 'without_genres', withoutGenres);
    _putIf(queryParameters, 'with_original_language', withOriginalLanguage);
    _putIf(queryParameters, 'with_networks', withNetworks);
    _putIf(queryParameters, 'with_origin_country', withOriginCountry);
    _putIf(queryParameters, 'with_keywords', withKeywords);
    _putIf(queryParameters, 'with_watch_providers', withWatchProviders);
    _putIf(queryParameters, 'watch_region', watchRegion);
    _putIf(queryParameters, 'vote_count.gte', voteCountGte);
    _putIf(queryParameters, 'vote_average.gte', voteAverageGte);
    _putIf(queryParameters, 'first_air_date.gte', firstAirDateGte);
    _putIf(queryParameters, 'first_air_date.lte', firstAirDateLte);
    _putIf(queryParameters, 'first_air_date_year', firstAirDateYear);
    _putIf(queryParameters, 'with_runtime.gte', withRuntimeGte);
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.tmdbBaseUrl}/discover/tv',
      queryParameters: queryParameters,
    );
    return _items(
      response,
    ).map((item) => MediaItem.fromTmdb(item, fallbackType: 'tv')).toList();
  }

  Future<String?> imdbIdFor(MediaItem item) async {
    if (!isConfigured) return null;
    final typePath = item.mediaType == MediaType.tv ? 'tv' : 'movie';
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.tmdbBaseUrl}/$typePath/${item.tmdbId}/external_ids',
      queryParameters: {'api_key': _apiKey},
    );
    final imdbId = response.data?['imdb_id'] as String?;
    return imdbId == null || imdbId.isEmpty ? null : imdbId;
  }

  /// Multi-search across movies, TV, and people. People are filtered out by
  /// the caller; here we just stream raw rows in TMDB order.
  Future<List<MediaItem>> searchMulti({
    required String query,
    int page = 1,
  }) async {
    if (!isConfigured) return const [];
    if (query.trim().isEmpty) return const [];
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.tmdbBaseUrl}/search/multi',
      queryParameters: {
        'api_key': _apiKey,
        'query': query,
        'page': page,
        'include_adult': false,
      },
    );
    return _items(response)
        .where(
          (item) => item['media_type'] == 'movie' || item['media_type'] == 'tv',
        )
        .map(MediaItem.fromTmdb)
        .toList();
  }

  /// Fetches the full TV record including the seasons array.
  Future<Map<String, dynamic>?> tvDetails(int tvId) async {
    if (!isConfigured) return null;
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.tmdbBaseUrl}/tv/$tvId',
      queryParameters: {'api_key': _apiKey},
    );
    return response.data;
  }

  /// Fetches one season's full episode list.
  Future<Map<String, dynamic>?> tvSeason(int tvId, int seasonNumber) async {
    if (!isConfigured) return null;
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.tmdbBaseUrl}/tv/$tvId/season/$seasonNumber',
      queryParameters: {'api_key': _apiKey},
    );
    return response.data;
  }

  /// Movie or TV record, including overview, runtime, genres, etc.
  Future<Map<String, dynamic>?> details({
    required int tmdbId,
    required MediaType mediaType,
  }) async {
    if (!isConfigured) return null;
    final typePath = mediaType == MediaType.tv ? 'tv' : 'movie';
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.tmdbBaseUrl}/$typePath/$tmdbId',
      queryParameters: {'api_key': _apiKey},
    );
    return response.data;
  }

  Future<List<MediaItem>> _list({
    required String path,
    required Map<String, dynamic> queryParameters,
    required String fallbackType,
  }) async {
    if (!isConfigured) return const [];
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.tmdbBaseUrl}$path',
      queryParameters: queryParameters,
    );
    return _items(response)
        .map((item) => MediaItem.fromTmdb(item, fallbackType: fallbackType))
        .toList();
  }

  void _putIf(Map<String, dynamic> map, String key, Object? value) {
    if (value == null) return;
    if (value is String && value.isEmpty) return;
    map[key] = value;
  }

  Iterable<Map<String, dynamic>> _items(
    Response<Map<String, dynamic>> response,
  ) {
    return (response.data?['results'] as List? ?? const [])
        .whereType<Map<String, dynamic>>();
  }
}
