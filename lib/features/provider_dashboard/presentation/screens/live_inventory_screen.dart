import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/provider_inventory_controller.dart';
import '../data/models/food_listing_model.dart';
import '../widgets/inventory_card.dart';

class LiveInventoryScreen extends ConsumerStatefulWidget {
  const LiveInventoryScreen({super.key});

  @override
  ConsumerState<LiveInventoryScreen> createState() => _LiveInventoryScreenState();
}

class _LiveInventoryScreenState extends ConsumerState<LiveInventoryScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(providerListingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Surplus Inventory'),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Available', 'available'),
                const SizedBox(width: 8),
                _buildFilterChip('Reserved', 'reserved'),
                const SizedBox(width: 8),
                _buildFilterChip('Picked Up', 'pickedUp'),
                const SizedBox(width: 8),
                _buildFilterChip('Expired', 'expired'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Streamed Inventory List
          Expanded(
            child: listingsAsync.when(
              data: (listings) {
                final filtered = listings.where((item) {
                  if (_selectedFilter == 'all') return true;
                  return item.status.name.toLowerCase() == _selectedFilter.toLowerCase();
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No listings found in ${_selectedFilter.toUpperCase()}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return InventoryCard(
                      listing: item,
                      onStatusChange: (newStatus) {
                        ref
                            .read(providerFoodRepositoryProvider)
                            .updateListingStatus(item.id, newStatus);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Error loading inventory: $err'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary.withOpacity(0.2),
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = value);
      },
    );
  }
}
