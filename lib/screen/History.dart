import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/model/weight_provider.dart';
import 'package:fl_chart/fl_chart.dart'; 

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Daily BMI", style: TextStyle(color: Color(0xFF7B61FF), fontWeight: FontWeight.bold, fontSize: 24)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            const TabBar(
              tabs: [Tab(text: "แบบย่อ"), Tab(text: "กราฟรายเดือน"), Tab(text: "กราฟรายปี")],
              labelColor: Color(0xFF7B61FF),
              indicatorColor: Color(0xFF7B61FF),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildSummaryList(context),
                  const MonthlyGraphView(), 
                  const YearlyGraphView(),  
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryList(BuildContext context) {
    final provider = context.watch<WeightProvider>();
    final records = provider.historyRecords;

    if (records.isEmpty) {
      return const Center(child: Text("ยังไม่มีข้อมูลบันทึก", style: TextStyle(color: Colors.grey, fontSize: 16)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final dateStr = "${record.timestamp.day}/${record.timestamp.month}/${record.timestamp.year + 543}";
        final timeStr = "${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')} น.";

        Color statusColor = Colors.green;
        String statusText = "สมส่วน";
        if (record.status == "Underweight") { statusText = "ผอมเกินไป"; statusColor = Colors.orange; }
        else if (record.status == "Healthy") { statusText = "สมส่วน"; statusColor = Colors.green; }
        else if (record.status == "Overweight") { statusText = "น้ำหนักเกิน"; statusColor = Colors.orangeAccent; }
        else if (record.status == "Obese") { statusText = "อ้วน"; statusColor = Colors.red; }

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF80F0F0), 
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Text("$dateStr   $timeStr", style: const TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 15),
                  Text("Weight: ${record.weight.toStringAsFixed(2)} กก.", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text("Height: ${record.height.toStringAsFixed(0)} ซม.", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text("Heart Rate: ${record.heartRate} ครั้ง/นาที", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text("BMI: ${record.bmi.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16)),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(15)),
                  child: Text(statusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => provider.deleteRecord(index), 
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFFF6B6B), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.delete, color: Colors.white, size: 24),
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

// ==========================================
// 📈 คลาสสำหรับกราฟ "รายเดือน"
// ==========================================
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
      return const Center(child: Text("ต้องมีข้อมูลอย่างน้อย 1 รายการเพื่อสร้างกราฟ", style: TextStyle(color: Colors.grey)));
    }

    Map<String, List<BmiRecord>> monthlyData = {};
    for (var r in records) {
      String key = "${r.timestamp.year}-${r.timestamp.month.toString().padLeft(2, '0')}";
      if (!monthlyData.containsKey(key)) monthlyData[key] = [];
      monthlyData[key]!.add(r);
    }

    List<String> monthKeys = monthlyData.keys.toList();
    monthKeys.sort((a, b) => b.compareTo(a)); 

    if (selectedMonthKey == null || !monthKeys.contains(selectedMonthKey)) {
      selectedMonthKey = monthKeys.first;
    }

    List<BmiRecord> selectedRecords = monthlyData[selectedMonthKey]!.reversed.toList();

    List<FlSpot> spots = selectedRecords.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.bmi)).toList();
    
    double minY = spots.isNotEmpty ? spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 1.0 : 0.0;
    double maxY = spots.isNotEmpty ? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1.0 : 0.0;

    double totalBmi = selectedRecords.fold(0.0, (sum, item) => sum + item.bmi);
    double displayValue1 = selectedRecords.isNotEmpty ? (totalBmi / selectedRecords.length) : 0.0;
    
    double displayChange = 0.0;
    if (selectedRecords.length > 1) {
      displayChange = selectedRecords.last.bmi - selectedRecords[selectedRecords.length - 2].bmi; 
    }

    List<String> xLabels = selectedRecords.asMap().entries.map((e) => (e.key + 1).toString()).toList();

    final List<String> thaiMonths = ['', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EFFF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedMonthKey,
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF7B61FF)),
                style: const TextStyle(color: Color(0xFF7B61FF), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Kanit'),
                items: monthKeys.map((key) {
                  final parts = key.split('-');
                  final year = int.parse(parts[0]) + 543;
                  final month = int.parse(parts[1]);
                  return DropdownMenuItem(
                    value: key,
                    child: Text("เดือน ${thaiMonths[month]} $year"),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      selectedMonthKey = val; 
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // กราฟเส้น
          Container(
            height: 250,
            padding: const EdgeInsets.only(right: 20, top: 20),
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        return LineTooltipItem(
                          touchedSpot.y.toStringAsFixed(2),
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: const FlGridData(show: true, drawHorizontalLine: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35, 
                      interval: 1, // 💡 บังคับให้แกน Y โชว์เฉพาะจำนวนเต็ม (ห่างทีละ 1)
                      getTitlesWidget: (value, meta) {
                        if (value % 1 == 0) { // โชว์เฉพาะเลขที่ไม่ทีทศนิยม
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 12, color: Colors.blueAccent)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, 
                      reservedSize: 30,
                      interval: 1, 
                      getTitlesWidget: (value, meta) {
                        if (value % 1 == 0) {
                          int index = value.toInt();
                          if (index >= 0 && index < xLabels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(xLabels[index], style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                            );
                          }
                        }
                        return const Text('');
                      },
                    ),
                  ), 
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF00BFFF), 
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true), 
                    belowBarData: BarAreaData(show: true, color: const Color(0xFF00BFFF).withValues(alpha: 0.1)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          Row(
            children: [
              Expanded(child: InfoCard(title: "BMI (เฉลี่ยเดือนนี้)", value: displayValue1.toStringAsFixed(2))),
              const SizedBox(width: 15),
              Expanded(child: InfoCard(title: "การเปลี่ยนแปลง", value: "${displayChange > 0 ? '+' : ''}${displayChange.toStringAsFixed(2)} BMI")),
            ],
          ),
          const SizedBox(height: 15),

          AIAnalysisBox(aiData: aiData),
        ],
      ),
    );
  }
}

// ==========================================
// 📊 คลาสสำหรับกราฟ "รายปี"
// ==========================================
class YearlyGraphView extends StatelessWidget {
  const YearlyGraphView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeightProvider>();
    final records = provider.historyRecords;
    final aiData = provider.aiAnalysis;

    if (records.isEmpty) {
      return const Center(child: Text("ต้องมีข้อมูลอย่างน้อย 1 รายการเพื่อสร้างกราฟ", style: TextStyle(color: Colors.grey)));
    }

    List<FlSpot> spots = [];
    List<String> xLabels = [];
    double displayValue1 = 0.0;
    double displayChange = 0.0;

    Map<String, List<BmiRecord>> monthlyData = {};
    for (var r in records) {
      String key = "${r.timestamp.year}-${r.timestamp.month.toString().padLeft(2, '0')}";
      if (!monthlyData.containsKey(key)) monthlyData[key] = [];
      monthlyData[key]!.add(r);
    }
    
    List<MapEntry<String, List<BmiRecord>>> sortedMonths = monthlyData.entries.toList();
    sortedMonths.sort((a, b) => b.key.compareTo(a.key));
    
    if (sortedMonths.length > 12) sortedMonths = sortedMonths.sublist(0, 12);
    sortedMonths = sortedMonths.reversed.toList();
    
    final List<String> thaiMonths = ['', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];

    for (int i = 0; i < sortedMonths.length; i++) {
      List<BmiRecord> monthRecords = sortedMonths[i].value;
      double avgBmi = monthRecords.map((e) => e.bmi).reduce((a, b) => a + b) / monthRecords.length;
      spots.add(FlSpot(i.toDouble(), avgBmi));
      
      int monthNum = int.parse(sortedMonths[i].key.split('-')[1]);
      xLabels.add(thaiMonths[monthNum]);
    }

    double minY = spots.isNotEmpty ? spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 1.0 : 0.0;
    double maxY = spots.isNotEmpty ? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1.0 : 0.0;

    if (spots.isNotEmpty) {
      double sumYearlyBmi = spots.fold(0.0, (prev, spot) => prev + spot.y);
      displayValue1 = sumYearlyBmi / spots.length;
    }
    
    if (spots.length > 1) {
      displayChange = spots.last.y - spots[spots.length - 2].y; 
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            height: 250,
            padding: const EdgeInsets.only(right: 20, top: 20),
            child: LineChart(
              LineChartData(
                minY: minY, 
                maxY: maxY, 
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        return LineTooltipItem(
                          touchedSpot.y.toStringAsFixed(2),
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: const FlGridData(show: true, drawHorizontalLine: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35, 
                      interval: 1, // 💡 บังคับให้แกน Y โชว์เฉพาะจำนวนเต็ม (ห่างทีละ 1)
                      getTitlesWidget: (value, meta) {
                        if (value % 1 == 0) { // โชว์เฉพาะเลขที่ไม่ทีทศนิยม
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 12, color: Colors.blueAccent)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, 
                      reservedSize: 30,
                      interval: 1, 
                      getTitlesWidget: (value, meta) {
                        if (value % 1 == 0) {
                          int index = value.toInt();
                          if (index >= 0 && index < xLabels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(xLabels[index], style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                            );
                          }
                        }
                        return const Text('');
                      },
                    ),
                  ), 
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF00BFFF), 
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true), 
                    belowBarData: BarAreaData(show: true, color: const Color(0xFF00BFFF).withValues(alpha: 0.1)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          Row(
            children: [
              Expanded(child: InfoCard(title: "BMI (เฉลี่ยรายปี)", value: displayValue1.toStringAsFixed(2))),
              const SizedBox(width: 15),
              Expanded(child: InfoCard(title: "การเปลี่ยนแปลง", value: "${displayChange > 0 ? '+' : ''}${displayChange.toStringAsFixed(2)} BMI")),
            ],
          ),
          const SizedBox(height: 15),

          AIAnalysisBox(aiData: aiData),
        ],
      ),
    );
  }
}

// ==========================================
// 🧩 คอมโพเนนต์ที่ใช้ร่วมกัน
// ==========================================
class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  
  const InfoCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFFF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF7B61FF))),
        ],
      ),
    );
  }
}

class AIAnalysisBox extends StatelessWidget {
  final Map<String, dynamic> aiData;
  const AIAnalysisBox({super.key, required this.aiData});

  @override
  Widget build(BuildContext context) {
    String predictionText = '-';
    if (aiData['prediction'] != null && aiData['prediction'] is double && aiData['prediction'] > 0) {
      predictionText = (aiData['prediction'] as double).toStringAsFixed(2);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E6), 
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.smart_toy, color: Colors.deepOrange),
              SizedBox(width: 10),
              Text("AI วิเคราะห์แนวโน้ม", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
            ],
          ),
          const Divider(color: Colors.orangeAccent),
          const SizedBox(height: 10),
          Center(child: Text("แนวโน้ม: ${aiData['trend'] ?? '-'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          Center(child: Text("คาดการณ์ BMI ครั้งถัดไป: $predictionText", style: const TextStyle(fontSize: 16))),
          
          const SizedBox(height: 20),
          const Text("📌 การประเมินสถานะ:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
          const SizedBox(height: 5),
          Text(aiData['evaluation'] ?? '-', style: const TextStyle(fontSize: 15, color: Colors.black87)),
          
          const SizedBox(height: 15),
          const Text("💡 คำแนะนำจากระบบ:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 5),
          Text(aiData['recommendation'] ?? '-', style: const TextStyle(fontSize: 15, color: Colors.black87)),
        ],
      ),
    );
  }
}