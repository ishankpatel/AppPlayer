import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

class SettingsState {
  const SettingsState({
    this.isStartingCloud = false,
    this.hasCloudSession = false,
    this.error,
  });

  final bool isStartingCloud;
  final bool hasCloudSession;
  final String? error;

  SettingsState copyWith({
    bool? isStartingCloud,
    bool? hasCloudSession,
    String? error,
    bool clearError = false,
  }) {
    return SettingsState(
      isStartingCloud: isStartingCloud ?? this.isStartingCloud,
      hasCloudSession: hasCloudSession ?? this.hasCloudSession,
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
    state = state.copyWith(
      hasCloudSession: ref.read(syncRepositoryProvider).hasCloudSession,
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
    } catch (error) {
      state = state.copyWith(
        isStartingCloud: false,
        error:
            'Could not start Supabase sync. Check anonymous auth and the schema.',
      );
    }
  }
}

final settingsProvider = NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);
