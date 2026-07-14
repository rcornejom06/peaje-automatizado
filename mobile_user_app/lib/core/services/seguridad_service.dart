import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import 'api_service.dart';
import 'storage_service.dart';

class SeguridadService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

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

  Uri _buildUri(String endpoint) {
    final baseUrl = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;

    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';

    return Uri.parse('$baseUrl$cleanEndpoint');
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
    String? documentoRespaldoPath,
    Uint8List? documentoRespaldoBytes,
    required String documentoRespaldoNombre,
  }) async {
    final token = await _storageService.obtenerAccessToken();

    final uri = _buildUri(ApiConfig.crearAvisoRobo);

    final request = http.MultipartRequest('POST', uri);

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['vehiculo'] = vehiculoId.toString();
    request.fields['numero_denuncia'] = numeroDenuncia;
    request.fields['entidad_denuncia'] = entidadDenuncia;
    request.fields['fecha_denuncia'] = fechaDenuncia;
    request.fields['lugar_robo'] = lugarRobo;
    request.fields['descripcion'] = descripcion;

    if (latitudRobo != null && latitudRobo.trim().isNotEmpty) {
      request.fields['latitud_robo'] = latitudRobo.trim();
    }

    if (longitudRobo != null && longitudRobo.trim().isNotEmpty) {
      request.fields['longitud_robo'] = longitudRobo.trim();
    }

    if (documentoRespaldoBytes != null && documentoRespaldoBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'documento_respaldo',
          documentoRespaldoBytes,
          filename: documentoRespaldoNombre,
        ),
      );
    } else if (documentoRespaldoPath != null &&
        documentoRespaldoPath.trim().isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'documento_respaldo',
          documentoRespaldoPath,
          filename: documentoRespaldoNombre,
        ),
      );
    } else {
      throw Exception('Debe adjuntar el documento PDF de respaldo.');
    }

    final streamedResponse = await request.send().timeout(
          const Duration(seconds: 30),
        );

    final response = await http.Response.fromStream(streamedResponse);

    dynamic data;

    if (response.bodyBytes.isNotEmpty) {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data is Map<String, dynamic>) {
        return data;
      }

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return {};
    }

    if (data is Map) {
      throw Exception(
        data['error'] ??
            data['detail'] ??
            data['mensaje'] ??
            'No se pudo crear el aviso de robo.',
      );
    }

    throw Exception('No se pudo crear el aviso de robo.');
  }
}