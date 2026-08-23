import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:project/core/app_theme.dart';
import 'package:project/model/history_graphs.dart';
import 'package:project/providers/weight_provider_bluetooth.dart';
import 'package:project/widgets/ai_analysis_card.dart';
import 'package:project/widgets/monthly_metric_chart.dart';
import 'package:provider/provider.dart';

class MonthlyGraphView extends StatefulWidget {
  const MonthlyGraphView({super.key});

  @override
  State<MonthlyGraphView> createState() => _MonthlyGraphViewState();
}

class _MonthlyGraphViewState extends State<MonthlyGraphView> {
  int? _selectedYear;
  int? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    final records = context.watch<WeightProvider>().historyRecords;
    final validRecords = records.where(isValidGraphRecord).toList();

    if (validRecords.isEmpty) {
      return const _EmptyGraphMessage(
        message: 'ต้องมีข้อมูลที่วัดครบอย่างน้อย 1 รายการเพื่อสร้างกราฟ',
      );
    }

    validRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final latest = validRecords.first;
    final years = availableYears(validRecords);

    _selectedYear ??= latest.timestamp.year;
    _selectedMonth ??= latest.timestamp.month;
    if (!years.contains(_selectedYear)) _selectedYear = years.first;

    final selectedRecords = recordsForYearMonth(
      validRecords,
      _selectedYear!,
      _selectedMonth!,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _DateFilter(
            years: years,
            selectedYear: _selectedYear!,
            selectedMonth: _selectedMonth!,
            onYearChanged: (value) => setState(() => _selectedYear = value),
            onMonthChanged: (value) => setState(() => _selectedMonth = value),
          ),
          const SizedBox(height: 20),
          if (selectedRecords.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: _EmptyGraphMessage(
                message: 'ไม่มีการบันทึกข้อมูลในปีและเดือนที่เลือก',
              ),
            )
          else ...[
            MonthlyMetricChart(
              title: 'กราฟ BMI',
              averageTitle: 'BMI เฉลี่ยเดือนนี้',
              unit: 'BMI',
              color: AppTheme.bmiGraph,
              metric: HealthMetric.bmi,
              records: selectedRecords,
            ),
            const SizedBox(height: 22),
            MonthlyMetricChart(
              title: 'กราฟน้ำหนัก',
              averageTitle: 'น้ำหนักเฉลี่ยเดือนนี้',
              unit: 'กก.',
              color: AppTheme.weightGraph,
              metric: HealthMetric.weight,
              records: selectedRecords,
            ),
            const SizedBox(height: 22),
            MonthlyMetricChart(
              title: 'กราฟส่วนสูง',
              averageTitle: 'ส่วนสูงเฉลี่ยเดือนนี้',
              unit: 'ซม.',
              color: AppTheme.heightGraph,
              metric: HealthMetric.height,
              records: selectedRecords,
            ),
            const SizedBox(height: 22),
            MonthlyMetricChart(
              title: 'กราฟอัตราการเต้นหัวใจ',
              averageTitle: 'ชีพจรเฉลี่ยเดือนนี้',
              unit: 'BPM',
              color: AppTheme.heartRateGraph,
              metric: HealthMetric.heartRate,
              records: selectedRecords,
            ),
          ],
        ],
      ),
    );
  }
}

class _DateFilter extends StatelessWidget {
  final List<int> years;
  final int selectedYear;
  final int selectedMonth;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<int> onMonthChanged;

  const _DateFilter({
    required this.years,
    required this.selectedYear,
    required this.selectedMonth,
    required this.onYearChanged,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterDropdown<int>(
              label: 'ปี',
              value: selectedYear,
              items: years,
              itemLabel: (year) => '${year + 543}',
              onChanged: onYearChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _FilterDropdown<int>(
              label: 'เดือน',
              value: selectedMonth,
              items: List.generate(12, (index) => index + 1),
              itemLabel: (month) => thaiMonths[month],
              onChanged: onMonthChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppTheme.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primary),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) onChanged(newValue);
      },
    );
  }
}

class _EmptyGraphMessage extends StatelessWidget {
  final String message;
  const _EmptyGraphMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 52, color: AppTheme.emptyData),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.emptyData, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class YearlyGraphView extends StatelessWidget {
  const YearlyGraphView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeightProvider>();
    final monthlyData = groupRecordsByMonth(provider.historyRecords);
    final yearlyData = buildYearlySpotsAndLabels(
      lastTwelveMonthsOldToNew(monthlyData),
    );

    if (yearlyData.spots.isEmpty) {
      return const _EmptyGraphMessage(
        message: 'ต้องมีข้อมูลที่วัดครบอย่างน้อย 1 รายการเพื่อสร้างกราฟ',
      );
    }

    final average = yearlyData.spots.fold<double>(0, (sum, spot) => sum + spot.y) /
        yearlyData.spots.length;
    final change = _spotChange(yearlyData.spots);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _YearlyBmiChart(spots: yearlyData.spots, labels: yearlyData.xLabels),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _YearInfo(title: 'BMI เฉลี่ยรายปี', value: average)),
              const SizedBox(width: 12),
              Expanded(child: _YearInfo(title: 'การเปลี่ยนแปลง', value: change)),
            ],
          ),
          const SizedBox(height: 15),
          AIAnalysisBox(aiData: provider.aiAnalysis),
        ],
      ),
    );
  }
}

double _spotChange(List<FlSpot> spots) {
  if (spots.length <= 1) return 0;
  if (spots.length < 4) return spots.last.y - spots[spots.length - 2].y;
  final recent = spots.sublist(spots.length - 4);
  double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
  for (int index = 0; index < recent.length; index++) {
    final x = (index + 1).toDouble();
    sumX += x;
    sumY += recent[index].y;
    sumXY += x * recent[index].y;
    sumX2 += x * x;
  }
  final denominator = recent.length * sumX2 - sumX * sumX;
  return denominator == 0
      ? 0
      : (recent.length * sumXY - sumX * sumY) / denominator;
}

class _YearlyBmiChart extends StatelessWidget {
  final List<FlSpot> spots;
  final List<String> labels;
  const _YearlyBmiChart({required this.spots, required this.labels});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
          maxY: 55,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppTheme.graphGrid,
              dashArray: [5, 5],
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) return const SizedBox();
                  return Text(labels[index], style: const TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.bmiGraph,
              barWidth: 4,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearInfo extends StatelessWidget {
  final String title;
  final double value;
  const _YearInfo({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center),
          const SizedBox(height: 5),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(
              color: AppTheme.bmiGraph,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
