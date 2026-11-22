import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/services/fcm_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Sign in with Email and Password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Register with Email and Password
  Future<UserCredential> registerWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Phone OTP Verification flow
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  /// Sign in with Phone Credential
  Future<UserCredential> signInWithPhoneCredential(
    String verificationId,
    String smsCode,
  ) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    return await _auth.signInWithCredential(credential);
  }

  /// Store or update user profile document in Firestore
  Future<void> saveUserProfile(UserModel user) async {
    final fcmToken = await FCMService.getToken();
    final data = user.copyWith(fcmToken: fcmToken).toMap();
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }

  /// Real-time stream of current user's profile
  Stream<UserModel?> streamUserProfile(String uid) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  /// Fetch user profile once
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection(FirestoreCollections.users).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
