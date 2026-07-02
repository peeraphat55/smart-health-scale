import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/providers/weight_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // ฟังก์ชันสร้าง Popup สำหรับกรอกส่วนสูง
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
                if (newHeight != null && newHeight > 0) {
                  provider.updateHeight(newHeight);
                }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Daily BMI",
          style: TextStyle(
            color: Color(0xFF7B61FF),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(child: Icon(Icons.person)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status Card ด้านบน
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF7B61FF),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    weightData.bodyStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // ปุ่ม Connect แบบดั้งเดิม (ปุ่มประดับ UI)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                    child: const Text(
                      "Connect",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B61FF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Data Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              children: [
                _buildDataCard(
                  "Weight",
                  "${weightData.currentWeight.toStringAsFixed(1)} Kg",
                ),

                GestureDetector(
                  onTap: () => _editHeightDialog(context, weightData),
                  child: _buildDataCard(
                    "Height",
                    "${weightData.heightCm.toStringAsFixed(0)} Cm",
                    isEditable: true,
                  ),
                ),

                _buildDataCard("BMI", weightData.bmi.toStringAsFixed(1)),
                _buildDataCard(
                  "Heart Rate",
                  "${weightData.currentHeartRate} BPM",
                ),
              ],
            ),
            const SizedBox(height: 20),

            // กล่อง Body ด้านล่าง
            _buildDataCard("Body", weightData.bodyStatus, fullWidth: true),

            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    // 1. เช็กก่อนเลยว่าน้ำหนักเป็น 0 ไหม
                    if (weightData.currentWeight == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❌ ไม่สามารถบันทึกได้!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return; // สั่งหยุดทำงานทันที
                    }
                    await weightData.saveCurrentData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ บันทึกข้อมูลลงฐานข้อมูลเรียบร้อย!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.red),
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
        color: const Color(0xFFF3EFFF),
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
                    color: Color(0xFF7B61FF),
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
