import 'package:flutter/material.dart';
import 'package:project/providers/weight_provider_bluetooth.dart';
import 'package:provider/provider.dart';
import 'package:project/core/app_theme.dart';
import 'package:project/widgets/dashboard_card.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';

// เปลี่ยนจาก StatelessWidget เป็น StatefulWidget
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 1. สร้างตัวแปรเช็คสถานะการบันทึก
  bool _isSaving = false;

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

    // ยังไม่เชื่อมต่อ -> รีเฟรชรายชื่ออุปกรณ์ที่จับคู่ไว้ แล้วเปิด dialog เลือกอุปกรณ์
    await provider.getPairedDevices();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("เลือกอุปกรณ์ ESP32"),
          content: SizedBox(
            width: double.maxFinite,
            child: provider.pairedDevices.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      "ยังไม่พบอุปกรณ์ที่จับคู่ไว้\nกรุณาไปจับคู่ 'ESP32_SmartScale' ผ่านหน้า Bluetooth settings ของเครื่องก่อน",
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: provider.pairedDevices.length,
                    itemBuilder: (context, index) {
                      final BluetoothDevice device = provider.pairedDevices[index];
                      return ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(device.name ?? "อุปกรณ์ไม่ทราบชื่อ"),
                        subtitle: Text(device.address),
                        onTap: () {
                          Navigator.pop(context);
                          provider.connectToDevice(device);
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
        : (isConnecting ? "กำลังเชื่อมต่อ..." : "ไม่ได้เชื่อมต่อ (แตะเพื่อเชื่อมต่อ)");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Scale"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _onStatusTap(context, weightData),
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
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (weightData.currentWeight == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('❌ ไม่สามารถบันทึกได้!'),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                            return;
                          }

                          // 3. ล็อคปุ่ม
                          setState(() {
                            _isSaving = true;
                          });

                          try {
                            // บันทึกข้อมูล
                            await weightData.saveCurrentData();
                            
                            // เพิ่มการดีเลย์ 1.5 วินาที เพื่อกันการกดรัว
                            await Future.delayed(const Duration(milliseconds: 1500));

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ บันทึกข้อมูลลงฐานข้อมูลเรียบร้อย!'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ เกิดข้อผิดพลาด: $e'),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                          } finally {
                            // 4. ปลดล็อคปุ่มเสมอ
                            if (mounted) {
                              setState(() {
                                _isSaving = false;
                              });
                            }
                          }
                        },
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
                ElevatedButton(
                  onPressed: () {},
                  child: const Text(
                    "Delete",
                    style: TextStyle(color: AppTheme.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}