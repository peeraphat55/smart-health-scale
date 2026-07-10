import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppAuthProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<String?> signIn({required String email, required String password}) async {
    _setLoading(true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _translateFirebaseError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required int age,
    required int gender,
  }) async {
    _setLoading(true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'age': age,
        'gender': gender,
        'created_at': FieldValue.serverTimestamp(),
      });

      await FirebaseAuth.instance.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      return _translateFirebaseError(e);
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _translateFirebaseError(FirebaseAuthException e) {
    if (e.code == 'user-not-found' || e.code == 'invalid-credential') return "อีเมลหรือรหัสผ่านไม่ถูกต้อง";
    if (e.code == 'email-already-in-use') return "อีเมลนี้มีผู้ใช้งานแล้ว";
    if (e.code == 'weak-password') return "รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร";
    return e.message ?? "เกิดข้อผิดพลาด ไม่สามารถดำเนินการได้";
  }
}