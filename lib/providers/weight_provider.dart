import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:tflite_flutter/tflite_flutter.dart';

class BmiRecord {
  final String? key;
  final DateTime timestamp;
  final double weight;
  final double height;
  final int heartRate;
  final double bmi;
  final String status;

  BmiRecord({
    this.key,
    required this.timestamp,
    required this.weight,
    required this.height,
    required this.heartRate,
    required this.bmi,
    required this.status,
  });
}

class WeightProvider with ChangeNotifier {
  double _currentWeight = 0.0;
  double _heightCm = 155.0;
  int _currentHeartRate = 0;

  // ข้อมูลส่วนตัวสำหรับให้ AI วิเคราะห์ (สามารถแก้ให้ดึงจากหน้าโปรไฟล์ทีหลังได้)
  int _age = 21;
  int _gender = 0; // 0 = ชาย, 1 = หญิง

  final List<BmiRecord> _historyRecords = [];

  final DatabaseReference _weightRef = FirebaseDatabase.instance.ref(
    "smart_scale/current_weight",
  );
  final DatabaseReference _hrRef = FirebaseDatabase.instance.ref(
    "smart_scale/current_heart_rate",
  );

  // ตัวแปรสำหรับเก็บสมอง AI
  Interpreter? _interpreter;

  double get currentWeight => _currentWeight;
  double get heightCm => _heightCm;
  int get currentHeartRate => _currentHeartRate;
  int get age => _age;
  int get gender => _gender;
  List<BmiRecord> get historyRecords => _historyRecords;

  WeightProvider() {
    _listenToDataChanges();
    _loadAIModel(); // โหลดสมอง AI ทันทีที่เปิดแอป
  }

  // โหลดโมเดล .tflite จากโฟลเดอร์ assets
  Future<void> _loadAIModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/health_model.tflite');
      print("✅ โหลดโมเดล AI (TFLite) สำเร็จ!");
    } catch (e) {
      print("❌ โหลดโมเดล AI ไม่สำเร็จ (จะสลับไปใช้ระบบสำรอง): $e");
    }
  }

  void updateProfile(int newAge, int newGender) {
    _age = newAge;
    _gender = newGender;
    notifyListeners();
  }

  double get bmi {
    if (_heightCm == 0 || _currentWeight == 0) return 0.0;
    double heightM = _heightCm / 100;
    return _currentWeight / pow(heightM, 2);
  }

  String get bodyStatus {
    double currentBmi = bmi;
    if (currentBmi == 0) return "Waiting...";
    if (currentBmi < 18.5) return "Underweight";
    if (currentBmi < 24.9) return "Healthy";
    if (currentBmi < 29.9) return "Overweight";
    return "Obese";
  }

  // วิเคราะห์แนวโน้มด้วย AI
  Map<String, dynamic> get aiAnalysis {
    if (_historyRecords.length < 2) {
      return {
        "slope": 0.0,
        "prediction": 0.0,
        "trend": "รวบรวมข้อมูล...",
        "evaluation": "AI ต้องการข้อมูลประวัติอย่างน้อย 2 ครั้งขึ้นไป",
        "recommendation": "กรุณาชั่งน้ำหนักและบันทึกข้อมูลเพิ่มเติม",
      };
    }

    // 1. คำนวณความชัน (Slope) จากประวัติ
    List<BmiRecord> chronologicalRecords = _historyRecords.reversed.toList();
    int n = chronologicalRecords.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (int i = 0; i < n; i++) {
      double x = (i + 1).toDouble();
      double y = chronologicalRecords[i].bmi;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    double intercept = (sumY - slope * sumX) / n;
    double nextX = (n + 1).toDouble();
    double prediction = slope * nextX + intercept;

    double currentBmi = chronologicalRecords.last.bmi;
    String trend = slope > 0.1
        ? "เพิ่มขึ้น 📈"
        : slope < -0.1
        ? "ลดลง 📉"
        : "คงที่ ➡️";

    String evaluation = "";
    String recommendation = "";

    // 2. ส่งข้อมูลให้ AI ประมวลผล
    if (_interpreter != null) {
      // Input: [เพศ, อายุ, BMI ปัจจุบัน, ความชัน]
      var input = [
        [_gender.toDouble(), _age.toDouble(), currentBmi, slope],
      ];
      // Output: ความน่าจะเป็น 6 รูปแบบ (Class 0 ถึง 5)
      var output = List.generate(1, (i) => List.filled(6, 0.0));

      try {
        _interpreter!.run(input, output);

        List<double> probabilities = output[0];
        int aiClass = 0;
        double maxProb = probabilities[0];
        for (int i = 1; i < probabilities.length; i++) {
          if (probabilities[i] > maxProb) {
            maxProb = probabilities[i];
            aiClass = i;
          }
        }

        switch (aiClass) {
          case 0:
            evaluation = "ร่างกายคุณสมส่วนเยี่ยมยอด!";
            recommendation =
                "ออกกำลังกายแบบ Maintainance คาร์ดิโอ 3 วัน/สัปดาห์ เพื่อรักษามวลกล้ามเนื้อ";
            break;
          case 1:
            evaluation = "ภาวะน้ำหนักเกินและกราฟกำลังพุ่งขึ้น ⚠️";
            recommendation =
                "ควรเริ่มควบคุมอาหารแบบ Calorie Deficit ทันที และเน้นคาร์ดิโออย่างน้อย 4 วัน/สัปดาห์";
            break;
          case 2:
            evaluation = "น้ำหนักเกินเกณฑ์ แต่กำลังลดลงได้ดี 👏";
            recommendation =
                "คุณมาถูกทางแล้ว! รักษาวินัยคาร์ดิโอไว้ และเริ่มเพิ่ม Weight Training";
            break;
          case 3:
            evaluation = "สุขภาพอยู่ในเกณฑ์มาตรฐาน แต่น้ำหนักพุ่งเร็วไปนิด";
            recommendation =
                "ระวังการรับประทานแป้งและน้ำตาลในช่วงนี้ ลองเพิ่มการเดินในชีวิตประจำวัน";
            break;
          case 4:
            evaluation = "รูปร่างสมส่วน แต่น้ำหนักลดลงเร็วจนน่ากังวล";
            recommendation =
                "ทานโปรตีนให้เพียงพอ เพื่อป้องกันภาวะสูญเสียมวลกล้ามเนื้อ";
            break;
          case 5:
            evaluation = "คุณมีภาวะน้ำหนักต่ำกว่าเกณฑ์ (ผอมเกินไป)";
            recommendation =
                "แนะนำเพิ่มปริมาณอาหารที่มีประโยชน์ (Calorie Surplus) และเล่นเวทเพื่อเพิ่มกล้ามเนื้อ";
            break;
          default:
            evaluation = "สุขภาพโดยรวมอยู่ในเกณฑ์ปกติ";
            recommendation = "รักษาสุขภาพและชั่งน้ำหนักอย่างสม่ำเสมอ";
        }
      } catch (e) {
        evaluation = "เกิดข้อผิดพลาดในการประมวลผล AI";
        recommendation = "ระบบขัดข้อง กรุณาลองใหม่อีกครั้ง";
      }
    } else {
      // กรณี AI โหลดไม่สำเร็จ จะใช้เงื่อนไขธรรมดา (Fallback)
      if (currentBmi > 24.9) {
        recommendation =
            "เน้น Cardio เพื่อเผาผลาญไขมัน + ควบคุมอาหารแบบ Calorie Deficit";
        evaluation = slope > 0.1
            ? "ภาวะน้ำหนักเกินและมีความเสี่ยงเพิ่มขึ้น"
            : "คุณลดน้ำหนักได้ดี";
      } else if (currentBmi >= 18.5) {
        recommendation =
            "แนะนำการออกกำลังกายแบบ Maintainance เพื่อรักษามวลกล้ามเนื้อ";
        evaluation = slope > 0.1
            ? "สุขภาพมาตรฐานแต่เสี่ยงที่จะอ้วนขึ้น"
            : "คุณควบคุมน้ำหนักได้ดี";
      } else {
        recommendation =
            "เน้น Strength Training + เพิ่มปริมาณอาหารแบบ Calorie Surplus";
        evaluation = slope > 0.1
            ? "คุณผอมมากแต่เพิ่มน้ำหนักได้ดี"
            : "คุณผอมมากจนน่าเป็นห่วง";
      }
    }

    return {
      "slope": slope,
      "prediction": prediction,
      "trend": trend,
      "evaluation": evaluation,
      "recommendation": recommendation,
    };
  }

void _listenToDataChanges() {
    // ... โค้ดดึงค่าน้ำหนักสดและชีพจร (ปล่อยไว้เหมือนเดิม) ...

    // 🟢 ดึง UID ของคนที่ล็อกอิน
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid != null) {
      // ดึงประวัติจาก Firestore แบบกรองเฉพาะของตัวเอง
      FirebaseFirestore.instance
          .collection('measurements')
          .where('user_id', isEqualTo: currentUid) // 🟢 เพิ่มบรรทัดนี้: กรองเฉพาะ UID ของตัวเอง
          .orderBy('measured_at', descending: true)
          .snapshots()
          .listen((QuerySnapshot snapshot) {
            _historyRecords.clear();

            for (var doc in snapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;

              DateTime timestamp = DateTime.now();
              if (data['measured_at'] != null) {
                timestamp = (data['measured_at'] as Timestamp).toDate();
              }

              _historyRecords.add(
                BmiRecord(
                  key: doc.id,
                  timestamp: timestamp,
                  weight: (data['weight'] ?? 0).toDouble(),
                  height: (data['height'] ?? 0).toDouble(),
                  heartRate: (data['heart_rate'] ?? 0).toInt(),
                  bmi: (data['bmi'] ?? 0).toDouble(),
                  status: data['body_type']?.toString() ?? "Unknown",
                ),
              );
            }
            notifyListeners();
          });
    }
  }

  void updateHeight(double newHeight) {
    _heightCm = newHeight;
    notifyListeners();
  }

  Future<void> saveCurrentData() async {
    if (_currentWeight == 0) return;

    // 🟢 ดึง UID ของผู้ใช้งานปัจจุบัน
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    
    if (currentUid == null) {
      print("❌ ไม่สามารถบันทึกได้ เนื่องจากยังไม่ได้เข้าสู่ระบบ");
      return;
    }

    try {
      print("👉 กำลังบันทึกข้อมูลลง Firestore...");
      await FirebaseFirestore.instance.collection('measurements').add({
        'user_id': currentUid, // 🟢 เปลี่ยนจาก 'UID_TEST_01' เป็น UID จริงของผู้ใช้
        'device_id': 'DEVICE_01',
        'weight': _currentWeight,
        'height': _heightCm,
        'heart_rate': _currentHeartRate,
        'bmi': bmi,
        'body_type': bodyStatus,
        'measured_at': FieldValue.serverTimestamp(),
      });
      print("✅ บันทึกข้อมูลลง Firestore สำเร็จ!");
    } catch (e) {
      print("❌ เกิดข้อผิดพลาดในการบันทึก: $e");
    }
  }

  Future<void> deleteRecord(int index) async {
    final recordKey = _historyRecords[index].key;
    if (recordKey != null) {
      await FirebaseFirestore.instance
          .collection('measurements')
          .doc(recordKey)
          .delete();
      print("✅ ลบข้อมูลสำเร็จ");
    }
  }
}
