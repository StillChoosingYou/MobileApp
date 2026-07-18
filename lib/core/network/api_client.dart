import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/local/hive_service.dart';

/// Thin REST client for your own Flask + Postgres (Supabase) backend — see
/// `api/` at the project root. Used only by the repositories in
/// `lib/data/repositories/api_repositories.dart`, which only run when
/// `AppConfig.backendMode == BackendMode.restApi`.
class ApiClient {
  ApiClient._();

  /// Where the Flask API lives. Override at build/run time instead of
  /// editing this file, so you don't have to touch source to point at a
  /// different environment:
  ///
  ///   flutter run --dart-define=PGPC_API_BASE_URL=https://your-project.vercel.app/api
  ///
  /// Defaults to `10.0.2.2` — the special address the **Android emulator**
  /// uses to reach your computer's `localhost`. Override it for other
  /// targets:
  ///   - iOS Simulator / macOS / Windows / Linux desktop: `http://localhost:5000/api`
  ///   - A physical phone on the same Wi-Fi as your computer: `http://<your-computer's-LAN-IP>:5000/api`
  ///   - Production: your deployed Vercel URL, e.g. `https://pgpc-campus-api.vercel.app/api`
  static const String baseUrl = String.fromEnvironment(
    'PGPC_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );

  static const _tokenKey = 'jwt';

  static String? get _token => HiveService.session.get(_tokenKey) as String?;

  static void saveToken(String token) => HiveService.session.put(_tokenKey, token);

  static void clearToken() => HiveService.session.delete(_tokenKey);

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final http.Response response;
    try {
      response = await http.get(uri, headers: _headers);
    } catch (_) {
      throw ApiException(
        'Could not reach the server. Check that the Flask API is running and '
        'ApiClient.baseUrl ($baseUrl) is reachable from this device.',
      );
    }
    return _decode(response);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body),
      );
    } catch (_) {
      throw ApiException(
        'Could not reach the server. Check that the Flask API is running and '
        'ApiClient.baseUrl ($baseUrl) is reachable from this device.',
      );
    }
    return _decode(response);
  }

  static dynamic _decode(http.Response response) {
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message = (decoded is Map && decoded['error'] is String)
        ? decoded['error'] as String
        : 'Request failed (HTTP ${response.statusCode}).';
    throw ApiException(message);
  }
}

/// Thrown by [ApiClient] on any non-2xx response or network failure. The
/// [message] is already suitable to show directly to the person (it's
/// either the Flask API's own `{"error": "..."}` body, or a plain-language
/// connectivity failure).
class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
