import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/media_item.dart';
import '../../data/repositories/media_repository.dart';
import '../../providers.dart';
import 'home_provider.dart';
import 'widgets/content_row.dart';
import 'widgets/continue_card.dart';
import 'widgets/hero_banner.dart';

enum BrowseSection { home, movies, tv, anime, myList }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  BrowseSection _section = BrowseSection.home;
  int _heroIndex = 0;
  Timer? _heroTimer;

  @override
  void initState() {
    super.initState();
    _heroTimer = Timer.periodic(const Duration(seconds: 9), (_) {
      if (mounted) setState(() => _heroIndex++);
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(homeFeedProvider);

    return Scaffold(
      body: Stack(
        children: [
          feed.when(
            data: (data) => _HomeContent(
              feed: data,
              section: _section,
              heroIndex: _heroIndex,
              repository: ref.read(mediaRepositoryProvider),
            ),
            loading: () => const _HomeSkeleton(),
            error: (error, stackTrace) => _HomeContent(
              feed: _sampleFeed(),
              section: _section,
              heroIndex: _heroIndex,
              repository: ref.read(mediaRepositoryProvider),
            ),
          ),
          _TopChrome(
            selected: _section,
            onSelected: (section) => setState(() => _section = section),
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
    return HomeFeed(
      hero: samples.first,
      continueWatching: samples.where((m) => m.hasProgress).toList(),
      homeRows: [
        ContentCategory(
          title: 'Top on Netflix',
          items: samples.where((m) => m.tags.contains('top-netflix')).toList(),
        ),
        ContentCategory(title: 'Trending Now', items: samples),
        ContentCategory(
          title: 'Top Hindi',
          items: samples.where((m) => m.tags.contains('top-hindi')).toList(),
        ),
        ContentCategory(
          title: 'Hindi Dubbed Hits',
          items: samples.where((m) => m.tags.contains('hindi-dubbed')).toList(),
        ),
        ContentCategory(
          title: 'New Releases',
          items: samples.reversed.toList(),
        ),
        ContentCategory(
          title: 'Action & Thrillers',
          items: samples.where((m) => m.tags.contains('action')).toList(),
        ),
      ],
      movieRows: [
        ContentCategory(title: 'Top Movies', items: movies),
        ContentCategory(
          title: 'Top Hindi',
          items: movies.where((m) => m.tags.contains('top-hindi')).toList(),
        ),
        ContentCategory(
          title: 'Hindi Dubbed Hits',
          items: movies.where((m) => m.tags.contains('hindi-dubbed')).toList(),
        ),
      ],
      tvRows: [
        ContentCategory(title: 'Top TV Shows', items: tv),
        ContentCategory(
          title: 'Top on Netflix',
          items: tv.where((m) => m.tags.contains('top-netflix')).toList(),
        ),
      ],
      animeRows: [
        ContentCategory(title: 'Anime Spotlight', items: anime),
        ContentCategory(
          title: 'Action Anime',
          items: anime.where((m) => m.tags.contains('action')).toList(),
        ),
      ],
      myListRows: [
        ContentCategory(title: 'My List', items: myList),
        ContentCategory(
          title: 'Favorites',
          items: samples.where((m) => m.isFavorite).toList(),
        ),
      ],
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.feed,
    required this.section,
    required this.heroIndex,
    required this.repository,
  });

  final HomeFeed feed;
  final BrowseSection section;
  final int heroIndex;
  final MediaRepository repository;

  @override
  Widget build(BuildContext context) {
    final rows = switch (section) {
      BrowseSection.home => feed.homeRows,
      BrowseSection.movies => feed.movieRows,
      BrowseSection.tv => feed.tvRows,
      BrowseSection.anime => feed.animeRows,
      BrowseSection.myList => feed.myListRows,
    };
    final heroPool =
        [
              for (final row in rows)
                for (final item in row.items) item,
            ]
            .where((item) => item.hasArtwork || item.mediaType == MediaType.tv)
            .toList();
    final hero = heroPool.isEmpty
        ? feed.hero
        : heroPool[heroIndex % heroPool.length];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 520),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: HeroBanner(
              key: ValueKey(hero.tmdbId),
              item: hero,
              onPlay: () => context.push('/detail', extra: hero),
              onMoreInfo: () => context.push('/detail', extra: hero),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 46),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (feed.continueWatching.isNotEmpty &&
                    section != BrowseSection.movies)
                  _ContinueRow(items: feed.continueWatching),
                for (final row in rows)
                  ContentRow(
                    key: ValueKey('${section.name}-${row.title}'),
                    title: row.title,
                    items: row.items,
                    onLoadMore: (page) =>
                        repository.loadMoreCategory(row.title, page: page),
                  ),
              ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _RowTitle('Continue Watching'),
          SizedBox(
            height: 156,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final item = items[index];
                return ContinueCard(
                  item: item,
                  onTap: () => context.push('/detail', extra: item),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(width: 14),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 0, 34, 12),
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
  const _TopChrome({required this.selected, required this.onSelected});

  final BrowseSection selected;
  final ValueChanged<BrowseSection> onSelected;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          MediaQuery.paddingOf(context).top + 12,
          24,
          18,
        ),
        decoration: BoxDecoration(
          color: AppColors.ink.withValues(alpha: 0.90),
          border: Border(
            bottom: const BorderSide(color: Color(0x1FFFFFFF), width: 0.8),
          ),
        ),
        child: Row(
          children: [
            const Text(
              'STREAMVAULT',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(width: 24),
            _NavLabel(
              'Home',
              active: selected == BrowseSection.home,
              onTap: () => onSelected(BrowseSection.home),
            ),
            _NavLabel(
              'Movies',
              active: selected == BrowseSection.movies,
              onTap: () => onSelected(BrowseSection.movies),
            ),
            _NavLabel(
              'TV Shows',
              active: selected == BrowseSection.tv,
              onTap: () => onSelected(BrowseSection.tv),
            ),
            _NavLabel(
              'Anime',
              active: selected == BrowseSection.anime,
              onTap: () => onSelected(BrowseSection.anime),
            ),
            _NavLabel(
              'My List',
              active: selected == BrowseSection.myList,
              onTap: () => onSelected(BrowseSection.myList),
            ),
            const Spacer(),
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
        ),
      ),
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

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceRaised,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Container(height: 520, color: Colors.white),
          const SizedBox(height: 30),
          for (var row = 0; row < 6; row++)
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 0, 28),
              child: Row(
                children: [
                  for (var i = 0; i < 5; i++)
                    Container(
                      margin: const EdgeInsets.only(right: 14),
                      width: 286,
                      height: 161,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
