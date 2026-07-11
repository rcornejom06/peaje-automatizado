import '../constants/api_config.dart';
import 'api_service.dart';

class PasoPeajeService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> obtenerPasosPeaje() async {
    final data = await _apiService.get(ApiConfig.pasosPeaje);

    if (data is List) {
      return data;
    }

    if (data is Map && data['results'] is List) {
      return data['results'];
    }

    return [];
  }
}