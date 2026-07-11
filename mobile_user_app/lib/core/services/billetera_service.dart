import '../constants/api_config.dart';
import 'api_service.dart';

class BilleteraService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> obtenerMiBilletera() async {
    final data = await _apiService.get(ApiConfig.miBilletera);

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {};
  }

  Future<Map<String, dynamic>> recargar({
    required double monto,
    String metodoPago = 'simulado',
    String referenciaPago = 'RECARGA-APP-MOVIL',
  }) async {
    final data = await _apiService.post(
      ApiConfig.recargarBilletera,
      body: {
        'monto': monto,
        'metodo_pago': metodoPago,
        'referencia_pago': referenciaPago,
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