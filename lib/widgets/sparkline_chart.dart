import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fleetwise/models/sensor_reading.dart';

class SparklineChart extends StatelessWidget {
  final List<SensorReading> data;
  final Color color;
  final double height;

  const SparklineChart({
    super.key,
    required this.data,
    required this.color,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    final spots = data.asMap().entries.map((entry) =>
      FlSpot(entry.key.toDouble(), entry.value.value)
    ).toList();

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.1),
              ),
            ),
          ],
          lineTouchData: const LineTouchData(enabled: false),
        ),
      ),
    );
  }
}
