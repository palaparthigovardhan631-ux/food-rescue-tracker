import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/impact_calculator.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../receiver_dashboard/data/models/claim_model.dart';
import '../data/models/food_listing_model.dart';
import '../data/repositories/provider_food_repository.dart';

final providerFoodRepositoryProvider = Provider<ProviderFoodRepository>((ref) {
  return ProviderFoodRepository();
});

/// Streams all active listings for the currently logged in provider
final providerListingsStreamProvider = StreamProvider<List<FoodListingModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  final repo = ref.watch(providerFoodRepositoryProvider);
  return repo.streamProviderListings(user.uid);
});

/// Streams incoming pending pickup claims for this provider
final providerIncomingClaimsStreamProvider = StreamProvider<List<ClaimModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  final repo = ref.watch(providerFoodRepositoryProvider);
  return repo.streamIncomingClaims(user.uid);
});

/// Streams provider impact statistics
final providerImpactStreamProvider = StreamProvider<ImpactMetrics>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const ImpactMetrics());
  final repo = ref.watch(providerFoodRepositoryProvider);
  return repo.streamProviderImpact(user.uid);
});
