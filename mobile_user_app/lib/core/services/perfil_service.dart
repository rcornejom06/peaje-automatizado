import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import 'api_service.dart';
import 'storage_service.dart';

class PerfilService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> obtenerMiPerfil() async {
    final data = await _apiService.get(
      '/usuarios/perfiles/mi-perfil/',
      requiereAuth: true,
    );

    if (data is Map<String, dynamic>) {
      return data;
    }

    return {};
  }

  Future<Map<String, dynamic>> actualizarMiPerfil({
    required String firstName,
    required String lastName,
    required String email,
    required String telefono,
    required String cedula,
  }) async {
    final storageService = StorageService();
    final token = await storageService.obtenerAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa. Inicie sesión nuevamente.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/usuarios/perfiles/actualizar-mi-perfil/',
    );

    final response = await http
        .patch(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'first_name': firstName,
            'last_name': lastName,
            'email': email,
            'telefono': telefono,
            'cedula': cedula,
          }),
        )
        .timeout(const Duration(seconds: 15));

    dynamic decoded;

    try {
      decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : <String, dynamic>{};
    } catch (_) {
      decoded = {'error': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        'mensaje': 'Perfil actualizado correctamente.',
      };
    }

    if (decoded is Map) {
      throw Exception(
        decoded['error'] ??
            decoded['detail'] ??
            decoded['message'] ??
            'Error al actualizar perfil.',
      );
    }

    throw Exception('Error al actualizar perfil.');
  }
}