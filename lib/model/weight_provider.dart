import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  
  final List<BmiRecord> _historyRecords = [];

  final DatabaseReference _weightRef = FirebaseDatabase.instance.ref("smart_scale/current_weight");
  final DatabaseReference _hrRef = FirebaseDatabase.instance.ref("smart_scale/current_heart_rate");
  final DatabaseReference _historyRef = FirebaseDatabase.instance.ref("smart_scale/history");

  double get currentWeight => _currentWeight;
  double get heightCm => _heightCm;
  int get currentHeartRate => _currentHeartRate;
  List<BmiRecord> get historyRecords => _historyRecords;

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

  Map<String, dynamic> get aiAnalysis {
    if (_historyRecords.length < 2) {
      return {
        "slope": 0.0,
        "prediction": 0.0,
        "trend": "รวบรวมข้อมูล...",
        "evaluation": "AI ต้องการข้อมูลประวัติอย่างน้อย 2 ครั้งขึ้นไป",
        "recommendation": "กรุณาชั่งน้ำหนักและบันทึกข้อมูลเพิ่มเติม"
      };
    }

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
    String trend = slope > 0.1 ? "เพิ่มขึ้น 📈" : slope < -0.1 ? "น้อยลง 📉" : "คงที่ ➡️";
    String evaluation = "";
    String recommendation = "";

    if (currentBmi > 24.9) { 
      recommendation = "เน้น Cardio เพื่อเผาผลาญไขมัน + ควบคุมอาหารแบบ Calorie Deficit";
      evaluation = slope > 0.1 ? "ภาวะน้ำหนักเกินและมีความเสี่ยงเพิ่มขึ้น" : slope < -0.1 ? "คุณลดน้ำหนักได้ดี" : "คุณควบคุมน้ำหนักได้ดี";
    } else if (currentBmi >= 18.5) { 
      recommendation = "แนะนำการออกกำลังกายแบบ Maintainance เพื่อรักษามวลกล้ามเนื้อ";
      evaluation = slope > 0.1 ? "สุขภาพอยู่ในเกณฑ์มาตรฐานแต่เสี่ยงที่จะอ้วนขึ้น" : slope < -0.1 ? "คุณลดน้ำหนักได้ดี" : "คุณควบคุมน้ำหนักได้ดี";
    } else { 
      recommendation = "เน้น Strength Training + เพิ่มปริมาณอาหารแบบ Calorie Surplus";
      evaluation = slope > 0.1 ? "คุณผอมมากแต่เพิ่มน้ำหนักได้ดี" : slope < -0.1 ? "คุณผอมมากจนน่าเป็นห่วง" : "คุณผอมมากและควรที่จะเพิ่มน้ำหนัก";
    }

    return {
      "slope": slope,
      "prediction": prediction,
      "trend": trend,
      "evaluation": evaluation,
      "recommendation": recommendation
    };
  }

  WeightProvider() {
    _listenToDataChanges();
  }

  void _listenToDataChanges() {
    _weightRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        _currentWeight = double.parse(event.snapshot.value.toString());
        notifyListeners();
      }
    });

    _hrRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        _currentHeartRate = int.parse(event.snapshot.value.toString());
        notifyListeners();
      }
    });

    _historyRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      _historyRecords.clear(); 

      if (data != null) {
        data.forEach((key, value) {
          final record = value as Map<dynamic, dynamic>;
          _historyRecords.add(
            BmiRecord(
              key: key.toString(), 
              timestamp: DateTime.fromMillisecondsSinceEpoch(int.tryParse(record['timestamp']?.toString() ?? '0') ?? 0),
              weight: double.tryParse(record['weight']?.toString() ?? '0') ?? 0.0,
              height: double.tryParse(record['height']?.toString() ?? '0') ?? 0.0,
              heartRate: int.tryParse(record['heartRate']?.toString() ?? '0') ?? 0,
              bmi: double.tryParse(record['bmi']?.toString() ?? '0') ?? 0.0,
              status: record['status']?.toString() ?? "Unknown",
            )
          );
        });
        _historyRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      notifyListeners(); 
    });
  }

  void updateHeight(double newHeight) {
    _heightCm = newHeight;
    notifyListeners();
  }

  Future<void> saveCurrentData() async {
    // ถ้าน้ำหนักเป็น 0 (ยังไม่ได้ชั่ง) จะไม่บันทึก
    if (_currentWeight == 0) return; 

    // ชี้เป้าหมายไปที่ Collection: measurements ใน Firestore
    CollectionReference measurements = FirebaseFirestore.instance.collection('measurements');

    try {
      // สั่งบันทึกข้อมูลโดยดึงค่าจากตัวแปรใน Provider มาใช้โดยตรง
      await measurements.add({
        'user_id': 'UID_TEST_01', // เดี๋ยวเราค่อยมาแก้ตรงนี้ตอนทำระบบ Login 
        'device_id': 'DEVICE_01',
        'weight': _currentWeight,
        'height': _heightCm,
        'heart_rate': _currentHeartRate,
        'bmi': bmi,
        'body_type': bodyStatus,
        'measured_at': FieldValue.serverTimestamp(), // ประทับเวลาของเซิร์ฟเวอร์
      });
      
      print("✅ บันทึกข้อมูลลง Firestore สำเร็จ!");
      
    } catch (e) {
      print("❌ เกิดข้อผิดพลาดในการบันทึก: $e");
    }
  }

  Future<void> deleteRecord(int index) async {
    final recordKey = _historyRecords[index].key;
    if (recordKey != null) {
      await _historyRef.child(recordKey).remove();
    }
  }
}