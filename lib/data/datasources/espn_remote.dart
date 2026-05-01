import 'package:dio/dio.dart';

class ScoreboardEvent {
  const ScoreboardEvent({
    required this.id,
    required this.shortName,
    required this.statusText,
    required this.statusState,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.homeLogo,
    required this.awayLogo,
    required this.startTime,
    this.broadcasts = const [],
    this.venue = '',
    this.period,
    this.clock,
  });

  final String id;
  final String shortName;
  final String statusText;
  final String statusState; // 'pre' | 'in' | 'post'
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final String? homeLogo;
  final String? awayLogo;
  final DateTime? startTime;
  final List<String> broadcasts;
  final String venue;
  final int? period;
  final String? clock;

  bool get isLive => statusState == 'in';
  bool get isFinal => statusState == 'post';
  bool get isUpcoming => statusState == 'pre';

  factory ScoreboardEvent.fromJson(Map<String, dynamic> json) {
    final competitions =
        (json['competitions'] as List? ?? const []).whereType<Map>().toList();
    final competition = competitions.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(competitions.first);
    final competitors =
        (competition['competitors'] as List? ?? const []).whereType<Map>().toList();
    Map<String, dynamic> teamFor(String role) {
      final match = competitors.firstWhere(
        (c) => (c['homeAway'] as String?) == role,
        orElse: () => competitors.isEmpty ? const {} : competitors.first,
      );
      return Map<String, dynamic>.from(match);
    }

    final home = teamFor('home');
    final away = teamFor('away');
    final homeTeamMap = (home['team'] as Map?) ?? const <String, dynamic>{};
    final awayTeamMap = (away['team'] as Map?) ?? const <String, dynamic>{};
    final status = (json['status'] as Map? ?? const {});
    final statusType = (status['type'] as Map? ?? const {});
    final venueMap =
        (competition['venue'] as Map? ?? const <String, dynamic>{});
    final broadcasts = (competition['broadcasts'] as List? ?? const [])
        .whereType<Map>()
        .expand(
          (b) => ((b['names'] as List?) ?? const [])
              .whereType<String>(),
        )
        .toList();

    return ScoreboardEvent(
      id: (json['id'] as String?) ?? '',
      shortName: (json['shortName'] as String?) ??
          (json['name'] as String?) ??
          'Match',
      statusText: ((statusType['shortDetail'] as String?) ??
              (statusType['detail'] as String?) ??
              (statusType['description'] as String?) ??
              '')
          .trim(),
      statusState: (statusType['state'] as String?) ?? 'pre',
      homeTeam: (homeTeamMap['displayName'] as String?) ??
          (homeTeamMap['shortDisplayName'] as String?) ??
          'Home',
      awayTeam: (awayTeamMap['displayName'] as String?) ??
          (awayTeamMap['shortDisplayName'] as String?) ??
          'Away',
      homeScore: int.tryParse((home['score'] as String?) ?? '') ?? 0,
      awayScore: int.tryParse((away['score'] as String?) ?? '') ?? 0,
      homeLogo: homeTeamMap['logo'] as String?,
      awayLogo: awayTeamMap['logo'] as String?,
      startTime: DateTime.tryParse((json['date'] as String?) ?? ''),
      broadcasts: broadcasts.cast<String>(),
      venue: (venueMap['fullName'] as String?) ?? '',
      period: (status['period'] as num?)?.toInt(),
      clock: status['displayClock'] as String?,
    );
  }
}

class EspnRemoteDataSource {
  EspnRemoteDataSource(this._dio);

  final Dio _dio;

  static const _baseUrl = 'https://site.api.espn.com/apis/site/v2/sports';

  Future<List<ScoreboardEvent>> scoreboard({
    required String sport,
    required String league,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/$sport/$league/scoreboard',
      );
      final events = (response.data?['events'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ScoreboardEvent.fromJson)
          .toList();
      // Sort: live first, then upcoming (by start), then finals
      events.sort((a, b) {
        int rank(ScoreboardEvent e) =>
            e.isLive ? 0 : (e.isUpcoming ? 1 : 2);
        final r = rank(a).compareTo(rank(b));
        if (r != 0) return r;
        return (a.startTime ?? DateTime(2100))
            .compareTo(b.startTime ?? DateTime(2100));
      });
      return events;
    } catch (_) {
      return const [];
    }
  }
}
