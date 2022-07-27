import 'dart:convert';

import 'package:flutter_aira/flutter_aira.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

void main() {
  final platformClientConfig = PlatformClientConfig(
    apiKey: 'testApiKey',
    clientId: 'testClientId',
    environment: PlatformEnvironment.dev,
  );

  group('loginWithToken', () {
    test('should throw PlatformInvalidTokenException on KN-UM-056 error', () async {
      final httpClient = MockClient((request) async {
        return Response(
            jsonEncode({
              'response': {'errorCode': 'KN-UM-056', 'errorMessage': ''},
            }),
            400);
      });

      final platformClient = PlatformClient(platformClientConfig, httpClient);
      try {
        await platformClient.loginWithToken('testToken', 1234);
        fail('');
      } on PlatformInvalidTokenException catch (_) {
        // Success.
      }
    });

    test('should throw PlatformInvalidTokenException on user ID mismatch', () async {
      final httpClient = MockClient((request) async {
        return Response(
            jsonEncode({
              'response': {'status': 'SUCCESS'},
              'userId': 5678, // Different user ID.
            }),
            200);
      });

      final platformClient = PlatformClient(platformClientConfig, httpClient);
      try {
        await platformClient.loginWithToken('testToken', 1234);
        fail('');
      } on PlatformInvalidTokenException catch (_) {
        // Success.
      }
    });

    test('should return UserLogin', () async {
      final httpClient = MockClient((request) async {
        expect('GET', request.method);
        expect('/api/user/login/validate-token', request.url.path);
        expect('testToken', request.headers['X-Aira-Token']);

        return Response(
            jsonEncode({
              'response': {'status': 'SUCCESS'},
              'userId': 1234,
            }),
            200);
      });

      final platformClient = PlatformClient(platformClientConfig, httpClient);
      final userLogin = await platformClient.loginWithToken('testToken', 1234);
      expect('testToken', userLogin.token);
      expect(1234, userLogin.userId);
    });
  });
}
