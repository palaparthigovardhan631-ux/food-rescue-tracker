import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/impact_calculator.dart';

enum UserRole { provider, receiver }

class UserModel {
  final String uid;
  final UserRole role;
  final String name;
  final String? email;
  final String? phone;
  final String orgName;
  final String orgType; // hotel, hostel, restaurant, bakery, orphanage, ngo, neighbor
  final UserLocation? location;
  final bool isVerified;
  final double rating;
  final int totalRatings;
  final ImpactMetrics impact;
  final String? fcmToken;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.role,
    required this.name,
    this.email,
    this.phone,
    required this.orgName,
    required this.orgType,
    this.location,
    this.isVerified = false,
    this.rating = 5.0,
    this.totalRatings = 0,
    this.impact = const ImpactMetrics(),
    this.fcmToken,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      role: (data['role'] == 'provider') ? UserRole.provider : UserRole.receiver,
      name: data['name'] ?? '',
      email: data['email'],
      phone: data['phone'],
      orgName: data['orgName'] ?? '',
      orgType: data['orgType'] ?? 'individual',
      location: data['location'] != null
          ? UserLocation.fromMap(data['location'] as Map<String, dynamic>)
          : null,
      isVerified: data['isVerified'] ?? false,
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      totalRatings: (data['totalRatings'] as num?)?.toInt() ?? 0,
      impact: ImpactMetrics.fromMap(data['impact'] as Map<String, dynamic>?),
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'role': role == UserRole.provider ? 'provider' : 'receiver',
      'name': name,
      'email': email,
      'phone': phone,
      'orgName': orgName,
      'orgType': orgType,
      'location': location?.toMap(),
      'isVerified': isVerified,
      'rating': rating,
      'totalRatings': totalRatings,
      'impact': impact.toMap(),
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    UserRole? role,
    String? name,
    String? email,
    String? phone,
    String? orgName,
    String? orgType,
    UserLocation? location,
    bool? isVerified,
    double? rating,
    int? totalRatings,
    ImpactMetrics? impact,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      orgName: orgName ?? this.orgName,
      orgType: orgType ?? this.orgType,
      location: location ?? this.location,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      impact: impact ?? this.impact,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}
