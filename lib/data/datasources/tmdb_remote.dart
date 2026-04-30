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
    if (!isConfigured) return const [];
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.tmdbBaseUrl}/movie/popular',
      queryParameters: {'api_key': _apiKey, 'page': page},
    );
    return _items(
      response,
    ).map((item) => MediaItem.fromTmdb(item, fallbackType: 'movie')).toList();
  }

  Future<List<MediaItem>> popularTv({int page = 1}) async {
    if (!isConfigured) return const [];
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.tmdbBaseUrl}/tv/popular',
      queryParameters: {'api_key': _apiKey, 'page': page},
    );
    return _items(
      response,
    ).map((item) => MediaItem.fromTmdb(item, fallbackType: 'tv')).toList();
  }

  Future<List<MediaItem>> discoverMovies({
    int page = 1,
    String? withGenres,
    String? withOriginalLanguage,
    String? region,
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
    if (withGenres != null) queryParameters['with_genres'] = withGenres;
    if (withOriginalLanguage != null) {
      queryParameters['with_original_language'] = withOriginalLanguage;
    }
    if (region != null) queryParameters['region'] = region;
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
    String? withOriginalLanguage,
    String? withNetworks,
    String sortBy = 'popularity.desc',
  }) async {
    if (!isConfigured) return const [];
    final queryParameters = <String, dynamic>{
      'api_key': _apiKey,
      'page': page,
      'sort_by': sortBy,
      'include_adult': false,
    };
    if (withGenres != null) queryParameters['with_genres'] = withGenres;
    if (withOriginalLanguage != null) {
      queryParameters['with_original_language'] = withOriginalLanguage;
    }
    if (withNetworks != null) queryParameters['with_networks'] = withNetworks;
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.tmdbBaseUrl}/discover/tv',
      queryParameters: queryParameters,
    );
    return _items(
      response,
    ).map((item) => MediaItem.fromTmdb(item, fallbackType: 'tv')).toList();
  }

  Future<List<MediaItem>> nowPlayingMovies({int page = 1}) async {
    if (!isConfigured) return const [];
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.tmdbBaseUrl}/movie/now_playing',
      queryParameters: {'api_key': _apiKey, 'page': page},
    );
    return _items(
      response,
    ).map((item) => MediaItem.fromTmdb(item, fallbackType: 'movie')).toList();
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

  Iterable<Map<String, dynamic>> _items(
    Response<Map<String, dynamic>> response,
  ) {
    return (response.data?['results'] as List? ?? const [])
        .whereType<Map<String, dynamic>>();
  }
}
