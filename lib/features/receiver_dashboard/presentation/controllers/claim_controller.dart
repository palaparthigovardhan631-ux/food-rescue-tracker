import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../data/models/claim_model.dart';
import 'receiver_feed_controller.dart';

class ClaimState {
  final bool isClaiming;
  final String? errorMessage;
  final ClaimModel? lastClaim;

  ClaimState({
    this.isClaiming = false,
    this.errorMessage,
    this.lastClaim,
  });

  ClaimState copyWith({
    bool? isClaiming,
    String? errorMessage,
    ClaimModel? lastClaim,
  }) {
    return ClaimState(
      isClaiming: isClaiming ?? this.isClaiming,
      errorMessage: errorMessage,
      lastClaim: lastClaim ?? this.lastClaim,
    );
  }
}

class ClaimController extends StateNotifier<ClaimState> {
  final Ref _ref;

  ClaimController(this._ref) : super(ClaimState());

  Future<ClaimModel?> claimListing({
    required String listingId,
    required double quantityToClaim,
  }) async {
    state = state.copyWith(isClaiming: true, errorMessage: null);

    try {
      final userProfile = _ref.read(userProfileStreamProvider).value;
      if (userProfile == null) throw Exception("User profile not found.");

      final repo = _ref.read(receiverFoodRepositoryProvider);
      final claim = await repo.claimFoodAtomic(
        listingId: listingId,
        quantityToClaim: quantityToClaim,
        recipient: userProfile,
      );

      state = state.copyWith(isClaiming: false, lastClaim: claim);
      return claim;
    } catch (e) {
      state = state.copyWith(
        isClaiming: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return null;
    }
  }

  Future<void> cancelClaim(String claimId) async {
    final repo = _ref.read(receiverFoodRepositoryProvider);
    await repo.cancelClaim(claimId);
  }
}

final claimControllerProvider =
    StateNotifierProvider<ClaimController, ClaimState>((ref) {
  return ClaimController(ref);
});
