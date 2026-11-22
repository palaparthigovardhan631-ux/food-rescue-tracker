import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/geohash_helper.dart';
import '../../provider_dashboard/data/models/food_listing_model.dart';
import '../../provider_dashboard/presentation/widgets/live_countdown_badge.dart';

class FoodFeedCard extends StatelessWidget {
  final FoodListingModel listing;
  final double userLat;
  final double userLng;
  final VoidCallback onTap;

  const FoodFeedCard({
    super.key,
    required this.listing,
    required this.userLat,
    required this.userLng,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final distanceKm = GeohashHelper.calculateDistanceKm(
      userLat,
      userLng,
      listing.location.latitude,
      listing.location.longitude,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  listing.imageUrl.isNotEmpty
                      ? listing.imageUrl
                      : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.fastfood, size: 48),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.navigation, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '${distanceKm.toStringAsFixed(1)} km away',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: LiveCountdownBadge(bestBefore: listing.bestBefore),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          listing.category.name.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          listing.providerName,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (listing.hygieneDeclaration)
                        const Row(
                          children: [
                            Icon(Icons.verified, size: 14, color: AppColors.primary),
                            SizedBox(width: 2),
                            Text('Hygiene Verified', style: TextStyle(fontSize: 10, color: AppColors.primary)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available: ${listing.remainingQuantity.value} ${listing.remainingQuantity.unit}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Row(
                        children: [
                          Text('Claim Food', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                          Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
