class AppConstants {
  // Cloudinary Configuration
  // Note: For production, configure your cloud name and unsigned upload preset
  static const String cloudinaryCloudName = "food-rescue-demo";
  static const String cloudinaryUploadPreset = "surplus_food_unsigned";
  static const String cloudinaryUploadUrl = 
      "https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload";

  // Google Maps API Defaults
  static const String googleDirectionsApiUrl = 
      "https://maps.googleapis.com/maps/api/directions/json";
  static const String googleMapsApiKey = "YOUR_GOOGLE_MAPS_SERVER_KEY";

  // Impact Constants
  // Average benchmark: 1 meal saved (~0.5 kg) prevents ~1.25 to 2.5 kg CO2e
  static const double co2SavedPerServingKg = 2.5; 
  static const double waterSavedPerServingLiters = 140.0;

  // Claim Lock Timeout Window (in minutes)
  static const int claimLockDurationMinutes = 30;

  // Default Geo Radius for Push Notifications
  static const double notificationRadiusKm = 5.0;
}
