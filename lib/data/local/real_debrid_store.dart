import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's Real-Debrid API key per device.
///
/// This intentionally does not sync through Supabase. The value is wrapped only
/// to avoid plain-text casual inspection; a production hardening pass can swap
/// this for Keychain/Credential Manager on native targets.
class RealDebridStore {
  static const _key = 'streamvault_real_debrid_api_key';

  Future<String?> readApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wrapped = prefs.getString(_key);
      if (wrapped == null || wrapped.isEmpty) return null;
      return _unwrap(wrapped);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeApiKey(String? apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    if (apiKey == null || apiKey.trim().isEmpty) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(_key, _wrap(apiKey.trim()));
  }

  String _wrap(String value) {
    return base64Url.encode(utf8.encode(value));
  }

  String? _unwrap(String value) {
    try {
      return utf8.decode(base64Url.decode(value));
    } catch (_) {
      return null;
    }
  }
}
