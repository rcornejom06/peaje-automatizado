import 'api_service.dart';
import '../constants/api_config.dart';

class NotificacionService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> obtenerNotificaciones() async {
    final data = await _apiService.get(ApiConfig.notificaciones);

    if (data is List) {
      return data;
    }

    if (data is Map && data['results'] is List) {
      return data['results'];
    }

    return [];
  }

  Future<int> obtenerNoLeidas() async {
    final data = await _apiService.get(ApiConfig.notificacionesNoLeidas);

    if (data is Map && data['no_leidas'] != null) {
      return int.tryParse(data['no_leidas'].toString()) ?? 0;
    }

    return 0;
  }

  Future<void> marcarLeida(int id) async {
    await _apiService.patch(
      '${ApiConfig.notificaciones}$id/marcar-leida/',
      body: {},
    );
  }

  Future<void> marcarTodasLeidas() async {
    await _apiService.patch(
      '${ApiConfig.notificaciones}marcar-todas-leidas/',
      body: {},
    );
  }
}