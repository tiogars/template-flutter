import 'package:domain_template_client/auth_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_settings.dart';

abstract interface class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  // Keep the storage key so existing sessions survive the domain rename.
  static const _tokenKey = 'domainTemplate.authToken';
  final FlutterSecureStorage _storage;

  @override
  Future<void> clear() => _storage.delete(key: _tokenKey);

  @override
  Future<String?> read() => _storage.read(key: _tokenKey);

  @override
  Future<void> write(String token) =>
      _storage.write(key: _tokenKey, value: token);
}

abstract interface class AuthGateway {
  Future<LoginResponse> login(String username, String password);
  Future<AuthUser> me();
}

class ApiAuthGateway implements AuthGateway {
  ApiAuthGateway({required Uri baseUri, required String? Function() token})
    : _client = AuthClient(baseUri: baseUri, accessTokenProvider: token);

  final AuthClient _client;

  @override
  Future<LoginResponse> login(String username, String password) =>
      _client.login(username, password);

  @override
  Future<AuthUser> me() => _client.me();
}

class AuthSession extends ChangeNotifier {
  AuthSession(
    this._settings, {
    TokenStorage? storage,
    AuthGateway Function(Uri baseUri, String? Function() token)? gatewayFactory,
    AuthUser? initialUser,
  }) : _storage = storage ?? SecureTokenStorage(),
       _gatewayFactory =
           gatewayFactory ??
           ((baseUri, token) => ApiAuthGateway(baseUri: baseUri, token: token)),
       _user = initialUser;

  final AppSettings _settings;
  final TokenStorage _storage;
  final AuthGateway Function(Uri baseUri, String? Function() token)
  _gatewayFactory;

  String? _accessToken;
  AuthUser? _user;
  bool _isLoading = false;
  String? _error;

  String? get accessToken => _accessToken;
  AuthUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.hasRole('ADMIN') ?? false;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthGateway get _gateway =>
      _gatewayFactory(Uri.parse(_settings.apiBaseUrl), () => _accessToken);

  Future<void> restore() async {
    _accessToken = await _storage.read();
    if (_accessToken == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _gateway.me();
    } catch (_) {
      await _storage.clear();
      _accessToken = null;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _gateway.login(username, password);
      _accessToken = response.token;
      _user = response.user;
      await _storage.write(response.token);
      return true;
    } catch (error) {
      _error = error is AuthException && error.statusCode == 401
          ? 'Invalid username or password.'
          : error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    _accessToken = null;
    _user = null;
    _error = null;
    notifyListeners();
  }
}
