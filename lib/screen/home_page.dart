import 'package:flutter/material.dart';
import 'package:project/providers/weight_provider_bluetooth.dart';
import 'package:project/widgets/measurement_dialog.dart';
import 'package:provider/provider.dart';
import 'package:project/core/app_theme.dart';
import 'package:project/widgets/dashboard_card.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';


// เปลี่ยนจาก StatelessWidget เป็น StatefulWidget
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 1. สร้างตัวแปรเช็คสถานะการบันทึก
  bool _isSaving = false;
  bool _isRefreshing = false;
  bool _isBluetoothBusy = false;

  static const Duration _buttonCooldown = Duration(seconds: 3);

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: _buttonCooldown,
      ),
    );
  }

  Future<void> _waitForCooldown(Stopwatch stopwatch) async {
    final remaining = _buttonCooldown - stopwatch.elapsed;
    if (!remaining.isNegative) await Future.delayed(remaining);
  }

  Future<void> _restartMeasurement() async {
    if (_isRefreshing) return;
    final cooldown = Stopwatch()..start();
    setState(() => _isRefreshing = true);

    try {
      final provider = context.read<WeightProvider>();
      await provider.restartMeasurement();
      _showMessage(
        'เริ่มวัดใหม่แล้ว กรุณายืนนิ่งและวางนิ้วบนเซนเซอร์',
        AppTheme.refreshButton,
      );
    } catch (e) {
      _showMessage('เริ่มวัดใหม่ไม่สำเร็จ: $e', AppTheme.error);
    } finally {
      await _waitForCooldown(cooldown);
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _handleStatusTap(
    BuildContext context,
    WeightProvider provider,
  ) async {
    if (_isBluetoothBusy) return;
    final cooldown = Stopwatch()..start();
    setState(() => _isBluetoothBusy = true);
    try {
      await _onStatusTap(context, provider);
    } finally {
      await _waitForCooldown(cooldown);
      if (mounted) setState(() => _isBluetoothBusy = false);
    }
  }

  Future<void> _saveMeasurement(WeightProvider weightData) async {
    if (_isSaving) return;
    final cooldown = Stopwatch()..start();
    setState(() => _isSaving = true);

    try {
      if (weightData.currentWeight == 0) {
        _showMessage('❌ ไม่สามารถบันทึกได้!', AppTheme.error);
        return;
      }

      await weightData.saveCurrentData();
      _showMessage(
        '✅ บันทึกข้อมูลลงฐานข้อมูลเรียบร้อย!',
        AppTheme.success,
      );
    } catch (e) {
      _showMessage('❌ เกิดข้อผิดพลาด: $e', AppTheme.error);
    } finally {
      await _waitForCooldown(cooldown);
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _onStatusTap(BuildContext context, WeightProvider provider) async {
    if (provider.isConnected) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("ตัดการเชื่อมต่อ"),
          content: Text("ต้องการตัดการเชื่อมต่อกับ '${provider.connectedDeviceName ?? "อุปกรณ์"}' หรือไม่?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("ยกเลิก"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("ตัดการเชื่อมต่อ"),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await provider.disconnectDevice();
      }
      return;
    }

    // เปิด dialog ทันที แล้วให้รายการอุปกรณ์อัปเดตสดระหว่างสแกน
    final scanFuture = provider.getPairedDevices();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("เลือกอุปกรณ์ ESP32"),
          content: SizedBox(
            width: double.maxFinite,
            child: Consumer<WeightProvider>(
              builder: (context, liveProvider, _) {
                return FutureBuilder<void>(
                  future: scanFuture,
                  builder: (context, snapshot) {
                    final devices = liveProvider.pairedDevices;

                    if (devices.isEmpty &&
                        snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: AppTheme.primary,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "กำลังค้นหา ESP32...\nกรุณาเปิดอุปกรณ์และรอสักครู่",
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    if (devices.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          "ยังไม่พบ ESP32_Health หรือ ESP32_SmartScale_BLE\n"
                          "ตรวจสอบว่าเปิด ESP32, Bluetooth และสิทธิ์อุปกรณ์ใกล้เคียงแล้ว",
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final BluetoothDevice device = devices[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.bluetooth,
                            color: AppTheme.primary,
                          ),
                          title: Text(
                            device.platformName.isNotEmpty
                                ? device.platformName
                                : "อุปกรณ์ ESP32",
                          ),
                          subtitle: Text(device.remoteId.str),
                          onTap: liveProvider.isConnecting
                              ? null
                              : () async {
                                  Navigator.pop(context);
                                  await liveProvider.connectToDevice(device);

                                  if (liveProvider.isConnected &&
                                      this.context.mounted) {
                                    showDialog(
                                      context: this.context,
                                      barrierDismissible: false,
                                      builder: (context) =>
                                          const MeasurementFlowDialog(),
                                    );
                                  }
                                },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ปิด"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final weightData = context.watch<WeightProvider>();
    final bool isConnected = weightData.isConnected;
    final bool isConnecting = weightData.isConnecting;
    final String deviceName = isConnected
        ? (weightData.connectedDeviceName ?? "ESP32 Scale")
        : (isConnecting ? "กำลังเชื่อมต่อ..." : "ไม่ได้เชื่อมต่อ");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Scale"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _isBluetoothBusy
                  ? null
                  : () => _handleStatusTap(context, weightData),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppTheme.success
                      : (isConnecting ? Colors.orange : AppTheme.error),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (isConnecting)
                            const Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              deviceName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                      child: Text(
                        isConnected ? "Connected" : (isConnecting ? "Connecting" : "Disconnected"),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isConnected
                              ? AppTheme.success
                              : (isConnecting ? Colors.orange : AppTheme.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              children: [
                DashboardCard(
                  label: "Weight",
                  value: "${weightData.currentWeight.toStringAsFixed(1)} Kg",
                ),
                DashboardCard(
                  label: "Height",
                  value: "${weightData.heightCm.toStringAsFixed(0)} Cm",
                ),
                DashboardCard(
                  label: "BMI",
                  value: weightData.bmi.toStringAsFixed(1),
                ),
                DashboardCard(
                  label: "Heart Rate",
                  value: "${weightData.currentHeartRate} BPM",
                ),
              ],
            ),
            const SizedBox(height: 20),
            DashboardCard(label: "Body", value: weightData.bodyStatus, fullWidth: true),
            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  // 2. ถ้า _isSaving เป็น true ให้ปิดปุ่ม (ตั้งค่าเป็น null)
                  onPressed:
                      _isSaving ? null : () => _saveMeasurement(weightData),
                  // 5. แสดงวงกลมโหลดสลับกับข้อความ Save
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Save",
                          style: TextStyle(color: AppTheme.success),
                        ),
                ),
                ElevatedButton.icon(
                  onPressed: isConnected && !_isRefreshing
                      ? _restartMeasurement
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.refreshButton,
                    foregroundColor: AppTheme.refreshButtonForeground,
                    disabledBackgroundColor:
                        AppTheme.refreshButton.withOpacity(0.35),
                    disabledForegroundColor:
                        AppTheme.refreshButtonForeground,
                  ),
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.refreshButtonForeground,
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_isRefreshing ? "กำลังเริ่มใหม่" : "Refresh"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}