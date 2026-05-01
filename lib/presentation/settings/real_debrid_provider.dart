import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/real_debrid_remote.dart';
import '../../data/local/real_debrid_store.dart';
import '../../providers.dart';

class RealDebridSettings {
  const RealDebridSettings({
    this.apiKey = '',
    this.user,
    this.remainingTrafficBytes = 0,
    this.validating = false,
    this.error,
  });

  final String apiKey;
  final RealDebridUser? user;
  final int remainingTrafficBytes;
  final bool validating;
  final String? error;

  bool get hasKey => apiKey.isNotEmpty;
  bool get isValid => user != null && error == null;

  RealDebridSettings copyWith({
    String? apiKey,
    RealDebridUser? user,
    bool clearUser = false,
    int? remainingTrafficBytes,
    bool? validating,
    String? error,
    bool clearError = false,
  }) {
    return RealDebridSettings(
      apiKey: apiKey ?? this.apiKey,
      user: clearUser ? null : (user ?? this.user),
      remainingTrafficBytes:
          remainingTrafficBytes ?? this.remainingTrafficBytes,
      validating: validating ?? this.validating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final realDebridStoreProvider = Provider<RealDebridStore>((ref) {
  return RealDebridStore();
});

final realDebridRemoteProvider = Provider<RealDebridRemoteDataSource>((ref) {
  return RealDebridRemoteDataSource(ref.watch(dioProvider));
});

class RealDebridSettingsNotifier extends AsyncNotifier<RealDebridSettings> {
  RealDebridStore get _store => ref.read(realDebridStoreProvider);
  RealDebridRemoteDataSource get _remote => ref.read(realDebridRemoteProvider);

  @override
  Future<RealDebridSettings> build() async {
    ref.keepAlive();
    final stored = await _store.readApiKey();
    if (stored == null || stored.isEmpty) {
      return const RealDebridSettings();
    }
    // Validate silently on launch so the badge reflects reality.
    return _validate(stored, persist: false);
  }

  RealDebridSettings _current() {
    return state.maybeWhen(
      data: (value) => value,
      orElse: () => const RealDebridSettings(),
    );
  }

  Future<void> updateKey(String key) async {
    final trimmed = key.trim();
    state = AsyncValue.data(
      _current().copyWith(apiKey: trimmed, clearError: true),
    );
  }

  Future<bool> saveAndValidate(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await _store.writeApiKey(null);
      state = const AsyncValue.data(RealDebridSettings());
      return false;
    }
    state = AsyncValue.data(
      _current().copyWith(apiKey: trimmed, validating: true, clearError: true),
    );
    try {
      final next = await _validate(trimmed, persist: true);
      state = AsyncValue.data(next);
      return next.isValid;
    } catch (e) {
      state = AsyncValue.data(
        _current().copyWith(
          apiKey: trimmed,
          validating: false,
          error: e is RealDebridException ? e.message : e.toString(),
          clearUser: true,
        ),
      );
      return false;
    }
  }

  Future<void> clear() async {
    await _store.writeApiKey(null);
    state = const AsyncValue.data(RealDebridSettings());
  }

  Future<RealDebridSettings> _validate(
    String key, {
    required bool persist,
  }) async {
    try {
      final user = await _remote.me(key);
      final traffic = await _remote
          .remainingTrafficBytes(key)
          .catchError((_) => 0);
      if (persist) await _store.writeApiKey(key);
      return RealDebridSettings(
        apiKey: key,
        user: user,
        remainingTrafficBytes: traffic,
        validating: false,
      );
    } on RealDebridException catch (e) {
      return RealDebridSettings(
        apiKey: key,
        validating: false,
        error: e.message,
      );
    }
  }
}

final realDebridSettingsProvider =
    AsyncNotifierProvider<RealDebridSettingsNotifier, RealDebridSettings>(
      RealDebridSettingsNotifier.new,
    );
