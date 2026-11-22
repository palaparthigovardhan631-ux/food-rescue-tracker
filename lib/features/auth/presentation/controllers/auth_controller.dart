import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/location_service.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

final userProfileStreamProvider = StreamProvider<UserModel?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return Stream.value(null);
  final repo = ref.watch(authRepositoryProvider);
  return repo.streamUserProfile(authUser.uid);
});

class AuthControllerState {
  final bool isLoading;
  final String? errorMessage;
  final String? verificationId;

  AuthControllerState({
    this.isLoading = false,
    this.errorMessage,
    this.verificationId,
  });

  AuthControllerState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? verificationId,
  }) {
    return AuthControllerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      verificationId: verificationId ?? this.verificationId,
    );
  }
}

class AuthController extends StateNotifier<AuthControllerState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(AuthControllerState());

  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.signInWithEmail(email, password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> registerWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.registerWithEmail(email, password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> sendPhoneOtp(String phoneNumber, Function(String) onCodeSent) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _repository.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId, resendToken) {
        state = state.copyWith(isLoading: false, verificationId: verificationId);
        onCodeSent(verificationId);
      },
      onVerificationFailed: (e) {
        state = state.copyWith(isLoading: false, errorMessage: e.message);
      },
      onVerificationCompleted: (cred) async {
        // Auto-resolution on Android devices
      },
      onCodeAutoRetrievalTimeout: (verificationId) {
        state = state.copyWith(verificationId: verificationId);
      },
    );
  }

  Future<bool> verifyOtp(String smsCode) async {
    if (state.verificationId == null) {
      state = state.copyWith(errorMessage: "Verification ID missing.");
      return false;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.signInWithPhoneCredential(state.verificationId!, smsCode);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> completeOnboarding({
    required UserRole role,
    required String name,
    required String orgName,
    required String orgType,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = _repository.currentUser;
      if (user == null) throw Exception("User not authenticated.");

      final location = await LocationService.getCurrentLocation();
      final userModel = UserModel(
        uid: user.uid,
        role: role,
        name: name,
        email: user.email,
        phone: user.phoneNumber,
        orgName: orgName,
        orgType: orgType,
        location: location,
        createdAt: DateTime.now(),
      );

      await _repository.saveUserProfile(userModel);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthControllerState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});
