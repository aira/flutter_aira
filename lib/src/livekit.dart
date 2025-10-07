import 'package:collection/collection.dart';

class LiveKit {
  final String wsUrl;
  final String token;
  final Map<String, dynamic> _rawMap;

  UnmodifiableMapView<String, dynamic> get rawMap => UnmodifiableMapView(_rawMap);

  LiveKit({
    required this.wsUrl,
    required this.token,
    required Map<String, dynamic> rawMap,
  }) : _rawMap = rawMap;

  Map<String, dynamic> toMap() {
    if (_rawMap.isNotEmpty) return _rawMap;
    return {
      'wsUrl': wsUrl,
      'token': token,
    };
  }

  factory LiveKit.fromMap(Map<String, dynamic> map) {
    return LiveKit(
      wsUrl: map['wsUrl'],
      token: map['token'],
      rawMap: map,
    );
  }
}
