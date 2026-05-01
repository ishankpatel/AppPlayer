import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers.dart';
import '../home/home_provider.dart';
import '../watchlist/watchlist_provider.dart';

class SettingsState {
  const SettingsState({
    this.isStartingCloud = false,
    this.isSavingPreferences = false,
    this.hasCloudSession = false,
    this.householdEmail = '',
    this.householdPassword = '',
    this.preferredSubtitleLang = 'en',
    this.preferredAudioLang = 'en',
    this.error,
  });

  final bool isStartingCloud;
  final bool isSavingPreferences;
  final bool hasCloudSession;
  final String householdEmail;
  final String householdPassword;
  final String preferredSubtitleLang;
  final String preferredAudioLang;
  final String? error;

  SettingsState copyWith({
    bool? isStartingCloud,
    bool? isSavingPreferences,
    bool? hasCloudSession,
    String? householdEmail,
    String? householdPassword,
    String? preferredSubtitleLang,
    String? preferredAudioLang,
    String? error,
    bool clearError = false,
  }) {
    return SettingsState(
      isStartingCloud: isStartingCloud ?? this.isStartingCloud,
      isSavingPreferences: isSavingPreferences ?? this.isSavingPreferences,
      hasCloudSession: hasCloudSession ?? this.hasCloudSession,
      householdEmail: householdEmail ?? this.householdEmail,
      householdPassword: householdPassword ?? this.householdPassword,
      preferredSubtitleLang:
          preferredSubtitleLang ?? this.preferredSubtitleLang,
      preferredAudioLang: preferredAudioLang ?? this.preferredAudioLang,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    Future.microtask(_load);
    return const SettingsState();
  }

  Future<void> _load() async {
    final hasSession = ref.read(syncRepositoryProvider).hasCloudSession;
    state = state.copyWith(hasCloudSession: hasSession);
    if (hasSession) await _loadProfilePreferences();
  }

  Future<void> _loadProfilePreferences() async {
    final profile = await ref.read(syncRepositoryProvider).currentProfile();
    if (profile == null) return;
    state = state.copyWith(
      preferredSubtitleLang:
          profile['preferred_subtitle_lang'] as String? ?? 'en',
      preferredAudioLang: profile['preferred_audio_lang'] as String? ?? 'en',
    );
  }

  Future<void> startCloudSession() async {
    state = state.copyWith(isStartingCloud: true, clearError: true);
    try {
      final started = await ref
          .read(syncRepositoryProvider)
          .startCloudSession();
      state = state.copyWith(
        isStartingCloud: false,
        hasCloudSession: started,
        error: started ? null : 'Supabase is not configured in .env yet.',
      );
      if (started) ref.invalidate(watchlistProvider);
      if (started) ref.invalidate(continueWatchingProvider);
      if (started) await _loadProfilePreferences();
    } catch (error) {
      state = state.copyWith(
        isStartingCloud: false,
        error:
            'Could not start Supabase sync. Check anonymous auth and the schema.',
      );
    }
  }

  void updateHouseholdEmail(String value) {
    state = state.copyWith(householdEmail: value.trim(), clearError: true);
  }

  void updateHouseholdPassword(String value) {
    state = state.copyWith(householdPassword: value, clearError: true);
  }

  void updatePreferredSubtitleLang(String value) {
    state = state.copyWith(preferredSubtitleLang: value, clearError: true);
  }

  void updatePreferredAudioLang(String value) {
    state = state.copyWith(preferredAudioLang: value, clearError: true);
  }

  Future<void> startHouseholdSession() async {
    final email = state.householdEmail.trim();
    final password = state.householdPassword;
    if (email.isEmpty || password.length < 6) {
      state = state.copyWith(
        error:
            'Enter a household email and a shared password with at least 6 characters.',
      );
      return;
    }

    state = state.copyWith(isStartingCloud: true, clearError: true);
    try {
      final started = await ref
          .read(syncRepositoryProvider)
          .startHouseholdSession(email: email, password: password);
      state = state.copyWith(
        isStartingCloud: false,
        hasCloudSession: started,
        householdPassword: started ? '' : state.householdPassword,
        error: started
            ? null
            : 'Household sign-in did not start. Check Supabase auth settings.',
      );
      if (started) ref.invalidate(watchlistProvider);
      if (started) ref.invalidate(continueWatchingProvider);
      if (started) await _loadProfilePreferences();
    } catch (error) {
      state = state.copyWith(
        isStartingCloud: false,
        error: error is AuthException
            ? error.message
            : 'Could not start household sync. Confirm email/password auth is enabled in Supabase.',
      );
    }
  }

  Future<void> savePlaybackPreferences() async {
    if (!ref.read(syncRepositoryProvider).hasCloudSession) {
      state = state.copyWith(
        error:
            'Start a household sync session before saving cloud preferences.',
      );
      return;
    }

    state = state.copyWith(isSavingPreferences: true, clearError: true);
    try {
      await ref
          .read(syncRepositoryProvider)
          .syncProfilePreferences(
            preferredSubtitleLang: state.preferredSubtitleLang,
            preferredAudioLang: state.preferredAudioLang,
          );
      state = state.copyWith(isSavingPreferences: false);
    } catch (error) {
      state = state.copyWith(
        isSavingPreferences: false,
        error: 'Could not save playback preferences to Supabase.',
      );
    }
  }
}

final settingsProvider = NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);
