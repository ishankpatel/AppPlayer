import 'package:dio/dio.dart';

import '../models/media_item.dart';

class TorrentioStream {
  const TorrentioStream({
    required this.name,
    required this.title,
    required this.infoHash,
    this.fileIdx,
    this.filename,
  });

  final String name;
  final String title;
  final String infoHash;
  final int? fileIdx;
  final String? filename;

  String get qualityLabel {
    final combined = '$name\n$title'.toLowerCase();
    final match = RegExp(
      r'(4320p|2160p|4k|1080p|720p|480p)',
    ).firstMatch(combined);
    final quality = match?.group(0)?.toLowerCase();
    if (quality == null) return 'Stream';
    if (quality == '2160p' || quality == '4k') return '4K';
    return quality.toUpperCase();
  }

  String get sizeLabel {
    final match = RegExp(
      r'(\d+(?:\.\d+)?)\s*(GB|MB)',
      caseSensitive: false,
    ).firstMatch(title);
    if (match == null) return '';
    return '${match.group(1)} ${match.group(2)?.toUpperCase()}';
  }

  String get seedLabel {
    final match = RegExp(r'\u{1F464}\s*(\d+)', unicode: true).firstMatch(title);
    if (match == null) return '';
    return '${match.group(1)} seeders';
  }

  String get providerLabel {
    final match = RegExp(
      r'\u2699\ufe0f?\s*([^\n]+)',
      unicode: true,
    ).firstMatch(title);
    return match?.group(1)?.trim() ?? 'Torrentio';
  }

  String get displayTitle {
    final firstLine = title.split('\n').first.trim();
    if (firstLine.isNotEmpty) return firstLine;
    return filename ?? name.replaceAll('\n', ' ');
  }

  List<String> get audioLanguages {
    final combined = '$name\n$title\n${filename ?? ''}'.toLowerCase();
    final languages = <String>[];

    if (RegExp(r'\b(hindi|hin|hnd)\b').hasMatch(combined)) {
      languages.add('Hindi');
    }
    if (RegExp(r'\b(gujarati|gujrati|guj)\b').hasMatch(combined)) {
      languages.add('Gujarati');
    }
    if (RegExp(r'\b(english|eng)\b').hasMatch(combined) ||
        combined.contains('\u{1F1EC}\u{1F1E7}')) {
      languages.add('English');
    }
    if (languages.isEmpty &&
        (combined.contains('dual audio') || combined.contains('multi audio'))) {
      languages.add('Multi');
    }
    return languages;
  }

  String get audioLabel {
    final languages = audioLanguages;
    return languages.isEmpty
        ? 'Audio: Unknown'
        : 'Audio: ${languages.join(', ')}';
  }

  String get magnetUri {
    final dn = Uri.encodeComponent(filename ?? displayTitle);
    return 'magnet:?xt=urn:btih:$infoHash&dn=$dn';
  }

  factory TorrentioStream.fromJson(Map<String, dynamic> json) {
    final hints = json['behaviorHints'] is Map
        ? (json['behaviorHints'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    return TorrentioStream(
      name: json['name'] as String? ?? 'Torrentio',
      title: json['title'] as String? ?? '',
      infoHash: (json['infoHash'] as String? ?? '').toLowerCase(),
      fileIdx: (json['fileIdx'] as num?)?.toInt(),
      filename: hints['filename'] as String?,
    );
  }
}

class TorrentioRemoteDataSource {
  TorrentioRemoteDataSource(this._dio);

  final Dio _dio;

  static const _nativeBaseUrl = 'https://torrentio.strem.fun';

  String get _baseUrl => _nativeBaseUrl;

  Future<List<TorrentioStream>> streams({
    required String imdbId,
    required MediaType mediaType,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    if (imdbId.isEmpty || !imdbId.startsWith('tt')) return const [];
    final type = mediaType == MediaType.tv ? 'series' : 'movie';
    final id =
        mediaType == MediaType.tv &&
            seasonNumber != null &&
            episodeNumber != null
        ? '$imdbId:$seasonNumber:$episodeNumber'
        : imdbId;

    final response = await _dio.get<Map<String, dynamic>>(
      '$_baseUrl/stream/$type/$id.json',
      options: Options(
        responseType: ResponseType.json,
        validateStatus: (code) => code != null && code < 600,
      ),
    );
    if ((response.statusCode ?? 500) >= 400) return const [];
    final rawStreams = response.data?['streams'] as List? ?? const [];
    final streams = rawStreams
        .whereType<Map<String, dynamic>>()
        .map(TorrentioStream.fromJson)
        .where((stream) => stream.infoHash.isNotEmpty)
        .toList();
    return _ranked(streams);
  }

  List<TorrentioStream> _ranked(List<TorrentioStream> streams) {
    final deduped = <String, TorrentioStream>{};
    for (final stream in streams) {
      deduped.putIfAbsent(
        '${stream.infoHash}:${stream.fileIdx ?? -1}',
        () => stream,
      );
    }
    final items = deduped.values.toList();
    items.sort((a, b) {
      final quality = _qualityScore(b).compareTo(_qualityScore(a));
      if (quality != 0) return quality;
      return _seedCount(b).compareTo(_seedCount(a));
    });
    return items.take(72).toList();
  }

  int _qualityScore(TorrentioStream stream) {
    final text = '${stream.name}\n${stream.title}'.toLowerCase();
    if (text.contains('4320p')) return 50;
    if (text.contains('2160p') || text.contains('4k')) return 40;
    if (text.contains('1080p')) return 30;
    if (text.contains('720p')) return 20;
    return 10;
  }

  int _seedCount(TorrentioStream stream) {
    final match = RegExp(
      r'\u{1F464}\s*(\d+)',
      unicode: true,
    ).firstMatch(stream.title);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }
}
