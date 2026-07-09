import 'package:fl_chart/fl_chart.dart';

// ไฟล์นี้เก็บเฉพาะ "ฟังก์ชันคำนวณ/ประมวลผลข้อมูล" สำหรับกราฟ BMI
// (จัดกลุ่มตามเดือน, คำนวณค่าเฉลี่ย, สร้างจุดกราฟ ฯลฯ)
// ไม่มีโค้ด UI/Widget อยู่ในไฟล์นี้เลย
//
// ส่วน UI (MonthlyGraphView, YearlyGraphView, การ์ดต่างๆ, ตัวกราฟ)
// ถูกย้ายไปอยู่ที่ history_graphs_ui.dart และเรียกใช้ฟังก์ชันจากไฟล์นี้

const List<String> thaiMonths = [
  '',
  'ม.ค.',
  'ก.พ.',
  'มี.ค.',
  'เม.ย.',
  'พ.ค.',
  'มิ.ย.',
  'ก.ค.',
  'ส.ค.',
  'ก.ย.',
  'ต.ค.',
  'พ.ย.',
  'ธ.ค.',
];

/// จัดกลุ่ม record ตามเดือน คืนค่าเป็น Map ที่ key คือ "yyyy-MM"
/// (ลำดับของ record ภายในแต่ละเดือนจะเรียงตามลำดับเดิมของ [records])
Map<String, List<dynamic>> groupRecordsByMonth(List<dynamic> records) {
  Map<String, List<dynamic>> monthlyData = {};
  for (var r in records) {
    String key =
        "${r.timestamp.year}-${r.timestamp.month.toString().padLeft(2, '0')}";
    if (!monthlyData.containsKey(key)) monthlyData[key] = [];
    monthlyData[key]!.add(r);
  }
  return monthlyData;
}

/// คืนรายชื่อ key ของเดือนทั้งหมด เรียงจากล่าสุด -> เก่าสุด
List<String> sortedMonthKeysDesc(Map<String, List<dynamic>> monthlyData) {
  return monthlyData.keys.toList()..sort((a, b) => b.compareTo(a));
}

/// คืน record ของเดือนที่เลือก โดยเรียงจาก "เก่าสุด -> ใหม่สุด"
/// (ข้อมูลดิบใน [monthlyData] เรียงใหม่สุดก่อน จึงต้อง reverse)
List<dynamic> recordsOldToNewForMonth(
  Map<String, List<dynamic>> monthlyData,
  String monthKey,
) {
  return monthlyData[monthKey]!.reversed.toList();
}

/// แปลง record (เรียงเก่า->ใหม่) เป็นจุดกราฟ BMI ตามลำดับ index
List<FlSpot> buildSpotsFromRecords(List<dynamic> recordsOldToNew) {
  return recordsOldToNew
      .asMap()
      .entries
      .map((e) => FlSpot(e.key.toDouble(), e.value.bmi))
      .toList();
}

/// สร้าง label แกน X เป็นลำดับที่ (1, 2, 3, ...) ตามจำนวน record
List<String> buildIndexLabels(List<dynamic> recordsOldToNew) {
  return recordsOldToNew
      .asMap()
      .entries
      .map((e) => (e.key + 1).toString())
      .toList();
}

/// ค่าเฉลี่ย BMI ของ record ที่ให้มา (คืน 0.0 ถ้าไม่มีข้อมูล)
double averageBmi(List<dynamic> records) {
  if (records.isEmpty) return 0.0;
  return records.fold(0.0, (sum, item) => sum + item.bmi) / records.length;
}

/// ผลต่างของ BMI ระหว่างค่าล่าสุดกับค่าก่อนหน้า (เรียงเก่า->ใหม่)
/// คืน 0.0 ถ้ามีข้อมูลไม่ถึง 2 รายการ
double bmiChange(List<dynamic> recordsOldToNew) {
  if (recordsOldToNew.length <= 1) return 0.0;
  return recordsOldToNew.last.bmi -
      recordsOldToNew[recordsOldToNew.length - 2].bmi;
}

/// คืนรายการ (เดือน -> records) ของ 12 เดือนล่าสุด เรียงจาก "เก่าสุด -> ใหม่สุด"
List<MapEntry<String, List<dynamic>>> lastTwelveMonthsOldToNew(
  Map<String, List<dynamic>> monthlyData,
) {
  List<MapEntry<String, List<dynamic>>> sortedMonths = monthlyData.entries
      .toList()
    ..sort((a, b) => b.key.compareTo(a.key)); // ใหม่ -> เก่า
  if (sortedMonths.length > 12) sortedMonths = sortedMonths.sublist(0, 12);
  return sortedMonths.reversed.toList(); // เก่า -> ใหม่
}

/// ผลลัพธ์ของการคำนวณกราฟรายปี: จุดกราฟ (ค่าเฉลี่ย BMI ต่อเดือน) + label เดือน
class YearlyGraphData {
  final List<FlSpot> spots;
  final List<String> xLabels;
  const YearlyGraphData(this.spots, this.xLabels);
}

/// คำนวณจุดกราฟและ label เดือน จากรายการเดือน (เรียงเก่า->ใหม่)
YearlyGraphData buildYearlySpotsAndLabels(
  List<MapEntry<String, List<dynamic>>> sortedMonthsOldToNew,
) {
  List<FlSpot> spots = [];
  List<String> xLabels = [];

  for (int i = 0; i < sortedMonthsOldToNew.length; i++) {
    double avgBmi = averageBmi(sortedMonthsOldToNew[i].value);
    spots.add(FlSpot(i.toDouble(), avgBmi));
    xLabels.add(
      thaiMonths[int.parse(sortedMonthsOldToNew[i].key.split('-')[1])],
    );
  }

  return YearlyGraphData(spots, xLabels);
}
