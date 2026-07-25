import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../models/comprobante_paso.dart';
import 'storage_service.dart';

class SesionExpiradaException implements Exception {
  @override
  String toString() => 'Sesión expirada. Inicia sesión nuevamente.';
}

class ApiException implements Exception {
  final String mensaje;
  final String? codigo;
  final Map<String, dynamic>? datos;

  ApiException(this.mensaje, {this.codigo, this.datos});

  @override
  String toString() => mensaje;
}

class ApiService {
  final StorageService _storageService = StorageService();
  Future<bool>? _renovacionEnCurso;

  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final String baseUrl = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;

    final String path = endpoint.startsWith('/') ? endpoint : '/$endpoint';

    return Uri.parse('$baseUrl$path').replace(
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
  }) {
    return _enviarConReintento(
      () async => http.get(
        _buildUri(endpoint, queryParams),
        headers: await _headers(requiereAuth: requiereAuth),
      ),
      requiereAuth: requiereAuth,
    );
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiereAuth = true,
  }) {
    return _enviarConReintento(
      () async => http.post(
        _buildUri(endpoint),
        headers: await _headers(requiereAuth: requiereAuth),
        body: jsonEncode(body ?? {}),
      ),
      requiereAuth: requiereAuth,
    );
  }

  Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiereAuth = true,
  }) {
    return _enviarConReintento(
      () async => http.patch(
        _buildUri(endpoint),
        headers: await _headers(requiereAuth: requiereAuth),
        body: jsonEncode(body ?? {}),
      ),
      requiereAuth: requiereAuth,
    );
  }

  Future<dynamic> delete(
    String endpoint, {
    bool requiereAuth = true,
  }) {
    return _enviarConReintento(
      () async => http.delete(
        _buildUri(endpoint),
        headers: await _headers(requiereAuth: requiereAuth),
      ),
      requiereAuth: requiereAuth,
    );
  }

  Future<dynamic> postMultipart(
    String endpoint, {
    Map<String, String> fields = const {},
    Map<String, String> files = const {},
    bool requiereAuth = true,
  }) {
    return _enviarConReintento(
      () async {
        final request = http.MultipartRequest(
          'POST',
          _buildUri(endpoint),
        );

        request.headers['Accept'] = 'application/json';

        if (requiereAuth) {
          final token = await _storageService.obtenerAccessToken();

          if (token != null && token.isNotEmpty) {
            request.headers['Authorization'] = 'Bearer $token';
          }
        }

        request.fields.addAll(fields);

        for (final entry in files.entries) {
          final fieldName = entry.key;
          final filePath = entry.value;

          if (filePath.trim().isEmpty) {
            continue;
          }

          final file = File(filePath);

          if (!await file.exists()) {
            throw Exception('No se encontró el archivo seleccionado.');
          }

          request.files.add(
            await http.MultipartFile.fromPath(
              fieldName,
              filePath,
            ),
          );
        }

        final streamedResponse = await request
            .send()
            .timeout(const Duration(seconds: 30));

        return await http.Response.fromStream(streamedResponse);
      },
      requiereAuth: requiereAuth,
    );
  }

  Future<dynamic> _enviarConReintento(
    Future<http.Response> Function() enviar, {
    required bool requiereAuth,
  }) async {
    try {
      final response = await enviar().timeout(const Duration(seconds: 30));

      if (response.statusCode == 401 && requiereAuth) {
        final renovado = await _renovarAccessToken();

        if (!renovado) {
          await _storageService.cerrarSesion();
          throw SesionExpiradaException();
        }

        final reintento = await enviar().timeout(const Duration(seconds: 30));
        return _procesarRespuesta(reintento);
      }

      return _procesarRespuesta(response);
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Intente nuevamente.');
    } on SesionExpiradaException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<bool> _renovarAccessToken() async {
    _renovacionEnCurso ??= _hacerRenovacion();

    final resultado = await _renovacionEnCurso!;
    _renovacionEnCurso = null;

    return resultado;
  }

  Future<bool> _hacerRenovacion() async {
    try {
      final refreshToken = await _storageService.obtenerRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final response = await http
          .post(
            _buildUri(ApiConfig.tokenRefresh),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'refresh': refreshToken,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final nuevoAccessToken = data['access'];

      if (nuevoAccessToken == null || nuevoAccessToken.toString().isEmpty) {
        return false;
      }

      await _storageService.actualizarAccessToken(nuevoAccessToken.toString());
      return true;
    } catch (_) {
      return false;
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

    Map<String, dynamic>? datos;
    String? codigo;

    if (data is Map) {
      datos = Map<String, dynamic>.from(data);
      codigo = datos['code']?.toString();
    }

    throw ApiException(mensaje, codigo: codigo, datos: datos);
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

        if (value is String && value.trim().isNotEmpty) {
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

        if (item is String && item.trim().isNotEmpty) {
          return item;
        }
      }
    }

    return value.toString();
  }
}