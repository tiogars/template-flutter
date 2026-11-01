import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  AppSettings([this._preferences]);

  static const _apiBaseUrlKey = 'apiBaseUrl';
  /// Overridable at build time with `--dart-define=API_BASE_URL=<url>`.
  static const defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8989',
  );

  SharedPreferencesAsync? _preferences;
  String _apiBaseUrl = defaultApiBaseUrl;

  String get apiBaseUrl => _apiBaseUrl;

  SharedPreferencesAsync get _storage =>
      _preferences ??= SharedPreferencesAsync();

  Future<void> load() async {
    _apiBaseUrl = await _storage.getString(_apiBaseUrlKey) ?? defaultApiBaseUrl;
    notifyListeners();
  }

  Future<void> setApiBaseUrl(String value) async {
    final normalized = value.trim().replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const FormatException('Enter a valid HTTP or HTTPS URL.');
    }
    await _storage.setString(_apiBaseUrlKey, normalized);
    _apiBaseUrl = normalized;
    notifyListeners();
  }
}
