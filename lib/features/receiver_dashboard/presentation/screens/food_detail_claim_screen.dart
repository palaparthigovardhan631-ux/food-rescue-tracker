import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../provider_dashboard/data/models/food_listing_model.dart';
import '../../provider_dashboard/presentation/widgets/live_countdown_badge.dart';
import '../controllers/claim_controller.dart';
import 'my_claims_screen.dart';

class FoodDetailClaimScreen extends ConsumerStatefulWidget {
  final FoodListingModel listing;

  const FoodDetailClaimScreen({super.key, required this.listing});

  @override
  ConsumerState<FoodDetailClaimScreen> createState() => _FoodDetailClaimScreenState();
}

class _FoodDetailClaimScreenState extends ConsumerState<FoodDetailClaimScreen> {
  late double _claimedQuantity;

  @override
  void initState() {
    super.initState();
    // Default claim quantity
    _claimedQuantity = widget.listing.allowsPartialClaims
        ? (widget.listing.remainingQuantity.value > 5 ? 5.0 : widget.listing.remainingQuantity.value)
        : widget.listing.remainingQuantity.value;
  }

  Future<void> _handleClaim() async {
    final controller = ref.read(claimControllerProvider.notifier);
    final claim = await controller.claimListing(
      listingId: widget.listing.id,
      quantityToClaim: _claimedQuantity,
    );

    if (claim != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primary,
          content: Text('🎉 Food claimed successfully! 30-minute pickup window activated.'),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MyClaimsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final claimState = ref.watch(claimControllerProvider);
    final listing = widget.listing;

    return Scaffold(
      appBar: AppBar(
        title: Text(listing.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header
            Stack(
              children: [
                Image.network(
                  listing.imageUrl.isNotEmpty
                      ? listing.imageUrl
                      : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 240,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.fastfood, size: 64),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: LiveCountdownBadge(bestBefore: listing.bestBefore),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Category
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          listing.category.name.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Provider Details Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.storefront, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.providerName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                listing.address,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time Information
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Prepared: ${DateFormat('hh:mm a').format(listing.preparedAt)}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                      const Spacer(),
                      const Icon(Icons.timer_outlined, size: 16, color: Colors.red),
                      const SizedBox(width: 6),
                      Text(
                        'Expiry: ${DateFormat('hh:mm a').format(listing.bestBefore)}',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  // Hygiene Guarantee
                  if (listing.hygieneDeclaration)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Provider Food-Safety Pledge: Handled in accordance with hygiene safety guidelines.',
                              style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Available Quantity
                  Text(
                    'Available Surplus: ${listing.remainingQuantity.value} ${listing.remainingQuantity.unit}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  // Partial Claims Adjustment (if enabled)
                  if (listing.allowsPartialClaims && listing.remainingQuantity.value > 1) ...[
                    const Text(
                      'Select portion to claim (Partial Claim Enabled):',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _claimedQuantity,
                            min: 1.0,
                            max: listing.remainingQuantity.value,
                            divisions: listing.remainingQuantity.value.toInt() - 1,
                            label: '${_claimedQuantity.toInt()} ${listing.remainingQuantity.unit}',
                            activeColor: AppColors.primary,
                            onChanged: (val) => setState(() => _claimedQuantity = val),
                          ),
                        ),
                        Text(
                          '${_claimedQuantity.toInt()} ${listing.remainingQuantity.unit}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      'Entire batch (${listing.remainingQuantity.value} ${listing.remainingQuantity.unit}) will be reserved.',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Concurrency & 30-min hold notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_clock_outlined, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Clicking "Claim Food" holds this batch for you for 30 minutes via atomic transaction.',
                            style: TextStyle(fontSize: 12, color: Colors.brown),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (claimState.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        claimState.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  ElevatedButton(
                    onPressed: claimState.isClaiming ? null : _handleClaim,
                    child: claimState.isClaiming
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text('Claim Food (${_claimedQuantity.toInt()} ${listing.remainingQuantity.unit})'),
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
