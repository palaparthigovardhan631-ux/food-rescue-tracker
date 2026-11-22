import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/routing_service.dart';
import '../data/models/claim_model.dart';

class TurnByTurnNavigationScreen extends StatelessWidget {
  final ClaimModel claim;

  const TurnByTurnNavigationScreen({super.key, required this.claim});

  @override
  Widget build(BuildContext context) {
    final destination = LatLng(claim.pickupLat, claim.pickupLng);

    return Scaffold(
      appBar: AppBar(
        title: Text('Route to ${claim.providerName}'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: destination,
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('pickup_destination'),
                position: destination,
                infoWindow: InfoWindow(
                  title: claim.providerName,
                  snippet: claim.pickupAddress,
                ),
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      claim.providerName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      claim.pickupAddress,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () {
                        RoutingService.launchTurnByTurnNavigation(
                          destinationLat: claim.pickupLat,
                          destinationLng: claim.pickupLng,
                          destinationTitle: claim.providerName,
                        );
                      },
                      icon: const Icon(Icons.navigation),
                      label: const Text('Open in Google Maps Navigation'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
