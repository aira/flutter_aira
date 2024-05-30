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
    test('should throw PlatformInvalidTokenException on KN-UM-056 error',
        () async {
      final httpClient = MockClient((request) async {
        return Response(
          jsonEncode({
            'response': {'errorCode': 'KN-UM-056', 'errorMessage': ''},
          }),
          400,
        );
      });

      final platformClient = PlatformClient(platformClientConfig, httpClient);
      try {
        await platformClient.loginWithToken('testToken', 1234);
        fail('');
      } on PlatformInvalidTokenException catch (_) {
        // Success.
      }
    });

    test('should throw PlatformInvalidTokenException on user ID mismatch',
        () async {
      final httpClient = MockClient((request) async {
        return Response(
          jsonEncode({
            'response': {'status': 'SUCCESS'},
            'userId': 5678, // Different user ID.
          }),
          200,
        );
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
          200,
        );
      });

      final platformClient = PlatformClient(platformClientConfig, httpClient);
      final userLogin = await platformClient.loginWithToken('testToken', 1234);
      expect('testToken', userLogin.token);
      expect(1234, userLogin.userId);
    });
  });

  group('Position', () {
    // 36.00282558105645, -78.93345583177252
    // 36.00404070162735, -78.93306959369106
    //
    // according to Google, this is 474.08 ft or 144.4996 meters from each other, but we get 139.5 meters...
    // is this close enough for now? Yes!
    test('Calculated Distance', () {
      var now = DateTime.now();
      var p1 = Position(
        latitude: 36.00282558105645,
        longitude: -78.93345583177252,
        timestamp: now.subtract(const Duration(seconds: 10)),
      );
      var p2 = Position(
        latitude: 36.00404070162735,
        longitude: -78.93306959369106,
        timestamp: now,
      );
      var distanceFrom = p1.distanceFrom(p2);
      expect(distanceFrom, lessThan(139.6));
      expect(distanceFrom, greaterThan(139.5));
    });
    // This test was added to confirm that the distance delta we get with Google is not an implementation issue.
    test(
        'Calculated Distance according to https://stackoverflow.com/questions/365826/calculate-distance-between-2-gps-coordinates',
        () {
      var now = DateTime.now();
      var p1 = Position(
        latitude: 51.5,
        longitude: 0,
        timestamp: now.subtract(const Duration(seconds: 10)),
      );
      var p2 = Position(latitude: 38.8, longitude: -77.1, timestamp: now);
      var distanceFrom = p1.distanceFrom(p2);
      expect(distanceFrom, lessThan(5918185.1));
      expect(distanceFrom, greaterThan(5918185.0));
    });
    // 139.5 meters in 30 seconds >>> 4.65m/s
    test('Calculated Speed', () {
      var now = DateTime.now();
      var p1 = Position(
        latitude: 36.00282558105645,
        longitude: -78.93345583177252,
        timestamp: now.subtract(const Duration(seconds: 30)),
      );
      var p2 = Position(
        latitude: 36.00404070162735,
        longitude: -78.93306959369106,
        timestamp: now,
      );
      var speed1 = p1.speedFrom(p2);
      var speed2 = p2.speedFrom(p1);
      expect(speed1, greaterThan(4));
      expect(speed1, lessThan(5));
      expect(speed1, equals(speed2));
    });
    test('Same timestamp could cause a division by zero', () {
      var now = DateTime.now();
      var p1 = Position(
        latitude: 36.00282558105645,
        longitude: -78.93345583177252,
        timestamp: now,
      );
      var p2 = Position(
        latitude: 36.00404070162735,
        longitude: -78.93306959369106,
        timestamp: now,
      );
      var speed = p1.speedFrom(p2);
      expect(speed, equals(-1));
    });
  });
}
