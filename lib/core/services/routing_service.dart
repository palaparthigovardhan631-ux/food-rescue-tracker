import 'package:url_launcher/url_launcher.dart';

class RoutingService {
  /// Opens Google Maps Navigation app directly with turn-by-turn guidance.
  static Future<bool> launchTurnByTurnNavigation({
    required double destinationLat,
    required double destinationLng,
    String? destinationTitle,
  }) async {
    // 1. Try native Android navigation intent
    final Uri nativeNavUri = Uri.parse(
      'google.navigation:q=$destinationLat,$destinationLng&mode=d',
    );

    // 2. Web fallback intent
    final Uri webFallbackUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLng&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(nativeNavUri)) {
        return await launchUrl(nativeNavUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webFallbackUri)) {
        return await launchUrl(webFallbackUri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      print("Error launching navigation: $e");
      return false;
    }
  }
}
