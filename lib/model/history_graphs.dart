import 'package:fl_chart/fl_chart.dart';

const List<String> thaiMonths = [
  '',
  'มกราคม',
  'กุมภาพันธ์',
  'มีนาคม',
  'เมษายน',
  'พฤษภาคม',
  'มิถุนายน',
  'กรกฎาคม',
  'สิงหาคม',
  'กันยายน',
  'ตุลาคม',
  'พฤศจิกายน',
  'ธันวาคม',
];

const List<String> thaiMonthsShort = [
  '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
  'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
];

enum HealthMetric { bmi, weight, height, heartRate }

double metricValue(dynamic record, HealthMetric metric) {
  switch (metric) {
    case HealthMetric.bmi:
      return record.bmi.toDouble();
    case HealthMetric.weight:
      return record.weight.toDouble();
    case HealthMetric.height:
      return record.height.toDouble();
    case HealthMetric.heartRate:
      return record.heartRate.toDouble();
  }
}

bool isValidGraphRecord(dynamic record) {
  return record.weight > 0 &&
      record.height > 0 &&
      record.bmi > 0 &&
      record.heartRate > 0;
}

List<int> availableYears(List<dynamic> records) {
  final years = records
      .where(isValidGraphRecord)
      .map<int>((record) => record.timestamp.year as int)
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));
  return years;
}

List<dynamic> recordsForYearMonth(
  List<dynamic> records,
  int year,
  int month,
) {
  final filtered = records.where((record) {
    return isValidGraphRecord(record) &&
        record.timestamp.year == year &&
        record.timestamp.month == month;
  }).toList();
  filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return filtered;
}

List<FlSpot> buildMetricSpots(
  List<dynamic> recordsOldToNew,
  HealthMetric metric,
) {
  return recordsOldToNew.asMap().entries.map((entry) {
    return FlSpot(
      (entry.key + 1).toDouble(),
      metricValue(entry.value, metric),
    );
  }).toList();
}

List<String> buildIndexLabels(List<dynamic> recordsOldToNew) {
  return List.generate(
    recordsOldToNew.length,
    (index) => (index + 1).toString(),
  );
}

double averageMetric(List<dynamic> records, HealthMetric metric) {
  if (records.isEmpty) return 0;
  final total = records.fold<double>(
    0,
    (sum, record) => sum + metricValue(record, metric),
  );
  return total / records.length;
}

/// แนวโน้มจาก 4 รายการล่าสุด ถ้ามี 2-3 รายการจะใช้ผลต่าง 2 รายการล่าสุด
double metricChange(List<dynamic> recordsOldToNew, HealthMetric metric) {
  final count = recordsOldToNew.length;
  if (count <= 1) return 0;

  if (count < 4) {
    return metricValue(recordsOldToNew.last, metric) -
        metricValue(recordsOldToNew[count - 2], metric);
  }

  const pointCount = 4;
  final recent = recordsOldToNew.sublist(count - pointCount);
  double sumX = 0;
  double sumY = 0;
  double sumXY = 0;
  double sumX2 = 0;

  for (int index = 0; index < pointCount; index++) {
    final x = (index + 1).toDouble();
    final y = metricValue(recent[index], metric);
    sumX += x;
    sumY += y;
    sumXY += x * y;
    sumX2 += x * x;
  }

  final denominator = pointCount * sumX2 - sumX * sumX;
  if (denominator == 0) return 0;
  return (pointCount * sumXY - sumX * sumY) / denominator;
}

Map<String, List<dynamic>> groupRecordsByMonth(List<dynamic> records) {
  final result = <String, List<dynamic>>{};
  for (final record in records.where(isValidGraphRecord)) {
    final key =
        '${record.timestamp.year}-${record.timestamp.month.toString().padLeft(2, '0')}';
    result.putIfAbsent(key, () => []).add(record);
  }
  return result;
}

List<MapEntry<String, List<dynamic>>> lastTwelveMonthsOldToNew(
  Map<String, List<dynamic>> monthlyData,
) {
  var months = monthlyData.entries.toList()
    ..sort((a, b) => b.key.compareTo(a.key));
  if (months.length > 12) months = months.sublist(0, 12);
  return months.reversed.toList();
}

class YearlyGraphData {
  final List<FlSpot> spots;
  final List<String> xLabels;
  const YearlyGraphData(this.spots, this.xLabels);
}

YearlyGraphData buildYearlySpotsAndLabels(
  List<MapEntry<String, List<dynamic>>> months,
) {
  final spots = <FlSpot>[];
  final labels = <String>[];
  for (int index = 0; index < months.length; index++) {
    spots.add(FlSpot(
      index.toDouble(),
      averageMetric(months[index].value, HealthMetric.bmi),
    ));
    labels.add(thaiMonthsShort[int.parse(months[index].key.split('-')[1])]);
  }
  return YearlyGraphData(spots, labels);
}
