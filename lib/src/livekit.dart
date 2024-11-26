class LiveKit {
  final String wsUrl;
  final String token;

  LiveKit({required this.wsUrl, required this.token});

  Map<String, dynamic> toMap() {
    return {
      'wsUrl': wsUrl,
      'token': token,
    };
  }

  factory LiveKit.fromMap(Map map) {
    return LiveKit(
      wsUrl: map['wsUrl'],
      token: map['token'],
    );
  }
}
