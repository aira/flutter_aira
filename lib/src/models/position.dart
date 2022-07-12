
import 'package:location/location.dart';

class Position {
  /// Constructs an instance with the given values for testing. [Position]
  /// instances constructed this way won't actually reflect any real information
  /// from the platform, just whatever was passed in at construction time.
  const Position({
    required this.longitude,
    required this.latitude,
    required this.timestamp,
    required this.accuracy,
    required this.verticalAccuracy,
    required this.altitude,
    required this.heading,
    required this.speed,
    required this.speedAccuracy,
    this.headingAccuracy,
  });

  Position.fromLocationData(LocationData position) :
        longitude = position.longitude,
        latitude = position.latitude,
        timestamp = null == position.time ? null : DateTime.fromMillisecondsSinceEpoch(position.time!.round()),
        accuracy = position.accuracy,
        altitude = position.altitude,
        heading = position.heading,
        headingAccuracy = position.headingAccuracy,
        speed = position.speed,
        speedAccuracy = position.speedAccuracy,
        verticalAccuracy = position.verticalAccuracy;


  /// The latitude of this position in degrees normalized to the interval -90.0
  /// to +90.0 (both inclusive).
  final double? latitude;

  /// The longitude of the position in degrees normalized to the interval -180
  /// (exclusive) to +180 (inclusive).
  final double? longitude;

  /// The time at which this position was determined.
  final DateTime? timestamp;

  /// The altitude of the device in meters.
  ///
  /// The altitude is not available on all devices. In these cases the returned
  /// value is 0.0.
  final double? altitude;

  /// Estimated horizontal accuracy of this location, radial, in meters
  ///
  /// Always 0 on Web
  final double? accuracy;

  /// Estimated vertical accuracy of this location, in meters.
  final double? verticalAccuracy;

  /// The heading in which the device is traveling in degrees.
  ///
  /// The heading is not available on all devices. In these cases the value is
  /// 0.0.
  final double? heading;

  /// The floor specifies the floor of the building on which the device is
  /// located.
  ///
  /// The floor property is only available on iOS and only when the information
  /// is available. In all other cases this value will be null.
  final double? headingAccuracy;

  /// The speed at which the devices is traveling in meters per second over
  /// ground.
  ///
  /// The speed is not available on all devices. In these cases the value is
  /// 0.0.
  final double? speed;

  /// The estimated speed accuracy of this position, in meters per second.
  ///
  /// The speedAccuracy is not available on all devices. In these cases the
  /// value is 0.0.
  final double? speedAccuracy;
}
