import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'http_support.dart';

/// The device's real location, with user-facing reasons when unavailable.
class LocationService {
  Future<LatLng> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const ServiceException('Location is turned off on this device.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw const ServiceException('Location permission was not granted.');
    }
    try {
      final p = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 15));
      return LatLng(p.latitude, p.longitude);
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return LatLng(last.latitude, last.longitude);
      throw const ServiceException('Could not get your location. Please try again.');
    }
  }
}
