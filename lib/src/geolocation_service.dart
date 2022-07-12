import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_aira/src/models/position.dart';
import 'package:location/location.dart';
import 'package:logging/logging.dart';

/// This abstraction over the GPS Location Provider is meant to:
///   1- allow "aira-flutter SDK" users to use the same library this sdk is using
///   2- allow control over when the GPS permissions are requested
///   3- simplify the use of the GPS
///   4- allow non breaking change of the SDK in the event we would change the GPS Location Provider
class GeolocationService {
  static final Logger _log = Logger('GeolocationService');

  /// Both [intervalInMilliseconds] and [distanceFilterInMeter] allows to filter the amount of notifications generated
  /// from [conditionallyGetPositionStream]'s stream. By default we will notify of a GPS location update only if the
  /// location moves of 3 meters or more or if the location didn't change for 10 seconds or more.
  /// For more information, please refer to: https://pub.dev/packages/location#public-methods-summary
  GeolocationService({double? distanceFilterInMeter = 3, int? intervalInMilliseconds = 10000}) {
    _location.changeSettings(
      distanceFilter: distanceFilterInMeter, // in meters
      accuracy: kIsWeb ? LocationAccuracy.low : LocationAccuracy.high,
      interval: intervalInMilliseconds, // in milliseconds
    );
  }

  final Location _location = Location();
  late FutureOr<bool> hasGeolocationPermission = _requestGeolocationPermission();

  /// Asks for localization permissions. This is done automatically once when you call either
  /// [conditionallyGetCurrentPosition] or [conditionallyGetPositionStream].
  /// If you want to ask for permission earlier or ask again, this is the function to call.
  Future<bool> requestGeolocationPermission() async {
    _log.finest('Forcing update of Permissions');
    hasGeolocationPermission = await _requestGeolocationPermission();
    return hasGeolocationPermission;
  }

  Future<bool> _requestGeolocationPermission() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        _log.warning('The user refused to enable the GPS');
        return false;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        _log.warning('The user did not allow the application to use the GPS');
        return false;
      }
    }

    return true;
  }

  /// Returns Position if we have the proper authorization to do so.
  /// If we don't have authorization and we haven't asked before, this function will ask for permissions.
  Future<Position?> conditionallyGetCurrentPosition() async {
    if (await hasGeolocationPermission) {
      return Position.fromLocationData(await _location.getLocation());
    }

    return null;
  }

  /// Returns a stream of Positions if we have the proper authorization to do so.
  /// If we don't have authorization and we haven't asked before, this function will ask for permissions.
  Future<Stream<Position>?> conditionallyGetPositionStream() async {
    if (await hasGeolocationPermission) {
      return _location.onLocationChanged.map(Position.fromLocationData);
    }
    return null;
  }
}