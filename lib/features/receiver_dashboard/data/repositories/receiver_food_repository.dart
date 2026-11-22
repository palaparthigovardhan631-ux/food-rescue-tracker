import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/geohash_helper.dart';
import '../../../auth/data/models/user_model.dart';
import '../../provider_dashboard/data/models/food_listing_model.dart';
import '../models/claim_model.dart';

class ReceiverFoodRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of active nearby surplus food listings
  Stream<List<FoodListingModel>> streamAvailableFoodListings() {
    final now = Timestamp.now();
    return _firestore
        .collection(FirestoreCollections.foodListings)
        .where('status', '==', 'available')
        .where('bestBefore', '>', now)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FoodListingModel.fromFirestore(doc))
            .toList());
  }

  /// Instant Claim & Locking Mechanism:
  /// Executes a Firestore atomic transaction to immediately lock the listing (or portion)
  /// for 30 minutes, preventing double-booking by multiple users in race conditions.
  Future<ClaimModel> claimFoodAtomic({
    required String listingId,
    required double quantityToClaim,
    required UserModel recipient,
  }) async {
    final listingRef = _firestore.collection(FirestoreCollections.foodListings).doc(listingId);
    final claimDocRef = _firestore.collection(FirestoreCollections.claims).doc();

    return await _firestore.runTransaction<ClaimModel>((transaction) async {
      final listingSnap = await transaction.get(listingRef);

      if (!listingSnap.exists) {
        throw Exception("This food listing no longer exists.");
      }

      final listing = FoodListingModel.fromFirestore(listingSnap);

      // Verify availability
      if (listing.status != ListingStatus.available) {
        throw Exception("Sorry! This food was just claimed by another recipient.");
      }

      if (listing.bestBefore.isBefore(DateTime.now())) {
        throw Exception("This listing has just expired.");
      }

      final currentRemaining = listing.remainingQuantity.value;
      if (currentRemaining < quantityToClaim) {
        throw Exception("Only $currentRemaining ${listing.totalQuantity.unit} remaining.");
      }

      final double newRemaining = currentRemaining - quantityToClaim;
      final newStatus = (newRemaining <= 0) ? ListingStatus.reserved : ListingStatus.available;

      // Generate 4-digit verification OTP
      final otp = (1000 + Random().nextInt(9000)).toString();
      final lockedUntil = DateTime.now().add(const Duration(minutes: 30));
      final qrData = 'RESCUE_${claimDocRef.id}_$otp';

      final claim = ClaimModel(
        id: claimDocRef.id,
        listingId: listing.id,
        foodTitle: listing.title,
        foodImageUrl: listing.imageUrl,
        providerId: listing.providerId,
        providerName: listing.providerName,
        providerPhone: listing.providerPhone,
        recipientId: recipient.uid,
        recipientName: recipient.orgName.isNotEmpty ? recipient.orgName : recipient.name,
        recipientPhone: recipient.phone,
        recipientRating: recipient.rating,
        claimedQuantity: QuantityData(value: quantityToClaim, unit: listing.totalQuantity.unit),
        status: ClaimStatus.locked,
        lockedUntil: lockedUntil,
        verificationOtp: otp,
        qrCodeData: qrData,
        pickupAddress: listing.address,
        pickupLat: listing.location.latitude,
        pickupLng: listing.location.longitude,
        createdAt: DateTime.now(),
      );

      // 1. Atomically update listing remaining quantity & status
      transaction.update(listingRef, {
        'remainingQuantity.value': newRemaining,
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Atomically create claim record
      transaction.set(claimDocRef, claim.toFirestore());

      return claim;
    });
  }

  /// Stream of user's active and historical claims
  Stream<List<ClaimModel>> streamUserClaims(String recipientId) {
    return _firestore
        .collection(FirestoreCollections.claims)
        .where('recipientId', '==', recipientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ClaimModel.fromFirestore(doc)).toList());
  }

  /// Cancel claim and restore quantity atomically
  Future<void> cancelClaim(String claimId) async {
    final claimRef = _firestore.collection(FirestoreCollections.claims).doc(claimId);

    await _firestore.runTransaction((transaction) async {
      final claimSnap = await transaction.get(claimRef);
      if (!claimSnap.exists) return;

      final claimData = claimSnap.data()!;
      if (claimData['status'] != 'locked') return;

      final listingId = claimData['listingId'] as String;
      final qty = (claimData['claimedQuantity']?['value'] as num?)?.toDouble() ?? 1.0;

      final listingRef = _firestore.collection(FirestoreCollections.foodListings).doc(listingId);
      final listingSnap = await transaction.get(listingRef);

      if (listingSnap.exists) {
        final currentRem = (listingSnap.data()?['remainingQuantity']?['value'] as num?)?.toDouble() ?? 0.0;
        final restoredRem = currentRem + qty;

        transaction.update(listingRef, {
          'remainingQuantity.value': restoredRem,
          'status': 'available',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(claimRef, {
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
