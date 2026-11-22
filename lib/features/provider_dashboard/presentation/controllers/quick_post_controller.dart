import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../data/models/food_listing_model.dart';
import 'provider_inventory_controller.dart';

class QuickPostState {
  final bool isUploading;
  final bool isSubmitting;
  final File? selectedImage;
  final String? uploadedImageUrl;
  final String? uploadedThumbnailUrl;
  final String? errorMessage;
  final bool hygieneAccepted;
  final bool allowsPartialClaims;

  QuickPostState({
    this.isUploading = false,
    this.isSubmitting = false,
    this.selectedImage,
    this.uploadedImageUrl,
    this.uploadedThumbnailUrl,
    this.errorMessage,
    this.hygieneAccepted = false,
    this.allowsPartialClaims = false,
  });

  QuickPostState copyWith({
    bool? isUploading,
    bool? isSubmitting,
    File? selectedImage,
    String? uploadedImageUrl,
    String? uploadedThumbnailUrl,
    String? errorMessage,
    bool? hygieneAccepted,
    bool? allowsPartialClaims,
  }) {
    return QuickPostState(
      isUploading: isUploading ?? this.isUploading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      selectedImage: selectedImage ?? this.selectedImage,
      uploadedImageUrl: uploadedImageUrl ?? this.uploadedImageUrl,
      uploadedThumbnailUrl: uploadedThumbnailUrl ?? this.uploadedThumbnailUrl,
      errorMessage: errorMessage,
      hygieneAccepted: hygieneAccepted ?? this.hygieneAccepted,
      allowsPartialClaims: allowsPartialClaims ?? this.allowsPartialClaims,
    );
  }
}

class QuickPostController extends StateNotifier<QuickPostState> {
  final Ref _ref;
  final ImagePicker _picker = ImagePicker();

  QuickPostController(this._ref) : super(QuickPostState());

  void toggleHygiene(bool? val) {
    state = state.copyWith(hygieneAccepted: val ?? false);
  }

  void togglePartialClaims(bool val) {
    state = state.copyWith(allowsPartialClaims: val);
  }

  Future<void> pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (file == null) return;

      final imageFile = File(file.path);
      state = state.copyWith(
        selectedImage: imageFile,
        isUploading: true,
        errorMessage: null,
      );

      // Cloudinary unsigned WebP upload
      final result = await CloudinaryService.uploadImage(imageFile);

      state = state.copyWith(
        isUploading: false,
        uploadedImageUrl: result.webpUrl,
        uploadedThumbnailUrl: result.thumbnailUrl,
      );
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: 'Image upload failed: $e',
      );
    }
  }

  Future<bool> submitListing({
    required String title,
    required String description,
    required FoodCategory category,
    required double quantityValue,
    required String quantityUnit,
    required DateTime preparedAt,
    required DateTime bestBefore,
    required String address,
  }) async {
    if (!state.hygieneAccepted) {
      state = state.copyWith(errorMessage: 'Food safety declaration is mandatory.');
      return false;
    }

    if (bestBefore.isBefore(DateTime.now())) {
      state = state.copyWith(errorMessage: 'Best before time must be in the future.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final userProfile = _ref.read(userProfileStreamProvider).value;
      if (userProfile == null) throw Exception("User profile not loaded.");

      final userLocation = userProfile.location ?? await LocationService.getCurrentLocation();

      final listing = FoodListingModel(
        id: '',
        providerId: userProfile.uid,
        providerName: userProfile.orgName.isNotEmpty ? userProfile.orgName : userProfile.name,
        providerPhone: userProfile.phone,
        title: title.trim(),
        description: description.trim(),
        category: category,
        totalQuantity: QuantityData(value: quantityValue, unit: quantityUnit),
        remainingQuantity: QuantityData(value: quantityValue, unit: quantityUnit),
        allowsPartialClaims: state.allowsPartialClaims,
        imageUrl: state.uploadedImageUrl ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
        thumbnailUrl: state.uploadedThumbnailUrl ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
        preparedAt: preparedAt,
        bestBefore: bestBefore,
        location: userLocation,
        address: address.trim().isNotEmpty ? address.trim() : (userProfile.orgName),
        hygieneDeclaration: true,
        createdAt: DateTime.now(),
      );

      final repo = _ref.read(providerFoodRepositoryProvider);
      await repo.createListing(listing);

      state = QuickPostState(); // Reset state
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }
}

final quickPostControllerProvider =
    StateNotifierProvider<QuickPostController, QuickPostState>((ref) {
  return QuickPostController(ref);
});
