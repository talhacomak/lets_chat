import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../models/user.dart' as app;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/common/widgets/helper_widgets.dart';
import '../../../utils/constants/routes_constants.dart';
import '../../../utils/constants/string_constants.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// provider to get AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance),
);

class AuthRepository {
  AuthRepository(FirebaseAuth auth, FirebaseFirestore firestore)
      : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> saveFcmTokenToFirestore(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        print('🔑 [FCM] Token alındı: $token');
        print('📍 [FCM] Firestore’a yazılıyor: users/$uid');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set({'fcmToken': token}, SetOptions(merge: true));

        print('✅ [FCM] Token Firestore’a başarıyla yazıldı.');
      } else {
        print('⚠️ [FCM] Token alınamadı (null).');
      }
    } catch (e) {
      print('❌ [FCM] Token Firestore’a yazılamadı: $e');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // user canceled the sign-in

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    await saveFcmTokenToFirestore(userCredential.user!.uid);
    return userCredential;
  }

  /// Invoke to signIn user with phone number.
  Future<void> signInWithPhone(
    BuildContext context, {
    required String phoneNumber,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (_) {},
        verificationFailed: (FirebaseAuthException error) {
          throw Exception(error.message);
        },
        codeSent: (String verificationId, int? forceResendingToken) {
          Navigator.pushNamed(
            context,
            AppRoutes.otpScreen,
            arguments: verificationId,
          );
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, content: e.message!);
    }
  }

  /// Invoke to verify otp.
  Future<void> verifyOTP(
    BuildContext context,
    bool mounted, {
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      await saveFcmTokenToFirestore(userCredential.user!.uid);

      if (userCredential.user != null) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.userInformationScreen,
          (route) => false,
        );
      } else {
        throw Exception('Something went wrong');
      }
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, content: e.message!);
    }
  }

  /// invoke to get user data form firestore.
  Stream<app.User> getReceiverUserData(String receiverUserId) {
    return _firestore
        .collection(StringsConsts.usersCollection)
        .doc(receiverUserId)
        .snapshots()
        .map(
          (snapshot) => app.User.fromMap(snapshot.data()!),
        );
  }
}
