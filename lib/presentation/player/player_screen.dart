import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/theme/app_colors.dart';
import '../../providers.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({
    required this.streamUrl,
    required this.title,
    this.mediaTitle,
    this.tmdbId,
    this.mediaType,
    this.posterPath,
    this.backdropPath,
    this.seasonNumber,
    this.episodeNumber,
    super.key,
  });

  final String? streamUrl;
  final String title;
  final String? mediaTitle;
  final int? tmdbId;
  final String? mediaType;
  final String? posterPath;
  final String? backdropPath;
  final int? seasonNumber;
  final int? episodeNumber;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  final _subscriptions = <StreamSubscription<Object?>>[];
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  DateTime _lastSavedAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _player = Player(
      configuration: const PlayerConfiguration(
        title: 'StreamVault',
        libass: true,
        bufferSize: 96 * 1024 * 1024,
      ),
    );
    _controller = VideoController(_player);
    _subscriptions.add(
      _player.stream.position.listen((position) {
        _position = position;
        _saveProgress();
      }),
    );
    _subscriptions.add(
      _player.stream.duration.listen((duration) {
        _duration = duration;
      }),
    );
    final url = widget.streamUrl;
    if (url != null && url.isNotEmpty) {
      _player.open(Media(url), play: true);
    }
  }

  @override
  void dispose() {
    unawaited(_saveProgress(force: true));
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  Future<void> _saveProgress({bool force = false}) async {
    final tmdbId = widget.tmdbId;
    final mediaType = widget.mediaType;
    if (tmdbId == null || mediaType == null || _duration.inSeconds <= 0) {
      return;
    }
    if (_position.inSeconds < 5) return;
    final now = DateTime.now();
    if (!force && now.difference(_lastSavedAt).inSeconds < 8) return;
    _lastSavedAt = now;

    await ref
        .read(databaseProvider)
        .savePlaybackProgress(
          tmdbId: tmdbId,
          mediaType: mediaType,
          positionSeconds: _position.inSeconds,
          durationSeconds: _duration.inSeconds,
          seasonNumber: widget.seasonNumber,
          episodeNumber: widget.episodeNumber,
        );
    await ref
        .read(syncRepositoryProvider)
        .syncContinueWatching(
          tmdbId: tmdbId,
          mediaType: mediaType,
          title: widget.mediaTitle ?? widget.title,
          positionSeconds: _position.inSeconds,
          durationSeconds: _duration.inSeconds,
          posterPath: widget.posterPath,
          seasonNumber: widget.seasonNumber,
          episodeNumber: widget.episodeNumber,
        );
  }

  @override
  Widget build(BuildContext context) {
    final hasStream = widget.streamUrl != null && widget.streamUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (hasStream)
            Video(controller: _controller)
          else
            const _NoStreamPlaceholder(),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 12,
            right: 12,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: context.pop,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Subtitles',
                  onPressed: _showSubtitleTracks,
                  icon: const Icon(Icons.subtitles_rounded),
                ),
                IconButton(
                  tooltip: 'Audio tracks',
                  onPressed: _showAudioTracks,
                  icon: const Icon(Icons.graphic_eq_rounded),
                ),
                StreamBuilder<VideoParams>(
                  stream: _player.stream.videoParams,
                  builder: (context, snapshot) {
                    final hw = snapshot.data?.hwPixelformat;
                    return Tooltip(
                      message: hw == null
                          ? 'Native media_kit playback. Hardware decoding depends on driver/codec support.'
                          : 'Hardware decode active: $hw',
                      child: Icon(
                        hw == null
                            ? Icons.memory_rounded
                            : Icons.offline_bolt_rounded,
                        color: hw == null ? AppColors.muted : AppColors.teal,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAudioTracks() async {
    final tracks = _player.state.tracks.audio;
    if (tracks.length <= 2) {
      _showMessage('No alternate audio tracks found in this stream.');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) {
        return _TrackSheet<AudioTrack>(
          title: 'Audio Tracks',
          tracks: tracks,
          selected: _player.state.track.audio,
          labelFor: _trackLabel,
          onSelected: (track) {
            _player.setAudioTrack(track);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> _showSubtitleTracks() async {
    final tracks = _player.state.tracks.subtitle;
    if (tracks.length <= 2) {
      _showMessage('No subtitle tracks found in this stream.');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) {
        return _TrackSheet<SubtitleTrack>(
          title: 'Subtitles',
          tracks: tracks,
          selected: _player.state.track.subtitle,
          labelFor: _trackLabel,
          onSelected: (track) {
            _player.setSubtitleTrack(track);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  String _trackLabel(dynamic track) {
    if (track.id == 'auto') return 'Auto';
    if (track.id == 'no') return 'Off';
    final title = track.title as String?;
    final language = track.language as String?;
    return [
      if (title != null && title.isNotEmpty) title,
      if (language != null && language.isNotEmpty) language.toUpperCase(),
      if ((title == null || title.isEmpty) &&
          (language == null || language.isEmpty))
        'Track ${track.id}',
    ].join('  ');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surfaceRaised,
      ),
    );
  }
}

class _TrackSheet<T> extends StatelessWidget {
  const _TrackSheet({
    required this.title,
    required this.tracks,
    required this.selected,
    required this.labelFor,
    required this.onSelected,
  });

  final String title;
  final List<T> tracks;
  final T selected;
  final String Function(T track) labelFor;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            for (final track in tracks)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(labelFor(track)),
                trailing: track == selected
                    ? const Icon(Icons.check_rounded, color: AppColors.gold)
                    : null,
                onTap: () => onSelected(track),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoStreamPlaceholder extends StatelessWidget {
  const _NoStreamPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_circle_outline_rounded,
            color: AppColors.gold,
            size: 72,
          ),
          SizedBox(height: 16),
          Text(
            'No stream URL selected',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          SizedBox(height: 6),
          Text(
            'The native player is ready for authorized direct playback links.',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
