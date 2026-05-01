import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/espn_remote.dart';
import '../../providers.dart';

enum SportLeague { nba, nfl, ipl, mlb, nhl, soccerEpl }

class SportsWatchProvider {
  const SportsWatchProvider({
    required this.name,
    required this.url,
    required this.note,
  });

  final String name;
  final String url;
  final String note;

  Uri get uri => Uri.parse(url);
}

extension SportLeagueX on SportLeague {
  String get label => switch (this) {
    SportLeague.nba => 'NBA',
    SportLeague.nfl => 'NFL',
    SportLeague.ipl => 'IPL',
    SportLeague.mlb => 'MLB',
    SportLeague.nhl => 'NHL',
    SportLeague.soccerEpl => 'EPL',
  };

  String get longLabel => switch (this) {
    SportLeague.nba => 'NBA Basketball',
    SportLeague.nfl => 'NFL Football',
    SportLeague.ipl => 'IPL Cricket',
    SportLeague.mlb => 'MLB Baseball',
    SportLeague.nhl => 'NHL Hockey',
    SportLeague.soccerEpl => 'EPL Soccer',
  };

  ({String sport, String league}) get espn => switch (this) {
    SportLeague.nba => (sport: 'basketball', league: 'nba'),
    SportLeague.nfl => (sport: 'football', league: 'nfl'),
    SportLeague.ipl => (sport: 'cricket', league: '8048'),
    SportLeague.mlb => (sport: 'baseball', league: 'mlb'),
    SportLeague.nhl => (sport: 'hockey', league: 'nhl'),
    SportLeague.soccerEpl => (sport: 'soccer', league: 'eng.1'),
  };

  List<SportsWatchProvider> get watchProviders => switch (this) {
    SportLeague.ipl => const [
      SportsWatchProvider(
        name: 'Willow TV',
        url: 'https://www.willow.tv/',
        note: 'Authorized cricket coverage in the US and Canada.',
      ),
      SportsWatchProvider(
        name: 'JioHotstar',
        url: 'https://www.hotstar.com/in/sports/cricket',
        note: 'Official streaming path for India where available.',
      ),
      SportsWatchProvider(
        name: 'YouTube TV Sports Plus',
        url: 'https://tv.youtube.com/',
        note: 'Includes Willow in supported US packages.',
      ),
      SportsWatchProvider(
        name: 'Fubo',
        url: 'https://www.fubo.tv/',
        note: 'Includes Willow in supported US packages.',
      ),
      SportsWatchProvider(
        name: 'Sling Desi TV',
        url: 'https://www.sling.com/international/desi-tv/cricket',
        note: 'Willow availability depends on package and region.',
      ),
    ],
    SportLeague.nba => const [
      SportsWatchProvider(
        name: 'NBA League Pass',
        url: 'https://www.nba.com/watch/league-pass-stream',
        note: 'Out-of-market games and official NBA streaming.',
      ),
      SportsWatchProvider(
        name: 'ESPN',
        url: 'https://www.espn.com/watch/',
        note: 'Available with participating TV providers.',
      ),
    ],
    SportLeague.nfl => const [
      SportsWatchProvider(
        name: 'NFL+',
        url: 'https://www.nfl.com/plus/',
        note: 'Official NFL live and replay access.',
      ),
      SportsWatchProvider(
        name: 'ESPN',
        url: 'https://www.espn.com/watch/',
        note: 'Available with participating TV providers.',
      ),
    ],
    SportLeague.mlb => const [
      SportsWatchProvider(
        name: 'MLB.TV',
        url: 'https://www.mlb.com/live-stream-games',
        note: 'Official out-of-market MLB streaming.',
      ),
    ],
    SportLeague.nhl => const [
      SportsWatchProvider(
        name: 'ESPN+',
        url: 'https://plus.espn.com/',
        note: 'Official US NHL streaming for eligible games.',
      ),
    ],
    SportLeague.soccerEpl => const [
      SportsWatchProvider(
        name: 'Peacock',
        url: 'https://www.peacocktv.com/sports/premier-league',
        note: 'US Premier League streaming for eligible matches.',
      ),
      SportsWatchProvider(
        name: 'NBC Sports',
        url: 'https://www.nbcsports.com/watch',
        note: 'Requires supported provider for select broadcasts.',
      ),
    ],
  };
}

class ActiveLeagueNotifier extends Notifier<SportLeague> {
  @override
  SportLeague build() => SportLeague.nba;

  void update(SportLeague value) {
    state = value;
  }
}

final activeLeagueProvider =
    NotifierProvider<ActiveLeagueNotifier, SportLeague>(
      ActiveLeagueNotifier.new,
    );

/// 30s auto-refresh per league (live scoreboards).
final scoreboardProvider =
    FutureProvider.family<List<ScoreboardEvent>, SportLeague>((
      ref,
      league,
    ) async {
      ref.keepAlive();
      final espn = ref.read(espnRemoteProvider);
      final ids = league.espn;
      final result = await espn.scoreboard(
        sport: ids.sport,
        league: ids.league,
      );

      // Auto-invalidate after 30s so UI re-fetches when games are live.
      final timer = Future.delayed(
        const Duration(seconds: 30),
        () => ref.invalidateSelf(),
      );
      ref.onDispose(() => timer.ignore());

      return result;
    });
