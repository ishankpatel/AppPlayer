import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/media_item.dart';
import '../common/smart_network_image.dart';
import '../watchlist/watchlist_provider.dart';
import 'tv_details_provider.dart';
import 'widgets/episode_panel.dart';

class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({required this.media, super.key});

  final MediaItem media;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  double _collapsedTitleOpacity = 0;

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

  void _openPlayer(BuildContext context, {EpisodePlayback? episode}) {
    final title = episode == null
        ? media.title
        : '${media.title} - ${episode.label}';
    context.push(
      Uri(
        path: '/player',
        queryParameters: {
          'title': title,
          'mediaTitle': media.title,
          'tmdbId': media.tmdbId.toString(),
          'mediaType': media.mediaType.name,
          if (media.posterPath != null) 'posterPath': media.posterPath!,
          if (media.backdropPath != null) 'backdropPath': media.backdropPath!,
          if (episode != null)
            'seasonNumber': episode.seasonNumber.toString(),
          if (episode != null)
            'episodeNumber': episode.episodeNumber.toString(),
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = media.mediaType == MediaType.tv
        ? ref.watch(tvDetailsProvider(media.tmdbId))
        : null;
    final richDetailsAsync = ref.watch(mediaDetailsProvider(media));
    final saved = ref.watch(
      isInWatchlistProvider(
        (tmdbId: media.tmdbId, mediaType: media.mediaType),
      ),
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

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 520,
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
                      onPlayEpisode: (s, e, label) => _openPlayer(
                        context,
                        episode: EpisodePlayback(s, e, label),
                      ),
                    );
                    final playback = _PlaybackPanel(
                      media: media,
                      onOpenPlayer: () => _openPlayer(context),
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

class _PlaybackPanel extends StatelessWidget {
  const _PlaybackPanel({required this.media, required this.onOpenPlayer});

  final MediaItem media;
  final VoidCallback onOpenPlayer;

  @override
  Widget build(BuildContext context) {
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'The native player shell is ready for authorized direct stream URLs. Provider connectors are intentionally kept out of this branch.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onOpenPlayer,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Open Player'),
          ),
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
            children: [
              _Pill('Status: $status'),
            ],
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
