import 'package:dio/dio.dart';

import '../models/media_item.dart';

class CinemetaRemoteDataSource {
  CinemetaRemoteDataSource(this._dio);

  final Dio _dio;

  static const _baseUrl = 'https://v3-cinemeta.strem.io';
  static const pageSize = 18;

  Future<List<MediaItem>> catalog({
    required MediaType mediaType,
    int page = 1,
    String? genre,
  }) async {
    final typePath = mediaType == MediaType.tv ? 'series' : 'movie';
    final extras = <String>[];
    if (genre != null && genre.isNotEmpty) {
      extras.add('genre=${Uri.encodeComponent(genre)}');
    }
    final skip = (page - 1).clamp(0, 999) * pageSize;
    if (skip > 0) extras.add('skip=$skip');
    final extraPath = extras.isEmpty ? '' : '/${extras.join('&')}';
    final response = await _dio.get<Map<String, dynamic>>(
      '$_baseUrl/catalog/$typePath/top$extraPath.json',
    );
    return _items(response)
        .map((item) => MediaItem.fromCinemeta(item, fallbackType: mediaType))
        .toList();
  }

  Future<MediaItem?> searchFirst({
    required String query,
    required MediaType mediaType,
  }) async {
    final list = await searchAll(query: query, mediaType: mediaType);
    return list.isEmpty ? null : list.first;
  }

  /// Returns up to 10 results for the given query/type. Used by live search.
  Future<List<MediaItem>> searchAll({
    required String query,
    required MediaType mediaType,
    int limit = 10,
  }) async {
    if (query.trim().isEmpty) return const [];
    final typePath = mediaType == MediaType.tv ? 'series' : 'movie';
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/catalog/$typePath/top/search=${Uri.encodeComponent(query)}.json',
      );
      return _items(response)
          .take(limit)
          .map((item) => MediaItem.fromCinemeta(item, fallbackType: mediaType))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Iterable<Map<String, dynamic>> _items(
    Response<Map<String, dynamic>> response,
  ) {
    return (response.data?['metas'] as List? ?? const [])
        .whereType<Map<String, dynamic>>();
  }
}
