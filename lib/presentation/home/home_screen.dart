import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/media_item.dart';
import '../../data/repositories/media_repository.dart';
import '../../providers.dart';
import '../sports/sports_screen.dart';
import '../watchlist/watchlist_provider.dart';
import 'home_provider.dart';
import 'widgets/content_row.dart';
import 'widgets/continue_card.dart';
import 'widgets/hero_banner.dart';

enum BrowseSection { home, movies, tv, anime, sports, myList }

extension BrowseSectionRoute on BrowseSection {
  String get routePath {
    return switch (this) {
      BrowseSection.home => '/',
      BrowseSection.movies => '/movies',
      BrowseSection.tv => '/tv-shows',
      BrowseSection.anime => '/anime',
      BrowseSection.sports => '/sports',
      BrowseSection.myList => '/my-list',
    };
  }

  String get label {
    return switch (this) {
      BrowseSection.home => 'Home',
      BrowseSection.movies => 'Movies',
      BrowseSection.tv => 'TV Shows',
      BrowseSection.anime => 'Anime',
      BrowseSection.sports => 'Sports',
      BrowseSection.myList => 'My List',
    };
  }

  IconData get icon {
    return switch (this) {
      BrowseSection.home => Icons.home_rounded,
      BrowseSection.movies => Icons.movie_rounded,
      BrowseSection.tv => Icons.live_tv_rounded,
      BrowseSection.anime => Icons.auto_awesome_rounded,
      BrowseSection.sports => Icons.sports_cricket_rounded,
      BrowseSection.myList => Icons.bookmark_rounded,
    };
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({this.initialSection = BrowseSection.home, super.key});

  final BrowseSection initialSection;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late BrowseSection _section;
  final _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection) {
      _section = widget.initialSection;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final next = _scrollController.offset.clamp(0.0, 1000.0);
    if ((next - _scrollOffset).abs() < 28 &&
        !(next == 0 && _scrollOffset > 0)) {
      return;
    }
    setState(() => _scrollOffset = next);
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(homeFeedProvider);
    final chromeOpacity = (_scrollOffset / 220).clamp(0.0, 1.0);

    return Scaffold(
      body: Stack(
        children: [
          if (_section == BrowseSection.sports)
            const SportsScreen()
          else
            feed.when(
              data: (data) => _HomeContent(
                feed: data,
                section: _section,
                repository: ref.read(mediaRepositoryProvider),
                scrollController: _scrollController,
                scrollOffset: _scrollOffset,
              ),
              loading: () => _HomeContent(
                feed: _sampleFeed(),
                section: _section,
                repository: ref.read(mediaRepositoryProvider),
                scrollController: _scrollController,
                scrollOffset: _scrollOffset,
              ),
              error: (error, stackTrace) => _HomeContent(
                feed: _sampleFeed(),
                section: _section,
                repository: ref.read(mediaRepositoryProvider),
                scrollController: _scrollController,
                scrollOffset: _scrollOffset,
              ),
            ),
          _TopChrome(
            selected: _section,
            opacity: chromeOpacity,
            onSelected: (section) {
              setState(() => _section = section);
              context.go(section.routePath);
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeOutCubic,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  HomeFeed _sampleFeed() {
    final samples = MediaItem.samples;
    final tv = samples.where((m) => m.mediaType == MediaType.tv).toList();
    final movies = samples
        .where((m) => m.mediaType == MediaType.movie)
        .toList();
    final myList = samples
        .where((m) => m.isFavorite || m.isInWatchlist)
        .toList();
    final anime = samples.where((m) => m.tags.contains('anime')).toList();
    final hindi = samples.where((m) => m.tags.contains('top-hindi')).toList();
    final dubbed = samples
        .where((m) => m.tags.contains('hindi-dubbed'))
        .toList();
    final action = samples.where((m) => m.tags.contains('action')).toList();
    final sciFi = samples.where((m) => m.tags.contains('sci-fi')).toList();
    final newer = samples.where((m) => m.tags.contains('new')).toList();
    return HomeFeed(
      hero: samples.first,
      continueWatching: samples.where((m) => m.hasProgress).toList(),
      homeRows: [
        ContentCategory(
          title: 'Top on Netflix',
          items: samples.where((m) => m.tags.contains('top-netflix')).toList(),
        ),
        ContentCategory(title: 'Trending Now', items: samples),
        ContentCategory(title: 'Top Hindi', items: hindi),
        ContentCategory(
          title: 'Hindi Web Series',
          items: hindi.where((m) => m.mediaType == MediaType.tv).toList(),
        ),
        ContentCategory(title: 'Hindi-Dubbed Hollywood', items: dubbed),
        ContentCategory(title: 'New Releases', items: newer),
        ContentCategory(title: 'Action & Thrillers', items: action),
        ContentCategory(title: 'Sci-Fi Vault', items: sciFi),
        ContentCategory(title: 'Anime Spotlight', items: anime),
        ContentCategory(title: 'Series Worth Starting', items: tv),
      ],
      movieRows: [
        ContentCategory(title: 'Most Popular Movies', items: movies),
        ContentCategory(title: 'Top Rated Movies', items: movies),
        ContentCategory(
          title: 'Acclaimed Dramas',
          items: movies.where((m) => m.genre == 'Drama').toList(),
        ),
        ContentCategory(
          title: 'Bollywood Action',
          items: hindi
              .where(
                (m) =>
                    m.mediaType == MediaType.movie && m.tags.contains('action'),
              )
              .toList(),
        ),
        ContentCategory(
          title: 'Latest Hindi Releases',
          items: hindi.where((m) => m.tags.contains('new')).toList(),
        ),
        ContentCategory(
          title: 'Comedy Picks',
          items: movies.where((m) => m.genre == 'Comedy').toList(),
        ),
        ContentCategory(
          title: 'Family Night',
          items: movies.where((m) => m.tags.contains('family')).toList(),
        ),
      ],
      tvRows: [
        ContentCategory(title: 'Most Popular Series', items: tv),
        ContentCategory(title: 'Top Rated Series', items: tv),
        ContentCategory(
          title: 'Currently Airing',
          items: tv.where((m) => m.tags.contains('new')).toList(),
        ),
        ContentCategory(
          title: 'Crime & Mystery',
          items: tv
              .where((m) => m.genre == 'Crime' || m.genre == 'Mystery')
              .toList(),
        ),
        ContentCategory(
          title: 'Sci-Fi Series',
          items: tv.where((m) => m.tags.contains('sci-fi')).toList(),
        ),
        ContentCategory(
          title: 'Action Series',
          items: tv.where((m) => m.tags.contains('action')).toList(),
        ),
      ],
      animeRows: [
        ContentCategory(title: 'Anime Spotlight', items: anime),
        ContentCategory(
          title: 'New Episodes This Season',
          items: anime.where((m) => m.tags.contains('new')).toList(),
        ),
        ContentCategory(
          title: 'Shounen Action',
          items: anime.where((m) => m.tags.contains('action')).toList(),
        ),
        ContentCategory(
          title: 'Anime Movies',
          items: anime.where((m) => m.mediaType == MediaType.movie).toList(),
        ),
      ],
      myListRows: [
        ContentCategory(
          title: 'Continue Watching',
          items: samples.where((m) => m.hasProgress).toList(),
        ),
        ContentCategory(title: 'My List', items: myList),
        ContentCategory(
          title: 'Favorites',
          items: samples.where((m) => m.isFavorite).toList(),
        ),
      ],
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({
    required this.feed,
    required this.section,
    required this.repository,
    required this.scrollController,
    required this.scrollOffset,
  });

  final HomeFeed feed;
  final BrowseSection section;
  final MediaRepository repository;
  final ScrollController scrollController;
  final double scrollOffset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlistAsync = ref.watch(watchlistProvider);
    final watchlistItems = watchlistAsync.maybeWhen(
      data: (records) => records.map((r) => r.toMedia()).toList(),
      orElse: () => const <MediaItem>[],
    );
    final continueWatching = ref
        .watch(continueWatchingProvider)
        .maybeWhen(data: (items) => items, orElse: () => feed.continueWatching);

    final myListRows = <ContentCategory>[
      if (continueWatching.isNotEmpty)
        ContentCategory(title: 'Continue Watching', items: continueWatching),
      ContentCategory(title: 'My List', items: watchlistItems),
      ContentCategory(
        title: 'Recently Saved',
        items: watchlistItems.take(20).toList(),
      ),
    ];

    final rows = switch (section) {
      BrowseSection.home => feed.homeRows,
      BrowseSection.movies => feed.movieRows,
      BrowseSection.tv => feed.tvRows,
      BrowseSection.anime => feed.animeRows,
      BrowseSection.sports => const <ContentCategory>[],
      BrowseSection.myList => myListRows,
    };

    if (section == BrowseSection.myList && watchlistItems.isEmpty) {
      return _MyListEmpty(scrollController: scrollController);
    }

    final compact = MediaQuery.sizeOf(context).width < 720;
    final visibleRowCount = rows.isEmpty
        ? 0
        : compact
        ? (4 + (scrollOffset / 520).floor()).clamp(1, rows.length)
        : rows.length;
    final visibleRows = rows.take(visibleRowCount).toList();

    final seen = <String>{};
    final heroPool = <MediaItem>[];
    for (final row in visibleRows) {
      for (final item in row.items) {
        if (!item.hasArtwork) continue;
        final key = '${item.mediaType.name}:${item.tmdbId}';
        if (seen.add(key)) heroPool.add(item);
        if (heroPool.length >= 6) break;
      }
      if (heroPool.length >= 6) break;
    }
    final heroItems = heroPool.isNotEmpty ? heroPool : <MediaItem>[feed.hero];

    return CustomScrollView(
      controller: scrollController,
      physics: compact
          ? const ClampingScrollPhysics()
          : const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: HeroBanner(
            key: ValueKey('hero-banner-${section.name}'),
            items: heroItems,
            onPlay: (item) => context.push('/detail', extra: item),
            onMoreInfo: (item) => context.push('/detail', extra: item),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 46),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (continueWatching.isNotEmpty &&
                    section != BrowseSection.movies &&
                    section != BrowseSection.myList)
                  _ContinueRow(items: continueWatching),
                for (final row in visibleRows)
                  ContentRow(
                    key: ValueKey('${section.name}-${row.title}'),
                    title: row.title,
                    items: row.items,
                    onLoadMore: section == BrowseSection.myList
                        ? null
                        : (page) => repository.loadMoreCategory(
                            row.title,
                            page: page,
                          ),
                  ),
                if (compact && visibleRowCount < rows.length)
                  _MoreRowsHint(loaded: visibleRowCount, total: rows.length),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MoreRowsHint extends StatelessWidget {
  const _MoreRowsHint({required this.loaded, required this.total});

  final int loaded;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                valueColor: AlwaysStoppedAnimation(AppColors.gold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Loading more rows as you scroll',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.text.withValues(alpha: 0.76),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$loaded/$total',
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyListEmpty extends StatelessWidget {
  const _MyListEmpty({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      physics: MediaQuery.sizeOf(context).width < 720
          ? const ClampingScrollPhysics()
          : const BouncingScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              34,
              MediaQuery.paddingOf(context).top + 110,
              34,
              60,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(44),
                        border: Border.all(color: AppColors.gold, width: 2),
                      ),
                      child: const Icon(
                        Icons.bookmark_outline_rounded,
                        size: 44,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your My List is empty',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap the bookmark icon on any title to save it here. '
                      'Your saved titles persist across sessions on this device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.text.withValues(alpha: 0.66),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinueRow extends StatelessWidget {
  const _ContinueRow({required this.items});

  final List<MediaItem> items;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    final horizontalPadding = compact ? 18.0 : 34.0;
    final cardWidth = compact
        ? (MediaQuery.sizeOf(context).width * 0.78)
              .clamp(256.0, 320.0)
              .toDouble()
        : 260.0;
    final rowHeight = compact ? 168.0 : 156.0;

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 28 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _RowTitle('Continue Watching'),
          SizedBox(
            height: rowHeight,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              scrollDirection: Axis.horizontal,
              cacheExtent: cardWidth * 3,
              physics: compact
                  ? const ClampingScrollPhysics()
                  : const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final item = items[index];
                return ContinueCard(
                  item: item,
                  width: cardWidth,
                  height: rowHeight,
                  onTap: () => context.push('/detail', extra: item),
                );
              },
              separatorBuilder: (context, index) =>
                  SizedBox(width: compact ? 12 : 14),
              itemCount: items.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowTitle extends StatelessWidget {
  const _RowTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = MediaQuery.sizeOf(context).width < 720
        ? 18.0
        : 34.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopChrome extends StatelessWidget {
  const _TopChrome({
    required this.selected,
    required this.onSelected,
    required this.opacity,
  });

  final BrowseSection selected;
  final ValueChanged<BrowseSection> onSelected;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    final horizontalPadding = compact ? 14.0 : 24.0;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          MediaQuery.paddingOf(context).top + (compact ? 8 : 12),
          horizontalPadding,
          compact ? 10 : 18,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.ink.withValues(alpha: 0.55 + 0.40 * opacity),
              AppColors.ink.withValues(alpha: 0.10 + 0.85 * opacity),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.06 * opacity),
              width: 0.8,
            ),
          ),
        ),
        child: compact
            ? _CompactChrome(selected: selected, onSelected: onSelected)
            : Row(
                children: [
                  const _BrandMark(),
                  const SizedBox(width: 24),
                  for (final section in BrowseSection.values)
                    _NavLabel(
                      section.label,
                      active: selected == section,
                      onTap: () => onSelected(section),
                    ),
                  const Spacer(),
                  const _ChromeActions(),
                ],
              ),
      ),
    );
  }
}

class _CompactChrome extends StatelessWidget {
  const _CompactChrome({required this.selected, required this.onSelected});

  final BrowseSection selected;
  final ValueChanged<BrowseSection> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _BrandMark(compact: true),
        const SizedBox(width: 10),
        PopupMenuButton<String>(
          tooltip: 'Browse sections',
          color: AppColors.surfaceRaised,
          surfaceTintColor: Colors.transparent,
          position: PopupMenuPosition.under,
          onSelected: (value) {
            if (value == 'search') {
              context.push('/search');
              return;
            }
            if (value == 'settings') {
              context.push('/settings');
              return;
            }
            final section = BrowseSection.values.firstWhere(
              (candidate) => value == candidate.name,
              orElse: () => selected,
            );
            onSelected(section);
          },
          itemBuilder: (context) => [
            for (final section in BrowseSection.values)
              PopupMenuItem(
                value: section.name,
                child: Row(
                  children: [
                    Icon(
                      section.icon,
                      color: selected == section
                          ? AppColors.gold
                          : AppColors.muted,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      section.label,
                      style: TextStyle(
                        color: selected == section
                            ? AppColors.text
                            : AppColors.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'search',
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: AppColors.gold, size: 18),
                  SizedBox(width: 10),
                  Text('Search', style: TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, color: AppColors.gold, size: 18),
                  SizedBox(width: 10),
                  Text(
                    'Settings',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
          child: Container(
            constraints: const BoxConstraints(maxWidth: 128),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selected.icon, color: AppColors.gold, size: 17),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    selected.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.expand_more_rounded,
                  color: AppColors.muted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Text(
      compact ? 'VAULT' : 'STREAMVAULT',
      maxLines: 1,
      style: TextStyle(
        color: AppColors.gold,
        fontSize: compact ? 20 : 22,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}

class _ChromeActions extends StatelessWidget {
  const _ChromeActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Search',
          onPressed: () => context.push('/search'),
          icon: const Icon(Icons.search_rounded),
        ),
        IconButton(
          tooltip: 'Preferences',
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.tune_rounded),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Family profile and sync settings',
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: () => context.push('/settings'),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.group_rounded,
                color: AppColors.ink,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavLabel extends StatelessWidget {
  const _NavLabel(this.label, {required this.onTap, this.active = false});

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: active ? AppColors.text : AppColors.muted,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: active ? 22 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
