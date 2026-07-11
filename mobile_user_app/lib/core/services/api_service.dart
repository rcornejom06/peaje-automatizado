import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import '../constants/api_config.dart';
import '../models/comprobante_paso.dart';
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

  Future<dynamic> get(String endpoint, {
    Map<String, String>? queryParams,
    bool requiereAuth = true,
  }) async {
    try {
      final response = await http
          .get(
        _buildUri(endpoint, queryParams),
        headers: await _headers(requiereAuth: requiereAuth),
      )
          .timeout(const Duration(seconds: 15));

      return _procesarRespuesta(response);
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Intente nuevamente.');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<dynamic> post(String endpoint, {
    Map<String, dynamic>? body,
    bool requiereAuth = true,
  }) async {
    try {
      final response = await http
          .post(
        _buildUri(endpoint),
        headers: await _headers(requiereAuth: requiereAuth),
        body: jsonEncode(body ?? {}),
      )
          .timeout(const Duration(seconds: 15));

      return _procesarRespuesta(response);
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Intente nuevamente.');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<dynamic> patch(String endpoint, {
    Map<String, dynamic>? body,
    bool requiereAuth = true,
  }) async {
    try {
      final response = await http
          .patch(
        _buildUri(endpoint),
        headers: await _headers(requiereAuth: requiereAuth),
        body: jsonEncode(body ?? {}),
      )
          .timeout(const Duration(seconds: 15));

      return _procesarRespuesta(response);
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Intente nuevamente.');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<ComprobantePaso> obtenerComprobantePaso(int pasoId) async {
    final data = await get('/peajes/pasos-peaje/$pasoId/comprobante/');

    if (data is Map<String, dynamic>) {
      return ComprobantePaso.fromJson(data);
    }

    return ComprobantePaso.fromJson(Map<String, dynamic>.from(data));
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
      return data ?? {};
    }

    final mensaje = _extraerMensajeError(data, statusCode);

    throw Exception(mensaje);
  }

  String _extraerMensajeError(dynamic data, int statusCode) {
    if (data == null) {
      return 'Error en la solicitud. Código: $statusCode';
    }

    if (data is String) {
      return data;
    }

    if (data is List && data.isNotEmpty) {
      return data.first.toString();
    }

    if (data is Map) {
      if (data.containsKey('detail')) {
        return _valorComoTexto(data['detail']);
      }

      if (data.containsKey('error')) {
        return _valorComoTexto(data['error']);
      }

      if (data.containsKey('mensaje')) {
        return _valorComoTexto(data['mensaje']);
      }

      if (data.containsKey('message')) {
        return _valorComoTexto(data['message']);
      }

      for (final entry in data.entries) {
        final value = entry.value;

        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }

        if (value is String && value
            .trim()
            .isNotEmpty) {
          return value;
        }

        if (value is Map) {
          return _extraerMensajeError(value, statusCode);
        }
      }
    }

    return 'Error en la solicitud. Código: $statusCode';
  }

  String _valorComoTexto(dynamic value) {
    if (value == null) {
      return 'Ocurrió un error. Intente nuevamente.';
    }

    if (value is List && value.isNotEmpty) {
      return value.first.toString();
    }

    if (value is Map) {
      for (final entry in value.entries) {
        final item = entry.value;

        if (item is List && item.isNotEmpty) {
          return item.first.toString();
        }

        if (item is String && item
            .trim()
            .isNotEmpty) {
          return item;
        }
      }
    }

    return value.toString();
  }
}