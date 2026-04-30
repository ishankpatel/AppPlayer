import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/media_item.dart';
import '../common/smart_network_image.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({required this.media, super.key});

  final MediaItem media;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  EpisodeInfo? _selectedEpisode;

  MediaItem get media => widget.media;

  @override
  void initState() {
    super.initState();
    _selectedEpisode = _firstEpisode(media);
  }

  @override
  void didUpdateWidget(covariant DetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media.tmdbId != media.tmdbId) {
      _selectedEpisode = _firstEpisode(media);
    }
  }

  EpisodeInfo? _firstEpisode(MediaItem item) {
    final seasons = item.availableSeasons;
    if (item.mediaType != MediaType.tv || seasons.isEmpty) return null;
    final episodes = seasons.first.episodes;
    return episodes.isEmpty ? null : episodes.first;
  }

  void _openPlayer(BuildContext context) {
    final episode = _selectedEpisode;
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
          if (episode != null) 'seasonNumber': episode.seasonNumber.toString(),
          if (episode != null)
            'episodeNumber': episode.episodeNumber.toString(),
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 520,
            pinned: true,
            leading: IconButton(
              tooltip: 'Back',
              onPressed: context.pop,
              icon: const Icon(Icons.arrow_back_rounded),
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
                            duration: const Duration(milliseconds: 160),
                            child: _Header(
                              media: media,
                              onPlay: () => _openPlayer(context),
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
                    selectedEpisode: _selectedEpisode,
                    onEpisodeSelected: (episode) {
                      setState(() => _selectedEpisode = episode);
                    },
                  );
                  final playback = _PlaybackPanel(
                    media: media,
                    episode: _selectedEpisode,
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
    );
  }
}

class _PlaybackPanel extends StatelessWidget {
  const _PlaybackPanel({
    required this.media,
    required this.episode,
    required this.onOpenPlayer,
  });

  final MediaItem media;
  final EpisodeInfo? episode;
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
                  episode == null ? 'Playback' : '${episode!.label} Playback',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The native player shell is ready for authorized direct stream URLs. Provider connectors are intentionally kept out of this branch.',
            style: const TextStyle(color: AppColors.muted, height: 1.4),
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
  const _Header({required this.media, required this.onPlay});

  final MediaItem media;
  final VoidCallback onPlay;

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
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _Pill(media.releaseYear),
              _Pill(media.runtimeLabel ?? media.mediaTypeLabel),
              _Pill(media.genre),
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
                onPressed: () {},
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add to List'),
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
    required this.selectedEpisode,
    required this.onEpisodeSelected,
  });

  final MediaItem media;
  final EpisodeInfo? selectedEpisode;
  final ValueChanged<EpisodeInfo> onEpisodeSelected;

  @override
  Widget build(BuildContext context) {
    final cast = media.cast.isNotEmpty ? media.cast : _fallbackCast(media);
    final seasons = media.availableSeasons;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Text(
          selectedEpisode?.overview ?? media.overview,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.55,
            color: AppColors.text.withValues(alpha: 0.82),
          ),
        ),
        if (media.mediaType == MediaType.tv && seasons.isNotEmpty) ...[
          const SizedBox(height: 24),
          _EpisodePanel(
            media: media,
            seasons: seasons,
            selected: selectedEpisode,
            onSelected: onEpisodeSelected,
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Cast',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [for (final person in cast) _PersonChip(person)],
        ),
        const SizedBox(height: 24),
        const Text(
          'Playback Defaults',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
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

  List<String> _fallbackCast(MediaItem item) {
    final base = item.mediaType == MediaType.tv
        ? ['Lead Performer', 'Series Regular', 'Guest Star', 'Showrunner']
        : ['Lead Actor', 'Supporting Actor', 'Director', 'Producer'];
    return base.map((role) => '${item.title} $role').toList();
  }
}

class _EpisodePanel extends StatefulWidget {
  const _EpisodePanel({
    required this.media,
    required this.seasons,
    required this.selected,
    required this.onSelected,
  });

  final MediaItem media;
  final List<SeasonInfo> seasons;
  final EpisodeInfo? selected;
  final ValueChanged<EpisodeInfo> onSelected;

  @override
  State<_EpisodePanel> createState() => _EpisodePanelState();
}

class _EpisodePanelState extends State<_EpisodePanel> {
  int _seasonIndex = 0;

  @override
  void initState() {
    super.initState();
    _syncSeasonToSelection();
  }

  @override
  void didUpdateWidget(covariant _EpisodePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected?.seasonNumber != widget.selected?.seasonNumber) {
      _syncSeasonToSelection();
    }
  }

  void _syncSeasonToSelection() {
    final selectedSeason = widget.selected?.seasonNumber;
    if (selectedSeason == null) return;
    final index = widget.seasons.indexWhere(
      (season) => season.seasonNumber == selectedSeason,
    );
    if (index >= 0) _seasonIndex = index;
  }

  @override
  Widget build(BuildContext context) {
    final season =
        widget.seasons[_seasonIndex.clamp(0, widget.seasons.length - 1)];

    return Container(
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Episodes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${season.title} - ${season.episodes.length} episodes',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SegmentedButton<int>(
                segments: [
                  for (var i = 0; i < widget.seasons.length; i++)
                    ButtonSegment<int>(
                      value: i,
                      label: Text('S${widget.seasons[i].seasonNumber}'),
                    ),
                ],
                selected: {_seasonIndex},
                onSelectionChanged: (selection) {
                  setState(() => _seasonIndex = selection.first);
                  widget.onSelected(
                    widget.seasons[selection.first].episodes.first,
                  );
                },
                showSelectedIcon: false,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 258,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: season.episodes.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final episode = season.episodes[index];
                final active =
                    widget.selected?.seasonNumber == episode.seasonNumber &&
                    widget.selected?.episodeNumber == episode.episodeNumber;
                return _EpisodeCard(
                  media: widget.media,
                  episode: episode,
                  active: active,
                  onTap: () => widget.onSelected(episode),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({
    required this.media,
    required this.episode,
    required this.active,
    required this.onTap,
  });

  final MediaItem media;
  final EpisodeInfo episode;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 344,
        decoration: BoxDecoration(
          color: active
              ? AppColors.gold.withValues(alpha: 0.16)
              : AppColors.ink,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? AppColors.gold : Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (media.backdropUrl != null)
                      SmartNetworkImage(
                        imageUrl: media.backdropUrl!,
                        fit: BoxFit.cover,
                        fallback: _EpisodeFallback(
                          media: media,
                          episode: episode,
                        ),
                      )
                    else
                      _EpisodeFallback(media: media, episode: episode),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xCC000000), Color(0x11000000)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _Pill(episode.label, accent: active),
                    ),
                    const Positioned(
                      right: 12,
                      bottom: 12,
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: AppColors.text,
                        size: 34,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          episode.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        episode.runtimeLabel,
                        style: TextStyle(
                          color: active ? AppColors.gold : AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    episode.overview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeFallback extends StatelessWidget {
  const _EpisodeFallback({required this.media, required this.episode});

  final MediaItem media;
  final EpisodeInfo episode;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF201114), Color(0xFF08090B), Color(0xFF24324A)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Text(
              media.title.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text.withValues(alpha: 0.22),
                fontSize: 28,
                height: 0.94,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned(
            right: -18,
            top: -30,
            child: Container(
              width: 126,
              height: 126,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(63),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 52,
            child: Text(
              'EPISODE ${episode.episodeNumber}',
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
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
