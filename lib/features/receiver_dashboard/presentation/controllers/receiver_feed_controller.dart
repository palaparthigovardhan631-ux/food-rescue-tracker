import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/geohash_helper.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../provider_dashboard/data/models/food_listing_model.dart';
import '../data/models/claim_model.dart';
import '../data/repositories/receiver_food_repository.dart';

final receiverFoodRepositoryProvider = Provider<ReceiverFoodRepository>((ref) {
  return ReceiverFoodRepository();
});

class ReceiverFilterState {
  final FoodCategory? category;
  final double radiusKm;
  final double minServings;

  const ReceiverFilterState({
    this.category,
    this.radiusKm = 10.0,
    this.minServings = 0.0,
  });

  ReceiverFilterState copyWith({
    FoodCategory? Function()? category,
    double? radiusKm,
    double? minServings,
  }) {
    return ReceiverFilterState(
      category: category != null ? category() : this.category,
      radiusKm: radiusKm ?? this.radiusKm,
      minServings: minServings ?? this.minServings,
    );
  }
}

class ReceiverFilterNotifier extends StateNotifier<ReceiverFilterState> {
  ReceiverFilterNotifier() : super(const ReceiverFilterState());

  void setCategory(FoodCategory? cat) {
    state = state.copyWith(category: () => cat);
  }

  void setRadius(double radius) {
    state = state.copyWith(radiusKm: radius);
  }

  void setMinServings(double servings) {
    state = state.copyWith(minServings: servings);
  }

  void reset() {
    state = const ReceiverFilterState();
  }
}

final receiverFilterProvider =
    StateNotifierProvider<ReceiverFilterNotifier, ReceiverFilterState>((ref) {
  return ReceiverFilterNotifier();
});

/// Raw available listings stream from Firestore
final availableFoodListingsStreamProvider = StreamProvider<List<FoodListingModel>>((ref) {
  final repo = ref.watch(receiverFoodRepositoryProvider);
  return repo.streamAvailableFoodListings();
});

/// Filtered & Sorted listings stream
final filteredFoodListingsProvider = Provider<AsyncValue<List<FoodListingModel>>>((ref) {
  final rawAsync = ref.watch(availableFoodListingsStreamProvider);
  final filter = ref.watch(receiverFilterProvider);
  final userProfile = ref.watch(userProfileStreamProvider).value;

  final userLat = userProfile?.location?.latitude ?? 12.9716;
  final userLng = userProfile?.location?.longitude ?? 77.5946;

  return rawAsync.whenData((listings) {
    return listings.where((item) {
      // 1. Dietary filter
      if (filter.category != null && item.category != filter.category) {
        return false;
      }
      // 2. Minimum serving size
      if (filter.minServings > 0 && item.remainingQuantity.value < filter.minServings) {
        return false;
      }
      // 3. Distance calculation (Haversine)
      final distance = GeohashHelper.calculateDistanceKm(
        userLat,
        userLng,
        item.location.latitude,
        item.location.longitude,
      );
      if (distance > filter.radiusKm) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        // Sort by expiry urgency first, then distance
        final aExpiry = a.bestBefore.millisecondsSinceEpoch;
        final bExpiry = b.bestBefore.millisecondsSinceEpoch;
        return aExpiry.compareTo(bExpiry);
      });
  });
});

/// User's claims stream
final userClaimsStreamProvider = StreamProvider<List<ClaimModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  final repo = ref.watch(receiverFoodRepositoryProvider);
  return repo.streamUserClaims(user.uid);
});
