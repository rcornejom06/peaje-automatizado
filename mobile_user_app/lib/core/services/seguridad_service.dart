import '../constants/api_config.dart';
import 'api_service.dart';

class SeguridadService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> obtenerAvisosRobo() async {
    final data = await _apiService.get(ApiConfig.avisosRobo);

    if (data is List) {
      return data;
    }

    if (data is Map && data['results'] is List) {
      return data['results'];
    }

    return [];
  }

  Future<List<dynamic>> obtenerAlertas() async {
    final data = await _apiService.get(ApiConfig.alertas);

    if (data is List) {
      return data;
    }

    if (data is Map && data['results'] is List) {
      return data['results'];
    }

    return [];
  }

  Future<Map<String, dynamic>> crearAvisoRobo({
    required int vehiculoId,
    required String numeroDenuncia,
    required String entidadDenuncia,
    required String fechaDenuncia,
    required String lugarRobo,
    required String descripcion,
    String? latitudRobo,
    String? longitudRobo,
  }) async {
    final body = {
      'vehiculo': vehiculoId,
      'numero_denuncia': numeroDenuncia,
      'entidad_denuncia': entidadDenuncia,
      'fecha_denuncia': fechaDenuncia,
      'lugar_robo': lugarRobo,
      'descripcion': descripcion,
    };

    if (latitudRobo != null && latitudRobo.isNotEmpty) {
      body['latitud_robo'] = latitudRobo;
    }

    if (longitudRobo != null && longitudRobo.isNotEmpty) {
      body['longitud_robo'] = longitudRobo;
    }

    final data = await _apiService.post(
      ApiConfig.crearAvisoRobo,
      body: body,
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