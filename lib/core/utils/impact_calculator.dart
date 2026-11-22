import '../constants/app_constants.dart';

class ImpactMetrics {
  final int totalMealsSaved;
  final double co2PreventedKg;
  final double waterSavedLiters;
  final int totalDonationsCount;

  const ImpactMetrics({
    this.totalMealsSaved = 0,
    this.co2PreventedKg = 0.0,
    this.waterSavedLiters = 0.0,
    this.totalDonationsCount = 0,
  });

  factory ImpactMetrics.fromMeals(int meals, int donationsCount) {
    return ImpactMetrics(
      totalMealsSaved: meals,
      co2PreventedKg: meals * AppConstants.co2SavedPerServingKg,
      waterSavedLiters: meals * AppConstants.waterSavedPerServingLiters,
      totalDonationsCount: donationsCount,
    );
  }

  factory ImpactMetrics.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const ImpactMetrics();
    final meals = (data['mealsSaved'] as num?)?.toInt() ?? 0;
    final donations = (data['donationsCount'] as num?)?.toInt() ?? 0;
    return ImpactMetrics.fromMeals(meals, donations);
  }

  Map<String, dynamic> toMap() {
    return {
      'mealsSaved': totalMealsSaved,
      'co2PreventedKg': co2PreventedKg,
      'waterSavedLiters': waterSavedLiters,
      'donationsCount': totalDonationsCount,
    };
  }
}
