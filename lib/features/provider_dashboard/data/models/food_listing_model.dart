import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/location_service.dart';

enum FoodCategory { veg, nonVeg, vegan, bakery }
enum ListingStatus { available, reserved, pickedUp, expired, cancelled }

class QuantityData {
  final double value;
  final String unit; // 'servings' or 'kg'

  const QuantityData({required this.value, required this.unit});

  Map<String, dynamic> toMap() => {'value': value, 'unit': unit};

  factory QuantityData.fromMap(Map<String, dynamic> map) {
    return QuantityData(
      value: (map['value'] as num).toDouble(),
      unit: map['unit'] ?? 'servings',
    );
  }
}

class FoodListingModel {
  final String id;
  final String providerId;
  final String providerName;
  final String? providerPhone;
  final String title;
  final String description;
  final FoodCategory category;
  final QuantityData totalQuantity;
  final QuantityData remainingQuantity;
  final bool allowsPartialClaims;
  final String imageUrl;
  final String thumbnailUrl;
  final DateTime preparedAt;
  final DateTime bestBefore;
  final ListingStatus status;
  final UserLocation location;
  final String address;
  final bool hygieneDeclaration;
  final List<String> allergenInfo;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FoodListingModel({
    required this.id,
    required this.providerId,
    required this.providerName,
    this.providerPhone,
    required this.title,
    this.description = '',
    required this.category,
    required this.totalQuantity,
    required this.remainingQuantity,
    this.allowsPartialClaims = false,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.preparedAt,
    required this.bestBefore,
    this.status = ListingStatus.available,
    required this.location,
    required this.address,
    this.hygieneDeclaration = true,
    this.allergenInfo = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory FoodListingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return FoodListingModel(
      id: doc.id,
      providerId: data['providerId'] ?? '',
      providerName: data['providerName'] ?? '',
      providerPhone: data['providerPhone'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: _parseCategory(data['category']),
      totalQuantity: QuantityData.fromMap(data['totalQuantity'] ?? {'value': 1, 'unit': 'servings'}),
      remainingQuantity: QuantityData.fromMap(data['remainingQuantity'] ?? {'value': 1, 'unit': 'servings'}),
      allowsPartialClaims: data['allowsPartialClaims'] ?? false,
      imageUrl: data['imageUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      preparedAt: (data['preparedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bestBefore: (data['bestBefore'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 3)),
      status: _parseStatus(data['status']),
      location: UserLocation.fromMap(data['location'] ?? {'lat': 0.0, 'lng': 0.0, 'geohash': ''}),
      address: data['address'] ?? '',
      hygieneDeclaration: data['hygieneDeclaration'] ?? false,
      allergenInfo: List<String>.from(data['allergenInfo'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'providerId': providerId,
      'providerName': providerName,
      'providerPhone': providerPhone,
      'title': title,
      'description': description,
      'category': category.name,
      'totalQuantity': totalQuantity.toMap(),
      'remainingQuantity': remainingQuantity.toMap(),
      'allowsPartialClaims': allowsPartialClaims,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'preparedAt': Timestamp.fromDate(preparedAt),
      'bestBefore': Timestamp.fromDate(bestBefore),
      'status': status.name,
      'location': location.toMap(),
      'geohash': location.geohash,
      'address': address,
      'hygieneDeclaration': hygieneDeclaration,
      'allergenInfo': allergenInfo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  static FoodCategory _parseCategory(String? value) {
    switch (value) {
      case 'nonVeg':
        return FoodCategory.nonVeg;
      case 'vegan':
        return FoodCategory.vegan;
      case 'bakery':
        return FoodCategory.bakery;
      default:
        return FoodCategory.veg;
    }
  }

  static ListingStatus _parseStatus(String? value) {
    switch (value) {
      case 'reserved':
        return ListingStatus.reserved;
      case 'pickedUp':
      case 'picked_up':
        return ListingStatus.pickedUp;
      case 'expired':
        return ListingStatus.expired;
      case 'cancelled':
        return ListingStatus.cancelled;
      default:
        return ListingStatus.available;
    }
  }

  FoodListingModel copyWith({
    ListingStatus? status,
    QuantityData? remainingQuantity,
    DateTime? updatedAt,
  }) {
    return FoodListingModel(
      id: id,
      providerId: providerId,
      providerName: providerName,
      providerPhone: providerPhone,
      title: title,
      description: description,
      category: category,
      totalQuantity: totalQuantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      allowsPartialClaims: allowsPartialClaims,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      preparedAt: preparedAt,
      bestBefore: bestBefore,
      status: status ?? this.status,
      location: location,
      address: address,
      hygieneDeclaration: hygieneDeclaration,
      allergenInfo: allergenInfo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
