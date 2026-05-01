import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/media_item.dart';

class SupabaseSyncDataSource {
  SupabaseSyncDataSource({required this.enabled});

  final bool enabled;

  SupabaseClient? get _client {
    if (!enabled) return null;
    return Supabase.instance.client;
  }

  Future<void> upsertWatchlist(MediaItem item, String userId) async {
    final client = _client;
    if (client == null) return;
    await _ensureProfile(userId: userId);

    await client.from('watchlist').upsert({
      'user_id': userId,
      'tmdb_id': item.tmdbId,
      'media_type': item.mediaType.name,
      'title': item.title,
      'poster_path': item.posterPath,
      'backdrop_path': item.backdropPath,
    });
  }

  Future<void> deleteWatchlist({
    required int tmdbId,
    required String mediaType,
    required String userId,
  }) async {
    final client = _client;
    if (client == null) return;

    await client
        .from('watchlist')
        .delete()
        .eq('user_id', userId)
        .eq('tmdb_id', tmdbId)
        .eq('media_type', mediaType);
  }

  Future<List<Map<String, dynamic>>> watchlistFor(String userId) async {
    final client = _client;
    if (client == null) return const [];

    final rows = await client
        .from('watchlist')
        .select()
        .eq('user_id', userId)
        .order('added_at', ascending: false);
    return rows.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> upsertFavorite(MediaItem item, String userId) async {
    final client = _client;
    if (client == null) return;
    await _ensureProfile(userId: userId);

    await client.from('favorites').upsert({
      'user_id': userId,
      'tmdb_id': item.tmdbId,
      'media_type': item.mediaType.name,
      'title': item.title,
      'poster_path': item.posterPath,
      'backdrop_path': item.backdropPath,
    });
  }

  Future<void> upsertContinueWatching({
    required int tmdbId,
    required String mediaType,
    required String title,
    required int positionSeconds,
    required int durationSeconds,
    String? posterPath,
    int? seasonNumber,
    int? episodeNumber,
    String? episodeTitle,
    String? preferredSubtitleLang,
    String? preferredAudioLang,
    String? backdropPath,
  }) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    await _ensureProfile(userId: userId);

    await client.from('continue_watching').upsert({
      'user_id': userId,
      'tmdb_id': tmdbId,
      'media_type': mediaType,
      'title': title,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'season_number': seasonNumber,
      'episode_number': episodeNumber,
      'episode_title': episodeTitle,
      'position_seconds': positionSeconds,
      'duration_seconds': durationSeconds,
      'preferred_subtitle_lang': preferredSubtitleLang,
      'preferred_audio_lang': preferredAudioLang,
      'last_watched_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> continueWatchingFor(String userId) async {
    final client = _client;
    if (client == null) return const [];

    final rows = await client
        .from('continue_watching')
        .select()
        .eq('user_id', userId)
        .order('last_watched_at', ascending: false)
        .limit(40);
    return rows.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>?> currentProfile() async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return null;

    await _ensureProfile(userId: userId);
    final rows = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .limit(1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> upsertProfilePreferences({
    String? preferredSubtitleLang,
    String? preferredAudioLang,
  }) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;

    final displayName = _displayNameFor(user);
    final values = <String, dynamic>{
      'id': user.id,
      'display_name': displayName,
    };
    if (preferredSubtitleLang != null) {
      values['preferred_subtitle_lang'] = preferredSubtitleLang;
    }
    if (preferredAudioLang != null) {
      values['preferred_audio_lang'] = preferredAudioLang;
    }
    await client.from('profiles').upsert(values);
  }

  Future<bool> startAnonymousSession() async {
    final client = _client;
    if (client == null) return false;
    if (client.auth.currentUser == null) {
      await client.auth.signInAnonymously();
    }
    if (client.auth.currentUser != null) {
      await _ensureProfile(userId: client.auth.currentUser!.id);
    }
    return client.auth.currentUser != null;
  }

  Future<bool> startHouseholdSession({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) return false;
    final normalizedEmail = email.trim().toLowerCase();
    final current = client.auth.currentUser;
    if (current != null &&
        (current.email ?? '').toLowerCase() == normalizedEmail) {
      await _ensureProfile(userId: current.id);
      return true;
    }
    if (current != null) {
      await client.auth.signOut();
    }

    try {
      await client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
    } on AuthException {
      final response = await client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: const {'display_name': 'StreamVault Family'},
      );
      if (response.session == null && client.auth.currentUser == null) {
        throw const AuthException(
          'Household account created. Confirm the email in Supabase, then sign in again.',
        );
      }
    }
    if (client.auth.currentUser != null) {
      await _ensureProfile(userId: client.auth.currentUser!.id);
    }
    return client.auth.currentUser != null;
  }

  bool get hasSession => _client?.auth.currentUser != null;

  String? get currentUserId => _client?.auth.currentUser?.id;

  Future<void> _ensureProfile({String? userId}) async {
    final client = _client;
    final user = client?.auth.currentUser;
    final id = userId ?? user?.id;
    if (client == null || id == null) return;

    await client.from('profiles').upsert({
      'id': id,
      'display_name': user == null
          ? 'StreamVault Family'
          : _displayNameFor(user),
    });
  }

  String _displayNameFor(User user) {
    final metadataName = user.userMetadata?['display_name'] as String?;
    if (metadataName != null && metadataName.trim().isNotEmpty) {
      return metadataName.trim();
    }
    final email = user.email ?? '';
    if (email.contains('@')) return email.split('@').first;
    return 'StreamVault Family';
  }
}
