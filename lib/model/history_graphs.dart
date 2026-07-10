import 'package:fl_chart/fl_chart.dart';

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

Map<String, List<dynamic>> groupRecordsByMonth(List<dynamic> records) {
  Map<String, List<dynamic>> monthlyData = {};
  for (var r in records) {
    
    // ถ้าค่าใดค่าหนึ่งเป็น 0 หรือสถานะไม่ได้อยู่ใน 4 ค่ามาตรฐาน (ซึ่งก็คือสถานะ "ไม่ทราบค่า")
    if (r.weight == 0 || r.height == 0 || r.bmi == 0 ||
        !(r.status == "Underweight" || r.status == "Healthy" || 
          r.status == "Overweight" || r.status == "Obese")) {
      continue; // ข้ามการทำงานรอบนี้ไปเลย (ไม่นำข้อมูลนี้ไปใส่ในกราฟ)
    }

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

/// ผลต่างของ BMI โดยใช้ Linear Regression จาก 4 จุดล่าสุด (หาแนวโน้มที่เสถียรขึ้น)
double bmiChange(List<dynamic> recordsOldToNew) {
  int n = recordsOldToNew.length;
  
  if (n <= 1) return 0.0; // ข้อมูลไม่พอเปรียบเทียบ

  // กรณีมี 2 หรือ 3 จุด ให้หาผลต่างจาก 2 จุดล่าสุด
  if (n == 2 || n == 3) {
    return recordsOldToNew.last.bmi - recordsOldToNew[n - 2].bmi;
  }

  // กรณีมีตั้งแต่ 4 จุดขึ้นไป ใช้ Linear Regression กับ 4 จุดล่าสุด
  int numPoints = 4;
  List<dynamic> recentRecords = recordsOldToNew.sublist(n - numPoints, n);

  double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
  for (int i = 0; i < numPoints; i++) {
    double x = (i + 1).toDouble();
    double y = recentRecords[i].bmi;
    
    sumX += x;
    sumY += y;
    sumXY += x * y;
    sumX2 += x * x;
  }

  double denominator = (numPoints * sumX2) - (sumX * sumX);
  if (denominator == 0) return 0.0;

  return ((numPoints * sumXY) - (sumX * sumY)) / denominator;
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
