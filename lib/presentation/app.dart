import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../data/models/media_item.dart';
import 'detail/detail_screen.dart';
import 'home/home_screen.dart';
import 'player/player_screen.dart';
import 'search/search_screen.dart';
import 'settings/settings_screen.dart';

final supabaseConfiguredProvider = Provider<bool>((ref) => false);

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/movies',
        builder: (context, state) =>
            const HomeScreen(initialSection: BrowseSection.movies),
      ),
      GoRoute(
        path: '/tv-shows',
        builder: (context, state) =>
            const HomeScreen(initialSection: BrowseSection.tv),
      ),
      GoRoute(
        path: '/anime',
        builder: (context, state) =>
            const HomeScreen(initialSection: BrowseSection.anime),
      ),
      GoRoute(
        path: '/sports',
        builder: (context, state) =>
            const HomeScreen(initialSection: BrowseSection.sports),
      ),
      GoRoute(
        path: '/my-list',
        builder: (context, state) =>
            const HomeScreen(initialSection: BrowseSection.myList),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/detail',
        pageBuilder: (context, state) {
          final item = state.extra is MediaItem
              ? state.extra as MediaItem
              : null;
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: DetailScreen(media: item ?? MediaItem.samples.first),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: '/player',
        pageBuilder: (context, state) {
          final url = state.uri.queryParameters['url'];
          final title = state.uri.queryParameters['title'] ?? 'StreamVault';
          final mediaTitle = state.uri.queryParameters['mediaTitle'];
          final tmdbId = int.tryParse(
            state.uri.queryParameters['tmdbId'] ?? '',
          );
          final seasonNumber = int.tryParse(
            state.uri.queryParameters['seasonNumber'] ?? '',
          );
          final episodeNumber = int.tryParse(
            state.uri.queryParameters['episodeNumber'] ?? '',
          );
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: PlayerScreen(
              streamUrl: url,
              title: title,
              mediaTitle: mediaTitle,
              tmdbId: tmdbId,
              mediaType: state.uri.queryParameters['mediaType'],
              posterPath: state.uri.queryParameters['posterPath'],
              backdropPath: state.uri.queryParameters['backdropPath'],
              seasonNumber: seasonNumber,
              episodeNumber: episodeNumber,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.04),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
          );
        },
      ),
    ],
  );
});

class StreamVaultApp extends ConsumerWidget {
  const StreamVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'StreamVault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
