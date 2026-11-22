import 'dart:math';

/// High-performance GeoHash encoder, bounding-box generator, and Haversine distance calculator.
/// Enables Firestore range queries for geo-spatial radius searching without relying on full-table scans.
class GeohashHelper {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Encodes latitude and longitude into a Base32 Geohash string of given precision.
  /// Precision 5 ~ 4.9 km x 4.9 km; Precision 6 ~ 1.2 km x 0.6 km.
  static String encode(double latitude, double longitude, {int precision = 6}) {
    List<double> latInterval = [-90.0, 90.0];
    List<double> lonInterval = [-180.0, 180.0];

    final buffer = StringBuffer();
    bool isEven = true;
    int bit = 0;
    int ch = 0;

    while (buffer.length < precision) {
      double mid;
      if (isEven) {
        mid = (lonInterval[0] + lonInterval[1]) / 2;
        if (longitude > mid) {
          ch |= (1 << (4 - bit));
          lonInterval[0] = mid;
        } else {
          lonInterval[1] = mid;
        }
      } else {
        mid = (latInterval[0] + latInterval[1]) / 2;
        if (latitude > mid) {
          ch |= (1 << (4 - bit));
          latInterval[0] = mid;
        } else {
          latInterval[1] = mid;
        }
      }

      isEven = !isEven;
      if (bit < 4) {
        bit++;
      } else {
        buffer.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }

    return buffer.toString();
  }

  /// Calculates the Haversine distance between two coordinates in kilometers.
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180.0);

  /// Returns geohash query prefixes matching the requested radius.
  /// 1-5 km: prefix length 5 (~4.9 km blocks)
  /// 5-15 km: prefix length 4 (~39 km blocks, then client-filtered with Haversine)
  static int getPrecisionForRadius(double radiusKm) {
    if (radiusKm <= 1.5) return 6;
    if (radiusKm <= 5.0) return 5;
    return 4;
  }
}
