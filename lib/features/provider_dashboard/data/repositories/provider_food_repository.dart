import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/utils/impact_calculator.dart';
import '../../receiver_dashboard/data/models/claim_model.dart';
import '../models/food_listing_model.dart';

class ProviderFoodRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a new surplus food listing
  Future<String> createListing(FoodListingModel listing) async {
    final docRef = _firestore.collection(FirestoreCollections.foodListings).doc();
    final data = listing.toFirestore();
    await docRef.set(data);
    return docRef.id;
  }

  /// Real-time stream of all listings posted by this provider
  Stream<List<FoodListingModel>> streamProviderListings(String providerId) {
    return _firestore
        .collection(FirestoreCollections.foodListings)
        .where('providerId', '==', providerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FoodListingModel.fromFirestore(doc))
            .toList());
  }

  /// One-tap toggle status (e.g. available <-> reserved <-> cancelled)
  Future<void> updateListingStatus(String listingId, ListingStatus newStatus) async {
    await _firestore
        .collection(FirestoreCollections.foodListings)
        .doc(listingId)
        .update({
      'status': newStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Real-time stream of active incoming pickup requests for this provider
  Stream<List<ClaimModel>> streamIncomingClaims(String providerId) {
    return _firestore
        .collection(FirestoreCollections.claims)
        .where('providerId', '==', providerId)
        .where('status', 'in', ['locked', 'confirmed'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ClaimModel.fromFirestore(doc)).toList());
  }

  /// Handover Verification via 4-Digit OTP or QR code
  /// Atomically verifies OTP, transitions claim status to 'picked_up',
  /// updates food listing status if fully collected, and credits impact stats to provider.
  Future<bool> verifyAndCompleteHandover({
    required String claimId,
    required String enteredOtp,
  }) async {
    final claimRef = _firestore.collection(FirestoreCollections.claims).doc(claimId);

    return await _firestore.runTransaction<bool>((transaction) async {
      final claimSnap = await transaction.get(claimRef);
      if (!claimSnap.exists) {
        throw Exception("Claim reservation not found.");
      }

      final claimData = claimSnap.data()!;
      final expectedOtp = claimData['verificationOtp']?.toString();

      if (expectedOtp != enteredOtp.trim()) {
        throw Exception("Invalid OTP! Handover could not be verified.");
      }

      final listingId = claimData['listingId'] as String;
      final listingRef = _firestore.collection(FirestoreCollections.foodListings).doc(listingId);
      final listingSnap = await transaction.get(listingRef);

      final claimedQty = (claimData['claimedQuantity']?['value'] as num?)?.toDouble() ?? 1.0;
      final providerId = claimData['providerId'] as String;
      final recipientId = claimData['recipientId'] as String;

      // 1. Mark claim picked up
      transaction.update(claimRef, {
        'status': 'picked_up',
        'pickedUpAt': FieldValue.serverTimestamp(),
      });

      // 2. If listing remaining is 0 or no partial claims, mark listing picked_up
      if (listingSnap.exists) {
        final remQty = (listingSnap.data()?['remainingQuantity']?['value'] as num?)?.toDouble() ?? 0.0;
        if (remQty <= 0) {
          transaction.update(listingRef, {
            'status': 'pickedUp',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // 3. Atomically increment provider impact stats
      final providerRef = _firestore.collection(FirestoreCollections.users).doc(providerId);
      transaction.update(providerRef, {
        'impact.mealsSaved': FieldValue.increment(claimedQty.toInt()),
        'impact.co2PreventedKg': FieldValue.increment(claimedQty * 2.5),
        'impact.donationsCount': FieldValue.increment(1),
      });

      // 4. Atomically increment recipient impact stats
      final recipientRef = _firestore.collection(FirestoreCollections.users).doc(recipientId);
      transaction.update(recipientRef, {
        'impact.mealsSaved': FieldValue.increment(claimedQty.toInt()),
        'impact.co2PreventedKg': FieldValue.increment(claimedQty * 2.5),
        'impact.donationsCount': FieldValue.increment(1),
      });

      return true;
    });
  }

  /// Impact stats for Provider
  Stream<ImpactMetrics> streamProviderImpact(String providerId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(providerId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return const ImpactMetrics();
      final data = doc.data() as Map<String, dynamic>;
      return ImpactMetrics.fromMap(data['impact'] as Map<String, dynamic>?);
    });
  }
}
