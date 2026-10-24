import 'dart:async';
import 'dart:convert';
import 'dart:io';

class AuthenticatedUser {
  const AuthenticatedUser({
    required this.name,
    required this.email,
    required this.token,
  });

  final String name;
  final String email;
  final String token;
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({String? baseUrl})
    : baseUrl =
          (baseUrl ??
                  const String.fromEnvironment(
                    'API_BASE_URL',
                    defaultValue: 'http://10.0.2.2:8000/api',
                  ))
              .replaceFirst(RegExp(r'/+$'), '');

  final String baseUrl;

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object?> body,
  ) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client
          .postUrl(Uri.parse('$baseUrl/$path'))
          .timeout(const Duration(seconds: 12));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.write(jsonEncode(body));
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final responseText = await utf8.decoder
          .bind(response)
          .join()
          .timeout(const Duration(seconds: 15));
      final decoded = responseText.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(responseText) as Map);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }

      final errors = decoded['errors'];
      if (errors is Map) {
        for (final messages in errors.values) {
          if (messages is List && messages.isNotEmpty) {
            throw ApiException(messages.first.toString());
          }
        }
      }
      throw ApiException(
        decoded['message']?.toString() ??
            'Permintaan gagal (HTTP ${response.statusCode}).',
      );
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa alamat API dan jaringan.',
      );
    } on HandshakeException {
      throw const ApiException(
        'Koneksi aman gagal. Periksa sertifikat HTTPS server.',
      );
    } on HttpException {
      throw const ApiException('Koneksi ke server gagal. Coba lagi.');
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons. Coba lagi.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _post('register', {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  Future<AuthenticatedUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _post('login', {
      'email': email,
      'password': password,
    });
    final data = Map<String, dynamic>.from(response['data'] as Map);
    final user = Map<String, dynamic>.from(data['user'] as Map);
    return AuthenticatedUser(
      name: user['name'].toString(),
      email: user['email'].toString(),
      token: data['token'].toString(),
    );
  }
}
