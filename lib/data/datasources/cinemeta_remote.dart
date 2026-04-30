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
    final typePath = mediaType == MediaType.tv ? 'series' : 'movie';
    final response = await _dio.get<Map<String, dynamic>>(
      '$_baseUrl/catalog/$typePath/top/search=${Uri.encodeComponent(query)}.json',
    );
    final items = _items(response);
    if (items.isEmpty) return null;
    return MediaItem.fromCinemeta(items.first, fallbackType: mediaType);
  }

  Iterable<Map<String, dynamic>> _items(
    Response<Map<String, dynamic>> response,
  ) {
    return (response.data?['metas'] as List? ?? const [])
        .whereType<Map<String, dynamic>>();
  }
}
