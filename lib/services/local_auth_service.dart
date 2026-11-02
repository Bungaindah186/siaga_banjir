import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cryptography/cryptography.dart' as web_crypto;

import 'api_client.dart';

/// Storage seam allows local-auth behavior to be tested without platform APIs.
abstract interface class CredentialStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            webOptions: WebOptions(useSessionStorage: false),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

/// Prototyping-only local accounts. Replace with Laravel authentication later.
/// Passwords are never saved; only a salted PBKDF2-HMAC-SHA256 verifier is.
class LocalAuthService {
  LocalAuthService({CredentialStore? store})
    : _store = store ?? SecureCredentialStore();

  final CredentialStore _store;
  static const _iterations = 120000;
  static const _saltLength = 16;
  static const _derivedKeyLength = 32;

  String _keyFor(String email) =>
      'local_auth.user.${base64Url.encode(utf8.encode(email.trim().toLowerCase()))}';

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (name.trim().length < 2 || !_looksLikeEmail(normalizedEmail)) {
      throw const ApiException('Nama atau email tidak valid.');
    }
    if (password.length < 8 || password != passwordConfirmation) {
      throw const ApiException('Kata sandi atau konfirmasinya tidak valid.');
    }

    try {
      final storageKey = _keyFor(normalizedEmail);
      if (await _store.read(storageKey) != null) {
        throw const ApiException('Email ini sudah terdaftar di perangkat.');
      }
      final random = Random.secure();
      final salt = List<int>.generate(_saltLength, (_) => random.nextInt(256));
      final verifier = await _derivePasswordVerifier(password, salt);
      await _store.write(
        storageKey,
        jsonEncode({
          'id': normalizedEmail.hashCode & 0x7fffffff,
          'name': name.trim(),
          'email': normalizedEmail,
          'salt': base64Url.encode(salt),
          'verifier': base64Url.encode(verifier),
          'iterations': _iterations,
        }),
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Akun tidak dapat disimpan dengan aman di perangkat ini.',
      );
    }
  }

  Future<AuthenticatedUser> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final encoded = await _store.read(_keyFor(normalizedEmail));
      if (encoded == null) {
        throw const ApiException('Email atau kata sandi salah.');
      }
      final saved = jsonDecode(encoded) as Map<String, dynamic>;
      final salt = base64Url.decode(saved['salt'] as String);
      final expected = base64Url.decode(saved['verifier'] as String);
      final iterations = saved['iterations'] as int;
      final actual = await _derivePasswordVerifier(
        password,
        salt,
        iterations: iterations,
      );
      if (!_constantTimeEquals(actual, expected)) {
        throw const ApiException('Email atau kata sandi salah.');
      }
      return AuthenticatedUser(
        id: saved['id'] as int,
        name: saved['name'] as String,
        email: saved['email'] as String,
        token: '',
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Penyimpanan akun lokal tidak dapat dibaca. Coba lagi.',
      );
    }
  }

  static bool _looksLikeEmail(String email) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

  static Future<List<int>> _derivePasswordVerifier(
    String password,
    List<int> salt, {
    int iterations = _iterations,
  }) {
    if (kIsWeb) {
      return _deriveWithBrowserCrypto(password, salt, iterations);
    }
    return Isolate.run(
      () => _pbkdf2(password, salt, iterations, _derivedKeyLength),
    );
  }

  static Future<List<int>> _deriveWithBrowserCrypto(
    String password,
    List<int> salt,
    int iterations,
  ) async => (await web_crypto.Pbkdf2(
    macAlgorithm: web_crypto.Hmac.sha256(),
    iterations: iterations,
    bits: _derivedKeyLength * 8,
  ).deriveKeyFromPassword(password: password, nonce: salt)).extractBytes();

  static List<int> _pbkdf2(
    String password,
    List<int> salt,
    int iterations,
    int outputLength,
  ) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final blockIndex = [0, 0, 0, 1];
    var u = hmac.convert([...salt, ...blockIndex]).bytes;
    final result = List<int>.from(u);
    for (var round = 1; round < iterations; round++) {
      u = hmac.convert(u).bytes;
      for (var i = 0; i < result.length; i++) {
        result[i] ^= u[i];
      }
    }
    return result.sublist(0, outputLength);
  }

  static bool _constantTimeEquals(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var i = 0; i < left.length; i++) {
      difference |= left[i] ^ right[i];
    }
    return difference == 0;
  }
}
