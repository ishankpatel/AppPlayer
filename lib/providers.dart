import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/datasources/cinemeta_remote.dart';
import 'data/datasources/espn_remote.dart';
import 'data/datasources/supabase_sync.dart';
import 'data/datasources/tmdb_remote.dart';
import 'data/datasources/torrentio_remote.dart';
import 'data/local/local_database.dart';
import 'data/repositories/media_repository.dart';
import 'data/repositories/sync_repository.dart';
import 'presentation/app.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 18),
      headers: {'Accept': 'application/json'},
    ),
  );
});

final databaseProvider = Provider<StreamVaultDatabase>((ref) {
  final db = StreamVaultDatabase();
  ref.onDispose(db.close);
  return db;
});

final tmdbRemoteProvider = Provider<TmdbRemoteDataSource>((ref) {
  return TmdbRemoteDataSource(ref.watch(dioProvider));
});

final cinemetaRemoteProvider = Provider<CinemetaRemoteDataSource>((ref) {
  return CinemetaRemoteDataSource(ref.watch(dioProvider));
});

final espnRemoteProvider = Provider<EspnRemoteDataSource>((ref) {
  return EspnRemoteDataSource(ref.watch(dioProvider));
});

final torrentioRemoteProvider = Provider<TorrentioRemoteDataSource>((ref) {
  return TorrentioRemoteDataSource(ref.watch(dioProvider));
});

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository(
    ref.watch(tmdbRemoteProvider),
    ref.watch(cinemetaRemoteProvider),
    ref.watch(databaseProvider),
  );
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(
    SupabaseSyncDataSource(enabled: ref.watch(supabaseConfiguredProvider)),
  );
});
