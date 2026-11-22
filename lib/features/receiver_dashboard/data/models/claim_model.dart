import 'package:cloud_firestore/cloud_firestore.dart';
import '../../provider_dashboard/data/models/food_listing_model.dart';

enum ClaimStatus { locked, confirmed, pickedUp, expired, cancelled }

class ClaimModel {
  final String id;
  final String listingId;
  final String foodTitle;
  final String foodImageUrl;
  final String providerId;
  final String providerName;
  final String? providerPhone;
  final String recipientId;
  final String recipientName;
  final String? recipientPhone;
  final double recipientRating;
  final QuantityData claimedQuantity;
  final ClaimStatus status;
  final DateTime lockedUntil;
  final String verificationOtp;
  final String qrCodeData;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final DateTime createdAt;
  final DateTime? pickedUpAt;

  ClaimModel({
    required this.id,
    required this.listingId,
    required this.foodTitle,
    this.foodImageUrl = '',
    required this.providerId,
    required this.providerName,
    this.providerPhone,
    required this.recipientId,
    required this.recipientName,
    this.recipientPhone,
    this.recipientRating = 5.0,
    required this.claimedQuantity,
    this.status = ClaimStatus.locked,
    required this.lockedUntil,
    required this.verificationOtp,
    required this.qrCodeData,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.createdAt,
    this.pickedUpAt,
  });

  factory ClaimModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ClaimModel(
      id: doc.id,
      listingId: data['listingId'] ?? '',
      foodTitle: data['foodTitle'] ?? '',
      foodImageUrl: data['foodImageUrl'] ?? '',
      providerId: data['providerId'] ?? '',
      providerName: data['providerName'] ?? '',
      providerPhone: data['providerPhone'],
      recipientId: data['recipientId'] ?? '',
      recipientName: data['recipientName'] ?? '',
      recipientPhone: data['recipientPhone'],
      recipientRating: (data['recipientRating'] as num?)?.toDouble() ?? 5.0,
      claimedQuantity: QuantityData.fromMap(
          data['claimedQuantity'] ?? {'value': 1, 'unit': 'servings'}),
      status: _parseStatus(data['status']),
      lockedUntil: (data['lockedUntil'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(minutes: 30)),
      verificationOtp: data['verificationOtp']?.toString() ?? '0000',
      qrCodeData: data['qrCodeData'] ?? '',
      pickupAddress: data['pickupAddress'] ?? '',
      pickupLat: (data['pickupLat'] as num?)?.toDouble() ?? 0.0,
      pickupLng: (data['pickupLng'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pickedUpAt: (data['pickedUpAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listingId': listingId,
      'foodTitle': foodTitle,
      'foodImageUrl': foodImageUrl,
      'providerId': providerId,
      'providerName': providerName,
      'providerPhone': providerPhone,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'recipientRating': recipientRating,
      'claimedQuantity': claimedQuantity.toMap(),
      'status': status.name,
      'lockedUntil': Timestamp.fromDate(lockedUntil),
      'verificationOtp': verificationOtp,
      'qrCodeData': qrCodeData,
      'pickupAddress': pickupAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'createdAt': Timestamp.fromDate(createdAt),
      'pickedUpAt': pickedUpAt != null ? Timestamp.fromDate(pickedUpAt!) : null,
    };
  }

  static ClaimStatus _parseStatus(String? value) {
    switch (value) {
      case 'confirmed':
        return ClaimStatus.confirmed;
      case 'picked_up':
      case 'pickedUp':
        return ClaimStatus.pickedUp;
      case 'expired':
        return ClaimStatus.expired;
      case 'cancelled':
        return ClaimStatus.cancelled;
      default:
        return ClaimStatus.locked;
    }
  }

  bool get isLockActive {
    return status == ClaimStatus.locked && DateTime.now().isBefore(lockedUntil);
  }
}
