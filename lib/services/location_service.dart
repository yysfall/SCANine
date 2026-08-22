import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  final String message;
  LocationException(this.message);
  @override
  String toString() => message;
}

class LocationService {
  /// Requests permission if needed and returns the device's current
  /// position. Throws [LocationException] with a message suitable for
  /// showing directly to the user if location can't be obtained.
  static Future<Position> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationException('Location services are turned off. Please enable them to find nearby vets.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Location permission denied — enable it to find nearby vets.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException('Location permission permanently denied — enable it in system settings.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );
  }
}
