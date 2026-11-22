import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../provider_dashboard/data/models/food_listing_model.dart';
import '../controllers/receiver_feed_controller.dart';

class SmartFilterSheet extends ConsumerStatefulWidget {
  const SmartFilterSheet({super.key});

  @override
  ConsumerState<SmartFilterSheet> createState() => _SmartFilterSheetState();
}

class _SmartFilterSheetState extends ConsumerState<SmartFilterSheet> {
  late FoodCategory? _selectedCategory;
  late double _radiusKm;
  late double _minServings;

  @override
  void initState() {
    super.initState();
    final current = ref.read(receiverFilterProvider);
    _selectedCategory = current.category;
    _radiusKm = current.radiusKm;
    _minServings = current.minServings;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Smart Rescue Filters',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  ref.read(receiverFilterProvider.notifier).reset();
                  Navigator.pop(context);
                },
                child: const Text('Reset All'),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),

          // Dietary Preference
          const Text(
            'Dietary Preference',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All Categories'),
                selected: _selectedCategory == null,
                onSelected: (val) {
                  if (val) setState(() => _selectedCategory = null);
                },
              ),
              ...FoodCategory.values.map((cat) {
                return ChoiceChip(
                  label: Text(cat.name.toUpperCase()),
                  selected: _selectedCategory == cat,
                  onSelected: (val) {
                    setState(() => _selectedCategory = val ? cat : null);
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 20),

          // Distance Radius Slider (1 km to 15 km)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Search Radius', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${_radiusKm.toStringAsFixed(1)} km',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          Slider(
            value: _radiusKm,
            min: 1.0,
            max: 15.0,
            divisions: 14,
            label: '${_radiusKm.toStringAsFixed(0)} km',
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _radiusKm = val),
          ),
          const SizedBox(height: 12),

          // Minimum Serving Size (Crucial for orphanages)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Minimum Portions', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('Important for orphanages & shelters', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              Text(
                _minServings == 0 ? 'Any' : '${_minServings.toInt()}+ servings',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          Slider(
            value: _minServings,
            min: 0,
            max: 50,
            divisions: 10,
            label: _minServings == 0 ? 'Any' : '${_minServings.toInt()} servings',
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _minServings = val),
          ),
          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: () {
              final notifier = ref.read(receiverFilterProvider.notifier);
              notifier.setCategory(_selectedCategory);
              notifier.setRadius(_radiusKm);
              notifier.setMinServings(_minServings);
              Navigator.pop(context);
            },
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}
