import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/countdown_formatter.dart';
import '../../receiver_dashboard/data/models/claim_model.dart';
import '../controllers/provider_inventory_controller.dart';
import '../widgets/otp_verification_dialog.dart';

class ClaimHandoverScreen extends ConsumerWidget {
  const ClaimHandoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimsAsync = ref.watch(providerIncomingClaimsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Pickup Requests'),
      ),
      body: claimsAsync.when(
        data: (claims) {
          if (claims.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'No pending pickup claims at the moment.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: claims.length,
            itemBuilder: (context, index) {
              final claim = claims[index];
              final isLocked = claim.status == ClaimStatus.locked;
              final remainingLockTime = CountdownFormatter.formatRemaining(claim.lockedUntil);

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primary.withOpacity(0.12),
                            child: const Icon(Icons.person, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  claim.recipientName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 15, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${claim.recipientRating.toStringAsFixed(1)} (Verified Recipient)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isLocked ? Colors.amber.shade100 : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isLocked ? '30-Min Hold' : claim.status.name.toUpperCase(),
                              style: TextStyle(
                                color: isLocked ? Colors.amber.shade900 : Colors.green.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Text(
                        'Claimed Item: ${claim.foodTitle}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Portion Reserved: ${claim.claimedQuantity.value} ${claim.claimedQuantity.unit}',
                        style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                      ),
                      if (isLocked) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 15, color: Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              'Hold Expires In: $remainingLockTime',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => OtpVerificationDialog(claim: claim),
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: const Text('Verify Handover (OTP / QR)'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
