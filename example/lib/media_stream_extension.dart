import 'package:flutter_webrtc/flutter_webrtc.dart';

extension MediaStreamExtension on MediaStream {
  Future<void> disposeTracks() async => await Future.wait(
        getTracks()
            .map((MediaStreamTrack track) => track.stop())
            .toList(growable: false),
      );

  Future<void> disposeMediaStream() async {
    await disposeTracks();
    await dispose();
  }
}
