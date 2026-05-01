import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class RealDebridUser {
  const RealDebridUser({
    required this.id,
    required this.username,
    required this.email,
    required this.points,
    required this.locale,
    required this.avatar,
    required this.type,
    required this.premiumSeconds,
    required this.expirationIso,
  });

  final int id;
  final String username;
  final String email;
  final int points;
  final String locale;
  final String avatar;
  final String type;
  final int premiumSeconds;
  final String expirationIso;

  bool get isPremium => type.toLowerCase() == 'premium' && premiumSeconds > 0;

  Duration get premiumRemaining => Duration(seconds: premiumSeconds);

  factory RealDebridUser.fromJson(Map<String, dynamic> json) {
    return RealDebridUser(
      id: (json['id'] as num? ?? 0).toInt(),
      username: (json['username'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      points: (json['points'] as num? ?? 0).toInt(),
      locale: (json['locale'] as String?) ?? '',
      avatar: (json['avatar'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'free',
      premiumSeconds: (json['premium'] as num? ?? 0).toInt(),
      expirationIso: (json['expiration'] as String?) ?? '',
    );
  }
}

class RealDebridTraffic {
  const RealDebridTraffic({required this.bytes, required this.limit});
  final int bytes;
  final int limit;
}

/// Thrown when a Real-Debrid call fails. We bubble enough info to render
/// helpful messages in the settings panel.
class RealDebridException implements Exception {
  RealDebridException(this.message, {this.statusCode, this.errorCode});
  final String message;
  final int? statusCode;
  final int? errorCode;

  @override
  String toString() =>
      'RealDebridException($message, status=$statusCode, code=$errorCode)';
}

/// Minimal Real-Debrid REST client. Covers the surfaces we need:
///  - validate API key (`/user`)
///  - resolve hoster link to direct stream (`/unrestrict/link`)
///  - magnet handling (`/torrents/addMagnet` + `/torrents/info` + `/torrents/selectFiles`)
///  - traffic ledger (`/traffic`)
class RealDebridRemoteDataSource {
  RealDebridRemoteDataSource(this._dio);

  final Dio _dio;

  static const _nativeBaseUrl = 'https://api.real-debrid.com/rest/1.0';
  static const _webProxyBaseUrl = '/api/real-debrid/rest/1.0';

  String get _baseUrl => kIsWeb ? _webProxyBaseUrl : _nativeBaseUrl;

  Future<RealDebridUser> me(String apiKey) async {
    final res = await _get<Map<String, dynamic>>(apiKey, '/user');
    if (res == null) {
      throw RealDebridException('Empty response from /user');
    }
    return RealDebridUser.fromJson(res);
  }

  /// Convert a "supported hoster" URL or a magnet-resolved direct link to
  /// a streamable URL. This is the core endpoint Real-Debrid users call.
  Future<String?> unrestrictLink({
    required String apiKey,
    required String link,
    String? password,
  }) async {
    final form = <String, String>{'link': link};
    if (password != null && password.isNotEmpty) {
      form['password'] = password;
    }
    final res = await _post<Map<String, dynamic>>(
      apiKey,
      '/unrestrict/link',
      formData: form,
    );
    if (res == null) return null;
    return res['download'] as String?;
  }

  /// Add a magnet link. Returns the new torrent id.
  Future<String?> addMagnet({
    required String apiKey,
    required String magnet,
  }) async {
    final res = await _post<Map<String, dynamic>>(
      apiKey,
      '/torrents/addMagnet',
      formData: {'magnet': magnet},
    );
    return res?['id'] as String?;
  }

  Future<Map<String, dynamic>?> torrentInfo({
    required String apiKey,
    required String torrentId,
  }) async {
    return _get<Map<String, dynamic>>(apiKey, '/torrents/info/$torrentId');
  }

  Future<void> selectFiles({
    required String apiKey,
    required String torrentId,
    required List<int> fileIds,
  }) async {
    final body = fileIds.isEmpty ? 'all' : fileIds.join(',');
    await _post<dynamic>(
      apiKey,
      '/torrents/selectFiles/$torrentId',
      formData: {'files': body},
    );
  }

  Future<int> remainingTrafficBytes(String apiKey) async {
    final res = await _get<Map<String, dynamic>>(apiKey, '/traffic');
    if (res == null) return 0;
    var sum = 0;
    res.forEach((_, value) {
      if (value is Map && value['left'] is num) {
        sum += (value['left'] as num).toInt();
      }
    });
    return sum;
  }

  Future<T?> _get<T>(String apiKey, String path) async {
    try {
      final response = await _dio.get<T>(
        '$_baseUrl$path',
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
          responseType: ResponseType.json,
          validateStatus: (code) => code != null && code < 600,
        ),
      );
      _ensureOk(response.statusCode, response.data);
      return response.data;
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<T?> _post<T>(
    String apiKey,
    String path, {
    Map<String, dynamic>? formData,
  }) async {
    try {
      final response = await _dio.post<T>(
        '$_baseUrl$path',
        data: formData == null ? null : FormData.fromMap(formData),
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
          responseType: ResponseType.json,
          validateStatus: (code) => code != null && code < 600,
        ),
      );
      _ensureOk(response.statusCode, response.data);
      return response.data;
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  void _ensureOk(int? statusCode, Object? data) {
    if (statusCode == null) return;
    if (statusCode >= 200 && statusCode < 300) return;
    if (statusCode == 401 || statusCode == 403) {
      throw RealDebridException(
        'Real-Debrid rejected the API key. Generate a new one at real-debrid.com/apitoken.',
        statusCode: statusCode,
      );
    }
    if (statusCode == 429) {
      throw RealDebridException(
        'Real-Debrid rate limit reached. Try again in a minute.',
        statusCode: statusCode,
      );
    }
    final code = (data is Map && data['error_code'] is num)
        ? (data['error_code'] as num).toInt()
        : null;
    final message = data is Map && data['error'] is String
        ? data['error'] as String
        : 'Real-Debrid request failed with status $statusCode';
    throw RealDebridException(message, statusCode: statusCode, errorCode: code);
  }

  RealDebridException _mapDio(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return RealDebridException(
        'Real-Debrid timed out. Check your connection and retry.',
      );
    }
    if (e.type == DioExceptionType.connectionError) {
      return RealDebridException(
        'Could not reach api.real-debrid.com. Check your network.',
      );
    }
    return RealDebridException(
      e.message ?? 'Network error talking to Real-Debrid',
    );
  }
}
