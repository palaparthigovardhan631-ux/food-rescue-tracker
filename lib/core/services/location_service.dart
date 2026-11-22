import 'package:geolocator/geolocator.dart';
import '../utils/geohash_helper.dart';

class UserLocation {
  final double latitude;
  final double longitude;
  final String geohash;

  UserLocation({
    required this.latitude,
    required this.longitude,
    required this.geohash,
  });

  Map<String, dynamic> toMap() {
    return {
      'lat': latitude,
      'lng': longitude,
      'geohash': geohash,
    };
  }

  factory UserLocation.fromMap(Map<String, dynamic> map) {
    return UserLocation(
      latitude: (map['lat'] as num).toDouble(),
      longitude: (map['lng'] as num).toDouble(),
      geohash: map['geohash'] as String,
    );
  }
}

class LocationService {
  /// Determines the current position with permission handling.
  static Future<UserLocation> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Default fallback location (e.g. City Center) if disabled for testing
      return _getDefaultLocation();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return _getDefaultLocation();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return _getDefaultLocation();
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      final hash = GeohashHelper.encode(position.latitude, position.longitude);
      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        geohash: hash,
      );
    } catch (_) {
      return _getDefaultLocation();
    }
  }

  static UserLocation _getDefaultLocation() {
    // Default fallback coordinates (e.g. Urban Center: 12.9716, 77.5946)
    const lat = 12.9716;
    const lng = 77.5946;
    return UserLocation(
      latitude: lat,
      longitude: lng,
      geohash: GeohashHelper.encode(lat, lng),
    );
  }
}
