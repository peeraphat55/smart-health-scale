import 'package:flutter/material.dart';
import 'package:project/providers/weight_provider_bluetooth.dart';
import 'package:provider/provider.dart';
import 'package:project/core/app_theme.dart';
import 'package:project/widgets/dashboard_card.dart'; // import ไฟล์นี้เข้าไป

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _editHeightDialog(BuildContext context, WeightProvider provider) {
    TextEditingController heightController = TextEditingController(
      text: provider.heightCm.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("แก้ไขส่วนสูง (Cm)"),
          content: TextField(
            controller: heightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "เช่น 170"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ยกเลิก"),
            ),
            ElevatedButton(
              onPressed: () {
                double? newHeight = double.tryParse(heightController.text);
                if (newHeight != null && newHeight > 0)
                  provider.updateHeight(newHeight);
                Navigator.pop(context);
              },
              child: const Text("บันทึก"),
            ),
          ],
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {
  final weightData = context.watch<WeightProvider>();
  // 🟢 สมมติว่ามีตัวแปรสถานะใน provider หรือคุณจะสร้างขึ้นมาใหม่
  bool isConnected = weightData.currentWeight > 0; 
  String deviceName = isConnected ? "ESP32_Scale_01" : "ไม่ได้เชื่อมต่อ";

  return Scaffold(
    appBar: AppBar(
      title: const Text("Daily BMI"),
      // 🟢 ลบส่วน CircleAvatar ออกเรียบร้อยแล้ว
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 🟢 กล่องสถานะบลูทูธ (แทนที่กล่อง Overweight เดิม)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isConnected ? AppTheme.success : AppTheme.error, // เปลี่ยนสีตามสถานะ
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    deviceName,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                  child: Text(
                    isConnected ? "Connected" : "Disconnected",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isConnected ? AppTheme.success : AppTheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // ... (ส่วน GridView และปุ่ม Save/Delete คงเดิม) ...
            const SizedBox(height: 20),

            // 📍 ค้นหาช่วง GridView.count ในไฟล์ home_page.dart แล้วเปลี่ยนเป็น:
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              children: [
                // 🟢 วาง DashboardCard แทนที่การเรียกฟังก์ชัน _buildDataCard เดิม
                DashboardCard(
                  label: "Weight",
                  value: "${weightData.currentWeight.toStringAsFixed(1)} Kg",
                ),

                GestureDetector(
                  onTap: () => _editHeightDialog(context, weightData),
                  child: DashboardCard(
                    label: "Height",
                    value: "${weightData.heightCm.toStringAsFixed(0)} Cm",
                    isEditable: true,
                  ),
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
                  onPressed: () async {
                    if (weightData.currentWeight == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❌ ไม่สามารถบันทึกได้!'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                      return;
                    }
                    await weightData.saveCurrentData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ บันทึกข้อมูลลงฐานข้อมูลเรียบร้อย!'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  },
                  child: const Text(
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

  Widget _buildDataCard(
    String label,
    String value, {
    bool fullWidth = false,
    bool isEditable = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          if (isEditable)
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(Icons.edit, size: 16, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
