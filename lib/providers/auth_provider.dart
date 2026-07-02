import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

// ------------------------------------
  // 1. ฟังก์ชันเข้าสู่ระบบ (Sign In)
  // ------------------------------------
  Future<String?> signIn({required String email, required String password}) async {
    _setLoading(true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // สำเร็จ ไม่มี Error
    } on FirebaseAuthException catch (e) {
      return _translateFirebaseError(e);
    } finally {
      _setLoading(false);
    }
  }

  // ------------------------------------
  // 2. ฟังก์ชันสมัครสมาชิก (Sign Up)
  // ------------------------------------
  Future<String?> signUp({
    required String email,
    required String password,
    required int age,
    required int gender,
  }) async {
    _setLoading(true);
    try {
      // 1. สร้างบัญชีผู้ใช้ใหม่
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. บันทึกโปรไฟล์ (อายุ, เพศ) ลง Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'age': age,
        'gender': gender,
        'created_at': FieldValue.serverTimestamp(),
      });

      // 3. 🟢 บังคับให้ออกจากระบบทันทีหลังสมัครเสร็จ เพื่อให้ผู้ใช้ไปหน้าล็อกอินเอง
      await FirebaseAuth.instance.signOut();

      return null; // สำเร็จ
    } on FirebaseAuthException catch (e) {
      return _translateFirebaseError(e);
    } finally {
      _setLoading(false);
    }
  }

  // ตัวจัดการ Loading
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // แปลง Error เป็นภาษาไทย
  String _translateFirebaseError(FirebaseAuthException e) {
    if (e.code == 'user-not-found' || e.code == 'invalid-credential') return "อีเมลหรือรหัสผ่านไม่ถูกต้อง";
    if (e.code == 'email-already-in-use') return "อีเมลนี้มีผู้ใช้งานแล้ว";
    if (e.code == 'weak-password') return "รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร";
    return e.message ?? "เกิดข้อผิดพลาด ไม่สามารถดำเนินการได้";
  }
}