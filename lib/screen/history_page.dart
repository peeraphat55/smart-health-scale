import 'package:flutter/material.dart';
import 'package:project/providers/weight_provider_bluetooth.dart';
import 'package:project/screen/history_graphs_ui.dart';
import 'package:provider/provider.dart';
import 'package:project/core/app_theme.dart';

// ไฟล์นี้เก็บเฉพาะโค้ดหน้า UI ของ History (Tab, List สรุป)
// ส่วนกราฟรายเดือน/รายปี (MonthlyGraphView, YearlyGraphView) ถูกย้ายไปอยู่ที่
// history_graphs_ui.dart (UI) และ history_graphs.dart (ฟังก์ชันคำนวณ)
// และถูกเรียกใช้งานผ่าน import ด้านบน

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: const Text("Daily BMI")),
        body: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: "แบบย่อ"),
                Tab(text: "กราฟรายเดือน"),
                Tab(text: "กราฟรายปี"),
              ],
              labelColor: AppTheme.primary,
              indicatorColor: AppTheme.primary,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildSummaryList(context),
                  const MonthlyGraphView(),
                  const YearlyGraphView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryList(BuildContext context) {
    final provider = context.watch<WeightProvider>();
    final records = provider.historyRecords;

    if (records.isEmpty) {
      return const Center(
        child: Text(
          "ยังไม่มีข้อมูลบันทึก",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final dateStr =
            "${record.timestamp.day}/${record.timestamp.month}/${record.timestamp.year + 543}";
        final timeStr =
            "${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')} น.";

        Color statusColor;
String statusText;

switch (record.status) {
  case "Underweight":
    statusText = "ผอม";
    statusColor = AppTheme.statusUnderweight;
    break;
  case "Healthy":
    statusText = "สมส่วน";
    statusColor = AppTheme.statusHealthy;
    break;
  case "Overweight":
    statusText = "น้ำหนักเกิน";
    statusColor = AppTheme.statusOverweight;
    break;
  case "Obese":
    statusText = "อ้วน";
    statusColor = AppTheme.statusObese;
    break;
  default:
    statusText = "ไม่ทราบค่า";
    statusColor = Colors.grey;
}

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppTheme.historyCardBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Center(
                        child: Text(
                          "$dateStr   $timeStr",
                          style: const TextStyle(color: AppTheme.historyLabelColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Weight: ${record.weight.toStringAsFixed(2)} กก.",
                    style: const TextStyle(color: AppTheme.historyLabelColor, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Height: ${record.height.toStringAsFixed(0)} ซม.",
                    style: const TextStyle(color: AppTheme.historyLabelColor, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Heart Rate: ${record.heartRate} ครั้ง/นาที",
                    style: const TextStyle(color: AppTheme.historyLabelColor, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "BMI: ${record.bmi.toStringAsFixed(2)}",
                    style: const TextStyle(color: AppTheme.historyLabelColor, fontSize: 16),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => provider.deleteRecord(index),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
