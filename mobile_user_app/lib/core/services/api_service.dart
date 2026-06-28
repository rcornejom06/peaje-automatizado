import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storageService = StorageService();

  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    return Uri.parse('${ApiConfig.baseUrl}$endpoint').replace(
      queryParameters: queryParams,
    );
  }

  Future<Map<String, String>> _headers({bool requiereAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiereAuth) {
      final token = await _storageService.obtenerAccessToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiereAuth = true,
  }) async {
    final response = await http.get(
      _buildUri(endpoint, queryParams),
      headers: await _headers(requiereAuth: requiereAuth),
    );

    return _procesarRespuesta(response);
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiereAuth = true,
  }) async {
    final response = await http.post(
      _buildUri(endpoint),
      headers: await _headers(requiereAuth: requiereAuth),
      body: jsonEncode(body ?? {}),
    );

    return _procesarRespuesta(response);
  }

  Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiereAuth = true,
  }) async {
    final response = await http.patch(
      _buildUri(endpoint),
      headers: await _headers(requiereAuth: requiereAuth),
      body: jsonEncode(body ?? {}),
    );

    return _procesarRespuesta(response);
  }

  dynamic _procesarRespuesta(http.Response response) {
    final statusCode = response.statusCode;

    dynamic data;

    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        data = response.body;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return data;
    }

    String mensaje = 'Error en la solicitud. Código: $statusCode';

    if (data is Map && data.containsKey('detail')) {
      mensaje = data['detail'].toString();
    } else if (data is Map && data.containsKey('error')) {
      mensaje = data['error'].toString();
    } else if (data is Map) {
      mensaje = data.toString();
    }

    throw Exception(mensaje);
  }
}