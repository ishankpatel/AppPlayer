import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/espn_remote.dart';
import '../../providers.dart';

enum SportLeague { nba, nfl, ipl, mlb, nhl, soccerEpl }

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
    FutureProvider.family<List<ScoreboardEvent>, SportLeague>((ref, league) async {
  ref.keepAlive();
  final espn = ref.read(espnRemoteProvider);
  final ids = league.espn;
  final result = await espn.scoreboard(sport: ids.sport, league: ids.league);

  // Auto-invalidate after 30s so UI re-fetches when games are live.
  final timer = Future.delayed(
    const Duration(seconds: 30),
    () => ref.invalidateSelf(),
  );
  ref.onDispose(() => timer.ignore());

  return result;
});
