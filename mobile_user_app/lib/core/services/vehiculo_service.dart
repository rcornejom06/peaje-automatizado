import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import 'api_service.dart';
import 'storage_service.dart';

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

  Future<Map<String, dynamic>> registrarVehiculo({
    required String placa,
    required String marca,
    required String modelo,
    required String color,
    required int anio,
    required int categoriaId,
    required File documentoRespaldo,
  }) async {

    final storageService = StorageService();
    final token = await storageService.obtenerAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa. Inicie sesión nuevamente.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/vehiculos/vehiculos/registrar-propio/',
    );

    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['placa'] = placa;
    request.fields['marca'] = marca;
    request.fields['modelo'] = modelo;
    request.fields['color'] = color;
    request.fields['anio'] = anio.toString();
    request.fields['categoria'] = categoriaId.toString();

    request.files.add(
      await http.MultipartFile.fromPath(
        'documento_respaldo',
        documentoRespaldo.path,
      ),
    );

    final streamedResponse = await request.send().timeout(
          const Duration(seconds: 30),
        );

    final response = await http.Response.fromStream(streamedResponse);

    dynamic decoded;

    try {
      decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : <String, dynamic>{};
    } catch (_) {
      decoded = {
        'error': response.body,
      };
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        'message': 'Vehículo registrado correctamente.',
      };
    }

    if (decoded is Map) {
      throw Exception(
        decoded['error'] ??
            decoded['detail'] ??
            decoded['message'] ??
            'Error al registrar vehículo.',
      );
    }

    throw Exception('Error al registrar vehículo.');
  }
}