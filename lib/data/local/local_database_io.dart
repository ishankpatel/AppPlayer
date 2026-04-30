import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/playback_progress.dart';

part 'local_database_io.g.dart';

class CachedMediaItems extends Table {
  IntColumn get tmdbId => integer()();
  TextColumn get mediaType => text()();
  TextColumn get title => text()();
  TextColumn get genre => text().withDefault(const Constant(''))();
  TextColumn get releaseYear => text().withDefault(const Constant(''))();
  TextColumn get overview => text().withDefault(const Constant(''))();
  RealColumn get voteAverage => real().withDefault(const Constant(0))();
  TextColumn get posterPath => text().nullable()();
  TextColumn get backdropPath => text().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {tmdbId, mediaType};
}

class LocalPlaybackEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tmdbId => integer()();
  TextColumn get mediaType => text()();
  IntColumn get seasonNumber => integer().nullable()();
  IntColumn get episodeNumber => integer().nullable()();
  IntColumn get positionSeconds => integer().withDefault(const Constant(0))();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  TextColumn get preferredSubtitleLang => text().nullable()();
  TextColumn get preferredAudioLang => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [CachedMediaItems, LocalPlaybackEntries])
class StreamVaultDatabase extends _$StreamVaultDatabase {
  StreamVaultDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<void> upsertCachedMedia(List<CachedMediaItemsCompanion> items) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(cachedMediaItems, items);
    });
  }

  Future<List<CachedMediaItem>> getCachedMedia() {
    return (select(
      cachedMediaItems,
    )..orderBy([(table) => OrderingTerm.desc(table.cachedAt)])).get();
  }

  Future<void> savePlaybackProgress({
    required int tmdbId,
    required String mediaType,
    required int positionSeconds,
    required int durationSeconds,
    int? seasonNumber,
    int? episodeNumber,
    String? preferredSubtitleLang,
    String? preferredAudioLang,
  }) async {
    await (delete(localPlaybackEntries)..where(
          (entry) =>
              entry.tmdbId.equals(tmdbId) &
              entry.mediaType.equals(mediaType) &
              (seasonNumber == null
                  ? entry.seasonNumber.isNull()
                  : entry.seasonNumber.equals(seasonNumber)) &
              (episodeNumber == null
                  ? entry.episodeNumber.isNull()
                  : entry.episodeNumber.equals(episodeNumber)),
        ))
        .go();
    await into(localPlaybackEntries).insert(
      LocalPlaybackEntriesCompanion.insert(
        tmdbId: tmdbId,
        mediaType: mediaType,
        seasonNumber: Value(seasonNumber),
        episodeNumber: Value(episodeNumber),
        positionSeconds: Value(positionSeconds),
        durationSeconds: Value(durationSeconds),
        preferredSubtitleLang: Value(preferredSubtitleLang),
        preferredAudioLang: Value(preferredAudioLang),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<PlaybackProgress>> getRecentPlayback({int limit = 20}) async {
    final entries =
        await (select(localPlaybackEntries)
              ..where((entry) => entry.positionSeconds.isBiggerThanValue(0))
              ..orderBy([(entry) => OrderingTerm.desc(entry.updatedAt)])
              ..limit(limit))
            .get();

    return entries.map((entry) {
      return PlaybackProgress(
        tmdbId: entry.tmdbId,
        mediaType: entry.mediaType,
        positionSeconds: entry.positionSeconds,
        durationSeconds: entry.durationSeconds,
        updatedAt: entry.updatedAt,
        seasonNumber: entry.seasonNumber,
        episodeNumber: entry.episodeNumber,
      );
    }).toList();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    final file = File(path.join(directory.path, 'streamvault.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
