import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/image_utils.dart';
import '../../providers.dart';
import '../common/smart_network_image.dart';
import '../home/home_provider.dart';

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
  String? _preferredSubtitleLanguage;
  String? _preferredAudioLanguage;

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
          preferredSubtitleLang: _preferredSubtitleLanguage,
          preferredAudioLang: _preferredAudioLanguage,
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
          backdropPath: widget.backdropPath,
          seasonNumber: widget.seasonNumber,
          episodeNumber: widget.episodeNumber,
          preferredSubtitleLang: _preferredSubtitleLanguage,
          preferredAudioLang: _preferredAudioLanguage,
        );
    if (_preferredSubtitleLanguage != null || _preferredAudioLanguage != null) {
      await ref
          .read(syncRepositoryProvider)
          .syncProfilePreferences(
            preferredSubtitleLang: _preferredSubtitleLanguage,
            preferredAudioLang: _preferredAudioLanguage,
          );
    }
    ref.invalidate(continueWatchingProvider);
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
            _NoStreamPlaceholder(
              title: widget.mediaTitle ?? widget.title,
              posterPath: widget.posterPath,
              backdropPath: widget.backdropPath,
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 132,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xCC000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),
          ),
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
            _preferredAudioLanguage = _trackLanguage(track);
            _player.setAudioTrack(track);
            unawaited(_saveProgress(force: true));
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
            _preferredSubtitleLanguage = _trackLanguage(track);
            _player.setSubtitleTrack(track);
            unawaited(_saveProgress(force: true));
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

  String? _trackLanguage(dynamic track) {
    if (track.id == 'no') return null;
    final language = track.language as String?;
    if (language != null && language.isNotEmpty) return language;
    final title = track.title as String?;
    if (title != null && title.isNotEmpty) return title;
    return null;
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
  const _NoStreamPlaceholder({
    required this.title,
    this.posterPath,
    this.backdropPath,
  });

  final String title;
  final String? posterPath;
  final String? backdropPath;

  @override
  Widget build(BuildContext context) {
    final artworkUrl =
        ImageUtils.tmdbBackdrop(backdropPath) ??
        ImageUtils.tmdbPoster(posterPath);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (artworkUrl != null)
          SmartNetworkImage(
            imageUrl: artworkUrl,
            fit: BoxFit.cover,
            cacheWidth: MediaQuery.sizeOf(context).width,
            cacheHeight: MediaQuery.sizeOf(context).height,
            fallback: const _PlayerArtFallback(),
          )
        else
          const _PlayerArtFallback(),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xAA000000), Color(0xEE000000)],
            ),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(44),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.ink,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No stream URL selected. The native player is ready for authorized direct playback links.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text.withValues(alpha: 0.62),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerArtFallback extends StatelessWidget {
  const _PlayerArtFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F1011), Color(0xFF050608), Color(0xFF1A2342)],
        ),
      ),
    );
  }
}
