import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/countdown_formatter.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../provider_dashboard/data/models/food_listing_model.dart';
import '../controllers/receiver_feed_controller.dart';
import '../widgets/food_feed_card.dart';
import '../widgets/smart_filter_sheet.dart';
import '../widgets/urgency_map_marker.dart';
import 'food_detail_claim_screen.dart';

class DualViewMapFeedScreen extends ConsumerStatefulWidget {
  const DualViewMapFeedScreen({super.key});

  @override
  ConsumerState<DualViewMapFeedScreen> createState() => _DualViewMapFeedScreenState();
}

class _DualViewMapFeedScreenState extends ConsumerState<DualViewMapFeedScreen> {
  bool _showMapView = true;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(filteredFoodListingsProvider);
    final userProfile = ref.watch(userProfileStreamProvider).value;

    final userLat = userProfile?.location?.latitude ?? 12.9716;
    final userLng = userProfile?.location?.longitude ?? 77.5946;
    final initialCameraPosition = CameraPosition(
      target: LatLng(userLat, userLng),
      zoom: 13.5,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Rescue Feed & Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Filter listings',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const SmartFilterSheet(),
              );
            },
          ),
          IconButton(
            icon: Icon(_showMapView ? Icons.view_list_rounded : Icons.map_rounded),
            tooltip: _showMapView ? 'Switch to List' : 'Switch to Map',
            onPressed: () {
              setState(() => _showMapView = !_showMapView);
            },
          ),
        ],
      ),
      body: listingsAsync.when(
        data: (listings) {
          _updateMarkers(listings);

          if (_showMapView) {
            return Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: initialCameraPosition,
                  onMapCreated: (ctrl) => _mapController = ctrl,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                ),

                // Floating Urgency Legend & Quick Stats
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegendItem(AppColors.urgencyCritical, '< 1h (Urgent)'),
                        _buildLegendItem(AppColors.urgencyWarning, '1-3h left'),
                        _buildLegendItem(AppColors.urgencySafe, '> 3h left'),
                      ],
                    ),
                  ),
                ),

                // Floating horizontal card carousel at bottom
                if (listings.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: listings.length,
                      itemBuilder: (context, index) {
                        final item = listings[index];
                        return SizedBox(
                          width: 310,
                          child: FoodFeedCard(
                            listing: item,
                            userLat: userLat,
                            userLng: userLng,
                            onTap: () => _openDetail(item),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          } else {
            // Real-time List View
            if (listings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.no_meals_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('No surplus food found matching your filters.'),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        ref.read(receiverFilterProvider.notifier).reset();
                      },
                      child: const Text('Reset Filters'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                final item = listings[index];
                return FoodFeedCard(
                  listing: item,
                  userLat: userLat,
                  userLng: userLng,
                  onTap: () => _openDetail(item),
                );
              },
            );
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Future<void> _updateMarkers(List<FoodListingModel> listings) async {
    final markers = <Marker>{};

    for (final item in listings) {
      final urgency = CountdownFormatter.getUrgency(item.bestBefore);
      final icon = await UrgencyMapMarkerHelper.getUrgencyMarkerIcon(urgency);

      markers.add(
        Marker(
          markerId: MarkerId(item.id),
          position: LatLng(item.location.latitude, item.location.longitude),
          icon: icon,
          infoWindow: InfoWindow(
            title: item.title,
            snippet: '${item.remainingQuantity.value} ${item.totalQuantity.unit} • ${CountdownFormatter.formatRemaining(item.bestBefore)}',
            onTap: () => _openDetail(item),
          ),
        ),
      );
    }

    if (mounted) {
      setState(() => _markers = markers);
    }
  }

  void _openDetail(FoodListingModel item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FoodDetailClaimScreen(listing: item),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
