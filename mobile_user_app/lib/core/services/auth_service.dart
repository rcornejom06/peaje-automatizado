import '../constants/api_config.dart';
import 'api_service.dart';
import 'push_notification_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final data = await _apiService.post(
      ApiConfig.token,
      requiereAuth: false,
      body: {
        'username': username,
        'password': password,
      },
    );

    final accessToken = data['access'];
    final refreshToken = data['refresh'];

    if (accessToken == null || refreshToken == null) {
      throw Exception('No se recibieron tokens de autenticación.');
    }

    await _storageService.guardarTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    await PushNotificationService().registrarTokenEnBackend();
  }

  Future<void> registrarUsuario({
    required String username,
    required String password,
    required String email,
    required String firstName,
    required String lastName,
    required String cedula,
    required String telefono,
    required bool aceptaTerminos,
  }) async {
    await _apiService.post(
      ApiConfig.registro,
      requiereAuth: false,
      body: {
        'username': username,
        'password': password,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'cedula': cedula,
        'telefono': telefono,
        'acepta_terminos': aceptaTerminos,
      },
    );
  }

  Future<void> verificarCorreo({
    required String email,
    required String codigo,
  }) async {
    await _apiService.post(
      ApiConfig.verificarCorreo,
      requiereAuth: false,
      body: {
        'email': email,
        'codigo': codigo,
      },
    );
  }

  Future<void> reenviarCodigo({
    required String email,
  }) async {
    await _apiService.post(
      ApiConfig.reenviarCodigo,
      requiereAuth: false,
      body: {
        'email': email,
      },
    );
  }

  Future<void> solicitarResetPassword({
    required String email,
  }) async {
    await _apiService.post(
      ApiConfig.solicitarResetPassword,
      requiereAuth: false,
      body: {
        'email': email,
      },
    );
  }

  Future<void> confirmarResetPassword({
    required String email,
    required String codigo,
    required String nuevaPassword,
    required String confirmarPassword,
  }) async {
    await _apiService.post(
      ApiConfig.confirmarResetPassword,
      requiereAuth: false,
      body: {
        'email': email,
        'codigo': codigo,
        'nueva_password': nuevaPassword,
        'confirmar_password': confirmarPassword,
      },
    );
  }

  Future<bool> estaAutenticado() async {
    return _storageService.estaAutenticado();
  }

  Future<void> cerrarSesion() async {
    await _storageService.cerrarSesion();
  }
}