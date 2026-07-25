import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento seguro de credenciales (tokens JWT).
///
/// Usa el Keystore/Keychain del sistema a través de [FlutterSecureStorage].
/// Los tokens NUNCA se guardan en `SharedPreferences` (texto plano). La API
/// pública se mantiene idéntica a la versión anterior, así que ningún otro
/// archivo necesita cambios.
///
/// Nota: al migrar desde la versión previa (SharedPreferences), la sesión
/// existente no se conserva y el usuario debe iniciar sesión una vez.
class StorageService {
  StorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  Future<void> guardarTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> obtenerAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> obtenerRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> actualizarAccessToken(String accessToken) =>
      _storage.write(key: _accessTokenKey, value: accessToken);

  Future<bool> estaAutenticado() async {
    final token = await obtenerAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> cerrarSesion() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
