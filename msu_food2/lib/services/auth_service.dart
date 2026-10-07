import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static bool _googleInitialized = false;

  // ใช้ getter แทนการประกาศตัวแปรตรงๆ เพื่อเรียกใช้งานหลังจาก Initialize Firebase แล้ว
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // เรียกครั้งเดียวตอนเปิดแอป ก่อนเรียก authenticate() เสมอ
  static Future<void> init(String serverClientId) async {
    final sanitizedClientId = serverClientId.trim();
    if (sanitizedClientId.isEmpty || _googleInitialized) {
      return;
    }

    await GoogleSignIn.instance.initialize(
      serverClientId: sanitizedClientId,
    );
    _googleInitialized = true;
  }

  // กระแสข้อมูลสถานะผู้ใช้ ใช้กับ AuthGate
  Stream<User?> get userChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<String?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        return null;
      }

      final idToken = googleUser.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return 'ไม่ได้รับ idToken ตรวจสอบค่า serverClientId';
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );
      await _auth.signInWithCredential(credential);
      return null;
    } on PlatformException catch (error) {
      if (error.code == 'sign_in_canceled') {
        return null;
      }
      return error.message ?? error.toString();
    } catch (error) {
      return error.toString();
    }
  }

  Future<void> signOut() async {
    Object? googleSignOutError;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (error) {
      googleSignOutError = error;
    }

    await _auth.signOut();

    if (googleSignOutError != null) {
      if (googleSignOutError is PlatformException &&
          googleSignOutError.code == 'sign_in_required') {
        return;
      }
      throw StateError('ออกจาก Google ไม่สำเร็จ: $googleSignOutError');
    }
  }
}