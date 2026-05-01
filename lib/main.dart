import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:media_kit/media_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'presentation/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  MediaKit.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  final hasSupabaseConfig =
      supabaseUrl.startsWith('https://') && supabaseAnonKey.isNotEmpty;

  if (hasSupabaseConfig) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  runApp(
    ProviderScope(
      overrides: [
        supabaseConfiguredProvider.overrideWithValue(hasSupabaseConfig),
      ],
      child: const StreamVaultApp(),
    ),
  );
}
