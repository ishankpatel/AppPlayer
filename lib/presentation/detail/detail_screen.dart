import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/datasources/real_debrid_remote.dart';
import '../../data/datasources/torrentio_remote.dart';
import '../../data/models/media_item.dart';
import '../common/smart_network_image.dart';
import '../settings/real_debrid_provider.dart';
import '../watchlist/watchlist_provider.dart';
import 'stream_sources_provider.dart';
import 'tv_details_provider.dart';
import 'widgets/episode_panel.dart';

class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({required this.media, super.key});

  final MediaItem media;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  final _scrollController = ScrollController();
  final _playbackKey = GlobalKey();
  double _collapsedTitleOpacity = 0;
  EpisodePlayback? _selectedEpisode;

  MediaItem get media => widget.media;

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification ||
        notification is ScrollEndNotification) {
      final offset = notification.metrics.pixels;
      final next = ((offset - 380) / 80).clamp(0.0, 1.0);
      if ((next - _collapsedTitleOpacity).abs() > 0.04) {
        setState(() => _collapsedTitleOpacity = next);
      }
    }
    return false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _selectEpisode(int seasonNumber, int episodeNumber, String label) {
    setState(
      () => _selectedEpisode = EpisodePlayback(
        seasonNumber,
        episodeNumber,
        label,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _playbackKey.currentContext;
      if (!mounted || context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    });
  }

  void _openPlayer(
    BuildContext context, {
    EpisodePlayback? episode,
    String? streamUrl,
  }) {
    final title = episode == null
        ? media.title
        : '${media.title} - ${episode.label}';
    context.push(
      Uri(
        path: '/player',
        queryParameters: {
          if (streamUrl != null && streamUrl.isNotEmpty) 'url': streamUrl,
          'title': title,
          'mediaTitle': media.title,
          'tmdbId': media.tmdbId.toString(),
          'mediaType': media.mediaType.name,
          if (media.posterPath != null) 'posterPath': media.posterPath!,
          if (media.backdropPath != null) 'backdropPath': media.backdropPath!,
          if (episode != null) 'seasonNumber': episode.seasonNumber.toString(),
          if (episode != null)
            'episodeNumber': episode.episodeNumber.toString(),
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = media.mediaType == MediaType.tv
        ? ref.watch(tvDetailsForMediaProvider(TvDetailsKey.fromMedia(media)))
        : null;
    final richDetailsAsync = ref.watch(mediaDetailsProvider(media));
    final saved = ref.watch(
      isInWatchlistProvider((tmdbId: media.tmdbId, mediaType: media.mediaType)),
    );

    String overview = media.overview;
    String? tagline;
    String? status;
    final richData = richDetailsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    if (richData != null) {
      final richOverview = (richData['overview'] as String?) ?? '';
      if (richOverview.length > overview.length) overview = richOverview;
      tagline = (richData['tagline'] as String?)?.trim();
      status = (richData['status'] as String?)?.trim();
    }
    final tvData = media.mediaType == MediaType.tv
        ? detailsAsync?.maybeWhen(data: (v) => v, orElse: () => null)
        : null;
    if (tvData != null) {
      if (tvData.overview.length > overview.length) {
        overview = tvData.overview;
      }
      if ((tagline == null || tagline.isEmpty) && tvData.tagline.isNotEmpty) {
        tagline = tvData.tagline;
      }
      if ((status == null || status.isEmpty) && tvData.status.isNotEmpty) {
        status = tvData.status;
      }
    }
    final compact = MediaQuery.sizeOf(context).width < 720;

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: CustomScrollView(
          controller: _scrollController,
          physics: compact
              ? const ClampingScrollPhysics()
              : const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: compact ? 440 : 520,
              pinned: true,
              backgroundColor: AppColors.ink.withValues(
                alpha: 0.20 + 0.75 * _collapsedTitleOpacity,
              ),
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                tooltip: 'Back',
                onPressed: context.pop,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: AnimatedOpacity(
                opacity: _collapsedTitleOpacity,
                duration: const Duration(milliseconds: 140),
                child: Text(
                  media.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Search',
                  onPressed: () => context.push('/search'),
                  icon: const Icon(Icons.search_rounded),
                ),
                IconButton(
                  tooltip: 'Settings',
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final showHeader = constraints.biggest.height > 430;
                  return FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if ((media.backdropUrl ?? media.posterUrl) != null)
                          SmartNetworkImage(
                            imageUrl: media.backdropUrl ?? media.posterUrl!,
                            fit: BoxFit.cover,
                            cacheWidth: MediaQuery.sizeOf(context).width,
                            cacheHeight: compact ? 440 : 520,
                            fallback: _DetailFallback(media),
                          )
                        else
                          _DetailFallback(media),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [AppColors.ink, Color(0x00060607)],
                              stops: [0, 0.7],
                            ),
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xEE060607), Color(0x33060607)],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 28,
                          right: 28,
                          bottom: 40,
                          child: IgnorePointer(
                            ignoring: !showHeader,
                            child: AnimatedOpacity(
                              opacity: showHeader ? 1 : 0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              child: _Header(
                                media: media,
                                tagline: tagline,
                                saved: saved,
                                onPlay: () => _openPlayer(context),
                                onMyList: () => ref
                                    .read(watchlistProvider.notifier)
                                    .toggle(media),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 44),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 900;
                    final metadata = _MetadataPanel(
                      media: media,
                      overview: overview,
                      status: status,
                      onPlayEpisode: _selectEpisode,
                    );
                    final playback = KeyedSubtree(
                      key: _playbackKey,
                      child: _PlaybackPanel(
                        media: media,
                        selectedEpisode: _selectedEpisode,
                        onOpenPlayer: (url, episode) => _openPlayer(
                          context,
                          streamUrl: url,
                          episode: episode,
                        ),
                      ),
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          metadata,
                          const SizedBox(height: 18),
                          playback,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: metadata),
                        const SizedBox(width: 20),
                        Expanded(flex: 4, child: playback),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EpisodePlayback {
  const EpisodePlayback(this.seasonNumber, this.episodeNumber, this.label);

  final int seasonNumber;
  final int episodeNumber;
  final String label;
}

class _PlaybackPanel extends ConsumerStatefulWidget {
  const _PlaybackPanel({
    required this.media,
    required this.onOpenPlayer,
    this.selectedEpisode,
  });

  final MediaItem media;
  final void Function(String? streamUrl, EpisodePlayback? episode) onOpenPlayer;
  final EpisodePlayback? selectedEpisode;

  @override
  ConsumerState<_PlaybackPanel> createState() => _PlaybackPanelState();
}

class _PlaybackPanelState extends ConsumerState<_PlaybackPanel> {
  final _sourceController = TextEditingController();
  bool _resolving = false;
  String? _resolvingKey;
  String? _error;

  @override
  void dispose() {
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _resolveAndPlay() async {
    final source = _sourceController.text.trim();
    if (source.isEmpty) {
      setState(() => _error = 'Paste an authorized hoster URL or magnet link.');
      return;
    }

    final settings = ref
        .read(realDebridSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final apiKey = settings?.apiKey ?? '';
    if (apiKey.isEmpty || settings?.isValid != true) {
      setState(() => _error = 'Add and validate your Real-Debrid key first.');
      return;
    }

    setState(() {
      _resolving = true;
      _error = null;
    });

    try {
      final remote = ref.read(realDebridRemoteProvider);
      final url = source.startsWith('magnet:')
          ? await _resolveMagnet(remote, apiKey, source)
          : await remote.unrestrictLink(apiKey: apiKey, link: source);
      if (!mounted) return;
      if (url == null || url.isEmpty) {
        setState(() {
          _resolving = false;
          _error = 'Real-Debrid did not return a playable URL.';
        });
        return;
      }
      setState(() => _resolving = false);
      widget.onOpenPlayer(url, _effectiveEpisode());
    } on RealDebridException catch (error) {
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _error = error.toString();
      });
    }
  }

  Future<String?> _resolveMagnet(
    RealDebridRemoteDataSource remote,
    String apiKey,
    String magnet, {
    int? fileIdx,
  }) async {
    final torrentId = await remote.addMagnet(apiKey: apiKey, magnet: magnet);
    if (torrentId == null || torrentId.isEmpty) {
      throw RealDebridException('Real-Debrid did not return a torrent id.');
    }

    var selectedFileIds = <int>[];
    final initialInfo = await remote.torrentInfo(
      apiKey: apiKey,
      torrentId: torrentId,
    );
    final files = (initialInfo?['files'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    if (fileIdx != null && fileIdx >= 0 && fileIdx < files.length) {
      final id = (files[fileIdx]['id'] as num?)?.toInt();
      if (id != null) selectedFileIds = [id];
    }
    if (selectedFileIds.isEmpty && files.isNotEmpty) {
      final videoFiles = [...files]
        ..sort((a, b) {
          final aBytes = (a['bytes'] as num?)?.toInt() ?? 0;
          final bBytes = (b['bytes'] as num?)?.toInt() ?? 0;
          return bBytes.compareTo(aBytes);
        });
      final id = (videoFiles.first['id'] as num?)?.toInt();
      if (id != null) selectedFileIds = [id];
    }

    await remote.selectFiles(
      apiKey: apiKey,
      torrentId: torrentId,
      fileIds: selectedFileIds,
    );

    for (var attempt = 0; attempt < 8; attempt++) {
      final info = await remote.torrentInfo(
        apiKey: apiKey,
        torrentId: torrentId,
      );
      final links = (info?['links'] as List? ?? const [])
          .whereType<String>()
          .where((link) => link.isNotEmpty)
          .toList();
      if (links.isNotEmpty) {
        return remote.unrestrictLink(apiKey: apiKey, link: links.first);
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    throw RealDebridException(
      'Real-Debrid accepted the magnet, but links are not ready yet. Try again in a moment.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final realDebrid = ref
        .watch(realDebridSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final hasValidKey = realDebrid?.isValid == true;
    final episode = _effectiveEpisode();
    final sourceSeasonNumber = widget.media.mediaType == MediaType.tv
        ? (episode?.seasonNumber ?? 1)
        : null;
    final sourceEpisodeNumber = widget.media.mediaType == MediaType.tv
        ? (episode?.episodeNumber ?? 1)
        : null;
    final sourceRequest = StreamSourceRequest(
      media: widget.media,
      seasonNumber: sourceSeasonNumber,
      episodeNumber: sourceEpisodeNumber,
    );
    final sourcesAsync = ref.watch(streamSourcesProvider(sourceRequest));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_fill_rounded, color: AppColors.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Playback',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Sources load automatically. Pick a source and StreamVault resolves it through Real-Debrid, then opens the native player.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          if (widget.media.mediaType == MediaType.tv) ...[
            const SizedBox(height: 12),
            _SelectedEpisodeBanner(episode: episode, onDefaultEpisode: () {}),
          ],
          const SizedBox(height: 16),
          if (!hasValidKey) ...[
            OutlinedButton.icon(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.vpn_key_rounded),
              label: const Text('Add Real-Debrid Key'),
            ),
            const SizedBox(height: 12),
          ],
          _SourceList(
            sourcesAsync: sourcesAsync,
            enabled: hasValidKey && !_resolving,
            resolvingKey: _resolvingKey,
            onRefresh: () =>
                ref.invalidate(streamSourcesProvider(sourceRequest)),
            onSelected: (source) => _resolveSource(source, hasValidKey),
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            collapsedIconColor: AppColors.muted,
            iconColor: AppColors.gold,
            title: const Text(
              'Manual source',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            children: [
              TextField(
                controller: _sourceController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Source URL',
                  hintText: 'https://... or magnet:?xt=urn:btih:...',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: hasValidKey && !_resolving
                        ? _resolveAndPlay
                        : null,
                    icon: _resolving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.bolt_rounded),
                    label: const Text('Resolve & Play'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => widget.onOpenPlayer(null, episode),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Open Player'),
                  ),
                ],
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.crimson)),
          ],
          const SizedBox(height: 18),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Pill('Subtitles UI'),
              _Pill('Audio track UI'),
              _Pill('Progress sync-ready'),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _resolveSource(TorrentioStream source, bool hasValidKey) async {
    if (!hasValidKey) {
      setState(() => _error = 'Add and validate your Real-Debrid key first.');
      return;
    }

    final settings = ref
        .read(realDebridSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final apiKey = settings?.apiKey ?? '';
    if (apiKey.isEmpty) {
      setState(() => _error = 'Add and validate your Real-Debrid key first.');
      return;
    }

    final key = '${source.infoHash}:${source.fileIdx ?? -1}';
    setState(() {
      _resolving = true;
      _resolvingKey = key;
      _error = null;
    });

    try {
      final url = await _resolveMagnet(
        ref.read(realDebridRemoteProvider),
        apiKey,
        source.magnetUri,
        fileIdx: source.fileIdx,
      );
      if (!mounted) return;
      if (url == null || url.isEmpty) {
        setState(() {
          _resolving = false;
          _resolvingKey = null;
          _error = 'Real-Debrid did not return a playable URL.';
        });
        return;
      }
      setState(() {
        _resolving = false;
        _resolvingKey = null;
      });
      widget.onOpenPlayer(url, _effectiveEpisode());
    } on RealDebridException catch (error) {
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _resolvingKey = null;
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _resolvingKey = null;
        _error = error.toString();
      });
    }
  }

  EpisodePlayback? _effectiveEpisode() {
    if (widget.media.mediaType != MediaType.tv) return null;
    return widget.selectedEpisode ?? const EpisodePlayback(1, 1, 'S1 E1');
  }
}

class _SelectedEpisodeBanner extends StatelessWidget {
  const _SelectedEpisodeBanner({
    required this.episode,
    required this.onDefaultEpisode,
  });

  final EpisodePlayback? episode;
  final VoidCallback onDefaultEpisode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.tv_rounded, color: AppColors.gold, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              episode == null
                  ? 'Defaulting to Season 1 Episode 1. Pick another episode below.'
                  : 'Selected ${episode!.label}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceList extends StatelessWidget {
  const _SourceList({
    required this.sourcesAsync,
    required this.enabled,
    required this.onSelected,
    required this.onRefresh,
    this.resolvingKey,
  });

  final AsyncValue<List<TorrentioStream>> sourcesAsync;
  final bool enabled;
  final String? resolvingKey;
  final ValueChanged<TorrentioStream> onSelected;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return sourcesAsync.when(
      data: (sources) {
        if (sources.isEmpty) {
          return _SourceMessage(
            icon: Icons.search_off_rounded,
            title: 'No automatic sources found',
            message:
                'Check TMDB/Torrentio connectivity or try a manual source below.',
            onRefresh: onRefresh,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.gold, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${sources.length} playable source options',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  tooltip: 'Reload sources',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 390),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sources.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final source = sources[index];
                  final key = '${source.infoHash}:${source.fileIdx ?? -1}';
                  final resolving = resolvingKey == key;
                  return _SourceTile(
                    source: source,
                    resolving: resolving,
                    enabled: enabled,
                    onTap: () => onSelected(source),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const _SourceMessage(
        icon: Icons.sync_rounded,
        title: 'Loading sources...',
        message: 'Searching Torrentio for playable options.',
      ),
      error: (error, _) => _SourceMessage(
        icon: Icons.warning_rounded,
        title: 'Sources unavailable',
        message: error.toString(),
        onRefresh: onRefresh,
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.source,
    required this.resolving,
    required this.enabled,
    required this.onTap,
  });

  final TorrentioStream source;
  final bool resolving;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.045),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled && !resolving ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: resolving ? AppColors.gold : Colors.white10,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  source.qualityLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _MiniMeta(source.providerLabel),
                        _MiniMeta(source.audioLabel),
                        if (source.sizeLabel.isNotEmpty)
                          _MiniMeta(source.sizeLabel),
                        if (source.seedLabel.isNotEmpty)
                          _MiniMeta(source.seedLabel),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              resolving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_rounded, color: AppColors.text),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMeta extends StatelessWidget {
  const _MiniMeta(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SourceMessage extends StatelessWidget {
  const _SourceMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.onRefresh,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: AppColors.muted, height: 1.35),
                ),
              ],
            ),
          ),
          if (onRefresh != null)
            IconButton(
              tooltip: 'Retry',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.media,
    required this.saved,
    required this.onPlay,
    required this.onMyList,
    this.tagline,
  });

  final MediaItem media;
  final bool saved;
  final VoidCallback onPlay;
  final VoidCallback onMyList;
  final String? tagline;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            media.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          if (tagline != null && tagline!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              tagline!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.gold.withValues(alpha: 0.84),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _Pill(media.releaseYear),
              _Pill(media.runtimeLabel ?? media.mediaTypeLabel),
              _Pill(media.genre),
              if (media.voteAverage > 0)
                _Pill(
                  'TMDB ${media.voteAverage.toStringAsFixed(1)}',
                  accent: true,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Play'),
              ),
              OutlinedButton.icon(
                onPressed: onMyList,
                icon: Icon(saved ? Icons.check_rounded : Icons.add_rounded),
                label: Text(saved ? 'In My List' : 'Add to List'),
                style: saved
                    ? OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        side: const BorderSide(color: AppColors.gold),
                      )
                    : null,
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.local_movies_rounded),
                label: const Text('Trailer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetadataPanel extends StatelessWidget {
  const _MetadataPanel({
    required this.media,
    required this.overview,
    required this.onPlayEpisode,
    this.status,
  });

  final MediaItem media;
  final String overview;
  final String? status;
  final void Function(int seasonNumber, int episodeNumber, String label)
  onPlayEpisode;

  @override
  Widget build(BuildContext context) {
    final cast = media.cast;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('About'),
        const SizedBox(height: 10),
        Text(
          overview.isEmpty
              ? 'A premium streaming title in the StreamVault catalog.'
              : overview,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.55,
            color: AppColors.text.withValues(alpha: 0.82),
          ),
        ),
        if (status != null && status!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [_Pill('Status: $status')],
          ),
        ],
        if (media.mediaType == MediaType.tv) ...[
          const SizedBox(height: 24),
          EpisodePanel(media: media, onPlayEpisode: onPlayEpisode),
        ],
        if (cast.isNotEmpty) ...[
          const SizedBox(height: 24),
          const _SectionHeading('Cast'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [for (final person in cast) _PersonChip(person)],
          ),
        ],
        const SizedBox(height: 24),
        const _SectionHeading('Playback Defaults'),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Pill('Subtitles: English'),
            _Pill('Audio: English'),
            _Pill('Resume sync enabled'),
          ],
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, {this.accent = false});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent
            ? AppColors.gold.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accent
              ? AppColors.gold.withValues(alpha: 0.45)
              : Colors.white12,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent ? AppColors.gold : AppColors.text,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PersonChip extends StatelessWidget {
  const _PersonChip(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _DetailFallback extends StatelessWidget {
  const _DetailFallback(this.media);

  final MediaItem media;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF451313), Color(0xFF080808), Color(0xFF172554)],
        ),
      ),
      child: Center(
        child: Text(
          media.title.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 64,
            height: 0.96,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
