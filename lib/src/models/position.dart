
/// Model used to carry the Position information.
///
/// If any information (other than the 3 required ones) is not available, set it to null.
class Position {
  const Position({
    required this.longitude,
    required this.latitude,
    required this.timestamp,
    this.altitude,
    this.accuracy,
    this.verticalAccuracy,
    this.heading,
    this.headingAccuracy,
    this.speed,
    this.speedAccuracy,
  });

  /// The latitude of this position in degrees normalized to the interval -90.0
  /// to +90.0 (both inclusive).
  final double latitude;

  /// The longitude of the position in degrees normalized to the interval -180
  /// (exclusive) to +180 (inclusive).
  final double longitude;

  /// The time at which this position was determined.
  final DateTime timestamp;

  /// The altitude of the device in meters.
  final double? altitude;

  /// Estimated horizontal accuracy of this location, radial, in meters
  final double? accuracy;

  /// Estimated vertical accuracy of this location, in meters.
  final double? verticalAccuracy;

  /// The heading in which the device is traveling in degrees.
  ///
  /// The heading is not available on all devices. In these cases the value should be null.
  final double? heading;

  /// The estimated bearing accuracy of this location, in degrees.
  ///
  /// In the case the accuracy is not available the value should be null.
  final double? headingAccuracy;

  /// The speed at which the devices is traveling in meters per second over
  /// ground.
  ///
  /// The speed is not available on all devices. In these cases the value should be null.
  final double? speed;

  /// The estimated speed accuracy of this position, in meters per second.
  ///
  /// The speedAccuracy is not available on all devices. In these cases the value should be null.
  final double? speedAccuracy;
}
