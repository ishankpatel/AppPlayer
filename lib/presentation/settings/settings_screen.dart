import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/datasources/real_debrid_remote.dart';
import '../../providers.dart';
import '../app.dart';
import 'real_debrid_provider.dart';
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
                'Use the same household login on every device so watchlist, progress, and preferences share one Supabase account.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusRow(
                  icon: Icons.cloud_done_rounded,
                  label: supabaseConfigured
                      ? state.hasCloudSession
                            ? 'Supabase configured and signed in'
                            : 'Supabase configured, household sign-in needed'
                      : 'Supabase is not configured for this build',
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
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: state.householdEmail,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Household email',
                          hintText: 'family@example.com',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                        onChanged: controller.updateHouseholdEmail,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: state.householdPassword,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.password],
                        decoration: const InputDecoration(
                          labelText: 'Shared password',
                          hintText: 'Use this same password on each device',
                          prefixIcon: Icon(Icons.lock_rounded),
                        ),
                        onChanged: controller.updateHouseholdPassword,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: supabaseConfigured && !state.isStartingCloud
                      ? controller.startHouseholdSession
                      : null,
                  icon: state.isStartingCloud
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.group_rounded),
                  label: Text(
                    state.hasCloudSession
                        ? 'Household Sync Active'
                        : 'Sign In / Create Household',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Anonymous sessions are only useful for local testing. Cross-device sync requires the same email/password on Windows, iPhone, and future TV builds.',
                  style: TextStyle(
                    color: AppColors.text.withValues(alpha: 0.62),
                    height: 1.4,
                  ),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 14),
                  _ErrorCard(message: state.error!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _RealDebridSection(),
          const SizedBox(height: 18),
          const _Section(
            title: 'Playback',
            subtitle:
                'Real-Debrid resolves authorized links into direct streams; media_kit handles native playback and track controls.',
            child: _PlaybackPreferencePanel(),
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

class _PlaybackPreferencePanel extends ConsumerWidget {
  const _PlaybackPreferencePanel();

  static const _languages = <MapEntry<String, String>>[
    MapEntry('en', 'English'),
    MapEntry('hi', 'Hindi'),
    MapEntry('gu', 'Gujarati'),
    MapEntry('es', 'Spanish'),
    MapEntry('fr', 'French'),
    MapEntry('ja', 'Japanese'),
    MapEntry('ko', 'Korean'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<String>(
                initialValue: _normalizedLanguage(state.preferredSubtitleLang),
                decoration: const InputDecoration(
                  labelText: 'Preferred subtitles',
                  prefixIcon: Icon(Icons.subtitles_rounded),
                ),
                items: [
                  for (final option in _languages)
                    DropdownMenuItem(
                      value: option.key,
                      child: Text(option.value),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.updatePreferredSubtitleLang(value);
                  }
                },
              ),
            ),
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<String>(
                initialValue: _normalizedLanguage(state.preferredAudioLang),
                decoration: const InputDecoration(
                  labelText: 'Preferred audio',
                  prefixIcon: Icon(Icons.graphic_eq_rounded),
                ),
                items: [
                  for (final option in _languages)
                    DropdownMenuItem(
                      value: option.key,
                      child: Text(option.value),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) controller.updatePreferredAudioLang(value);
                },
              ),
            ),
            FilledButton.icon(
              onPressed: state.isSavingPreferences
                  ? null
                  : controller.savePlaybackPreferences,
              icon: state.isSavingPreferences
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_rounded),
              label: const Text('Save Preferences'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _PreferenceGrid(),
      ],
    );
  }

  String _normalizedLanguage(String value) {
    return _languages.any((option) => option.key == value) ? value : 'en';
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

class _RealDebridSection extends ConsumerStatefulWidget {
  const _RealDebridSection();

  @override
  ConsumerState<_RealDebridSection> createState() => _RealDebridSectionState();
}

class _RealDebridSectionState extends ConsumerState<_RealDebridSection> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _hydrated = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncSettings = ref.watch(realDebridSettingsProvider);

    return _Section(
      title: 'Real-Debrid',
      subtitle:
          'Plug in a Real-Debrid API key to resolve premium streams in the player. The key lives only on this device.',
      child: asyncSettings.when(
        data: (settings) {
          if (!_hydrated && settings.apiKey.isNotEmpty) {
            _controller.text = settings.apiKey;
            _hydrated = true;
          }
          return _buildBody(settings);
        },
        loading: () => const SizedBox(
          height: 80,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.gold),
              ),
            ),
          ),
        ),
        error: (e, _) => _ErrorCard(message: e.toString()),
      ),
    );
  }

  Widget _buildBody(RealDebridSettings settings) {
    final controller = ref.read(realDebridSettingsProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (settings.user != null)
          _AccountCard(
            user: settings.user!,
            remainingTrafficBytes: settings.remainingTrafficBytes,
          )
        else
          _StatusRow(
            icon: Icons.vpn_key_rounded,
            label: settings.hasKey
                ? settings.error == null
                      ? 'Key saved, tap "Test & Save" to validate'
                      : 'Key needs attention'
                : 'No Real-Debrid key configured',
            good: false,
          ),
        const SizedBox(height: 14),
        TextField(
          controller: _controller,
          obscureText: _obscure,
          enableSuggestions: false,
          autocorrect: false,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          decoration: InputDecoration(
            labelText: 'API key',
            hintText: 'Paste your Real-Debrid token',
            prefixIcon: const Icon(Icons.vpn_key_rounded),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Paste',
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    final text = data?.text?.trim();
                    if (text != null && text.isNotEmpty) {
                      _controller.text = text;
                    }
                  },
                  icon: const Icon(Icons.content_paste_rounded),
                ),
                IconButton(
                  tooltip: _obscure ? 'Show' : 'Hide',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
              ],
            ),
          ),
          onChanged: (v) => controller.updateKey(v),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: settings.validating
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await controller.saveAndValidate(
                        _controller.text,
                      );
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Real-Debrid key validated and saved.'
                                : 'Real-Debrid validation failed.',
                          ),
                          backgroundColor: ok
                              ? AppColors.teal
                              : AppColors.crimson,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
              icon: settings.validating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.task_alt_rounded),
              label: const Text('Test & Save'),
            ),
            OutlinedButton.icon(
              onPressed: settings.hasKey
                  ? () async {
                      final messenger = ScaffoldMessenger.of(context);
                      _controller.clear();
                      _hydrated = true;
                      await controller.clear();
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Real-Debrid key removed from this device.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Clear'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(
                  const ClipboardData(text: 'https://real-debrid.com/apitoken'),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Token URL copied to clipboard.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Copy token URL'),
            ),
          ],
        ),
        if (settings.error != null) ...[
          const SizedBox(height: 14),
          _ErrorCard(message: settings.error!),
        ],
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user, required this.remainingTrafficBytes});

  final RealDebridUser user;
  final int remainingTrafficBytes;

  @override
  Widget build(BuildContext context) {
    final remainingDays = (user.premiumRemaining.inHours / 24).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold.withValues(alpha: 0.18),
            AppColors.surfaceRaised,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: user.isPremium ? AppColors.gold : Colors.white12,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.surface,
            backgroundImage: user.avatar.isNotEmpty
                ? NetworkImage(user.avatar)
                : null,
            child: user.avatar.isEmpty
                ? const Icon(Icons.person_rounded, color: AppColors.gold)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.username.isEmpty
                            ? 'Real-Debrid user'
                            : user.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: user.isPremium
                            ? AppColors.gold
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: user.isPremium
                              ? AppColors.gold
                              : Colors.white24,
                        ),
                      ),
                      child: Text(
                        user.isPremium ? 'PREMIUM' : 'FREE',
                        style: TextStyle(
                          color: user.isPremium
                              ? AppColors.ink
                              : AppColors.muted,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _MetaText('${user.points} fidelity points'),
                    if (user.isPremium)
                      _MetaText('$remainingDays days remaining'),
                    if (remainingTrafficBytes > 0)
                      _MetaText(
                        '${_formatBytes(remainingTrafficBytes)} hoster traffic left',
                      ),
                    if (user.email.isNotEmpty) _MetaText(user.email),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    final precision = unit <= 1 ? 0 : 1;
    return '${value.toStringAsFixed(precision)} ${units[unit]}';
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.muted,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }
}
