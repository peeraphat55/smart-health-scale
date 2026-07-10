import 'package:flutter/material.dart';
import 'package:project/model/history_graphs.dart';
import 'package:project/providers/weight_provider_bluetooth.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:project/core/app_theme.dart';
import 'package:project/widgets/ai_analysis_card.dart';

// ไฟล์นี้เก็บเฉพาะ "โค้ด UI/Widget" ของหน้ากราฟ BMI (รายเดือน/รายปี)
// ส่วนการคำนวณ/ประมวลผลข้อมูลทั้งหมดอยู่ที่ history_graphs.dart
// และถูกเรียกใช้งานผ่าน import ด้านบน

// 📊 กราฟรายเดือน
class MonthlyGraphView extends StatefulWidget {
  const MonthlyGraphView({super.key});
  @override
  State<MonthlyGraphView> createState() => _MonthlyGraphViewState();
}

class _MonthlyGraphViewState extends State<MonthlyGraphView> {
  String? selectedMonthKey;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeightProvider>();
    final records = provider.historyRecords;
    final aiData = provider.aiAnalysis;

    if (records.isEmpty) {
      return const Center(
        child: Text(
          "ต้องมีข้อมูลอย่างน้อย 1 รายการเพื่อสร้างกราฟ",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final monthlyData = groupRecordsByMonth(records);
    final monthKeys = sortedMonthKeysDesc(monthlyData);
    if (selectedMonthKey == null || !monthKeys.contains(selectedMonthKey)) {
      selectedMonthKey = monthKeys.first;
    }

    final selectedRecords = recordsOldToNewForMonth(
      monthlyData,
      selectedMonthKey!,
    );
    final spots = buildSpotsFromRecords(selectedRecords);
    final xLabels = buildIndexLabels(selectedRecords);
    final displayValue1 = averageBmi(selectedRecords);
    final displayChange = bmiChange(selectedRecords);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(15),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedMonthKey,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppTheme.primary,
                ),
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Kanit',
                ),
                items: monthKeys.map((key) {
                  final parts = key.split('-');
                  return DropdownMenuItem(
                    value: key,
                    child: Text(
                      "เดือน ${thaiMonths[int.parse(parts[1])]} ${int.parse(parts[0]) + 543}",
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedMonthKey = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          buildBmiGraphBox(context, spots, xLabels),
          const SizedBox(height: 30),
          buildBmiInfoRow(
            title1: "BMI (เฉลี่ยเดือนนี้)",
            value1: displayValue1,
            change: displayChange,
          ),
          const SizedBox(height: 15),
          AIAnalysisBox(aiData: aiData),
        ],
      ),
    );
  }
}

// 📈 กราฟรายปี
class YearlyGraphView extends StatelessWidget {
  const YearlyGraphView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeightProvider>();
    final records = provider.historyRecords;
    final aiData = provider.aiAnalysis;

    if (records.isEmpty) {
      return const Center(
        child: Text(
          "ต้องมีข้อมูลอย่างน้อย 1 รายการเพื่อสร้างกราฟ",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final monthlyData = groupRecordsByMonth(records);
    final sortedMonths = lastTwelveMonthsOldToNew(monthlyData);
    final yearlyData = buildYearlySpotsAndLabels(sortedMonths);
    final spots = yearlyData.spots;
    final xLabels = yearlyData.xLabels;

    final displayValue1 = spots.isNotEmpty
        ? (spots.fold(0.0, (prev, spot) => prev + spot.y) / spots.length)
        : 0.0;
    // คำนวณการเปลี่ยนแปลงรายปี
    double displayChange = 0.0;
    int n = spots.length;
    
    if (n == 2 || n == 3) {
      // กรณีมี 2 หรือ 3 จุด: ใช้ 2 จุดล่าสุดลบกันโดยตรง
      displayChange = spots.last.y - spots[n - 2].y;
    } else if (n >= 4) {
      // กรณีมี 4 จุดขึ้นไป: คำนวณด้วย Linear Regression 4 จุดล่าสุด
      int numPoints = 4;
      List<FlSpot> recentSpots = spots.sublist(n - numPoints, n);

      double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
      for (int i = 0; i < numPoints; i++) {
        double x = (i + 1).toDouble();
        double y = recentSpots[i].y;
        sumX += x;
        sumY += y;
        sumXY += x * y;
        sumX2 += x * x;
      }
      
      double denominator = (numPoints * sumX2) - (sumX * sumX);
      if (denominator != 0) {
        displayChange = ((numPoints * sumXY) - (sumX * sumY)) / denominator;
      }
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          buildBmiGraphBox(context, spots, xLabels),
          const SizedBox(height: 30),
          buildBmiInfoRow(
            title1: "BMI (เฉลี่ยรายปี)",
            value1: displayValue1,
            change: displayChange,
          ),
          const SizedBox(height: 15),
          AIAnalysisBox(aiData: aiData),
        ],
      ),
    );
  }
}

// === ส่วนประกอบ UI ที่ใช้ร่วมกันระหว่างกราฟรายเดือน/รายปี ===

Widget buildBmiGraphBox(
  BuildContext context,
  List<FlSpot> spots,
  List<String> xLabels,
) {
  double screenWidth = MediaQuery.of(context).size.width - 40;

  double chartWidth = spots.length > 8 ? spots.length * 35 : screenWidth;

  return SizedBox(
    height: 250,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: chartWidth,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: spots.isEmpty ? 1 : (spots.length - 1).toDouble(),

            minY: 0,
            maxY: 55,

            // สำหรับแสดงตัวเลขทศนิยม 2 ตำแหน่งเมื่อกด
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      spot.y.toStringAsFixed(2), // แสดง 2 ตำแหน่ง
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),

            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.shade300,
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              },
            ),

            borderData: FlBorderData(
              show: true,
              border: const Border(
                left: BorderSide(color: Colors.grey),
                bottom: BorderSide(color: Colors.grey),
              ),
            ),

            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),

              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),

              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 20,
                  interval: 5,
                  getTitlesWidget: (value, meta) {
                    // ถ้าค่ามากกว่า 50 ให้ส่ง SizedBox ว่างๆ กลับไป (ไม่แสดงเลข)
                    if (value > 50) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),

              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();

                    if (index < 0 || index >= xLabels.length) {
                      return const SizedBox();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        xLabels[index],
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),

            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.blue,
                barWidth: 4,
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// แถวข้อมูลสรุป (ค่าเฉลี่ย BMI + การเปลี่ยนแปลง) ใช้ร่วมกันทั้งกราฟรายเดือน/รายปี
Widget buildBmiInfoRow({
  required String title1,
  required double value1,
  required double change,
}) {
  return Row(
    children: [
      Expanded(
        child: InfoCard(title: title1, value: value1.toStringAsFixed(2)),
      ),
      const SizedBox(width: 15),
      Expanded(
        child: InfoCard(
          title: "การเปลี่ยนแปลง",
          value: "${change > 0 ? '+' : ''}${change.toStringAsFixed(2)} BMI",
        ),
      ),
    ],
  );
}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  const InfoCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
