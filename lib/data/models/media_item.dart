import '../../core/utils/image_utils.dart';

enum MediaType { movie, tv }

class EpisodeInfo {
  const EpisodeInfo({
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    required this.overview,
    this.runtimeLabel = '48m',
  });

  final int seasonNumber;
  final int episodeNumber;
  final String title;
  final String overview;
  final String runtimeLabel;

  String get label => 'S$seasonNumber E$episodeNumber';
}

class SeasonInfo {
  const SeasonInfo({
    required this.seasonNumber,
    required this.title,
    required this.episodes,
  });

  final int seasonNumber;
  final String title;
  final List<EpisodeInfo> episodes;
}

class MediaItem {
  const MediaItem({
    required this.tmdbId,
    required this.title,
    required this.mediaType,
    required this.genre,
    required this.releaseYear,
    required this.overview,
    required this.voteAverage,
    this.posterPath,
    this.backdropPath,
    this.imdbId,
    this.runtimeLabel,
    this.isNew = false,
    this.isFavorite = false,
    this.isInWatchlist = false,
    this.progress = 0,
    this.seasonEpisodeLabel,
    this.tags = const [],
    this.cast = const [],
    this.seasons = const [],
  });

  final int tmdbId;
  final String title;
  final MediaType mediaType;
  final String genre;
  final String releaseYear;
  final String overview;
  final double voteAverage;
  final String? posterPath;
  final String? backdropPath;
  final String? imdbId;
  final String? runtimeLabel;
  final bool isNew;
  final bool isFavorite;
  final bool isInWatchlist;
  final double progress;
  final String? seasonEpisodeLabel;
  final List<String> tags;
  final List<String> cast;
  final List<SeasonInfo> seasons;

  String? get posterUrl => ImageUtils.tmdbPoster(posterPath);
  String? get backdropUrl => ImageUtils.tmdbBackdrop(backdropPath);
  String get mediaTypeLabel =>
      mediaType == MediaType.movie ? 'Movie' : 'Series';
  bool get hasProgress => progress > 0;
  bool get hasArtwork => posterUrl != null || backdropUrl != null;
  List<SeasonInfo> get availableSeasons {
    if (mediaType != MediaType.tv) return const [];
    return seasons.isNotEmpty ? seasons : sampleSeasons;
  }

  factory MediaItem.fromTmdb(
    Map<String, dynamic> json, {
    String? fallbackType,
  }) {
    final type = (json['media_type'] as String?) ?? fallbackType ?? 'movie';
    final title = (json['title'] ?? json['name'] ?? 'Untitled') as String;
    final date =
        (json['release_date'] ?? json['first_air_date'] ?? '') as String;
    final year = date.length >= 4 ? date.substring(0, 4) : 'New';
    final genreIds = (json['genre_ids'] as List? ?? const [])
        .whereType<num>()
        .map((id) => id.toInt())
        .toList();

    return MediaItem(
      tmdbId: (json['id'] as num).toInt(),
      title: title,
      mediaType: type == 'tv' ? MediaType.tv : MediaType.movie,
      genre: _genreName(
        genreIds,
        type == 'tv' ? MediaType.tv : MediaType.movie,
      ),
      releaseYear: year,
      overview: (json['overview'] ?? '') as String,
      voteAverage: ((json['vote_average'] ?? 0) as num).toDouble(),
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      isNew: year == DateTime.now().year.toString(),
    );
  }

  factory MediaItem.fromCinemeta(
    Map<String, dynamic> json, {
    required MediaType fallbackType,
  }) {
    final type = (json['type'] ?? '') as String;
    final mediaType = type == 'series'
        ? MediaType.tv
        : type == 'movie'
        ? MediaType.movie
        : fallbackType;
    final imdbId = (json['imdb_id'] ?? json['id']) as String?;
    final genres = (json['genre'] as List? ?? const [])
        .whereType<String>()
        .toList();
    final rawRating = (json['imdbRating'] ?? '') as String;
    final rating = double.tryParse(rawRating) ?? 0;
    final releaseInfo = (json['releaseInfo'] ?? json['year'] ?? '') as String;
    final released = (json['released'] ?? '') as String;

    return MediaItem(
      tmdbId: (json['moviedb_id'] as num?)?.toInt() ?? _stableNumericId(imdbId),
      title: (json['name'] ?? 'Untitled') as String,
      mediaType: mediaType,
      genre: genres.isNotEmpty
          ? genres.first
          : mediaType == MediaType.tv
          ? 'Drama'
          : 'Cinema',
      releaseYear: _yearFrom(releaseInfo, released),
      overview: (json['description'] ?? '') as String,
      voteAverage: rating,
      posterPath: json['poster'] as String?,
      backdropPath: json['background'] as String?,
      imdbId: imdbId,
      runtimeLabel: mediaType == MediaType.tv
          ? 'Series'
          : (json['runtime'] as String?),
      seasons: mediaType == MediaType.tv ? sampleSeasons : const [],
      cast: (json['cast'] as List? ?? const []).whereType<String>().toList(),
      tags: [if (mediaType == MediaType.tv) 'tv' else 'movies', ...genres],
    );
  }

  static String _yearFrom(String releaseInfo, String released) {
    final source = releaseInfo.isNotEmpty ? releaseInfo : released;
    final match = RegExp(r'\d{4}').firstMatch(source);
    return match?.group(0) ?? 'New';
  }

  static int _stableNumericId(String? value) {
    var hash = 0;
    for (final codeUnit in (value ?? 'cinemeta').codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x0fffffff;
    }
    return 700000000 + hash;
  }

  static String _genreName(List<int> genreIds, MediaType mediaType) {
    const names = {
      12: 'Adventure',
      14: 'Fantasy',
      16: 'Animation',
      18: 'Drama',
      27: 'Horror',
      28: 'Action',
      35: 'Comedy',
      36: 'History',
      37: 'Western',
      53: 'Thriller',
      80: 'Crime',
      878: 'Sci-Fi',
      9648: 'Mystery',
      10749: 'Romance',
      10751: 'Family',
      10759: 'Action',
      10762: 'Kids',
      10765: 'Sci-Fi',
      10768: 'War',
    };
    for (final id in genreIds) {
      final name = names[id];
      if (name != null) return name;
    }
    return mediaType == MediaType.tv ? 'Series' : 'Film';
  }

  MediaItem copyWith({
    String? genre,
    String? releaseYear,
    double? voteAverage,
    String? runtimeLabel,
    List<String>? tags,
    bool? isFavorite,
    bool? isInWatchlist,
    double? progress,
    String? seasonEpisodeLabel,
  }) {
    return MediaItem(
      tmdbId: tmdbId,
      title: title,
      mediaType: mediaType,
      genre: genre ?? this.genre,
      releaseYear: releaseYear ?? this.releaseYear,
      overview: overview,
      voteAverage: voteAverage ?? this.voteAverage,
      posterPath: posterPath,
      backdropPath: backdropPath,
      imdbId: imdbId,
      runtimeLabel: runtimeLabel ?? this.runtimeLabel,
      isNew: isNew,
      isFavorite: isFavorite ?? this.isFavorite,
      isInWatchlist: isInWatchlist ?? this.isInWatchlist,
      progress: progress ?? this.progress,
      seasonEpisodeLabel: seasonEpisodeLabel ?? this.seasonEpisodeLabel,
      tags: tags ?? this.tags,
      cast: cast,
      seasons: seasons,
    );
  }

  static const sampleSeasons = <SeasonInfo>[
    SeasonInfo(
      seasonNumber: 1,
      title: 'Season 1',
      episodes: [
        EpisodeInfo(
          seasonNumber: 1,
          episodeNumber: 1,
          title: 'Opening Night',
          overview: 'A strange signal pulls the family into a larger mystery.',
        ),
        EpisodeInfo(
          seasonNumber: 1,
          episodeNumber: 2,
          title: 'The Signal',
          overview: 'A hidden lead points toward a dangerous source.',
        ),
        EpisodeInfo(
          seasonNumber: 1,
          episodeNumber: 3,
          title: 'Pressure Drop',
          overview: 'Old alliances bend as the stakes become personal.',
        ),
        EpisodeInfo(
          seasonNumber: 1,
          episodeNumber: 4,
          title: 'No Safe House',
          overview: 'The crew moves fast when a quiet refuge collapses.',
        ),
        EpisodeInfo(
          seasonNumber: 1,
          episodeNumber: 5,
          title: 'Fault Lines',
          overview: 'Pressure builds as the first betrayal becomes visible.',
        ),
        EpisodeInfo(
          seasonNumber: 1,
          episodeNumber: 6,
          title: 'Hard Reset',
          overview: 'A desperate plan changes the rules for everyone involved.',
        ),
        EpisodeInfo(
          seasonNumber: 1,
          episodeNumber: 7,
          title: 'The Turn',
          overview:
              'A hidden motive turns an uneasy alliance into open danger.',
        ),
        EpisodeInfo(
          seasonNumber: 1,
          episodeNumber: 8,
          title: 'Blackout',
          overview: 'The city goes dark while the crew races a closing window.',
        ),
        EpisodeInfo(
          seasonNumber: 1,
          episodeNumber: 9,
          title: 'Point of No Return',
          overview: 'The cost of the mission becomes impossible to ignore.',
        ),
        EpisodeInfo(
          seasonNumber: 1,
          episodeNumber: 10,
          title: 'Final Signal',
          overview: 'A season-long mystery breaks open in the final hours.',
          runtimeLabel: '55m',
        ),
      ],
    ),
    SeasonInfo(
      seasonNumber: 2,
      title: 'Season 2',
      episodes: [
        EpisodeInfo(
          seasonNumber: 2,
          episodeNumber: 1,
          title: 'Aftermath',
          overview: 'The next chapter opens with hard consequences.',
        ),
        EpisodeInfo(
          seasonNumber: 2,
          episodeNumber: 2,
          title: 'Line of Fire',
          overview: 'A new threat forces a different kind of plan.',
        ),
        EpisodeInfo(
          seasonNumber: 2,
          episodeNumber: 3,
          title: 'The Long Way Down',
          overview: 'Secrets surface during a dangerous descent.',
        ),
        EpisodeInfo(
          seasonNumber: 2,
          episodeNumber: 4,
          title: 'Red Line',
          overview: 'A rescue attempt forces the team across enemy ground.',
        ),
        EpisodeInfo(
          seasonNumber: 2,
          episodeNumber: 5,
          title: 'After Image',
          overview: 'The truth leaves behind a trail no one can fully erase.',
        ),
        EpisodeInfo(
          seasonNumber: 2,
          episodeNumber: 6,
          title: 'The Weight',
          overview: 'Old promises collide with the demands of survival.',
        ),
        EpisodeInfo(
          seasonNumber: 2,
          episodeNumber: 7,
          title: 'Open Channel',
          overview: 'A message from the outside changes the endgame.',
        ),
        EpisodeInfo(
          seasonNumber: 2,
          episodeNumber: 8,
          title: 'Endgame',
          overview: 'The season closes with a victory that does not feel safe.',
          runtimeLabel: '52m',
        ),
      ],
    ),
    SeasonInfo(
      seasonNumber: 3,
      title: 'Season 3',
      episodes: [
        EpisodeInfo(
          seasonNumber: 3,
          episodeNumber: 1,
          title: 'New Terms',
          overview: 'A new order takes shape after the fallout.',
        ),
        EpisodeInfo(
          seasonNumber: 3,
          episodeNumber: 2,
          title: 'Deep Cover',
          overview: 'An infiltration mission exposes a second conspiracy.',
        ),
        EpisodeInfo(
          seasonNumber: 3,
          episodeNumber: 3,
          title: 'Loose Ends',
          overview: 'A forgotten lead returns at exactly the wrong time.',
        ),
        EpisodeInfo(
          seasonNumber: 3,
          episodeNumber: 4,
          title: 'Countermove',
          overview: 'The opposition answers with a strike nobody predicted.',
        ),
        EpisodeInfo(
          seasonNumber: 3,
          episodeNumber: 5,
          title: 'Pressure Test',
          overview: 'The team finds out which loyalties can survive contact.',
        ),
        EpisodeInfo(
          seasonNumber: 3,
          episodeNumber: 6,
          title: 'The Crossing',
          overview: 'A dangerous route becomes the only way forward.',
        ),
        EpisodeInfo(
          seasonNumber: 3,
          episodeNumber: 7,
          title: 'Last Light',
          overview: 'Everything narrows to one final window of action.',
        ),
        EpisodeInfo(
          seasonNumber: 3,
          episodeNumber: 8,
          title: 'The Reckoning',
          overview: 'The season ends with choices that cannot be walked back.',
          runtimeLabel: '54m',
        ),
      ],
    ),
  ];

  static const samples = <MediaItem>[
    MediaItem(
      tmdbId: 693134,
      title: 'Dune: Part Two',
      mediaType: MediaType.movie,
      genre: 'Sci-Fi',
      releaseYear: '2024',
      runtimeLabel: '2h 46m',
      voteAverage: 8.2,
      posterPath: '/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
      backdropPath: '/xOMo8BRK7PfcJv9JCnx7s5hj0PX.jpg',
      imdbId: 'tt15239678',
      overview:
          'Paul Atreides unites with Chani and the Fremen while seeking revenge against the conspirators who destroyed his family.',
      isNew: true,
      isInWatchlist: true,
      tags: ['top-netflix', 'sci-fi', 'movies', 'new'],
    ),
    MediaItem(
      tmdbId: 872585,
      title: 'Oppenheimer',
      mediaType: MediaType.movie,
      genre: 'Drama',
      releaseYear: '2023',
      runtimeLabel: '3h 0m',
      voteAverage: 8.1,
      posterPath: '/ptpr0kGAckfQkJeJIt8st5dglvd.jpg',
      backdropPath: '/fm6KqXpk3M2HVveHwCrBSSBaO0V.jpg',
      imdbId: 'tt15398776',
      overview:
          'The story of J. Robert Oppenheimer and the creation of the atomic bomb during World War II.',
      tags: ['top-netflix', 'movies', 'drama'],
    ),
    MediaItem(
      tmdbId: 157336,
      title: 'Interstellar',
      mediaType: MediaType.movie,
      genre: 'Sci-Fi',
      releaseYear: '2014',
      runtimeLabel: '2h 49m',
      voteAverage: 8.4,
      posterPath: '/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
      backdropPath: '/pbrkL804c8yAv3zBZR4QPEafpAR.jpg',
      imdbId: 'tt0816692',
      overview:
          'A team of explorers travels through a wormhole in space in an attempt to ensure humanity survival.',
      tags: ['top-netflix', 'sci-fi', 'movies'],
    ),
    MediaItem(
      tmdbId: 76479,
      title: 'The Boys',
      mediaType: MediaType.tv,
      genre: 'Action',
      releaseYear: '2019',
      runtimeLabel: 'Series',
      voteAverage: 8.5,
      posterPath: '/2zmTngn1tYC1AvfnrFLhxeD82hz.jpg',
      backdropPath: '/mGVrXeIjyecj6TKmwPVpHlscEmw.jpg',
      imdbId: 'tt1190634',
      overview:
          'A group of vigilantes set out to take down corrupt superheroes who abuse their powers.',
      progress: 0.32,
      seasonEpisodeLabel: 'S1 E3 - 34m left',
      seasons: sampleSeasons,
      tags: ['tv', 'action'],
    ),
    MediaItem(
      tmdbId: 94605,
      title: 'Arcane',
      mediaType: MediaType.tv,
      genre: 'Animation',
      releaseYear: '2021',
      runtimeLabel: 'Series',
      voteAverage: 8.7,
      posterPath: '/fqldf2t8ztc9aiwn3k6mlX3tvRT.jpg',
      backdropPath: '/rkB4LyZHo1NHXFEDHl9vSD9r1lI.jpg',
      imdbId: 'tt11126994',
      overview:
          'Amid the stark discord of twin cities Piltover and Zaun, two sisters fight on rival sides of a war.',
      progress: 0.45,
      seasonEpisodeLabel: 'S2 E5 - 42m left',
      seasons: sampleSeasons,
      tags: ['tv', 'anime', 'action'],
    ),
    MediaItem(
      tmdbId: 125988,
      title: 'Silo',
      mediaType: MediaType.tv,
      genre: 'Mystery',
      releaseYear: '2023',
      runtimeLabel: 'Series',
      voteAverage: 8.1,
      posterPath: '/x2LSRK2Cm7MZhjluni1msVJ3wDF.jpg',
      backdropPath: '/wO15XEgeLbeijtf3MQAUqWCxSxc.jpg',
      imdbId: 'tt14688458',
      overview:
          'In a ruined and toxic future, thousands live in a giant silo deep underground with strict rules.',
      progress: 0.72,
      seasonEpisodeLabel: 'S2 E9 - 28m left',
      seasons: sampleSeasons,
      tags: ['tv', 'sci-fi'],
    ),
    MediaItem(
      tmdbId: 1184918,
      title: 'The Wild Robot',
      mediaType: MediaType.movie,
      genre: 'Adventure',
      releaseYear: '2024',
      runtimeLabel: '1h 42m',
      voteAverage: 8.3,
      posterPath: '/wTnV3PCVW5O92JMrFvvrRcV39RU.jpg',
      backdropPath: '/v9acaWVVFdZT5yAU7J2QjwfhXyD.jpg',
      imdbId: 'tt29623480',
      overview:
          'After a shipwreck, an intelligent robot adapts to island life and forms an unlikely family.',
      isFavorite: true,
      tags: ['movies', 'family', 'new'],
    ),
    MediaItem(
      tmdbId: 108978,
      title: 'Reacher',
      mediaType: MediaType.tv,
      genre: 'Thriller',
      releaseYear: '2022',
      runtimeLabel: 'Series',
      voteAverage: 8.1,
      posterPath: '/jFuH0md41x5mB4qj5344mSmtHrO.jpg',
      backdropPath: '/aV1KGO9X3S4kzqEptVDAvGjccql.jpg',
      imdbId: 'tt9288030',
      overview:
          'Jack Reacher, a veteran military police investigator, enters civilian life and keeps finding trouble.',
      isInWatchlist: true,
      seasons: sampleSeasons,
      tags: ['tv', 'action'],
    ),
    MediaItem(
      tmdbId: 579974,
      title: 'RRR',
      mediaType: MediaType.movie,
      genre: 'Action',
      releaseYear: '2022',
      runtimeLabel: '3h 7m',
      voteAverage: 7.8,
      posterPath: '/u0XUBNQWlOvrh0Gd97ARGpIkL0.jpg',
      backdropPath: '/i0Y0wP8H6SRgjr6QmuwbtQbS24D.jpg',
      imdbId: 'tt8178634',
      overview:
          'Two legendary revolutionaries cross paths in a roaring action epic about friendship, duty, and rebellion.',
      tags: ['top-hindi', 'hindi-dubbed', 'action', 'movies'],
    ),
    MediaItem(
      tmdbId: 872906,
      title: 'Jawan',
      mediaType: MediaType.movie,
      genre: 'Action',
      releaseYear: '2023',
      runtimeLabel: '2h 49m',
      voteAverage: 7.2,
      posterPath: '/jFt1gS4BGHlK8xt76Y81Alp4dbt.jpg',
      backdropPath: '/5LtSjMNw6j3LkG29Oa4O0iY5U8.jpg',
      imdbId: 'tt15354916',
      overview:
          'A prison warden recruits inmates for bold missions while confronting a dangerous arms dealer.',
      tags: ['top-hindi', 'action', 'movies'],
    ),
    MediaItem(
      tmdbId: 864692,
      title: 'Pathaan',
      mediaType: MediaType.movie,
      genre: 'Thriller',
      releaseYear: '2023',
      runtimeLabel: '2h 26m',
      voteAverage: 6.6,
      posterPath: '/arf00BkwvXo0CFKbaD9OpqdE4Nu.jpg',
      backdropPath: '/9wRAIQeOv2qzcgpfvA4dYZKeezl.jpg',
      imdbId: 'tt12844910',
      overview:
          'An exiled agent returns for a high-stakes mission against a mercenary threat.',
      tags: ['top-hindi', 'action', 'movies'],
    ),
    MediaItem(
      tmdbId: 1140066,
      title: '12th Fail',
      mediaType: MediaType.movie,
      genre: 'Drama',
      releaseYear: '2023',
      runtimeLabel: '2h 26m',
      voteAverage: 8.1,
      posterPath: '/yGz88hNPcHUJkUx7MPm0Ue6GZt7.jpg',
      backdropPath: '/df8ya9FKghk0U45G2nJru6ZOuUK.jpg',
      imdbId: 'tt23849204',
      overview:
          'A student from a small town battles setbacks while chasing the civil service dream.',
      tags: ['top-hindi', 'drama', 'movies'],
    ),
    MediaItem(
      tmdbId: 360814,
      title: 'Dangal',
      mediaType: MediaType.movie,
      genre: 'Drama',
      releaseYear: '2016',
      runtimeLabel: '2h 41m',
      voteAverage: 7.9,
      posterPath: '/1CoKNi3XVyijPCvy0usDbSWEXAg.jpg',
      backdropPath: '/l0fNAHLOFReQJsxCOmGWvJDnimn.jpg',
      imdbId: 'tt5074352',
      overview:
          'A former wrestler trains his daughters to compete on the world stage.',
      tags: ['top-hindi', 'family', 'drama', 'movies'],
    ),
    MediaItem(
      tmdbId: 897087,
      title: 'Kantara',
      mediaType: MediaType.movie,
      genre: 'Thriller',
      releaseYear: '2022',
      runtimeLabel: '2h 27m',
      voteAverage: 7.2,
      posterPath: '/7Bd4EUOqQDKZXA6Od5gkfzRNb0.jpg',
      backdropPath: '/zIYROrkHJPYB3VTiW1L9QVgaQO.jpg',
      imdbId: 'tt15327088',
      overview:
          'Folklore, land conflict, and justice collide in a fierce coastal village story.',
      tags: ['hindi-dubbed', 'thriller', 'movies'],
    ),
    MediaItem(
      tmdbId: 801688,
      title: 'Kalki 2898 AD',
      mediaType: MediaType.movie,
      genre: 'Sci-Fi',
      releaseYear: '2024',
      runtimeLabel: '3h 1m',
      voteAverage: 6.9,
      posterPath: '/rstcAnBeCkxNQjNp3YXrF6IP1tW.jpg',
      backdropPath: '/o8XSR1SONnjcsv84NRu6Mwsl5io.jpg',
      imdbId: 'tt12735488',
      overview:
          'A mythic sci-fi future unfolds around rebels, bounty hunters, and a prophesied child.',
      tags: ['hindi-dubbed', 'sci-fi', 'action', 'movies', 'new'],
    ),
    MediaItem(
      tmdbId: 667538,
      title: 'Transformers One',
      mediaType: MediaType.movie,
      genre: 'Animation',
      releaseYear: '2024',
      runtimeLabel: '1h 44m',
      voteAverage: 8.0,
      posterPath: '/gPbM0MK8CP8A174rmUwGsADNYKD.jpg',
      backdropPath: '/2vFuG6bWGyQUzYS9d69E5l85nIz.jpg',
      imdbId: 'tt8864596',
      overview:
          'The origin story of Optimus Prime and Megatron before they became sworn enemies.',
      tags: ['hindi-dubbed', 'family', 'action', 'movies', 'new'],
    ),
    MediaItem(
      tmdbId: 66732,
      title: 'Stranger Things',
      mediaType: MediaType.tv,
      genre: 'Sci-Fi',
      releaseYear: '2016',
      runtimeLabel: 'Series',
      voteAverage: 8.6,
      posterPath: '/uOOtwVbSr4QDjAGIifLDwpb2Pdl.jpg',
      backdropPath: '/56v2KjBlU4XaOv9rVYEQypROD7P.jpg',
      imdbId: 'tt4574334',
      overview:
          'Friends in a small town uncover secret experiments and a terrifying parallel world.',
      seasons: sampleSeasons,
      tags: ['top-netflix', 'tv', 'sci-fi'],
    ),
    MediaItem(
      tmdbId: 71446,
      title: 'Money Heist',
      mediaType: MediaType.tv,
      genre: 'Crime',
      releaseYear: '2017',
      runtimeLabel: 'Series',
      voteAverage: 8.2,
      posterPath: '/reEMJA1uzscCbkpeRJeTT2bjqUp.jpg',
      backdropPath: '/gFZriCkpJYsApPZEF3jhxL4yLzG.jpg',
      imdbId: 'tt6468322',
      overview:
          'A criminal mastermind gathers specialists for a meticulously planned heist.',
      seasons: sampleSeasons,
      tags: ['top-netflix', 'tv', 'crime'],
    ),
    MediaItem(
      tmdbId: 93405,
      title: 'Squid Game',
      mediaType: MediaType.tv,
      genre: 'Thriller',
      releaseYear: '2021',
      runtimeLabel: 'Series',
      voteAverage: 7.9,
      posterPath: '/1QdXdRYfktUSONkl1oD5gc6Be0s.jpg',
      backdropPath: '/2meX1nMdScFOoV4370rqHWKmXhY.jpg',
      imdbId: 'tt10919420',
      overview:
          'Cash-strapped contestants enter deadly children games for a life-changing prize.',
      seasons: sampleSeasons,
      tags: ['top-netflix', 'tv', 'thriller'],
    ),
    MediaItem(
      tmdbId: 1429001,
      title: 'Attack on Titan',
      mediaType: MediaType.tv,
      genre: 'Anime',
      releaseYear: '2013',
      runtimeLabel: 'Series',
      voteAverage: 8.7,
      posterPath: '/hTP1DtLGFamjfu8WqjnuQdP1n4i.jpg',
      backdropPath: '/rqbCbjB19amtOtFQbb3K2lgm2zv.jpg',
      imdbId: 'tt2560140',
      overview:
          'Humanity fights for survival against enormous beings beyond the walls.',
      seasons: sampleSeasons,
      tags: ['anime', 'tv', 'action', 'top-netflix'],
    ),
    MediaItem(
      tmdbId: 85937,
      title: 'Demon Slayer',
      mediaType: MediaType.tv,
      genre: 'Anime',
      releaseYear: '2019',
      runtimeLabel: 'Series',
      voteAverage: 8.6,
      posterPath: '/xUfRZu2mi8jH6SzQEJGP6tjBuYj.jpg',
      backdropPath: '/3GQKYh6Trm8pxd2AypovoYQf4Ay.jpg',
      imdbId: 'tt9335498',
      overview:
          'A kindhearted boy trains as a demon slayer after tragedy changes his family forever.',
      progress: 0.18,
      seasonEpisodeLabel: 'S1 E2 - 19m left',
      seasons: sampleSeasons,
      tags: ['anime', 'tv', 'action'],
    ),
    MediaItem(
      tmdbId: 95479,
      title: 'Jujutsu Kaisen',
      mediaType: MediaType.tv,
      genre: 'Anime',
      releaseYear: '2020',
      runtimeLabel: 'Series',
      voteAverage: 8.5,
      posterPath: '/fHpKWq9ayzSk8nSwqRuaAUemRKh.jpg',
      backdropPath: '/qpin8cASXEVtwhzNsprHYFiOAGk.jpg',
      imdbId: 'tt12343534',
      overview:
          'A student enters a secret world of curses, sorcerers, and impossible choices.',
      seasons: sampleSeasons,
      tags: ['anime', 'tv', 'action'],
    ),
    MediaItem(
      tmdbId: 127532,
      title: 'Solo Leveling',
      mediaType: MediaType.tv,
      genre: 'Anime',
      releaseYear: '2024',
      runtimeLabel: 'Series',
      voteAverage: 8.4,
      posterPath: '/geCRueV3ElhRTr0xtJuEWJt6dJ1.jpg',
      backdropPath: '/xMNH87maNLt9n2bMDYeI6db5VFm.jpg',
      imdbId: 'tt21209876',
      overview:
          'The weakest hunter begins a brutal climb through gates, monsters, and hidden power.',
      seasons: sampleSeasons,
      tags: ['anime', 'tv', 'new', 'action'],
    ),
    MediaItem(
      tmdbId: 94997,
      title: 'House of the Dragon',
      mediaType: MediaType.tv,
      genre: 'Fantasy',
      releaseYear: '2022',
      runtimeLabel: 'Series',
      voteAverage: 8.3,
      posterPath: '/7QMsOTMUswlwxJP0rTTZfmz2tX2.jpg',
      backdropPath: '/etj8E2o0Bud0HkONVQPjyCkIvpv.jpg',
      imdbId: 'tt11198330',
      overview:
          'House Targaryen fractures as rival heirs drag Westeros toward civil war.',
      seasons: sampleSeasons,
      tags: ['tv', 'fantasy', 'top-netflix', 'action'],
    ),
    MediaItem(
      tmdbId: 100088,
      title: 'The Last of Us',
      mediaType: MediaType.tv,
      genre: 'Drama',
      releaseYear: '2023',
      runtimeLabel: 'Series',
      voteAverage: 8.6,
      posterPath: '/uKvVjHNqB5VmOrdxqAt2F7J78ED.jpg',
      backdropPath: '/uDgy6hyPd82kOHh6I95FLtLnj6p.jpg',
      imdbId: 'tt3581920',
      overview:
          'Two survivors cross a broken America while carrying hope through a hostile world.',
      progress: 0.58,
      seasonEpisodeLabel: 'S1 E6 - 23m left',
      seasons: sampleSeasons,
      tags: ['tv', 'drama', 'top-netflix'],
    ),
    MediaItem(
      tmdbId: 108545,
      title: '3 Body Problem',
      mediaType: MediaType.tv,
      genre: 'Sci-Fi',
      releaseYear: '2024',
      runtimeLabel: 'Series',
      voteAverage: 7.5,
      posterPath: '/ykZ7hlShkdRQaL2aiieXdEMmrLb.jpg',
      backdropPath: '/20eIP9o5ebArmu2HxJutaBjhLf4.jpg',
      imdbId: 'tt13016388',
      overview:
          'A mystery spanning decades reveals a threat far beyond human imagination.',
      seasons: sampleSeasons,
      tags: ['tv', 'sci-fi', 'new', 'top-netflix'],
    ),
    MediaItem(
      tmdbId: 126308,
      title: 'Shogun',
      mediaType: MediaType.tv,
      genre: 'Drama',
      releaseYear: '2024',
      runtimeLabel: 'Series',
      voteAverage: 8.6,
      posterPath: '/7O4iVfOMQmdCSxhOg1WnzG1AgYT.jpg',
      backdropPath: '/6Tb87q9Tog30F5AAHh1gyDT2Vve.jpg',
      imdbId: 'tt2788316',
      overview:
          'A marooned pilot becomes entangled in a ruthless struggle for power in feudal Japan.',
      seasons: sampleSeasons,
      tags: ['tv', 'drama', 'new', 'top-netflix'],
    ),
    MediaItem(
      tmdbId: 1399,
      title: 'Game of Thrones',
      mediaType: MediaType.tv,
      genre: 'Fantasy',
      releaseYear: '2011',
      runtimeLabel: 'Series',
      voteAverage: 8.5,
      posterPath: '/1XS1oqL89opfnbLl8WnZY1O1uJx.jpg',
      backdropPath: '/2OMB0ynKlyIenMJWI2Dy9IWT4c.jpg',
      imdbId: 'tt0944947',
      overview:
          'Noble houses fight for the Iron Throne while an ancient enemy gathers beyond the wall.',
      seasons: sampleSeasons,
      tags: ['tv', 'fantasy', 'action'],
    ),
    MediaItem(
      tmdbId: 42009,
      title: 'Black Mirror',
      mediaType: MediaType.tv,
      genre: 'Sci-Fi',
      releaseYear: '2011',
      runtimeLabel: 'Series',
      voteAverage: 8.3,
      posterPath: '/7PRddOvz7Je0rWxT7olZ77Ty4jF.jpg',
      imdbId: 'tt2085059',
      overview:
          'Anthology stories explore technology, culture, and the uneasy future around the corner.',
      seasons: sampleSeasons,
      tags: ['tv', 'sci-fi', 'top-netflix'],
    ),
    MediaItem(
      tmdbId: 17610,
      title: 'NCIS',
      mediaType: MediaType.tv,
      genre: 'Crime',
      releaseYear: '2003',
      runtimeLabel: 'Series',
      voteAverage: 7.6,
      posterPath: '/TIIgcznwNfNr3KOZvxn26eKV99.jpg',
      backdropPath: '/dAepkmD4vdfhS82r2OIqF1nwGR5.jpg',
      imdbId: 'tt0364845',
      overview:
          'A naval investigative team solves cases involving military personnel and national security.',
      seasons: sampleSeasons,
      tags: ['tv', 'crime'],
    ),
    MediaItem(
      tmdbId: 60574,
      title: 'Peaky Blinders',
      mediaType: MediaType.tv,
      genre: 'Crime',
      releaseYear: '2013',
      runtimeLabel: 'Series',
      voteAverage: 8.5,
      posterPath: '/vUUqzWa2LnHIVqkaKVlVGkVcZIW.jpg',
      imdbId: 'tt2442560',
      overview:
          'A crime family builds power through ambition, loyalty, and violence in postwar Birmingham.',
      seasons: sampleSeasons,
      tags: ['tv', 'crime', 'top-netflix'],
    ),
    MediaItem(
      tmdbId: 112836,
      title: 'Money Heist: Korea - Joint Economic Area',
      mediaType: MediaType.tv,
      genre: 'Crime',
      releaseYear: '2022',
      runtimeLabel: 'Series',
      voteAverage: 7.8,
      posterPath: 'https://images.metahub.space/poster/small/tt13696452/img',
      backdropPath:
          'https://images.metahub.space/background/medium/tt13696452/img',
      imdbId: 'tt13696452',
      overview:
          'A new crew targets a mint inside a divided Korea with a plan built for chaos.',
      seasons: sampleSeasons,
      tags: ['tv', 'crime', 'top-netflix'],
    ),
    MediaItem(
      tmdbId: 114614,
      title: 'Wednesday',
      mediaType: MediaType.tv,
      genre: 'Mystery',
      releaseYear: '2022',
      runtimeLabel: 'Series',
      voteAverage: 8.4,
      posterPath: '/9PFonBhy4cQy7Jz20NpMygczOkv.jpg',
      backdropPath: '/iHSwvRVsRyxpX7FE7GbviaDvgGZ.jpg',
      imdbId: 'tt13443470',
      overview:
          'Wednesday Addams investigates murders, family secrets, and school politics at Nevermore.',
      seasons: sampleSeasons,
      tags: ['tv', 'mystery', 'top-netflix'],
    ),
    MediaItem(
      tmdbId: 37854,
      title: 'One Piece',
      mediaType: MediaType.tv,
      genre: 'Adventure',
      releaseYear: '1999',
      runtimeLabel: 'Series',
      voteAverage: 8.7,
      posterPath: '/dB4EDhre2dsC2kxYDavyKWqLQwi.jpg',
      backdropPath: '/4Mt7WHox67uJ1yErwTBFcV8KWgG.jpg',
      imdbId: 'tt0388629',
      overview:
          'A rubber-bodied pirate and his crew chase the legendary treasure across dangerous seas.',
      seasons: sampleSeasons,
      tags: ['anime', 'tv', 'action', 'fantasy'],
    ),
    MediaItem(
      tmdbId: 209867,
      title: 'Frieren',
      mediaType: MediaType.tv,
      genre: 'Anime',
      releaseYear: '2023',
      runtimeLabel: 'Series',
      voteAverage: 8.9,
      posterPath: '/dqZENchTd7lp5zht7BdlqM7RBhD.jpg',
      backdropPath: '/rBOnrVlck7BIlGeWVlzYiZeg4l2.jpg',
      imdbId: 'tt22248376',
      overview:
          'An elf mage retraces old journeys and learns what time meant to the people beside her.',
      seasons: sampleSeasons,
      tags: ['anime', 'tv', 'fantasy', 'new'],
    ),
    MediaItem(
      tmdbId: 114410,
      title: 'Chainsaw Man',
      mediaType: MediaType.tv,
      genre: 'Anime',
      releaseYear: '2022',
      runtimeLabel: 'Series',
      voteAverage: 8.5,
      posterPath: '/yVtx7Xn9UxNJqvG2BkvhCcmed9S.jpg',
      backdropPath: '/5DUMPBSnHOZsbBv81GFXZXvDpo6.jpg',
      imdbId: 'tt13616990',
      overview:
          'A broke devil hunter fuses with his pet devil and enters a violent government unit.',
      seasons: sampleSeasons,
      tags: ['anime', 'tv', 'action'],
    ),
    MediaItem(
      tmdbId: 65930,
      title: 'My Hero Academia',
      mediaType: MediaType.tv,
      genre: 'Anime',
      releaseYear: '2016',
      runtimeLabel: 'Series',
      voteAverage: 8.6,
      posterPath: '/phuYuzqWW9ru8EA3HVjE9W2Rr3M.jpg',
      backdropPath: '/ol0H2DGp4ifBHA4JDlCpwJWxnY2.jpg',
      imdbId: 'tt5626028',
      overview:
          'A powerless boy enters a hero academy after inheriting the world greatest ability.',
      seasons: sampleSeasons,
      tags: ['anime', 'tv', 'action'],
    ),
    MediaItem(
      tmdbId: 1429,
      title: 'Attack on Titan: Final Chapters',
      mediaType: MediaType.tv,
      genre: 'Anime',
      releaseYear: '2023',
      runtimeLabel: 'Series',
      voteAverage: 8.9,
      imdbId: 'tt2560140',
      overview:
          'The war reaches its final stage as friends confront the impossible cost of freedom.',
      seasons: sampleSeasons,
      tags: ['anime', 'tv', 'action', 'new'],
    ),
    MediaItem(
      tmdbId: 135157,
      title: 'Vinland Saga',
      mediaType: MediaType.tv,
      genre: 'Anime',
      releaseYear: '2019',
      runtimeLabel: 'Series',
      voteAverage: 8.5,
      posterPath: '/gvOZN1NlAoL8iz9ghpES1zWA3w3.jpg',
      backdropPath: '/nBZyWSGAUEzCH7Mna0zUNTpBQlQ.jpg',
      imdbId: 'tt10233448',
      overview:
          'A young warrior chases revenge through a brutal world of raiders, kings, and consequence.',
      seasons: sampleSeasons,
      tags: ['anime', 'tv', 'action', 'drama'],
    ),
    MediaItem(
      tmdbId: 70981,
      title: 'Prometheus',
      mediaType: MediaType.movie,
      genre: 'Sci-Fi',
      releaseYear: '2012',
      runtimeLabel: '2h 4m',
      voteAverage: 6.6,
      posterPath: '/qsYQflQhOuhDpQ0W2aOcwqgDAeI.jpg',
      backdropPath: '/sM42bpH73dmf3kJrE8xr4kztYqR.jpg',
      imdbId: 'tt1446714',
      overview:
          'Explorers follow clues to humanity origins and discover something far more dangerous.',
      tags: ['movies', 'sci-fi', 'hindi-dubbed'],
    ),
    MediaItem(
      tmdbId: 1011985,
      title: 'Kung Fu Panda 4',
      mediaType: MediaType.movie,
      genre: 'Animation',
      releaseYear: '2024',
      runtimeLabel: '1h 34m',
      voteAverage: 7.1,
      posterPath: '/kDp1vUBnMpe8ak4rjgl3cLELqjU.jpg',
      backdropPath: '/3ffPx9jqg0yj9y1KWeagT7D20CB.jpg',
      imdbId: 'tt21692408',
      overview:
          'Po searches for a new Dragon Warrior while facing a sorceress who can summon old enemies.',
      tags: ['movies', 'family', 'new', 'hindi-dubbed'],
    ),
    MediaItem(
      tmdbId: 1022789,
      title: 'Inside Out 2',
      mediaType: MediaType.movie,
      genre: 'Animation',
      releaseYear: '2024',
      runtimeLabel: '1h 37m',
      voteAverage: 7.6,
      posterPath: '/vpnVM9B6NMmQpWeZvzLvDESb2QY.jpg',
      backdropPath: '/stKGOm8UyhuLPR9sZLjs5AkmncA.jpg',
      imdbId: 'tt22022452',
      overview:
          'New emotions arrive as Riley grows up and her inner world gets more complicated.',
      isFavorite: true,
      tags: ['movies', 'family', 'new', 'top-netflix'],
    ),
    MediaItem(
      tmdbId: 519182,
      title: 'Despicable Me 4',
      mediaType: MediaType.movie,
      genre: 'Animation',
      releaseYear: '2024',
      runtimeLabel: '1h 34m',
      voteAverage: 7.0,
      posterPath: '/wWba3TaojhK7NdycRhoQpsG0FaH.jpg',
      backdropPath: '/twsxsfao6ZOVvT8LfudH603MMi6.jpg',
      imdbId: 'tt7510222',
      overview:
          'Gru and his family face a revenge-obsessed villain while adapting to a new baby.',
      tags: ['movies', 'family', 'new', 'hindi-dubbed'],
    ),
    MediaItem(
      tmdbId: 823464,
      title: 'Godzilla x Kong',
      mediaType: MediaType.movie,
      genre: 'Action',
      releaseYear: '2024',
      runtimeLabel: '1h 55m',
      voteAverage: 7.1,
      posterPath: '/z1p34vh7dEOnLDmyCrlUVLuoDzd.jpg',
      backdropPath: '/1XDDXPXGiI8id7MrUxK36ke7gkX.jpg',
      imdbId: 'tt14539740',
      overview:
          'Two titans uncover a hidden threat that could reshape the surface world.',
      tags: ['movies', 'action', 'new', 'hindi-dubbed'],
    ),
    MediaItem(
      tmdbId: 786892,
      title: 'Furiosa',
      mediaType: MediaType.movie,
      genre: 'Action',
      releaseYear: '2024',
      runtimeLabel: '2h 29m',
      voteAverage: 7.5,
      posterPath: '/iADOJ8Zymht2JPMoy3R7xceZprc.jpg',
      backdropPath: '/wNAhuOZ3Zf84jCIlrcI6JhgmY5q.jpg',
      imdbId: 'tt12037194',
      overview:
          'A young Furiosa survives warlords and wasteland trials on her road home.',
      tags: ['movies', 'action', 'new'],
    ),
    MediaItem(
      tmdbId: 748783,
      title: 'The Garfield Movie',
      mediaType: MediaType.movie,
      genre: 'Family',
      releaseYear: '2024',
      runtimeLabel: '1h 41m',
      voteAverage: 7.1,
      posterPath: '/xYduFGuch9OwbCOEUiamml18ZoB.jpg',
      backdropPath: '/P82NAcEsLIYgQtrtn36tYsj41m.jpg',
      imdbId: 'tt5779228',
      overview:
          'Garfield is pulled from his pampered life into an outdoor heist with his long-lost father.',
      tags: ['movies', 'family', 'new'],
    ),
    MediaItem(
      tmdbId: 533535,
      title: 'Deadpool & Wolverine',
      mediaType: MediaType.movie,
      genre: 'Action',
      releaseYear: '2024',
      runtimeLabel: '2h 8m',
      voteAverage: 7.6,
      posterPath: '/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
      backdropPath: '/yDHYTfA3R0jFYba16jBB1ef8oIt.jpg',
      imdbId: 'tt6263850',
      overview:
          'A reckless mercenary teams with a weary mutant for a multiverse-shaking mission.',
      tags: ['movies', 'action', 'new', 'hindi-dubbed'],
    ),
    MediaItem(
      tmdbId: 346698,
      title: 'Barbie',
      mediaType: MediaType.movie,
      genre: 'Comedy',
      releaseYear: '2023',
      runtimeLabel: '1h 54m',
      voteAverage: 7.0,
      posterPath: '/iuFNMS8U5cb6xfzi51Dbkovj7vM.jpg',
      backdropPath: '/nHf61UzkfFno5X1ofIhugCPus2R.jpg',
      imdbId: 'tt1517268',
      overview:
          'A perfect doll leaves a perfect world and discovers the complicated real one.',
      tags: ['movies', 'comedy', 'top-netflix'],
    ),
    MediaItem(
      tmdbId: 155,
      title: 'The Dark Knight',
      mediaType: MediaType.movie,
      genre: 'Action',
      releaseYear: '2008',
      runtimeLabel: '2h 32m',
      voteAverage: 8.5,
      posterPath: '/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
      backdropPath: '/dqK9Hag1054tghRQSqLSfrkvQnA.jpg',
      imdbId: 'tt0468569',
      overview:
          'Batman faces a criminal mastermind determined to burn Gotham order to the ground.',
      tags: ['movies', 'action', 'top-netflix'],
    ),
    MediaItem(
      tmdbId: 361743,
      title: 'Top Gun: Maverick',
      mediaType: MediaType.movie,
      genre: 'Action',
      releaseYear: '2022',
      runtimeLabel: '2h 11m',
      voteAverage: 8.2,
      posterPath: '/62HCnUTziyWcpDaBO2i1DX17ljH.jpg',
      backdropPath: '/odJ4hx6g6vBt4lBWKFD1tI8WS4x.jpg',
      imdbId: 'tt1745960',
      overview:
          'A veteran pilot trains elite graduates for a mission that demands impossible precision.',
      tags: ['movies', 'action', 'top-netflix'],
    ),
    MediaItem(
      tmdbId: 324857,
      title: 'Spider-Man: Into the Spider-Verse',
      mediaType: MediaType.movie,
      genre: 'Animation',
      releaseYear: '2018',
      runtimeLabel: '1h 57m',
      voteAverage: 8.4,
      posterPath: '/iiZZdoQBEYBv6id8su7ImL0oCbD.jpg',
      backdropPath: '/uUiId6cG32JSRI6RyBQSvQtLjz2.jpg',
      imdbId: 'tt4633694',
      overview:
          'Miles Morales becomes Spider-Man and meets heroes from other dimensions.',
      tags: ['movies', 'family', 'action', 'hindi-dubbed'],
    ),
    MediaItem(
      tmdbId: 696506,
      title: 'Mickey 17',
      mediaType: MediaType.movie,
      genre: 'Sci-Fi',
      releaseYear: '2025',
      runtimeLabel: '2h 17m',
      voteAverage: 7.0,
      posterPath: '/edKpE9B5qN3e559OuMCLZdW1iBZ.jpg',
      backdropPath: '/9PRKAdrDvAdCfg3EcApLTfzGsEt.jpg',
      imdbId: 'tt12299608',
      overview:
          'A disposable worker on a distant colony confronts what it means to be replaced.',
      tags: ['movies', 'sci-fi', 'new'],
    ),
    MediaItem(
      tmdbId: 1029235,
      title: 'Azrael',
      mediaType: MediaType.movie,
      genre: 'Thriller',
      releaseYear: '2024',
      runtimeLabel: '1h 25m',
      voteAverage: 6.0,
      posterPath: '/qpdFKDvJS7oLKTcBLXOaMwUESbs.jpg',
      backdropPath: '/np58LPJkwC3THsKBkBscDKSlQPz.jpg',
      imdbId: 'tt22173666',
      overview:
          'A hunted woman escapes a silent cult in a world where speech has vanished.',
      tags: ['movies', 'thriller', 'new'],
    ),
    MediaItem(
      tmdbId: 949484,
      title: 'HIT: The Third Case',
      mediaType: MediaType.movie,
      genre: 'Thriller',
      releaseYear: '2025',
      runtimeLabel: '2h 35m',
      voteAverage: 7.0,
      posterPath: '/tLdUPi2h6LGmF5foza0a5PXtQRr.jpg',
      backdropPath: '/VsGIIEdZTf6QXwMy3tCf3CwrH4.jpg',
      imdbId: 'tt27276483',
      overview:
          'A specialist investigator follows a violent case through a maze of suspects.',
      tags: ['movies', 'top-hindi', 'thriller', 'new'],
    ),
    MediaItem(
      tmdbId: 976573,
      title: 'Animal',
      mediaType: MediaType.movie,
      genre: 'Action',
      releaseYear: '2023',
      runtimeLabel: '3h 21m',
      voteAverage: 6.4,
      posterPath: '/4Y1WNkd88JXmGfhtWR7dmDAo1T2.jpg',
      backdropPath: '/4fLZUr1e65hKPPVw0R3PmKFKxj1.jpg',
      imdbId: 'tt13751694',
      overview:
          'A son bound by obsession and loyalty unleashes a violent feud around his family.',
      tags: ['movies', 'top-hindi', 'action'],
    ),
    MediaItem(
      tmdbId: 949229,
      title: 'Leo',
      mediaType: MediaType.movie,
      genre: 'Action',
      releaseYear: '2023',
      runtimeLabel: '2h 44m',
      voteAverage: 6.8,
      posterPath: '/t1oAdt8JjUs4sHEBvE8fKtjV7er.jpg',
      backdropPath: '/MSNYxWe4u4en9vQ3oZIKQWKYHu.jpg',
      imdbId: 'tt15654328',
      overview:
          'A cafe owner with a hidden past is dragged back into a brutal underworld.',
      tags: ['movies', 'top-hindi', 'hindi-dubbed', 'action'],
    ),
    MediaItem(
      tmdbId: 743563,
      title: 'Drishyam 2',
      mediaType: MediaType.movie,
      genre: 'Thriller',
      releaseYear: '2022',
      runtimeLabel: '2h 20m',
      voteAverage: 7.8,
      posterPath: '/774UV1aCURb4s4JfEFg3IEMu5Zj.jpg',
      backdropPath: '/dkIX4dSMuVqjfrPGunBJUR7K3LQ.jpg',
      imdbId: 'tt15501640',
      overview:
          'A family tries to stay ahead as an old investigation threatens to reopen.',
      tags: ['movies', 'top-hindi', 'thriller', 'drama'],
    ),
    MediaItem(
      tmdbId: 858082,
      title: 'Vikram',
      mediaType: MediaType.movie,
      genre: 'Action',
      releaseYear: '2022',
      runtimeLabel: '2h 54m',
      voteAverage: 7.6,
      posterPath: '/1fMM5yjLYJNfO3CSQBpfC1kqeIK.jpg',
      backdropPath: '/dWwcwqAOkS6e4GCRJ5fC9iSVx9O.jpg',
      imdbId: 'tt9179430',
      overview:
          'A covert agent hunts a drug syndicate while old identities come back to life.',
      tags: ['movies', 'hindi-dubbed', 'action'],
    ),
    MediaItem(
      tmdbId: 1160956,
      title: 'Maharaja',
      mediaType: MediaType.movie,
      genre: 'Thriller',
      releaseYear: '2024',
      runtimeLabel: '2h 21m',
      voteAverage: 8.0,
      posterPath: '/8iMPQl13q89jQhaA5nXb6UiT0t0.jpg',
      backdropPath: '/8cc4AypHsnqcCQeIIpNoh6Wrc5B.jpg',
      imdbId: 'tt26548265',
      overview:
          'A quiet barber reports a strange theft and pulls police into a darker story.',
      tags: ['movies', 'top-hindi', 'thriller', 'new'],
    ),
    MediaItem(
      tmdbId: 1112419,
      title: 'Stree 2',
      mediaType: MediaType.movie,
      genre: 'Comedy',
      releaseYear: '2024',
      runtimeLabel: '2h 27m',
      voteAverage: 7.2,
      posterPath: '/oSz7OAthkTCCDNXttsmP7g3dAhf.jpg',
      imdbId: 'tt27510174',
      overview:
          'A haunted town faces a new terror as familiar friends reunite for the fight.',
      tags: ['movies', 'top-hindi', 'comedy', 'new'],
    ),
  ];
}
