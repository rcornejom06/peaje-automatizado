import '../constants/api_config.dart';
import 'api_service.dart';

class VehiculoService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> obtenerVehiculos() async {
    final data = await _apiService.get(ApiConfig.vehiculos);

    if (data is List) {
      return data;
    }

    if (data is Map && data['results'] is List) {
      return data['results'];
    }

    return [];
  }

  Future<List<dynamic>> obtenerCategorias() async {
    final data = await _apiService.get(ApiConfig.categoriasVehiculo);

    if (data is List) {
      return data;
    }

    if (data is Map && data['results'] is List) {
      return data['results'];
    }

    return [];
  }

  Future<void> registrarVehiculo({
    required String placa,
    required String marca,
    required String modelo,
    required String color,
    required int anio,
    required int categoriaId,
  }) async {
    await _apiService.post(
      ApiConfig.registrarVehiculoPropio,
      body: {
        'placa': placa,
        'marca': marca,
        'modelo': modelo,
        'color': color,
        'anio': anio,
        'categoria': categoriaId,
      },
    );
  }
}