
import 'package:flutter/foundation.dart';
import 'package:flutter_aira/src/models/position.dart';
import 'package:geolocator/geolocator.dart' as g;
import 'package:logging/logging.dart';

Logger _log = Logger('GeolocatorExtension');

class GeolocationAbstraction {
  static Future<Position?> conditionallyGetCurrentPosition() async {
    if(await hasGeolocationPermission()) {
      _log.info('Sending location with service request');
      return Position.fromGeolocatorPlugin(await g.Geolocator.getCurrentPosition(desiredAccuracy: g.LocationAccuracy.best));
    }

    return null;
  }

  static Future<Stream<Position>?> conditionallyGetPositionStream() async {
    if(await hasGeolocationPermission()) {
      _log.info('Sending location with service request');
      g.LocationSettings locationSettings = const g.LocationSettings(
        accuracy: kIsWeb ? g.LocationAccuracy.low : g.LocationAccuracy.best,
        distanceFilter: kIsWeb ? 100 : 10, // In meters... good old meters I do miss you!
        timeLimit: Duration(seconds: kIsWeb ? 60 : 20), // In seconds.
      );
      return g.Geolocator.getPositionStream(locationSettings: locationSettings).map(Position.fromGeolocatorPlugin);
    }
    return null;
  }

  static Future<bool> hasGeolocationPermission() async {
    bool isGeolocationEnabled = await g.Geolocator.isLocationServiceEnabled();
    if(isGeolocationEnabled) {
      g.LocationPermission permission = await g.Geolocator.checkPermission();
      if(g.LocationPermission.denied == permission) {
        permission = await g.Geolocator.requestPermission();
      }

      if({g.LocationPermission.always, g.LocationPermission.whileInUse}.contains(permission)) {
        return true;
      } else {
        _log.warning('We don\'t have the permission to get position: $permission');
      }
    } else {
      _log.warning('Geolocation is not enabled');
    }

    return false;
  }
}