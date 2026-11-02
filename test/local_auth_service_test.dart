import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_firstapp/services/api_client.dart';
import 'package:flutter_firstapp/services/local_auth_service.dart';

void main() {
  test('local account persists across service instances without plain password',
      () async {
    final store = _MemoryCredentialStore();
    final firstRun = LocalAuthService(store: store);
    await firstRun.register(
      name: 'Rani Rahmadani',
      email: 'Rani@example.com',
      password: 'safePassword123',
      passwordConfirmation: 'safePassword123',
    );

    final savedRecord = store.values.values.single;
    expect(savedRecord, isNot(contains('safePassword123')));
    final decoded = jsonDecode(savedRecord) as Map<String, dynamic>;
    expect(decoded['verifier'], isNotEmpty);
    expect(decoded['salt'], isNotEmpty);

    // Recreate the service as if the app had been closed and opened again.
    final reopened = LocalAuthService(store: store);
    final user = await reopened.login(
      email: 'rani@example.com',
      password: 'safePassword123',
    );
    expect(user.name, 'Rani Rahmadani');
    expect(user.email, 'rani@example.com');
    expect(user.token, isEmpty); // local prototype is not a server session

    await expectLater(
      reopened.login(email: 'rani@example.com', password: 'wrongPassword'),
      throwsA(isA<ApiException>()),
    );
    await expectLater(
      reopened.register(
        name: 'Rani Rahmadani',
        email: 'rani@example.com',
        password: 'safePassword123',
        passwordConfirmation: 'safePassword123',
      ),
      throwsA(isA<ApiException>()),
    );
  });

  test('registration rejects invalid credentials before saving', () async {
    final store = _MemoryCredentialStore();
    final auth = LocalAuthService(store: store);
    await expectLater(
      auth.register(
        name: 'Rani',
        email: 'not-an-email',
        password: 'password123',
        passwordConfirmation: 'password123',
      ),
      throwsA(isA<ApiException>()),
    );
    expect(store.values, isEmpty);
  });
}

class _MemoryCredentialStore implements CredentialStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
