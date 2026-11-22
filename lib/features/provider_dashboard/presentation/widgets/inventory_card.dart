import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../data/models/food_listing_model.dart';
import 'live_countdown_badge.dart';

class InventoryCard extends StatelessWidget {
  final FoodListingModel listing;
  final Function(ListingStatus) onStatusChange;

  const InventoryCard({
    super.key,
    required this.listing,
    required this.onStatusChange,
  });

  Color _getCategoryColor(FoodCategory cat) {
    switch (cat) {
      case FoodCategory.veg:
        return AppColors.veg;
      case FoodCategory.nonVeg:
        return AppColors.nonVeg;
      case FoodCategory.vegan:
        return AppColors.vegan;
      case FoodCategory.bakery:
        return AppColors.bakery;
    }
  }

  Color _getStatusColor(ListingStatus status) {
    switch (status) {
      case ListingStatus.available:
        return AppColors.statusAvailable;
      case ListingStatus.reserved:
        return AppColors.statusReserved;
      case ListingStatus.pickedUp:
        return AppColors.statusPickedUp;
      case ListingStatus.expired:
      case ListingStatus.cancelled:
        return AppColors.statusExpired;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(listing.category);
    final statusColor = _getStatusColor(listing.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(
                listing.imageUrl.isNotEmpty
                    ? listing.imageUrl
                    : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.fastfood, size: 40)),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: catColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    listing.category.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        listing.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        listing.status.name.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Remaining: ${listing.remainingQuantity.value} / ${listing.totalQuantity.value} ${listing.totalQuantity.unit}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    if (listing.allowsPartialClaims) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Partial Claim Allowed',
                          style: TextStyle(fontSize: 10, color: Colors.teal),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Quick Action:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const Spacer(),
                    if (listing.status == ListingStatus.available)
                      TextButton.icon(
                        onPressed: () => onStatusChange(ListingStatus.reserved),
                        icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                        label: const Text('Mark Reserved', style: TextStyle(fontSize: 12)),
                      )
                    else if (listing.status == ListingStatus.reserved)
                      TextButton.icon(
                        onPressed: () => onStatusChange(ListingStatus.available),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Reopen Available', style: TextStyle(fontSize: 12)),
                      ),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                      tooltip: 'Cancel Listing',
                      onPressed: () => onStatusChange(ListingStatus.cancelled),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
