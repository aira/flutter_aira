import 'dart:convert';

import 'package:flutter_aira/flutter_aira.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlatformClient', () {
    group('getExceptionFromApiResponse', () {
      test('should return null if status SUCCESS', () {
        final json = {
          'response': {'status': 'SUCCESS'},
        };
        final e = PlatformClient.getExceptionFromApiResponse(
          json: json,
          body: jsonEncode(json),
        );
        expect(e, isNull);
      });

      test(
          'should return PlatformInvalidTokenException if errorCode is SEC-001',
          () {
        final json = {
          'response': {'errorMessage': 'error-msg', 'errorCode': 'SEC-001'},
        };
        final e = PlatformClient.getExceptionFromApiResponse(
          json: json,
          body: jsonEncode(json),
        );
        expect(e, isA<PlatformInvalidTokenException>());
      });

      test(
          'should return PlatformBusinessLoginRequiredException if errorCode is AIRA-ACCESS-017 and connection is not null',
          () {
        final json = {
          'response': {
            'errorMessage': 'error-msg',
            'errorCode': 'AIRA-ACCESS-017',
          },
          'metadata': {'connection': 'some-value'},
        };
        final e = PlatformClient.getExceptionFromApiResponse(
          json: json,
          body: jsonEncode(json),
        );
        expect(e, isA<PlatformBusinessLoginRequiredException>());
        if (e is PlatformBusinessLoginRequiredException) {
          expect(e.code, 'AIRA-ACCESS-017');
          expect(e.toString(), 'error-msg');
          expect(e.connection, 'some-value');
        }

        final jsonWithEmptyConnection = {
          'response': {
            'errorMessage': 'error-msg',
            'errorCode': 'AIRA-ACCESS-017',
          },
          'metadata': {'connection': ''},
        };
        final e2 = PlatformClient.getExceptionFromApiResponse(
          json: jsonWithEmptyConnection,
          body: jsonEncode(jsonWithEmptyConnection),
        );
        expect(e2, isA<PlatformBusinessLoginRequiredException>());
        if (e2 is PlatformBusinessLoginRequiredException) {
          expect(e2.code, 'AIRA-ACCESS-017');
          expect(e2.toString(), 'error-msg');
          expect(e2.connection, isEmpty);
        }
      });

      test(
          'should return PlatformDeleteAccountException if errorCode is KN-UM-065',
          () {
        final json = {
          'response': {
            'errorCode': 'KN-UM-065',
            'errorMessage': 'error-msg',
          },
        };
        final e = PlatformClient.getExceptionFromApiResponse(
          json: json,
          body: jsonEncode(json),
        );
        expect(e, isA<PlatformDeleteAccountException>());
        if (e is PlatformDeleteAccountException) {
          expect(e.code, 'KN-UM-065');
          expect(e.toString(), 'error-msg');
        }
      });

      test(
          'should return PlatformLocalizedException if errorMessage is not empty',
          () {
        final json = {
          'response': {
            'errorCode': 'some-error-code',
            'errorMessage': 'non-empty-error-message',
          },
        };
        final e = PlatformClient.getExceptionFromApiResponse(
          json: json,
          body: jsonEncode(json),
        );
        expect(e, isA<PlatformLocalizedException>());
        if (e is PlatformLocalizedException) {
          expect(e.code, 'some-error-code');
          expect(e.toString(), 'non-empty-error-message');
        }
      });
    });

    test('should return PlatformUnknownException if status not success', () {
      final json = {
        'response': {'status': 'FAILURE'},
      };
      final e = PlatformClient.getExceptionFromApiResponse(
        json: json,
        body: jsonEncode(json),
      );
      expect(e, isA<PlatformUnknownException>());
      if (e is PlatformUnknownException) {
        final body = jsonEncode(json);
        expect(e.toString(), 'Platform returned unexpected body: $body');
      }
    });
  });
}
