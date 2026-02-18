import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AuthSessionService {
  AuthSessionService._();
  static final AuthSessionService instance = AuthSessionService._();

  File? _sessionFile;
  bool _initialized = false;

  String _token = '';
  String get token => _token;

  String _email = '';
  String get email => _email;

  Future<void> init() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    _sessionFile = File('${dir.path}/auth_session.json');
    await _load();
    _initialized = true;
  }

  Future<void> saveSession({
    required String token,
    required String email,
  }) async {
    await init();
    _token = token.trim();
    _email = email.trim().toLowerCase();
    await _persist();
  }

  Future<void> clearSession() async {
    await init();
    _token = '';
    _email = '';
    await _persist();
  }

  Future<void> _load() async {
    final file = _sessionFile;
    if (file == null || !await file.exists()) return;
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return;
      final decoded = json.decode(content);
      if (decoded is Map<String, dynamic>) {
        _token = (decoded['token'] ?? '').toString();
        _email = (decoded['email'] ?? '').toString();
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    final file = _sessionFile;
    if (file == null) return;
    await file.writeAsString(json.encode({'token': _token, 'email': _email}));
  }
}
