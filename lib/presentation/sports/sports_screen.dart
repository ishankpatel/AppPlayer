import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/datasources/espn_remote.dart';
import '../common/smart_network_image.dart';
import 'sports_provider.dart';

class SportsScreen extends ConsumerWidget {
  const SportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final league = ref.watch(activeLeagueProvider);
    final eventsAsync = ref.watch(scoreboardProvider(league));

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              34,
              MediaQuery.paddingOf(context).top + 92,
              34,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.sports_basketball_rounded,
                      color: AppColors.gold,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Live Sports',
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: () =>
                          ref.invalidate(scoreboardProvider(league)),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Real-time scoreboards from ESPN. Updates every 30 seconds while a game is live.',
                  style: TextStyle(
                    color: AppColors.text.withValues(alpha: 0.65),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _LeagueTabs(active: league),
              ],
            ),
          ),
        ),
        eventsAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(league: league),
              );
            }
            final live = events.where((e) => e.isLive).toList();
            final upcoming = events.where((e) => e.isUpcoming).toList();
            final finals = events.where((e) => e.isFinal).toList();

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(34, 0, 34, 60),
              sliver: SliverList.list(
                children: [
                  if (live.isNotEmpty) ...[
                    const _SectionHeading(label: 'Live now', dotColor: Colors.red),
                    const SizedBox(height: 12),
                    for (final e in live)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _GameCard(event: e),
                      ),
                    const SizedBox(height: 22),
                  ],
                  if (upcoming.isNotEmpty) ...[
                    const _SectionHeading(label: 'Upcoming'),
                    const SizedBox(height: 12),
                    for (final e in upcoming.take(12))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _GameCard(event: e),
                      ),
                    const SizedBox(height: 22),
                  ],
                  if (finals.isNotEmpty) ...[
                    const _SectionHeading(label: 'Final'),
                    const SizedBox(height: 12),
                    for (final e in finals.take(12))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _GameCard(event: e),
                      ),
                  ],
                ],
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(AppColors.gold),
                ),
              ),
            ),
          ),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: _ErrorState(
              league: league,
              onRetry: () => ref.invalidate(scoreboardProvider(league)),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeagueTabs extends ConsumerWidget {
  const _LeagueTabs({required this.active});

  final SportLeague active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: SportLeague.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final league = SportLeague.values[index];
          final selected = league == active;
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () =>
                ref.read(activeLeagueProvider.notifier).update(league),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.gold.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.gold : Colors.white12,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                league.longLabel,
                style: TextStyle(
                  color: selected ? AppColors.gold : AppColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.label, this.dotColor});

  final String label;
  final Color? dotColor;

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
        if (dotColor != null) ...[
          const SizedBox(width: 12),
          _LiveDot(color: dotColor!),
        ],
      ],
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot({required this.color});
  final Color color;

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: widget.color
                .withValues(alpha: 0.5 + (_ctrl.value * 0.5)),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: widget.color
                    .withValues(alpha: 0.4 * (1 - _ctrl.value)),
                blurRadius: 12 * _ctrl.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.event});

  final ScoreboardEvent event;

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat.MMMd().add_jm();
    final start = event.startTime?.toLocal();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: event.isLive
              ? Colors.red.withValues(alpha: 0.55)
              : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (event.isLive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _LiveDot(color: Colors.red),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              if (!event.isLive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: event.isFinal
                        ? Colors.white.withValues(alpha: 0.06)
                        : AppColors.gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: event.isFinal ? Colors.white24 : AppColors.gold,
                    ),
                  ),
                  child: Text(
                    event.isFinal ? 'FINAL' : 'UPCOMING',
                    style: TextStyle(
                      color:
                          event.isFinal ? AppColors.muted : AppColors.gold,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  event.statusText.isEmpty
                      ? (start == null ? '' : timeFmt.format(start))
                      : event.statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: event.isLive
                        ? AppColors.text
                        : AppColors.text.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              if (event.broadcasts.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    event.broadcasts.first,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TeamRow(
                  team: event.awayTeam,
                  logo: event.awayLogo,
                  score: event.awayScore,
                  showScore: !event.isUpcoming,
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 1,
                height: 56,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _TeamRow(
                  team: event.homeTeam,
                  logo: event.homeLogo,
                  score: event.homeScore,
                  showScore: !event.isUpcoming,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          if (event.venue.isNotEmpty || (start != null && event.isUpcoming)) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (event.venue.isNotEmpty) ...[
                  const Icon(
                    Icons.stadium_rounded,
                    color: AppColors.muted,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.venue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                if (start != null && event.isUpcoming) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.muted,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeFmt.format(start),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (event.isLive) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _showStreamDialog(context, event),
              icon: const Icon(Icons.live_tv_rounded),
              label: const Text('Open Stream'),
            ),
          ],
        ],
      ),
    );
  }

  void _showStreamDialog(BuildContext context, ScoreboardEvent event) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surfaceRaised,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${event.awayTeam} @ ${event.homeTeam}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'StreamVault does not host or redistribute live sports streams. '
                  'Open the official broadcaster app or your authorized provider '
                  'to watch this game. The score line on this card stays in sync '
                  'with ESPN data while the broadcast is live.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                    fontSize: 13,
                  ),
                ),
                if (event.broadcasts.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final b in event.broadcasts)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.gold),
                          ),
                          child: Text(
                            b,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.team,
    required this.logo,
    required this.score,
    required this.showScore,
    this.alignEnd = false,
  });

  final String team;
  final String? logo;
  final int score;
  final bool showScore;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final logoBox = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: logo == null
          ? const Icon(
              Icons.sports_rounded,
              color: AppColors.muted,
              size: 20,
            )
          : SmartNetworkImage(
              imageUrl: logo!,
              fit: BoxFit.contain,
              fallback: const Icon(
                Icons.sports_rounded,
                color: AppColors.muted,
                size: 20,
              ),
            ),
    );
    final children = <Widget>[
      logoBox,
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          team,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ),
      if (showScore)
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            score.toString(),
            style: TextStyle(
              color: score > 0 ? AppColors.gold : AppColors.text,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ),
    ];
    if (alignEnd) {
      return Row(children: children.reversed.toList());
    }
    return Row(children: children);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.league});

  final SportLeague league;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: AppColors.gold, width: 1.5),
              ),
              child: const Icon(
                Icons.sports_score_rounded,
                size: 40,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No ${league.longLabel} games today',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check back closer to the next scheduled game window.',
              style: TextStyle(
                color: AppColors.text.withValues(alpha: 0.65),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.league, required this.onRetry});

  final SportLeague league;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: AppColors.muted,
            ),
            const SizedBox(height: 14),
            Text(
              'Could not load ${league.longLabel}',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your connection and retry.',
              style: TextStyle(
                color: AppColors.text.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
