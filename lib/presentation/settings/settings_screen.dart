import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers.dart';
import '../app.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final supabaseConfigured = ref.watch(supabaseConfiguredProvider);
    final tmdbConfigured = ref.watch(tmdbRemoteProvider).isConfigured;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: context.pop,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('StreamVault Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        children: [
          _Section(
            title: 'Cloud Sync',
            subtitle:
                'Supabase sync runs behind the local cache when environment values are configured.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusRow(
                  icon: Icons.cloud_done_rounded,
                  label: supabaseConfigured
                      ? state.hasCloudSession
                            ? 'Supabase configured and signed in'
                            : 'Supabase configured, session not started'
                      : 'Supabase is not configured in .env',
                  good: supabaseConfigured && state.hasCloudSession,
                ),
                const SizedBox(height: 10),
                _StatusRow(
                  icon: Icons.image_search_rounded,
                  label: tmdbConfigured
                      ? 'TMDB configured for live posters and paged rows'
                      : 'TMDB key missing, using local and public fallback catalogs',
                  good: tmdbConfigured,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: supabaseConfigured && !state.isStartingCloud
                      ? controller.startCloudSession
                      : null,
                  icon: state.isStartingCloud
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                  label: const Text('Start Household Sync Session'),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 14),
                  _ErrorCard(message: state.error!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _Section(
            title: 'Playback',
            subtitle:
                'The local player shell is included. External provider integrations are intentionally not included in this handoff.',
            child: _PreferenceGrid(),
          ),
          const SizedBox(height: 18),
          const _Section(
            title: 'Local Cache',
            subtitle:
                'Drift and SQLite keep browsing metadata fast and available when the network is offline.',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _PreferenceChip(
                  icon: Icons.storage_rounded,
                  label: 'SQLite metadata cache',
                ),
                _PreferenceChip(
                  icon: Icons.offline_bolt_rounded,
                  label: 'Offline-first browsing',
                ),
                _PreferenceChip(
                  icon: Icons.sync_rounded,
                  label: 'Background sync-ready',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.good,
  });

  final IconData icon;
  final String label;
  final bool good;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: good ? AppColors.teal : AppColors.muted, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _PreferenceGrid extends StatelessWidget {
  const _PreferenceGrid();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _PreferenceChip(
          icon: Icons.play_circle_fill_rounded,
          label: 'Direct URL playback shell',
        ),
        _PreferenceChip(
          icon: Icons.subtitles_rounded,
          label: 'Subtitle track UI',
        ),
        _PreferenceChip(
          icon: Icons.graphic_eq_rounded,
          label: 'Audio track UI',
        ),
        _PreferenceChip(
          icon: Icons.memory_rounded,
          label: 'media_kit native engine',
        ),
      ],
    );
  }
}

class _PreferenceChip extends StatelessWidget {
  const _PreferenceChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.gold),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.crimson.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.crimson),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
