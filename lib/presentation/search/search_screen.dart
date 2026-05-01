import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/media_item.dart';
import '../home/widgets/media_card.dart';
import 'search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    ref.read(searchQueryProvider.notifier).update(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider).trim();
    final live = ref.watch(liveSearchProvider);

    final results = live.maybeWhen(
      data: (result) => result.items,
      orElse: () => const <MediaItem>[],
    );
    final isLoading = live.isLoading && query.length >= 2;
    final hasError = live.hasError && results.isEmpty;
    final showSamples = query.length < 2;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: context.pop,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search movies, TV, anime, Hindi...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _controller.clear();
                      ref.read(searchQueryProvider.notifier).update('');
                    },
                  ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      showSamples
                          ? 'Explore the Vault'
                          : isLoading
                              ? 'Searching...'
                              : '${results.length} results for "$query"',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.gold),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (showSamples)
            _SamplesGrid(items: MediaItem.samples)
          else if (results.isEmpty && !isLoading)
            _EmptyState(query: query, hasError: hasError)
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 40),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  mainAxisExtent: 214,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 20,
                ),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final item = results[index];
                  return MediaCard(
                    item: item,
                    onTap: () => context.push('/detail', extra: item),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SamplesGrid extends StatelessWidget {
  const _SamplesGrid({required this.items});

  final List<MediaItem> items;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 320,
          mainAxisExtent: 214,
          crossAxisSpacing: 14,
          mainAxisSpacing: 20,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return MediaCard(
            item: item,
            onTap: () => context.push('/detail', extra: item),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query, required this.hasError});

  final String query;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: Colors.white12, width: 1),
                ),
                child: Icon(
                  hasError
                      ? Icons.cloud_off_rounded
                      : Icons.search_off_rounded,
                  size: 32,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                hasError
                    ? 'Search service unavailable'
                    : 'No matches for "$query"',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasError
                    ? 'Check your connection and try again.'
                    : 'Try fewer words or a different spelling.',
                style: TextStyle(
                  color: AppColors.text.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
