class Throttler {
  Throttler({this.delay = 1000});

  final int delay;
  DateTime _lastTimestamp = DateTime.fromMillisecondsSinceEpoch(0);

  DateTime get lastTimestamp => _lastTimestamp;

  bool get shouldThrottle {
    DateTime now = DateTime.now();
    if (now.difference(_lastTimestamp).inMilliseconds < delay) {
      return true;
    }
    _lastTimestamp = now;
    return false;
  }
}