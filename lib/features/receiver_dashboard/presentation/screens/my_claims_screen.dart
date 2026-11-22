import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/routing_service.dart';
import '../../../../core/utils/countdown_formatter.dart';
import '../controllers/claim_controller.dart';
import '../controllers/receiver_feed_controller.dart';
import '../data/models/claim_model.dart';
import 'turn_by_turn_navigation_screen.dart';

class MyClaimsScreen extends ConsumerWidget {
  const MyClaimsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimsAsync = ref.watch(userClaimsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Food Claims & Pickup Codes'),
      ),
      body: claimsAsync.when(
        data: (claims) {
          if (claims.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No food claims yet. Explore surplus food on the map!'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: claims.length,
            itemBuilder: (context, index) {
              final claim = claims[index];
              return _buildClaimCard(context, ref, claim);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildClaimCard(BuildContext context, WidgetRef ref, ClaimModel claim) {
    final isLocked = claim.status == ClaimStatus.locked;
    final isPickedUp = claim.status == ClaimStatus.pickedUp;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    claim.foodTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPickedUp
                        ? Colors.green.shade100
                        : (isLocked ? Colors.amber.shade100 : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPickedUp ? 'PICKED UP' : (isLocked ? '30-MIN HOLD' : claim.status.name.toUpperCase()),
                    style: TextStyle(
                      color: isPickedUp ? Colors.green.shade900 : (isLocked ? Colors.amber.shade900 : Colors.grey.shade800),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Provider: ${claim.providerName}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            Text(
              'Portion: ${claim.claimedQuantity.value} ${claim.claimedQuantity.unit}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const Divider(height: 24),

            if (isLocked) ...[
              // 30-Minute Hold Countdown Banner
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pickup Window: ${CountdownFormatter.formatRemaining(claim.lockedUntil)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4-Digit Handover OTP & QR Code Presentation
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Present this 4-Digit Code to Provider at Pickup:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: Text(
                        claim.verificationOtp,
                        style: const TextStyle(
                          fontSize: 32,
                          letterSpacing: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // QR Code
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: QrImageView(
                        data: claim.qrCodeData,
                        version: QrVersions.auto,
                        size: 120.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Navigation & Cancel Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        RoutingService.launchTurnByTurnNavigation(
                          destinationLat: claim.pickupLat,
                          destinationLng: claim.pickupLng,
                          destinationTitle: claim.providerName,
                        );
                      },
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Start Navigation'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.map_outlined, color: AppColors.primary),
                    tooltip: 'In-app Map',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TurnByTurnNavigationScreen(claim: claim),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    tooltip: 'Release Claim',
                    onPressed: () {
                      ref.read(claimControllerProvider.notifier).cancelClaim(claim.id);
                    },
                  ),
                ],
              ),
            ] else if (isPickedUp) ...[
              const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                  SizedBox(width: 6),
                  Text('Successfully Rescued & Picked Up!'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
