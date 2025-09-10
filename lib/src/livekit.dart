import 'package:collection/collection.dart';

class LiveKit {
  final String wsUrl;
  final String token;
  final LiveKitSettings settings;

  final Map<String, dynamic> _rawMap;

  UnmodifiableMapView<String, dynamic> get rawMap => UnmodifiableMapView(_rawMap);

  LiveKit({
    required this.wsUrl,
    required this.token,
    required this.settings,
    required Map<String, dynamic> rawMap,
  }) : _rawMap = rawMap;

  Map<String, dynamic> toMap() {
    return {
      'wsUrl': wsUrl,
      'token': token,
      'settings': settings.toMap(),
    };
  }

  factory LiveKit.fromMap(Map<String, dynamic> map) {
    return LiveKit(
      wsUrl: map['wsUrl'],
      token: map['token'],
      settings: LiveKitSettings.fromMap(map['settings']),
      rawMap: map,
    );
  }
}

class LiveKitSettings {
  final LiveKitGlobalSettings global;
  final LiveKitMicrophoneSettings microphone;
  final LiveKitScreenShareSettings screenShare;
  final LiveKitCameraSettings camera;

  LiveKitSettings({
    required this.global,
    required this.microphone,
    required this.screenShare,
    required this.camera,
  });

  Map<String, dynamic> toMap() {
    return {
      'global': global.toMap(),
      'microphone': microphone.toMap(),
      'screenShare': screenShare.toMap(),
      'camera': camera.toMap(),
    };
  }

  factory LiveKitSettings.fromMap(Map map) {
    return LiveKitSettings(
      global: LiveKitGlobalSettings.fromMap(map['global']),
      microphone: LiveKitMicrophoneSettings.fromMap(map['microphone']),
      screenShare: LiveKitScreenShareSettings.fromMap(map['screenShare']),
      camera: LiveKitCameraSettings.fromMap(map['camera']),
    );
  }
}

class LiveKitGlobalSettings {
  final bool dynacast;

  LiveKitGlobalSettings({required this.dynacast});

  Map<String, dynamic> toMap() {
    return {'dynacast': dynacast};
  }

  factory LiveKitGlobalSettings.fromMap(Map map) {
    return LiveKitGlobalSettings(dynacast: map['dynacast']);
  }
}

class LiveKitMicrophoneSettings {
  final LiveKitMicrophoneCaptureSettings capture;
  final LiveKitMicrophonePublishSettings publish;

  LiveKitMicrophoneSettings({required this.capture, required this.publish});

  Map<String, dynamic> toMap() {
    return {
      'capture': capture.toMap(),
      'publish': publish.toMap(),
    };
  }

  factory LiveKitMicrophoneSettings.fromMap(Map map) {
    return LiveKitMicrophoneSettings(
      capture: LiveKitMicrophoneCaptureSettings.fromMap(map['capture']),
      publish: LiveKitMicrophonePublishSettings.fromMap(map['publish']),
    );
  }
}

class LiveKitMicrophoneCaptureSettings {
  final bool autoGainControl;
  final bool echoCancellation;
  final bool noiseSuppression;
  final bool typingNoiseSuppression;
  final bool highpassFilter;
  final bool voiceIsolation;
  final int sampleRate;

  LiveKitMicrophoneCaptureSettings({
    required this.autoGainControl,
    required this.echoCancellation,
    required this.noiseSuppression,
    required this.typingNoiseSuppression,
    required this.highpassFilter,
    required this.voiceIsolation,
    required this.sampleRate,
  });

  Map<String, dynamic> toMap() {
    return {
      'autoGainControl': autoGainControl,
      'echoCancellation': echoCancellation,
      'noiseSuppression': noiseSuppression,
      'typingNoiseSuppression': typingNoiseSuppression,
      'highpassFilter': highpassFilter,
      'voiceIsolation': voiceIsolation,
      'sampleRate': sampleRate,
    };
  }

  factory LiveKitMicrophoneCaptureSettings.fromMap(Map map) {
    return LiveKitMicrophoneCaptureSettings(
      autoGainControl: map['autoGainControl'],
      echoCancellation: map['echoCancellation'],
      noiseSuppression: map['noiseSuppression'],
      typingNoiseSuppression: map['typingNoiseSuppression'],
      highpassFilter: map['highpassFilter'],
      voiceIsolation: map['voiceIsolation'],
      sampleRate: map['sampleRate'],
    );
  }
}

class LiveKitMicrophonePublishSettings {
  final bool dtx;
  final bool red;
  final int maxBitrate;

  LiveKitMicrophonePublishSettings({
    required this.dtx,
    required this.red,
    required this.maxBitrate,
  });

  Map<String, dynamic> toMap() {
    return {
      'dtx': dtx,
      'red': red,
      'maxBitrate': maxBitrate,
    };
  }

  factory LiveKitMicrophonePublishSettings.fromMap(Map map) {
    return LiveKitMicrophonePublishSettings(
      dtx: map['dtx'],
      red: map['red'],
      maxBitrate: map['maxBitrate'],
    );
  }
}

class LiveKitScreenShareSettings {
  final LiveKitScreenShareCaptureSettings capture;
  final LiveKitScreenSharePublishSettings publish;

  LiveKitScreenShareSettings({required this.capture, required this.publish});

  Map<String, dynamic> toMap() {
    return {
      'capture': capture.toMap(),
      'publish': publish.toMap(),
    };
  }

  factory LiveKitScreenShareSettings.fromMap(Map map) {
    return LiveKitScreenShareSettings(
      capture: LiveKitScreenShareCaptureSettings.fromMap(map['capture']),
      publish: LiveKitScreenSharePublishSettings.fromMap(map['publish']),
    );
  }
}

class LiveKitScreenShareCaptureSettings {
  final int width;
  final int height;
  final int maxFramerate;

  LiveKitScreenShareCaptureSettings({
    required this.width,
    required this.height,
    required this.maxFramerate,
  });

  Map<String, dynamic> toMap() {
    return {
      'width': width,
      'height': height,
      'maxFramerate': maxFramerate,
    };
  }

  factory LiveKitScreenShareCaptureSettings.fromMap(Map map) {
    return LiveKitScreenShareCaptureSettings(
      width: map['width'],
      height: map['height'],
      maxFramerate: map['maxFramerate'],
    );
  }
}

class LiveKitScreenSharePublishSettings {
  final int maxBitrate;
  final int maxFramerate;
  final String codec;
  final String degradationPreference;
  final LiveKitSimulcastSettings simulcast;
  final LiveKitSvcSettings? svc;

  LiveKitScreenSharePublishSettings({
    required this.maxBitrate,
    required this.maxFramerate,
    required this.codec,
    required this.degradationPreference,
    required this.simulcast,
    this.svc,
  });

  Map<String, dynamic> toMap() {
    return {
      'maxBitrate': maxBitrate,
      'maxFramerate': maxFramerate,
      'codec': codec,
      'degradationPreference': degradationPreference,
      'simulcast': simulcast.toMap(),
      'svc': svc?.toMap(),
    };
  }

  factory LiveKitScreenSharePublishSettings.fromMap(Map map) {
    return LiveKitScreenSharePublishSettings(
      maxBitrate: map['maxBitrate'],
      maxFramerate: map['maxFramerate'],
      codec: map['codec'],
      degradationPreference: map['degradationPreference'],
      simulcast: LiveKitSimulcastSettings.fromMap(map['simulcast']),
      svc: map['svc'] != null ? LiveKitSvcSettings.fromMap(map['svc']) : null,
    );
  }
}

class LiveKitCameraSettings {
  final LiveKitCameraCaptureSettings capture;
  final LiveKitCameraPublishSettings publish;

  LiveKitCameraSettings({required this.capture, required this.publish});

  Map<String, dynamic> toMap() {
    return {
      'capture': capture.toMap(),
      'publish': publish.toMap(),
    };
  }

  factory LiveKitCameraSettings.fromMap(Map map) {
    return LiveKitCameraSettings(
      capture: LiveKitCameraCaptureSettings.fromMap(map['capture']),
      publish: LiveKitCameraPublishSettings.fromMap(map['publish']),
    );
  }
}

class LiveKitCameraCaptureSettings {
  final int width;
  final int height;
  final int maxFramerate;

  LiveKitCameraCaptureSettings({
    required this.width,
    required this.height,
    required this.maxFramerate,
  });

  Map<String, dynamic> toMap() {
    return {
      'width': width,
      'height': height,
      'maxFramerate': maxFramerate,
    };
  }

  factory LiveKitCameraCaptureSettings.fromMap(Map map) {
    return LiveKitCameraCaptureSettings(
      width: map['width'],
      height: map['height'],
      maxFramerate: map['maxFramerate'],
    );
  }
}

class LiveKitCameraPublishSettings {
  final int maxBitrate;
  final int maxFramerate;
  final String codec;
  final String degradationPreference;
  final LiveKitSimulcastSettings simulcast;
  final LiveKitSvcSettings? svc;

  LiveKitCameraPublishSettings({
    required this.maxBitrate,
    required this.maxFramerate,
    required this.codec,
    required this.degradationPreference,
    required this.simulcast,
    this.svc,
  });

  Map<String, dynamic> toMap() {
    return {
      'maxBitrate': maxBitrate,
      'maxFramerate': maxFramerate,
      'codec': codec,
      'degradationPreference': degradationPreference,
      'simulcast': simulcast.toMap(),
      'svc': svc?.toMap(),
    };
  }

  factory LiveKitCameraPublishSettings.fromMap(Map map) {
    return LiveKitCameraPublishSettings(
      maxBitrate: map['maxBitrate'],
      maxFramerate: map['maxFramerate'],
      codec: map['codec'],
      degradationPreference: map['degradationPreference'],
      simulcast: LiveKitSimulcastSettings.fromMap(map['simulcast']),
      svc: map['svc'] != null ? LiveKitSvcSettings.fromMap(map['svc']) : null,
    );
  }
}

class LiveKitSvcSettings {
  final String scalabilityMode;
  final LiveKitSvcBackupSettings? backup;

  LiveKitSvcSettings({required this.scalabilityMode, this.backup});

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'scalabilityMode': scalabilityMode,
    };
    if (backup != null) {
      map['backup'] = backup!.toMap();
    }
    return map;
  }

  factory LiveKitSvcSettings.fromMap(Map map) {
    return LiveKitSvcSettings(
      scalabilityMode: map['scalabilityMode'],
      backup: map['backup'] != null
          ? LiveKitSvcBackupSettings.fromMap(map['backup'])
          : null,
    );
  }
}

class LiveKitSvcBackupSettings {
  final String codec;
  final bool simulcastWithMainCodec;

  LiveKitSvcBackupSettings(
      {required this.codec, required this.simulcastWithMainCodec});

  Map<String, dynamic> toMap() {
    return {
      'codec': codec,
      'simulcastWithMainCodec': simulcastWithMainCodec,
    };
  }

  factory LiveKitSvcBackupSettings.fromMap(Map map) {
    return LiveKitSvcBackupSettings(
      codec: map['codec'],
      simulcastWithMainCodec: map['simulcastWithMainCodec'],
    );
  }
}

class LiveKitSimulcastSettings {
  final List<LiveKitSimulcastLayer> layers;

  LiveKitSimulcastSettings({required this.layers});

  Map<String, dynamic> toMap() {
    return {
      'layers': layers.map((x) => x.toMap()).toList(),
    };
  }

  factory LiveKitSimulcastSettings.fromMap(Map map) {
    return LiveKitSimulcastSettings(
      layers: List<LiveKitSimulcastLayer>.from(
          map['layers']?.map((x) => LiveKitSimulcastLayer.fromMap(x))),
    );
  }
}

class LiveKitSimulcastLayer {
  final int maxBitrate;
  final int maxFramerate;
  final int width;
  final int height;

  LiveKitSimulcastLayer({
    required this.maxBitrate,
    required this.maxFramerate,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toMap() {
    return {
      'maxBitrate': maxBitrate,
      'maxFramerate': maxFramerate,
      'width': width,
      'height': height,
    };
  }

  factory LiveKitSimulcastLayer.fromMap(Map map) {
    return LiveKitSimulcastLayer(
      maxBitrate: map['maxBitrate'],
      maxFramerate: map['maxFramerate'],
      width: map['width'],
      height: map['height'],
    );
  }
}
