import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Persists the user's Real-Debrid API key to
/// `<appSupport>/real_debrid.json`. The key is base64-wrapped at rest as a
/// minor obfuscation; for production deployments swap this for
/// `flutter_secure_storage` (Keychain on iOS, Credential Manager on Windows).
class RealDebridStore {
  RealDebridStore();

  File? _cachedFile;

  Future<File> _file() async {
    final cached = _cachedFile;
    if (cached != null) return cached;
    final dir = await getApplicationSupportDirectory();
    final f = File(path.join(dir.path, 'real_debrid.json'));
    if (!await f.exists()) {
      await f.create(recursive: true);
      await f.writeAsString('{}');
    }
    _cachedFile = f;
    return f;
  }

  Future<String?> readApiKey() async {
    try {
      final f = await _file();
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return null;
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final wrapped = json['k'] as String?;
      if (wrapped == null || wrapped.isEmpty) return null;
      return _unwrap(wrapped);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeApiKey(String? apiKey) async {
    final f = await _file();
    if (apiKey == null || apiKey.isEmpty) {
      await f.writeAsString('{}');
      return;
    }
    final wrapped = _wrap(apiKey);
    await f.writeAsString(jsonEncode({'k': wrapped}));
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
