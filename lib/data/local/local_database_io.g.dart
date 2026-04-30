// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database_io.dart';

// ignore_for_file: type=lint
class $CachedMediaItemsTable extends CachedMediaItems
    with TableInfo<$CachedMediaItemsTable, CachedMediaItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMediaItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
    'tmdb_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _releaseYearMeta = const VerificationMeta(
    'releaseYear',
  );
  @override
  late final GeneratedColumn<String> releaseYear = GeneratedColumn<String>(
    'release_year',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta(
    'overview',
  );
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _voteAverageMeta = const VerificationMeta(
    'voteAverage',
  );
  @override
  late final GeneratedColumn<double> voteAverage = GeneratedColumn<double>(
    'vote_average',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _posterPathMeta = const VerificationMeta(
    'posterPath',
  );
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
    'poster_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backdropPathMeta = const VerificationMeta(
    'backdropPath',
  );
  @override
  late final GeneratedColumn<String> backdropPath = GeneratedColumn<String>(
    'backdrop_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tmdbId,
    mediaType,
    title,
    genre,
    releaseYear,
    overview,
    voteAverage,
    posterPath,
    backdropPath,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_media_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedMediaItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tmdb_id')) {
      context.handle(
        _tmdbIdMeta,
        tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tmdbIdMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('release_year')) {
      context.handle(
        _releaseYearMeta,
        releaseYear.isAcceptableOrUnknown(
          data['release_year']!,
          _releaseYearMeta,
        ),
      );
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
      );
    }
    if (data.containsKey('vote_average')) {
      context.handle(
        _voteAverageMeta,
        voteAverage.isAcceptableOrUnknown(
          data['vote_average']!,
          _voteAverageMeta,
        ),
      );
    }
    if (data.containsKey('poster_path')) {
      context.handle(
        _posterPathMeta,
        posterPath.isAcceptableOrUnknown(data['poster_path']!, _posterPathMeta),
      );
    }
    if (data.containsKey('backdrop_path')) {
      context.handle(
        _backdropPathMeta,
        backdropPath.isAcceptableOrUnknown(
          data['backdrop_path']!,
          _backdropPathMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tmdbId, mediaType};
  @override
  CachedMediaItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMediaItem(
      tmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tmdb_id'],
      )!,
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      )!,
      releaseYear: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}release_year'],
      )!,
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      )!,
      voteAverage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vote_average'],
      )!,
      posterPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_path'],
      ),
      backdropPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backdrop_path'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedMediaItemsTable createAlias(String alias) {
    return $CachedMediaItemsTable(attachedDatabase, alias);
  }
}

class CachedMediaItem extends DataClass implements Insertable<CachedMediaItem> {
  final int tmdbId;
  final String mediaType;
  final String title;
  final String genre;
  final String releaseYear;
  final String overview;
  final double voteAverage;
  final String? posterPath;
  final String? backdropPath;
  final DateTime cachedAt;
  const CachedMediaItem({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    required this.genre,
    required this.releaseYear,
    required this.overview,
    required this.voteAverage,
    this.posterPath,
    this.backdropPath,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tmdb_id'] = Variable<int>(tmdbId);
    map['media_type'] = Variable<String>(mediaType);
    map['title'] = Variable<String>(title);
    map['genre'] = Variable<String>(genre);
    map['release_year'] = Variable<String>(releaseYear);
    map['overview'] = Variable<String>(overview);
    map['vote_average'] = Variable<double>(voteAverage);
    if (!nullToAbsent || posterPath != null) {
      map['poster_path'] = Variable<String>(posterPath);
    }
    if (!nullToAbsent || backdropPath != null) {
      map['backdrop_path'] = Variable<String>(backdropPath);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedMediaItemsCompanion toCompanion(bool nullToAbsent) {
    return CachedMediaItemsCompanion(
      tmdbId: Value(tmdbId),
      mediaType: Value(mediaType),
      title: Value(title),
      genre: Value(genre),
      releaseYear: Value(releaseYear),
      overview: Value(overview),
      voteAverage: Value(voteAverage),
      posterPath: posterPath == null && nullToAbsent
          ? const Value.absent()
          : Value(posterPath),
      backdropPath: backdropPath == null && nullToAbsent
          ? const Value.absent()
          : Value(backdropPath),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedMediaItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMediaItem(
      tmdbId: serializer.fromJson<int>(json['tmdbId']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      title: serializer.fromJson<String>(json['title']),
      genre: serializer.fromJson<String>(json['genre']),
      releaseYear: serializer.fromJson<String>(json['releaseYear']),
      overview: serializer.fromJson<String>(json['overview']),
      voteAverage: serializer.fromJson<double>(json['voteAverage']),
      posterPath: serializer.fromJson<String?>(json['posterPath']),
      backdropPath: serializer.fromJson<String?>(json['backdropPath']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tmdbId': serializer.toJson<int>(tmdbId),
      'mediaType': serializer.toJson<String>(mediaType),
      'title': serializer.toJson<String>(title),
      'genre': serializer.toJson<String>(genre),
      'releaseYear': serializer.toJson<String>(releaseYear),
      'overview': serializer.toJson<String>(overview),
      'voteAverage': serializer.toJson<double>(voteAverage),
      'posterPath': serializer.toJson<String?>(posterPath),
      'backdropPath': serializer.toJson<String?>(backdropPath),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedMediaItem copyWith({
    int? tmdbId,
    String? mediaType,
    String? title,
    String? genre,
    String? releaseYear,
    String? overview,
    double? voteAverage,
    Value<String?> posterPath = const Value.absent(),
    Value<String?> backdropPath = const Value.absent(),
    DateTime? cachedAt,
  }) => CachedMediaItem(
    tmdbId: tmdbId ?? this.tmdbId,
    mediaType: mediaType ?? this.mediaType,
    title: title ?? this.title,
    genre: genre ?? this.genre,
    releaseYear: releaseYear ?? this.releaseYear,
    overview: overview ?? this.overview,
    voteAverage: voteAverage ?? this.voteAverage,
    posterPath: posterPath.present ? posterPath.value : this.posterPath,
    backdropPath: backdropPath.present ? backdropPath.value : this.backdropPath,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedMediaItem copyWithCompanion(CachedMediaItemsCompanion data) {
    return CachedMediaItem(
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      title: data.title.present ? data.title.value : this.title,
      genre: data.genre.present ? data.genre.value : this.genre,
      releaseYear: data.releaseYear.present
          ? data.releaseYear.value
          : this.releaseYear,
      overview: data.overview.present ? data.overview.value : this.overview,
      voteAverage: data.voteAverage.present
          ? data.voteAverage.value
          : this.voteAverage,
      posterPath: data.posterPath.present
          ? data.posterPath.value
          : this.posterPath,
      backdropPath: data.backdropPath.present
          ? data.backdropPath.value
          : this.backdropPath,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMediaItem(')
          ..write('tmdbId: $tmdbId, ')
          ..write('mediaType: $mediaType, ')
          ..write('title: $title, ')
          ..write('genre: $genre, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('overview: $overview, ')
          ..write('voteAverage: $voteAverage, ')
          ..write('posterPath: $posterPath, ')
          ..write('backdropPath: $backdropPath, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tmdbId,
    mediaType,
    title,
    genre,
    releaseYear,
    overview,
    voteAverage,
    posterPath,
    backdropPath,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMediaItem &&
          other.tmdbId == this.tmdbId &&
          other.mediaType == this.mediaType &&
          other.title == this.title &&
          other.genre == this.genre &&
          other.releaseYear == this.releaseYear &&
          other.overview == this.overview &&
          other.voteAverage == this.voteAverage &&
          other.posterPath == this.posterPath &&
          other.backdropPath == this.backdropPath &&
          other.cachedAt == this.cachedAt);
}

class CachedMediaItemsCompanion extends UpdateCompanion<CachedMediaItem> {
  final Value<int> tmdbId;
  final Value<String> mediaType;
  final Value<String> title;
  final Value<String> genre;
  final Value<String> releaseYear;
  final Value<String> overview;
  final Value<double> voteAverage;
  final Value<String?> posterPath;
  final Value<String?> backdropPath;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedMediaItemsCompanion({
    this.tmdbId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.title = const Value.absent(),
    this.genre = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.overview = const Value.absent(),
    this.voteAverage = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.backdropPath = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedMediaItemsCompanion.insert({
    required int tmdbId,
    required String mediaType,
    required String title,
    this.genre = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.overview = const Value.absent(),
    this.voteAverage = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.backdropPath = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tmdbId = Value(tmdbId),
       mediaType = Value(mediaType),
       title = Value(title);
  static Insertable<CachedMediaItem> custom({
    Expression<int>? tmdbId,
    Expression<String>? mediaType,
    Expression<String>? title,
    Expression<String>? genre,
    Expression<String>? releaseYear,
    Expression<String>? overview,
    Expression<double>? voteAverage,
    Expression<String>? posterPath,
    Expression<String>? backdropPath,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (mediaType != null) 'media_type': mediaType,
      if (title != null) 'title': title,
      if (genre != null) 'genre': genre,
      if (releaseYear != null) 'release_year': releaseYear,
      if (overview != null) 'overview': overview,
      if (voteAverage != null) 'vote_average': voteAverage,
      if (posterPath != null) 'poster_path': posterPath,
      if (backdropPath != null) 'backdrop_path': backdropPath,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedMediaItemsCompanion copyWith({
    Value<int>? tmdbId,
    Value<String>? mediaType,
    Value<String>? title,
    Value<String>? genre,
    Value<String>? releaseYear,
    Value<String>? overview,
    Value<double>? voteAverage,
    Value<String?>? posterPath,
    Value<String?>? backdropPath,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedMediaItemsCompanion(
      tmdbId: tmdbId ?? this.tmdbId,
      mediaType: mediaType ?? this.mediaType,
      title: title ?? this.title,
      genre: genre ?? this.genre,
      releaseYear: releaseYear ?? this.releaseYear,
      overview: overview ?? this.overview,
      voteAverage: voteAverage ?? this.voteAverage,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (releaseYear.present) {
      map['release_year'] = Variable<String>(releaseYear.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (voteAverage.present) {
      map['vote_average'] = Variable<double>(voteAverage.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (backdropPath.present) {
      map['backdrop_path'] = Variable<String>(backdropPath.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMediaItemsCompanion(')
          ..write('tmdbId: $tmdbId, ')
          ..write('mediaType: $mediaType, ')
          ..write('title: $title, ')
          ..write('genre: $genre, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('overview: $overview, ')
          ..write('voteAverage: $voteAverage, ')
          ..write('posterPath: $posterPath, ')
          ..write('backdropPath: $backdropPath, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPlaybackEntriesTable extends LocalPlaybackEntries
    with TableInfo<$LocalPlaybackEntriesTable, LocalPlaybackEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPlaybackEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
    'tmdb_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seasonNumberMeta = const VerificationMeta(
    'seasonNumber',
  );
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
    'season_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _episodeNumberMeta = const VerificationMeta(
    'episodeNumber',
  );
  @override
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
    'episode_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionSecondsMeta = const VerificationMeta(
    'positionSeconds',
  );
  @override
  late final GeneratedColumn<int> positionSeconds = GeneratedColumn<int>(
    'position_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _preferredSubtitleLangMeta =
      const VerificationMeta('preferredSubtitleLang');
  @override
  late final GeneratedColumn<String> preferredSubtitleLang =
      GeneratedColumn<String>(
        'preferred_subtitle_lang',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _preferredAudioLangMeta =
      const VerificationMeta('preferredAudioLang');
  @override
  late final GeneratedColumn<String> preferredAudioLang =
      GeneratedColumn<String>(
        'preferred_audio_lang',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tmdbId,
    mediaType,
    seasonNumber,
    episodeNumber,
    positionSeconds,
    durationSeconds,
    preferredSubtitleLang,
    preferredAudioLang,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_playback_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPlaybackEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tmdb_id')) {
      context.handle(
        _tmdbIdMeta,
        tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tmdbIdMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(
        _seasonNumberMeta,
        seasonNumber.isAcceptableOrUnknown(
          data['season_number']!,
          _seasonNumberMeta,
        ),
      );
    }
    if (data.containsKey('episode_number')) {
      context.handle(
        _episodeNumberMeta,
        episodeNumber.isAcceptableOrUnknown(
          data['episode_number']!,
          _episodeNumberMeta,
        ),
      );
    }
    if (data.containsKey('position_seconds')) {
      context.handle(
        _positionSecondsMeta,
        positionSeconds.isAcceptableOrUnknown(
          data['position_seconds']!,
          _positionSecondsMeta,
        ),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('preferred_subtitle_lang')) {
      context.handle(
        _preferredSubtitleLangMeta,
        preferredSubtitleLang.isAcceptableOrUnknown(
          data['preferred_subtitle_lang']!,
          _preferredSubtitleLangMeta,
        ),
      );
    }
    if (data.containsKey('preferred_audio_lang')) {
      context.handle(
        _preferredAudioLangMeta,
        preferredAudioLang.isAcceptableOrUnknown(
          data['preferred_audio_lang']!,
          _preferredAudioLangMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPlaybackEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPlaybackEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tmdb_id'],
      )!,
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      seasonNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season_number'],
      ),
      episodeNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_number'],
      ),
      positionSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_seconds'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      preferredSubtitleLang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_subtitle_lang'],
      ),
      preferredAudioLang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_audio_lang'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalPlaybackEntriesTable createAlias(String alias) {
    return $LocalPlaybackEntriesTable(attachedDatabase, alias);
  }
}

class LocalPlaybackEntry extends DataClass
    implements Insertable<LocalPlaybackEntry> {
  final int id;
  final int tmdbId;
  final String mediaType;
  final int? seasonNumber;
  final int? episodeNumber;
  final int positionSeconds;
  final int durationSeconds;
  final String? preferredSubtitleLang;
  final String? preferredAudioLang;
  final DateTime updatedAt;
  const LocalPlaybackEntry({
    required this.id,
    required this.tmdbId,
    required this.mediaType,
    this.seasonNumber,
    this.episodeNumber,
    required this.positionSeconds,
    required this.durationSeconds,
    this.preferredSubtitleLang,
    this.preferredAudioLang,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tmdb_id'] = Variable<int>(tmdbId);
    map['media_type'] = Variable<String>(mediaType);
    if (!nullToAbsent || seasonNumber != null) {
      map['season_number'] = Variable<int>(seasonNumber);
    }
    if (!nullToAbsent || episodeNumber != null) {
      map['episode_number'] = Variable<int>(episodeNumber);
    }
    map['position_seconds'] = Variable<int>(positionSeconds);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    if (!nullToAbsent || preferredSubtitleLang != null) {
      map['preferred_subtitle_lang'] = Variable<String>(preferredSubtitleLang);
    }
    if (!nullToAbsent || preferredAudioLang != null) {
      map['preferred_audio_lang'] = Variable<String>(preferredAudioLang);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalPlaybackEntriesCompanion toCompanion(bool nullToAbsent) {
    return LocalPlaybackEntriesCompanion(
      id: Value(id),
      tmdbId: Value(tmdbId),
      mediaType: Value(mediaType),
      seasonNumber: seasonNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(seasonNumber),
      episodeNumber: episodeNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(episodeNumber),
      positionSeconds: Value(positionSeconds),
      durationSeconds: Value(durationSeconds),
      preferredSubtitleLang: preferredSubtitleLang == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredSubtitleLang),
      preferredAudioLang: preferredAudioLang == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredAudioLang),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalPlaybackEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPlaybackEntry(
      id: serializer.fromJson<int>(json['id']),
      tmdbId: serializer.fromJson<int>(json['tmdbId']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      seasonNumber: serializer.fromJson<int?>(json['seasonNumber']),
      episodeNumber: serializer.fromJson<int?>(json['episodeNumber']),
      positionSeconds: serializer.fromJson<int>(json['positionSeconds']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      preferredSubtitleLang: serializer.fromJson<String?>(
        json['preferredSubtitleLang'],
      ),
      preferredAudioLang: serializer.fromJson<String?>(
        json['preferredAudioLang'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tmdbId': serializer.toJson<int>(tmdbId),
      'mediaType': serializer.toJson<String>(mediaType),
      'seasonNumber': serializer.toJson<int?>(seasonNumber),
      'episodeNumber': serializer.toJson<int?>(episodeNumber),
      'positionSeconds': serializer.toJson<int>(positionSeconds),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'preferredSubtitleLang': serializer.toJson<String?>(
        preferredSubtitleLang,
      ),
      'preferredAudioLang': serializer.toJson<String?>(preferredAudioLang),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalPlaybackEntry copyWith({
    int? id,
    int? tmdbId,
    String? mediaType,
    Value<int?> seasonNumber = const Value.absent(),
    Value<int?> episodeNumber = const Value.absent(),
    int? positionSeconds,
    int? durationSeconds,
    Value<String?> preferredSubtitleLang = const Value.absent(),
    Value<String?> preferredAudioLang = const Value.absent(),
    DateTime? updatedAt,
  }) => LocalPlaybackEntry(
    id: id ?? this.id,
    tmdbId: tmdbId ?? this.tmdbId,
    mediaType: mediaType ?? this.mediaType,
    seasonNumber: seasonNumber.present ? seasonNumber.value : this.seasonNumber,
    episodeNumber: episodeNumber.present
        ? episodeNumber.value
        : this.episodeNumber,
    positionSeconds: positionSeconds ?? this.positionSeconds,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    preferredSubtitleLang: preferredSubtitleLang.present
        ? preferredSubtitleLang.value
        : this.preferredSubtitleLang,
    preferredAudioLang: preferredAudioLang.present
        ? preferredAudioLang.value
        : this.preferredAudioLang,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalPlaybackEntry copyWithCompanion(LocalPlaybackEntriesCompanion data) {
    return LocalPlaybackEntry(
      id: data.id.present ? data.id.value : this.id,
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      episodeNumber: data.episodeNumber.present
          ? data.episodeNumber.value
          : this.episodeNumber,
      positionSeconds: data.positionSeconds.present
          ? data.positionSeconds.value
          : this.positionSeconds,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      preferredSubtitleLang: data.preferredSubtitleLang.present
          ? data.preferredSubtitleLang.value
          : this.preferredSubtitleLang,
      preferredAudioLang: data.preferredAudioLang.present
          ? data.preferredAudioLang.value
          : this.preferredAudioLang,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaybackEntry(')
          ..write('id: $id, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('mediaType: $mediaType, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('positionSeconds: $positionSeconds, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('preferredSubtitleLang: $preferredSubtitleLang, ')
          ..write('preferredAudioLang: $preferredAudioLang, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tmdbId,
    mediaType,
    seasonNumber,
    episodeNumber,
    positionSeconds,
    durationSeconds,
    preferredSubtitleLang,
    preferredAudioLang,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPlaybackEntry &&
          other.id == this.id &&
          other.tmdbId == this.tmdbId &&
          other.mediaType == this.mediaType &&
          other.seasonNumber == this.seasonNumber &&
          other.episodeNumber == this.episodeNumber &&
          other.positionSeconds == this.positionSeconds &&
          other.durationSeconds == this.durationSeconds &&
          other.preferredSubtitleLang == this.preferredSubtitleLang &&
          other.preferredAudioLang == this.preferredAudioLang &&
          other.updatedAt == this.updatedAt);
}

class LocalPlaybackEntriesCompanion
    extends UpdateCompanion<LocalPlaybackEntry> {
  final Value<int> id;
  final Value<int> tmdbId;
  final Value<String> mediaType;
  final Value<int?> seasonNumber;
  final Value<int?> episodeNumber;
  final Value<int> positionSeconds;
  final Value<int> durationSeconds;
  final Value<String?> preferredSubtitleLang;
  final Value<String?> preferredAudioLang;
  final Value<DateTime> updatedAt;
  const LocalPlaybackEntriesCompanion({
    this.id = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.positionSeconds = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.preferredSubtitleLang = const Value.absent(),
    this.preferredAudioLang = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalPlaybackEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int tmdbId,
    required String mediaType,
    this.seasonNumber = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.positionSeconds = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.preferredSubtitleLang = const Value.absent(),
    this.preferredAudioLang = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : tmdbId = Value(tmdbId),
       mediaType = Value(mediaType);
  static Insertable<LocalPlaybackEntry> custom({
    Expression<int>? id,
    Expression<int>? tmdbId,
    Expression<String>? mediaType,
    Expression<int>? seasonNumber,
    Expression<int>? episodeNumber,
    Expression<int>? positionSeconds,
    Expression<int>? durationSeconds,
    Expression<String>? preferredSubtitleLang,
    Expression<String>? preferredAudioLang,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (mediaType != null) 'media_type': mediaType,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (positionSeconds != null) 'position_seconds': positionSeconds,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (preferredSubtitleLang != null)
        'preferred_subtitle_lang': preferredSubtitleLang,
      if (preferredAudioLang != null)
        'preferred_audio_lang': preferredAudioLang,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalPlaybackEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? tmdbId,
    Value<String>? mediaType,
    Value<int?>? seasonNumber,
    Value<int?>? episodeNumber,
    Value<int>? positionSeconds,
    Value<int>? durationSeconds,
    Value<String?>? preferredSubtitleLang,
    Value<String?>? preferredAudioLang,
    Value<DateTime>? updatedAt,
  }) {
    return LocalPlaybackEntriesCompanion(
      id: id ?? this.id,
      tmdbId: tmdbId ?? this.tmdbId,
      mediaType: mediaType ?? this.mediaType,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      preferredSubtitleLang:
          preferredSubtitleLang ?? this.preferredSubtitleLang,
      preferredAudioLang: preferredAudioLang ?? this.preferredAudioLang,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (episodeNumber.present) {
      map['episode_number'] = Variable<int>(episodeNumber.value);
    }
    if (positionSeconds.present) {
      map['position_seconds'] = Variable<int>(positionSeconds.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (preferredSubtitleLang.present) {
      map['preferred_subtitle_lang'] = Variable<String>(
        preferredSubtitleLang.value,
      );
    }
    if (preferredAudioLang.present) {
      map['preferred_audio_lang'] = Variable<String>(preferredAudioLang.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaybackEntriesCompanion(')
          ..write('id: $id, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('mediaType: $mediaType, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('positionSeconds: $positionSeconds, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('preferredSubtitleLang: $preferredSubtitleLang, ')
          ..write('preferredAudioLang: $preferredAudioLang, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$StreamVaultDatabase extends GeneratedDatabase {
  _$StreamVaultDatabase(QueryExecutor e) : super(e);
  $StreamVaultDatabaseManager get managers => $StreamVaultDatabaseManager(this);
  late final $CachedMediaItemsTable cachedMediaItems = $CachedMediaItemsTable(
    this,
  );
  late final $LocalPlaybackEntriesTable localPlaybackEntries =
      $LocalPlaybackEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedMediaItems,
    localPlaybackEntries,
  ];
}

typedef $$CachedMediaItemsTableCreateCompanionBuilder =
    CachedMediaItemsCompanion Function({
      required int tmdbId,
      required String mediaType,
      required String title,
      Value<String> genre,
      Value<String> releaseYear,
      Value<String> overview,
      Value<double> voteAverage,
      Value<String?> posterPath,
      Value<String?> backdropPath,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$CachedMediaItemsTableUpdateCompanionBuilder =
    CachedMediaItemsCompanion Function({
      Value<int> tmdbId,
      Value<String> mediaType,
      Value<String> title,
      Value<String> genre,
      Value<String> releaseYear,
      Value<String> overview,
      Value<double> voteAverage,
      Value<String?> posterPath,
      Value<String?> backdropPath,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedMediaItemsTableFilterComposer
    extends Composer<_$StreamVaultDatabase, $CachedMediaItemsTable> {
  $$CachedMediaItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get voteAverage => $composableBuilder(
    column: $table.voteAverage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedMediaItemsTableOrderingComposer
    extends Composer<_$StreamVaultDatabase, $CachedMediaItemsTable> {
  $$CachedMediaItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get voteAverage => $composableBuilder(
    column: $table.voteAverage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedMediaItemsTableAnnotationComposer
    extends Composer<_$StreamVaultDatabase, $CachedMediaItemsTable> {
  $$CachedMediaItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<String> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<double> get voteAverage => $composableBuilder(
    column: $table.voteAverage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedMediaItemsTableTableManager
    extends
        RootTableManager<
          _$StreamVaultDatabase,
          $CachedMediaItemsTable,
          CachedMediaItem,
          $$CachedMediaItemsTableFilterComposer,
          $$CachedMediaItemsTableOrderingComposer,
          $$CachedMediaItemsTableAnnotationComposer,
          $$CachedMediaItemsTableCreateCompanionBuilder,
          $$CachedMediaItemsTableUpdateCompanionBuilder,
          (
            CachedMediaItem,
            BaseReferences<
              _$StreamVaultDatabase,
              $CachedMediaItemsTable,
              CachedMediaItem
            >,
          ),
          CachedMediaItem,
          PrefetchHooks Function()
        > {
  $$CachedMediaItemsTableTableManager(
    _$StreamVaultDatabase db,
    $CachedMediaItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedMediaItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedMediaItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedMediaItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> tmdbId = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> genre = const Value.absent(),
                Value<String> releaseYear = const Value.absent(),
                Value<String> overview = const Value.absent(),
                Value<double> voteAverage = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String?> backdropPath = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMediaItemsCompanion(
                tmdbId: tmdbId,
                mediaType: mediaType,
                title: title,
                genre: genre,
                releaseYear: releaseYear,
                overview: overview,
                voteAverage: voteAverage,
                posterPath: posterPath,
                backdropPath: backdropPath,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int tmdbId,
                required String mediaType,
                required String title,
                Value<String> genre = const Value.absent(),
                Value<String> releaseYear = const Value.absent(),
                Value<String> overview = const Value.absent(),
                Value<double> voteAverage = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String?> backdropPath = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMediaItemsCompanion.insert(
                tmdbId: tmdbId,
                mediaType: mediaType,
                title: title,
                genre: genre,
                releaseYear: releaseYear,
                overview: overview,
                voteAverage: voteAverage,
                posterPath: posterPath,
                backdropPath: backdropPath,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedMediaItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$StreamVaultDatabase,
      $CachedMediaItemsTable,
      CachedMediaItem,
      $$CachedMediaItemsTableFilterComposer,
      $$CachedMediaItemsTableOrderingComposer,
      $$CachedMediaItemsTableAnnotationComposer,
      $$CachedMediaItemsTableCreateCompanionBuilder,
      $$CachedMediaItemsTableUpdateCompanionBuilder,
      (
        CachedMediaItem,
        BaseReferences<
          _$StreamVaultDatabase,
          $CachedMediaItemsTable,
          CachedMediaItem
        >,
      ),
      CachedMediaItem,
      PrefetchHooks Function()
    >;
typedef $$LocalPlaybackEntriesTableCreateCompanionBuilder =
    LocalPlaybackEntriesCompanion Function({
      Value<int> id,
      required int tmdbId,
      required String mediaType,
      Value<int?> seasonNumber,
      Value<int?> episodeNumber,
      Value<int> positionSeconds,
      Value<int> durationSeconds,
      Value<String?> preferredSubtitleLang,
      Value<String?> preferredAudioLang,
      Value<DateTime> updatedAt,
    });
typedef $$LocalPlaybackEntriesTableUpdateCompanionBuilder =
    LocalPlaybackEntriesCompanion Function({
      Value<int> id,
      Value<int> tmdbId,
      Value<String> mediaType,
      Value<int?> seasonNumber,
      Value<int?> episodeNumber,
      Value<int> positionSeconds,
      Value<int> durationSeconds,
      Value<String?> preferredSubtitleLang,
      Value<String?> preferredAudioLang,
      Value<DateTime> updatedAt,
    });

class $$LocalPlaybackEntriesTableFilterComposer
    extends Composer<_$StreamVaultDatabase, $LocalPlaybackEntriesTable> {
  $$LocalPlaybackEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionSeconds => $composableBuilder(
    column: $table.positionSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredSubtitleLang => $composableBuilder(
    column: $table.preferredSubtitleLang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredAudioLang => $composableBuilder(
    column: $table.preferredAudioLang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalPlaybackEntriesTableOrderingComposer
    extends Composer<_$StreamVaultDatabase, $LocalPlaybackEntriesTable> {
  $$LocalPlaybackEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionSeconds => $composableBuilder(
    column: $table.positionSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredSubtitleLang => $composableBuilder(
    column: $table.preferredSubtitleLang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredAudioLang => $composableBuilder(
    column: $table.preferredAudioLang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalPlaybackEntriesTableAnnotationComposer
    extends Composer<_$StreamVaultDatabase, $LocalPlaybackEntriesTable> {
  $$LocalPlaybackEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get positionSeconds => $composableBuilder(
    column: $table.positionSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredSubtitleLang => $composableBuilder(
    column: $table.preferredSubtitleLang,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredAudioLang => $composableBuilder(
    column: $table.preferredAudioLang,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalPlaybackEntriesTableTableManager
    extends
        RootTableManager<
          _$StreamVaultDatabase,
          $LocalPlaybackEntriesTable,
          LocalPlaybackEntry,
          $$LocalPlaybackEntriesTableFilterComposer,
          $$LocalPlaybackEntriesTableOrderingComposer,
          $$LocalPlaybackEntriesTableAnnotationComposer,
          $$LocalPlaybackEntriesTableCreateCompanionBuilder,
          $$LocalPlaybackEntriesTableUpdateCompanionBuilder,
          (
            LocalPlaybackEntry,
            BaseReferences<
              _$StreamVaultDatabase,
              $LocalPlaybackEntriesTable,
              LocalPlaybackEntry
            >,
          ),
          LocalPlaybackEntry,
          PrefetchHooks Function()
        > {
  $$LocalPlaybackEntriesTableTableManager(
    _$StreamVaultDatabase db,
    $LocalPlaybackEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPlaybackEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPlaybackEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalPlaybackEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> tmdbId = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<int?> seasonNumber = const Value.absent(),
                Value<int?> episodeNumber = const Value.absent(),
                Value<int> positionSeconds = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<String?> preferredSubtitleLang = const Value.absent(),
                Value<String?> preferredAudioLang = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalPlaybackEntriesCompanion(
                id: id,
                tmdbId: tmdbId,
                mediaType: mediaType,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                positionSeconds: positionSeconds,
                durationSeconds: durationSeconds,
                preferredSubtitleLang: preferredSubtitleLang,
                preferredAudioLang: preferredAudioLang,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int tmdbId,
                required String mediaType,
                Value<int?> seasonNumber = const Value.absent(),
                Value<int?> episodeNumber = const Value.absent(),
                Value<int> positionSeconds = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<String?> preferredSubtitleLang = const Value.absent(),
                Value<String?> preferredAudioLang = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalPlaybackEntriesCompanion.insert(
                id: id,
                tmdbId: tmdbId,
                mediaType: mediaType,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                positionSeconds: positionSeconds,
                durationSeconds: durationSeconds,
                preferredSubtitleLang: preferredSubtitleLang,
                preferredAudioLang: preferredAudioLang,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalPlaybackEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$StreamVaultDatabase,
      $LocalPlaybackEntriesTable,
      LocalPlaybackEntry,
      $$LocalPlaybackEntriesTableFilterComposer,
      $$LocalPlaybackEntriesTableOrderingComposer,
      $$LocalPlaybackEntriesTableAnnotationComposer,
      $$LocalPlaybackEntriesTableCreateCompanionBuilder,
      $$LocalPlaybackEntriesTableUpdateCompanionBuilder,
      (
        LocalPlaybackEntry,
        BaseReferences<
          _$StreamVaultDatabase,
          $LocalPlaybackEntriesTable,
          LocalPlaybackEntry
        >,
      ),
      LocalPlaybackEntry,
      PrefetchHooks Function()
    >;

class $StreamVaultDatabaseManager {
  final _$StreamVaultDatabase _db;
  $StreamVaultDatabaseManager(this._db);
  $$CachedMediaItemsTableTableManager get cachedMediaItems =>
      $$CachedMediaItemsTableTableManager(_db, _db.cachedMediaItems);
  $$LocalPlaybackEntriesTableTableManager get localPlaybackEntries =>
      $$LocalPlaybackEntriesTableTableManager(_db, _db.localPlaybackEntries);
}
