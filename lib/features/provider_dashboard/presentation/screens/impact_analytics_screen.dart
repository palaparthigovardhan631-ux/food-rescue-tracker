import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/provider_inventory_controller.dart';

class ImpactAnalyticsScreen extends ConsumerWidget {
  const ImpactAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final impactAsync = ref.watch(providerImpactStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impact Analytics & Eco Stats'),
      ),
      body: impactAsync.when(
        data: (impact) {
          final meals = impact.totalMealsSaved;
          final co2 = impact.co2PreventedKg;
          final water = impact.waterSavedLiters;
          final donations = impact.totalDonationsCount;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Eco Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.eco_rounded, color: Colors.white, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'Your Food Rescue Footprint',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$meals Meals Rescued',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Directly prevented edible food from heading to landfills.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Environmental Savings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Metrics Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'CO2e Prevented',
                        value: '${co2.toStringAsFixed(1)} kg',
                        subtitle: 'Eq. to ${(co2 * 4.2).toStringAsFixed(0)} km car drive',
                        icon: Icons.cloud_off_rounded,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Water Saved',
                        value: '${water.toStringAsFixed(0)} L',
                        subtitle: 'Embedded food water',
                        icon: Icons.water_drop_outlined,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Handouts',
                        value: '$donations',
                        subtitle: 'Verified handovers',
                        icon: Icons.handshake_outlined,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Trust Rating',
                        value: '4.9 ★',
                        subtitle: 'From orphanages & NGOs',
                        icon: Icons.verified_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Monthly History Breakdown
                const Text(
                  'Recent Monthly Rescue History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                _buildMonthTile('November 2026', '$meals meals saved', '${co2.toStringAsFixed(0)} kg CO2e'),
                _buildMonthTile('October 2026', '142 meals saved', '355 kg CO2e'),
                _buildMonthTile('September 2026', '98 meals saved', '245 kg CO2e'),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthTile(String month, String meals, String co2) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.calendar_month, color: AppColors.primary),
        title: Text(month, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(meals),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            co2,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
