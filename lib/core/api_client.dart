import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

/// Error coming from the backend in the API's standard format:
/// { "error": { "code": "...", "message": "...", "details": {} } }
class ApiException implements Exception {
  ApiException({
    required this.status,
    required this.code,
    required this.message,
  });

  final int status;
  final String code;
  final String message;

  /// 422: we sent parameters the backend doesn't recognize or accept.
  /// Almost always means a query param name doesn't match the contract.
  /// See AGENTS.md → "API contract".
  bool get isInvalidParams => code == 'invalid_params';

  @override
  String toString() => 'ApiException($status, $code): $message';
}

/// Network error: no connection, timeout, unreachable host.
class NetworkException implements Exception {
  NetworkException(this.message);
  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// GET against the API.
  ///
  /// [query] is sent as-is: keys MUST be snake_case because that's how the
  /// backend contract is defined. Values are converted to String; a list is
  /// sent by repeating the key (?category=a&category=b).
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final uri = Uri.parse('${Config.apiBaseUrl}$path').replace(
      queryParameters: _normalizeQuery(query),
    );

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(Config.timeout);
    } catch (error) {
      throw NetworkException('Could not connect to the server.');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      final error = body['error'] as Map<String, dynamic>? ?? const {};
      throw ApiException(
        status: response.statusCode,
        code: error['code'] as String? ?? 'unknown',
        message: error['message'] as String? ?? 'Unexpected server error.',
      );
    }

    return body;
  }

  Map<String, dynamic>? _normalizeQuery(Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return null;

    final result = <String, dynamic>{};
    query.forEach((key, value) {
      if (value == null) return;
      if (value is Iterable) {
        final list = value.map((e) => e.toString()).toList();
        if (list.isNotEmpty) result[key] = list;
      } else {
        result[key] = value.toString();
      }
    });

    return result.isEmpty ? null : result;
  }

  void dispose() => _client.close();
}
