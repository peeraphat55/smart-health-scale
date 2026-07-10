import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project/model/bmi_record.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';

class WeightProvider with ChangeNotifier {
  double _currentWeight = 50.0;
  double _heightCm = 163.0;
  int _currentHeartRate = 80;
  double _receivedBmi = 38.0;

  int _age = 0;
  int _gender = 0;

  final List<BmiRecord> _historyRecords = [];

  Interpreter? _interpreter;

  // ---------------- Bluetooth (ESP32) ----------------
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;
  List<BluetoothDevice> _pairedDevices = [];
  BluetoothDevice? _connectedDevice;
  bool _isConnecting = false;
  bool _isConnected = false;
  String _btBuffer = ''; // เก็บข้อมูลที่ยังไม่ครบบรรทัด (ESP32 ส่งมาเป็น chunk)

  double get bmi => _receivedBmi;
  double get currentWeight => _currentWeight;
  double get heightCm => _heightCm;
  int get currentHeartRate => _currentHeartRate;
  int get age => _age;
  int get gender => _gender;
  List<BmiRecord> get historyRecords => _historyRecords;

  List<BluetoothDevice> get pairedDevices => _pairedDevices;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  String? get connectedDeviceName => _connectedDevice?.name;

  WeightProvider() {
    _listenToDataChanges();
    _loadAIModel();
    _initBluetooth();
  }

  // ---------------------------------------------------------------------
  // BLUETOOTH: setup, scan, connect, listen
  // ---------------------------------------------------------------------

  Future<void> _initBluetooth() async {
  bool granted = await _requestBluetoothPermissions();
  if (!granted) {
    print("❌ ผู้ใช้ไม่ได้ให้สิทธิ์ Bluetooth/Location จึงยังเชื่อมต่อไม่ได้");
    return;
  }

  try {
    bool? isEnabled = await _bluetooth.isEnabled;
    if (isEnabled != true) {
      await _bluetooth.requestEnable();
    }
    await getPairedDevices();
  } catch (e) {
    print("❌ Bluetooth init error: $e");
  }
}

Future<bool> _requestBluetoothPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
    Permission.locationWhenInUse,
  ].request();

  return statuses.values.every((status) => status.isGranted);
}

  /// ดึงรายชื่ออุปกรณ์ที่จับคู่ (paired) ไว้แล้วในตัวเครื่อง
  /// อย่าลืม: ต้องไปจับคู่ ESP32_SmartScale ผ่านหน้า Bluetooth settings ของมือถือก่อน
  Future<void> getPairedDevices() async {
    try {
      List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
      _pairedDevices = devices;
      notifyListeners();
    } catch (e) {
      print("❌ ดึงรายชื่ออุปกรณ์ที่จับคู่ไม่สำเร็จ: $e");
    }
  }

  /// เชื่อมต่อไปยังอุปกรณ์ ESP32 ที่เลือก (เรียกจากหน้าจอเลือกอุปกรณ์)
  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_isConnecting || _isConnected) return;

    _isConnecting = true;
    notifyListeners();

    try {
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(device.address);
      _connection = connection;
      _connectedDevice = device;
      _isConnected = true;
      _isConnecting = false;
      notifyListeners();

      print("✅ เชื่อมต่อ ${device.name} สำเร็จ");

      _connection!.input!.listen(
        _onDataReceived,
        onDone: () {
          print("🔌 การเชื่อมต่อบลูทูธถูกตัด");
          _isConnected = false;
          _connectedDevice = null;
          _connection = null;
          notifyListeners();
        },
        onError: (error) {
          print("❌ Bluetooth stream error: $error");
          _isConnected = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print("❌ เชื่อมต่อไม่สำเร็จ: $e");
      _isConnecting = false;
      _isConnected = false;
      notifyListeners();
    }
  }

  Future<void> disconnectDevice() async {
    try {
      await _connection?.finish();
    } catch (_) {}
    _connection = null;
    _connectedDevice = null;
    _isConnected = false;
    notifyListeners();
  }

  /// ESP32 อาจส่งข้อมูลมาไม่ครบบรรทัดในครั้งเดียว จึงต้อง buffer แล้วตัดด้วย \n
  void _onDataReceived(List<int> data) {
    _btBuffer += String.fromCharCodes(data);

    while (_btBuffer.contains('\n')) {
      int index = _btBuffer.indexOf('\n');
      String line = _btBuffer.substring(0, index).trim();
      _btBuffer = _btBuffer.substring(index + 1);
      if (line.isNotEmpty) {
        _parseSensorLine(line);
      }
    }
  }

  /// รับข้อมูล string รูปแบบ: "น้ำหนัก,ส่วนสูง,ชีพจร,bmi" เช่น "70.0,155.0,80,29.1"
  /// (ต้องตรงกับรูปแบบที่ฝั่ง ESP32 (esp32_smart_scale.ino) ส่งออกมา)
  void _parseSensorLine(String line) {
    try {
      List<String> values = line.split(',');
      if (values.length == 4) {
        double weight = double.parse(values[0]);
        double height = double.parse(values[1]);
        int heartRate = int.parse(values[2]);
        double bmiValue = double.parse(values[3]);

        // ความสูงเท่ากับ 0 หมายถึง ESP32 ยังอ่านค่าไม่ได้ (ยังไม่มีคนยืน) -> ข้ามไปก่อน
        if (height <= 0) return;

        _currentWeight = weight;
        _heightCm = height;
        _currentHeartRate = heartRate;
        _receivedBmi = bmiValue;
        notifyListeners();
      }
    } catch (e) {
      print("❌ Error parsing sensor data: '$line' -> $e");
    }
  }

  // ---------------------------------------------------------------------
  // AI MODEL / Firestore ประวัติ (เดิม ไม่เปลี่ยนแปลง)
  // ---------------------------------------------------------------------

  Future<void> _loadAIModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/health_model.tflite');
      print("✅ โหลดโมเดล AI (TFLite) สำเร็จ!");
    } catch (e) {
      print("❌ โหลดโมเดล AI ไม่สำเร็จ: $e");
    }
  }

  void updateProfile(int newAge, int newGender) {
    _age = newAge;
    _gender = newGender;
    notifyListeners();
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
        "recommendation": "กรุณาชั่งน้ำหนักและบันทึกข้อมูลเพิ่มเติม",
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

    String trend = slope > 0.1 ? "เพิ่มขึ้น 📈" : slope < -0.1 ? "ลดลง 📉" : "คงที่ ➡️";
    String evaluation = "";
    String recommendation = "";

    if (_interpreter != null) {
      var input = [[_gender.toDouble(), _age.toDouble(), currentBmi, slope]];
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
            recommendation = "ออกกำลังกายแบบ Maintainance คาร์ดิโอ 3 วัน/สัปดาห์ เพื่อรักษามวลกล้ามเนื้อ";
            break;
          case 1:
            evaluation = "ภาวะน้ำหนักเกินและกราฟกำลังพุ่งขึ้น ⚠️";
            recommendation = "ควรเริ่มควบคุมอาหารแบบ Calorie Deficit ทันที และเน้นคาร์ดิโออย่างน้อย 4 วัน/สัปดาห์";
            break;
          case 2:
            evaluation = "น้ำหนักเกินเกณฑ์ แต่กำลังลดลงได้ดี 👏";
            recommendation = "คุณมาถูกทางแล้ว! รักษาวินัยคาร์ดิโอไว้ และเริ่มเพิ่ม Weight Training";
            break;
          case 3:
            evaluation = "สุขภาพอยู่ในเกณฑ์มาตรฐาน แต่น้ำหนักพุ่งเร็วไปนิด";
            recommendation = "ระวังการรับประทานแป้งและน้ำตาลในช่วงนี้ ลองเพิ่มการเดินในชีวิตประจำวัน";
            break;
          case 4:
            evaluation = "รูปร่างสมส่วน แต่น้ำหนักลดลงเร็วจนน่ากังวล";
            recommendation = "ทานโปรตีนให้เพียงพอ เพื่อป้องกันภาวะสูญเสียมวลกล้ามเนื้อ";
            break;
          case 5:
            evaluation = "คุณมีภาวะน้ำหนักต่ำกว่าเกณฑ์ (ผอมเกินไป)";
            recommendation = "แนะนำเพิ่มปริมาณอาหารที่มีประโยชน์ (Calorie Surplus) และเล่นเวทเพื่อเพิ่มกล้ามเนื้อ";
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
      evaluation = "ระบบ AI ไม่พร้อมทำงาน";
      recommendation = "โปรดอัปเดตหรือตรวจสอบแอปพลิเคชัน";
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
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid != null) {
      FirebaseFirestore.instance
          .collection('measurements')
          .where('user_id', isEqualTo: currentUid)
          .orderBy('measured_at', descending: true)
          .snapshots()
          .listen((QuerySnapshot snapshot) {
        print("📥 ได้รับข้อมูลใหม่จำนวน: ${snapshot.docs.length} รายการ");
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
      }, onError: (error) {
        print("❌ เกิดข้อผิดพลาดขณะฟัง Firestore: $error");
      });
    }
  }

  void updateHeight(double newHeight) {
    _heightCm = newHeight;
    notifyListeners();
  }

  Future<void> saveCurrentData() async {
    if (_currentWeight == 0) return;

    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    try {
      await FirebaseFirestore.instance.collection('measurements').add({
        'user_id': currentUid,
        'device_id': _connectedDevice?.address ?? 'DEVICE_01',
        'weight': _currentWeight,
        'height': _heightCm,
        'heart_rate': _currentHeartRate,
        'bmi': bmi,
        'body_type': bodyStatus,
        'measured_at': FieldValue.serverTimestamp(),
      });

      print("✅ บันทึกและระบบจะอัปเดตประวัติให้อัตโนมัติ!");
    } catch (e) {
      print("❌ เกิดข้อผิดพลาด: $e");
    }
  }

  Future<void> deleteRecord(int index) async {
    final recordKey = _historyRecords[index].key;
    if (recordKey != null) {
      await FirebaseFirestore.instance.collection('measurements').doc(recordKey).delete();
    }
  }

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }
}
