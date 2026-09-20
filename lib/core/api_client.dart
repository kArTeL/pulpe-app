import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

/// Error que viene del backend con el formato estándar de la API:
/// { "error": { "codigo": "...", "mensaje": "...", "detalles": {} } }
class ApiException implements Exception {
  ApiException({
    required this.status,
    required this.codigo,
    required this.mensaje,
  });

  final int status;
  final String codigo;
  final String mensaje;

  /// 422: mandamos parámetros que el backend no reconoce o no acepta.
  /// Casi siempre significa que el nombre de un query param no coincide
  /// con el contrato. Ver AGENTS.md → "Contrato de la API".
  bool get esParametrosInvalidos => codigo == 'parametros_invalidos';

  @override
  String toString() => 'ApiException($status, $codigo): $mensaje';
}

/// Error de red: sin conexión, timeout, host inalcanzable.
class RedException implements Exception {
  RedException(this.mensaje);
  final String mensaje;

  @override
  String toString() => 'RedException: $mensaje';
}

class ApiClient {
  ApiClient({http.Client? cliente}) : _cliente = cliente ?? http.Client();

  final http.Client _cliente;

  /// GET contra la API.
  ///
  /// [query] se manda tal cual: las llaves DEBEN estar en snake_case porque
  /// así está definido el contrato del backend. Los valores se convierten a
  /// String; una lista se manda repitiendo la llave (?categoria=a&categoria=b).
  Future<Map<String, dynamic>> get(
    String ruta, {
    Map<String, dynamic>? query,
  }) async {
    final uri = Uri.parse('${Config.apiBaseUrl}$ruta').replace(
      queryParameters: _normalizarQuery(query),
    );

    final http.Response respuesta;
    try {
      respuesta = await _cliente.get(uri).timeout(Config.timeout);
    } catch (error) {
      throw RedException('No se pudo conectar con el servidor.');
    }

    final cuerpo = jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;

    if (respuesta.statusCode >= 400) {
      final error = cuerpo['error'] as Map<String, dynamic>? ?? const {};
      throw ApiException(
        status: respuesta.statusCode,
        codigo: error['codigo'] as String? ?? 'desconocido',
        mensaje: error['mensaje'] as String? ?? 'Error inesperado del servidor.',
      );
    }

    return cuerpo;
  }

  Map<String, dynamic>? _normalizarQuery(Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return null;

    final resultado = <String, dynamic>{};
    query.forEach((llave, valor) {
      if (valor == null) return;
      if (valor is Iterable) {
        final lista = valor.map((e) => e.toString()).toList();
        if (lista.isNotEmpty) resultado[llave] = lista;
      } else {
        resultado[llave] = valor.toString();
      }
    });

    return resultado.isEmpty ? null : resultado;
  }

  void dispose() => _cliente.close();
}
