import 'api_service.dart';

class TarjetaBancariaService {
  final ApiService _apiService = ApiService();

  static const String _tarjetasUrl = '/pagos/tarjetas/';
  static const String _recargarUrl = '/pagos/billeteras/recargar/';

  Future<List<dynamic>> obtenerTarjetas() async {
    final data = await _apiService.get(_tarjetasUrl);

    if (data is List) {
      return data;
    }

    if (data is Map && data['results'] is List) {
      return data['results'];
    }

    return [];
  }

  Future<dynamic> agregarTarjeta({
    required String numeroTarjeta,
    required String titular,
    required int mesExpiracion,
    required int anioExpiracion,
    String? alias,
    bool principal = false,
  }) async {
    final body = {
      'numero_tarjeta': numeroTarjeta,
      'titular': titular,
      'mes_expiracion': mesExpiracion,
      'anio_expiracion': anioExpiracion,
      'alias': alias ?? '',
      'principal': principal,
    };

    return await _apiService.post(
      _tarjetasUrl,
      body: body,
    );
  }

  Future<dynamic> eliminarTarjeta(int tarjetaId) async {
    return await _apiService.patch(
      '${_tarjetasUrl}$tarjetaId/',
      body: {
        'estado': 'inactiva',
        'principal': false,
      },
    );
  }

  Future<dynamic> establecerPrincipal(int tarjetaId) async {
    return await _apiService.patch(
      '${_tarjetasUrl}$tarjetaId/establecer-principal/',
      body: {},
    );
  }

  Future<dynamic> recargarBilletera({
    required int tarjetaId,
    required String monto,
    required String cvv,
  }) async {
    final body = {
      'tarjeta_id': tarjetaId,
      'monto': monto,
      'cvv': cvv,
    };

    return await _apiService.post(
      _recargarUrl,
      body: body,
    );
  }
}