class PlaybackProgress {
  const PlaybackProgress({
    required this.tmdbId,
    required this.mediaType,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.updatedAt,
    this.seasonNumber,
    this.episodeNumber,
  });

  final int tmdbId;
  final String mediaType;
  final int positionSeconds;
  final int durationSeconds;
  final DateTime updatedAt;
  final int? seasonNumber;
  final int? episodeNumber;

  double get progress {
    if (durationSeconds <= 0) return 0;
    return (positionSeconds / durationSeconds).clamp(0, 1).toDouble();
  }
}
