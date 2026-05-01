import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../../data/models/media_item.dart';
import '../../common/smart_network_image.dart';
import '../tv_details_provider.dart';

/// Production-grade episode browser. Handles One Piece-scale shows (1000+
/// episodes across 25+ seasons) without horizontal scrolling: a vertical
/// virtualized list with a season dropdown + filter box.
class EpisodePanel extends ConsumerStatefulWidget {
  const EpisodePanel({
    required this.media,
    required this.onPlayEpisode,
    super.key,
  });

  final MediaItem media;
  final void Function(int seasonNumber, int episodeNumber, String label)
  onPlayEpisode;

  @override
  ConsumerState<EpisodePanel> createState() => _EpisodePanelState();
}

class _EpisodePanelState extends ConsumerState<EpisodePanel> {
  int? _selectedSeason;
  final _filterController = TextEditingController();
  String _filter = '';
  int _showLimit = 30;

  @override
  void initState() {
    super.initState();
    _filterController.addListener(_onFilter);
  }

  @override
  void dispose() {
    _filterController.removeListener(_onFilter);
    _filterController.dispose();
    super.dispose();
  }

  void _onFilter() {
    final next = _filterController.text.trim().toLowerCase();
    if (next != _filter) {
      setState(() {
        _filter = next;
        _showLimit = 30;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(
      tvDetailsForMediaProvider(TvDetailsKey.fromMedia(widget.media)),
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: detailsAsync.when(
        data: (details) {
          final seasons = details?.seasons ?? const <TvSeasonSummary>[];
          if (seasons.isEmpty) return _staticFallback(context);
          final selected = _selectedSeason ?? seasons.first.seasonNumber;
          if (_selectedSeason == null) {
            // pick once after first build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _selectedSeason = selected);
            });
          }
          return _buildSeasons(context, details!, seasons, selected);
        },
        loading: () => _loadingState(),
        error: (_, _) => _staticFallback(context),
      ),
    );
  }

  Widget _buildSeasons(
    BuildContext context,
    TvDetails details,
    List<TvSeasonSummary> seasons,
    int selectedSeason,
  ) {
    final season = seasons.firstWhere(
      (s) => s.seasonNumber == selectedSeason,
      orElse: () => seasons.first,
    );
    final episodesAsync = ref.watch(
      tvSeasonProvider(
        SeasonKey(
          widget.media.tmdbId,
          season.seasonNumber,
          imdbId: widget.media.imdbId,
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, details, seasons, season),
        const SizedBox(height: 14),
        _buildFilterRow(seasons, season),
        const SizedBox(height: 16),
        episodesAsync.when(
          data: (episodes) => _buildList(episodes, season),
          loading: _loadingList,
          error: (_, _) => _episodeError(),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    TvDetails details,
    List<TvSeasonSummary> seasons,
    TvSeasonSummary season,
  ) {
    final totalEpisodes = details.numberOfEpisodes > 0
        ? details.numberOfEpisodes
        : seasons.fold<int>(0, (sum, s) => sum + s.episodeCount);
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Episodes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                '${seasons.length} seasons \u00B7 $totalEpisodes total \u00B7 '
                '${season.name} (${season.episodeCount})',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow(
    List<TvSeasonSummary> seasons,
    TvSeasonSummary current,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: current.seasonNumber,
              dropdownColor: AppColors.surfaceRaised,
              icon: const Icon(
                Icons.expand_more_rounded,
                color: AppColors.gold,
                size: 18,
              ),
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              items: [
                for (final s in seasons)
                  DropdownMenuItem<int>(
                    value: s.seasonNumber,
                    child: Text('Season ${s.seasonNumber} (${s.episodeCount})'),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedSeason = value;
                  _showLimit = 30;
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: TextField(
              controller: _filterController,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: InputBorder.none,
                hintText: 'Filter episodes by title or number...',
                hintStyle: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.filter_list_rounded,
                  color: AppColors.muted,
                  size: 18,
                ),
                suffixIcon: _filter.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear filter',
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () => _filterController.clear(),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<EpisodeDetails> episodes, TvSeasonSummary season) {
    if (episodes.isEmpty) return _episodeError();
    final filtered = _filter.isEmpty
        ? episodes
        : episodes.where((e) {
            final hay =
                '${e.title} S${e.seasonNumber} E${e.episodeNumber} '
                        '${e.label} ${e.overview}'
                    .toLowerCase();
            return hay.contains(_filter);
          }).toList();
    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: Text(
          'No episodes match "$_filter"',
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    final displayed = filtered.take(_showLimit).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final ep in displayed)
          _EpisodeRow(
            media: widget.media,
            episode: ep,
            onTap: () => widget.onPlayEpisode(
              ep.seasonNumber,
              ep.episodeNumber,
              ep.label,
            ),
          ),
        if (filtered.length > _showLimit)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton(
              onPressed: () => setState(() => _showLimit += 30),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: const BorderSide(color: AppColors.gold),
              ),
              child: Text(
                'Show more (${filtered.length - _showLimit} remaining)',
              ),
            ),
          ),
      ],
    );
  }

  Widget _loadingState() {
    return Container(
      height: 220,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(AppColors.gold),
        ),
      ),
    );
  }

  Widget _loadingList() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(AppColors.gold),
        ),
      ),
    );
  }

  Widget _episodeError() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      alignment: Alignment.center,
      child: const Text(
        'Episode list unavailable for this season.',
        style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _staticFallback(BuildContext context) {
    final seasons = widget.media.availableSeasons;
    if (seasons.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        alignment: Alignment.center,
        child: const Text(
          'No episode data available.',
          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
        ),
      );
    }
    final fallbackSummaries = seasons
        .map(
          (s) => TvSeasonSummary(
            seasonNumber: s.seasonNumber,
            name: s.title,
            episodeCount: s.episodes.length,
          ),
        )
        .toList();
    final selected = _selectedSeason ?? fallbackSummaries.first.seasonNumber;
    final season = fallbackSummaries.firstWhere(
      (s) => s.seasonNumber == selected,
      orElse: () => fallbackSummaries.first,
    );
    final episodes = seasons
        .firstWhere((s) => s.seasonNumber == season.seasonNumber)
        .episodes
        .map(
          (e) => EpisodeDetails(
            seasonNumber: e.seasonNumber,
            episodeNumber: e.episodeNumber,
            title: e.title,
            overview: e.overview,
            runtimeMinutes: 48,
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            const Text(
              'Episodes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildFilterRow(fallbackSummaries, season),
        const SizedBox(height: 16),
        _buildList(episodes, season),
      ],
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({
    required this.media,
    required this.episode,
    required this.onTap,
  });

  final MediaItem media;
  final EpisodeDetails episode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final seriesArtworkUrl = media.backdropUrl ?? media.posterUrl;
    final stillUrl = episode.stillPath != null
        ? ImageUtils.tmdbBackdrop(episode.stillPath)
        : seriesArtworkUrl;
    final rowFallback = _RowFallback(media: media, episode: episode);
    final imageFallback =
        seriesArtworkUrl != null && seriesArtworkUrl != stillUrl
        ? SmartNetworkImage(
            imageUrl: seriesArtworkUrl,
            fit: BoxFit.cover,
            fallback: rowFallback,
            cacheWidth: 168,
            cacheHeight: 95,
            enableShimmer: false,
          )
        : rowFallback;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 168,
                height: 95,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (stillUrl != null)
                        SmartNetworkImage(
                          imageUrl: stillUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 168,
                          cacheHeight: 95,
                          fallback: imageFallback,
                        )
                      else
                        rowFallback,
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                            colors: [Color(0x88000000), Color(0x00000000)],
                          ),
                        ),
                      ),
                      Positioned(left: 6, top: 6, child: _Badge(episode.label)),
                      const Positioned(
                        right: 4,
                        bottom: 4,
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          color: AppColors.text,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${episode.episodeNumber}. ${episode.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (episode.runtimeLabel.isNotEmpty)
                          Text(
                            episode.runtimeLabel,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      episode.overview.isEmpty
                          ? (episode.airDate != null &&
                                    episode.airDate!.isNotEmpty
                                ? 'Aired ${episode.airDate}'
                                : 'Tap to play this episode in the native player.')
                          : episode.overview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.text.withValues(alpha: 0.65),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    if (episode.airDate != null && episode.airDate!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          episode.airDate!,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowFallback extends StatelessWidget {
  const _RowFallback({required this.media, required this.episode});

  final MediaItem media;
  final EpisodeDetails episode;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF20141D), Color(0xFF09090B), Color(0xFF24324A)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            top: -16,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 6,
            right: 8,
            child: Text(
              media.title.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text.withValues(alpha: 0.42),
                fontSize: 14,
                height: 0.95,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
