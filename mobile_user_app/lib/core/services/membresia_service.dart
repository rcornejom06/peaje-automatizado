import '../constants/api_config.dart';
import 'api_service.dart';

class MembresiaService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> obtenerPlanes() async {
    final data = await _apiService.get(ApiConfig.planesMembresia);

    if (data is List) {
      return data;
    }

    if (data is Map && data['results'] is List) {
      return data['results'];
    }

    return [];
  }

  Future<Map<String, dynamic>?> obtenerMembresiaActiva() async {
    try {
      final data = await _apiService.get(ApiConfig.miMembresiaActiva);

      if (data == null) {
        return null;
      }

      if (data is Map<String, dynamic>) {
        return data;
      }

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return null;
    } catch (e) {
      // Si el backend responde 400/404 porque no hay membresía activa,
      // la app no debe fallar; solo mostrará "No tienes membresía activa".
      return null;
    }
  }

  Future<Map<String, dynamic>> comprarMembresia({
    required int planId,
  }) async {
    final data = await _apiService.post(
      ApiConfig.comprarMembresia,
      body: {
        'plan_id': planId,
        'plan': planId,
      },
    );

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {};
  }
}