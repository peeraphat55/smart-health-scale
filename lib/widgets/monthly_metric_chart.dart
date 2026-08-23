import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:project/core/app_theme.dart';
import 'package:project/model/history_graphs.dart';

class MonthlyMetricChart extends StatelessWidget {
  final String title;
  final String averageTitle;
  final String unit;
  final Color color;
  final HealthMetric metric;
  final List<dynamic> records;

  const MonthlyMetricChart({
    super.key,
    required this.title,
    required this.averageTitle,
    required this.unit,
    required this.color,
    required this.metric,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final spots = buildMetricSpots(records, metric);
    final labels = buildIndexLabels(records);
    final average = averageMetric(records, metric);
    final change = metricChange(records, metric);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.graphCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 230,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: math
                    .max(
                      MediaQuery.sizeOf(context).width - 74,
                      spots.length * 48,
                    )
                    .toDouble(),
                child: LineChart(
                  LineChartData(
                    minX: 1,
                    maxX: math.max(1, spots.length).toDouble(),
                    minY: 0,
                    maxY: _maxY(),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (items) => items.map((spot) {
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(metric == HealthMetric.heartRate ? 0 : 2)} $unit',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _yInterval(),
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppTheme.graphGrid,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        left: BorderSide(color: AppTheme.graphAxis),
                        bottom: BorderSide(color: AppTheme.graphAxis),
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
                          reservedSize: 42,
                          interval: _yInterval(),
                          getTitlesWidget: (value, _) {
                            if (value < 0 || value > _maxY()) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              value.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 28,
                          getTitlesWidget: (value, _) {
                            final index = value.toInt() - 1;
                            if (index < 0 || index >= labels.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                labels[index],
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
                        color: color,
                        barWidth: 4,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: color.withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  title: averageTitle,
                  value: '${average.toStringAsFixed(_decimalPlaces())} $unit',
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  title: 'การเปลี่ยนแปลง',
                  value:
                      '${change > 0 ? '+' : ''}${change.toStringAsFixed(_decimalPlaces())} $unit',
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _decimalPlaces() => metric == HealthMetric.heartRate ? 0 : 2;

  double _maxY() {
    switch (metric) {
      case HealthMetric.bmi:
        return 40;
      case HealthMetric.weight:
        return 120;
      case HealthMetric.height:
        return 200;
      case HealthMetric.heartRate:
        return 120;
    }
  }

  double _yInterval() {
    switch (metric) {
      case HealthMetric.bmi:
        return 10;
      case HealthMetric.weight:
        return 30;
      case HealthMetric.height:
        return 50;
      case HealthMetric.heartRate:
        return 30;
    }
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
