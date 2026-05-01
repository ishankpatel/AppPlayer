import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/torrentio_remote.dart';
import '../../data/models/media_item.dart';
import '../../providers.dart';

class StreamSourceRequest {
  const StreamSourceRequest({
    required this.media,
    this.seasonNumber,
    this.episodeNumber,
  });

  final MediaItem media;
  final int? seasonNumber;
  final int? episodeNumber;

  @override
  bool operator ==(Object other) {
    return other is StreamSourceRequest &&
        media.tmdbId == other.media.tmdbId &&
        media.mediaType == other.media.mediaType &&
        seasonNumber == other.seasonNumber &&
        episodeNumber == other.episodeNumber;
  }

  @override
  int get hashCode =>
      Object.hash(media.tmdbId, media.mediaType, seasonNumber, episodeNumber);
}

final streamSourcesProvider =
    FutureProvider.family<List<TorrentioStream>, StreamSourceRequest>((
      ref,
      request,
    ) async {
      final media = request.media;
      var imdbId = media.imdbId ?? '';
      if (imdbId.isEmpty) {
        imdbId = await ref.read(tmdbRemoteProvider).imdbIdFor(media) ?? '';
      }
      if (imdbId.isEmpty) return const [];

      return ref
          .read(torrentioRemoteProvider)
          .streams(
            imdbId: imdbId,
            mediaType: media.mediaType,
            seasonNumber: request.seasonNumber,
            episodeNumber: request.episodeNumber,
          );
    });
