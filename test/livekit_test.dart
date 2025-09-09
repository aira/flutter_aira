import 'package:flutter_aira/src/livekit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveKit', () {
    test('fromMap and toMap', () {
      final map = {
        'wsUrl': 'ws://localhost:7880',
        'token': 'some-token',
        'settings': {
          'global': {'dynacast': true},
          'microphone': {
            'capture': {
              'autoGainControl': true,
              'echoCancellation': true,
              'noiseSuppression': true,
              'typingNoiseSuppression': false,
              'highpassFilter': true,
              'voiceIsolation': false,
              'sampleRate': 48000
            },
            'publish': {'dtx': true, 'red': true, 'maxBitrate': 128000}
          },
          'screenShare': {
            'capture': {'width': 1920, 'height': 1080, 'maxFramerate': 30},
            'publish': {
              'maxBitrate': 3000000,
              'maxFramerate': 30,
              'codec': 'vp8',
              'degradationPreference': 'balanced',
              'simulcast': {
                'layers': [
                  {
                    'width': 1920,
                    'height': 1080,
                    'maxBitrate': 3000000,
                    'maxFramerate': 30
                  },
                  {
                    'width': 960,
                    'height': 540,
                    'maxBitrate': 800000,
                    'maxFramerate': 15
                  }
                ]
              },
              'svc': null
            }
          },
          'camera': {
            'capture': {'width': 1280, 'height': 720, 'maxFramerate': 30},
            'publish': {
              'maxBitrate': 1200000,
              'maxFramerate': 30,
              'codec': 'vp8',
              'degradationPreference': 'balanced',
              'simulcast': {
                'layers': [
                  {
                    'width': 1280,
                    'height': 720,
                    'maxBitrate': 1200000,
                    'maxFramerate': 30
                  },
                  {
                    'width': 640,
                    'height': 360,
                    'maxBitrate': 400000,
                    'maxFramerate': 15
                  }
                ]
              },
              'svc': null
            }
          }
        }
      };

      final livekit = LiveKit.fromMap(map);
      expect(livekit.toMap(), map);
    });
  });

  group('LiveKitSettings', () {
    test('fromMap and toMap', () {
      final map = {
        'global': {'dynacast': true},
        'microphone': {
          'capture': {
            'autoGainControl': true,
            'echoCancellation': true,
            'noiseSuppression': true,
            'typingNoiseSuppression': false,
            'highpassFilter': true,
            'voiceIsolation': false,
            'sampleRate': 48000
          },
          'publish': {'dtx': true, 'red': true, 'maxBitrate': 128000}
        },
        'screenShare': {
          'capture': {'width': 1920, 'height': 1080, 'maxFramerate': 30},
          'publish': {
            'maxBitrate': 3000000,
            'maxFramerate': 30,
            'codec': 'vp8',
            'degradationPreference': 'balanced',
            'simulcast': {
              'layers': [
                {
                  'width': 1920,
                  'height': 1080,
                  'maxBitrate': 3000000,
                  'maxFramerate': 30
                },
                {
                  'width': 960,
                  'height': 540,
                  'maxBitrate': 800000,
                  'maxFramerate': 15
                }
              ]
            },
            'svc': null
          }
        },
        'camera': {
          'capture': {'width': 1280, 'height': 720, 'maxFramerate': 30},
          'publish': {
            'maxBitrate': 1200000,
            'maxFramerate': 30,
            'codec': 'vp8',
            'degradationPreference': 'balanced',
            'simulcast': {
              'layers': [
                {
                  'width': 1280,
                  'height': 720,
                  'maxBitrate': 1200000,
                  'maxFramerate': 30
                },
                {
                  'width': 640,
                  'height': 360,
                  'maxBitrate': 400000,
                  'maxFramerate': 15
                }
              ]
            },
            'svc': null
          }
        }
      };

      final settings = LiveKitSettings.fromMap(map);
      expect(settings.toMap(), map);
    });
  });
}
