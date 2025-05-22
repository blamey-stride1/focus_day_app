import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ScoreChart extends StatelessWidget {
  final Map<String, int> scoreHistory;

  ScoreChart({required this.scoreHistory});

  @override
  Widget build(BuildContext context) {
    final sortedDates = scoreHistory.keys.toList()
      ..sort(); // Sort dates ascending
    final recentDates = sortedDates.length <= 7
    ? sortedDates
    : sortedDates.skip(sortedDates.length - 7).toList();


    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  int index = value.toInt();
                  if (index < 0 || index >= recentDates.length) return SizedBox();
                  String date = recentDates[index].substring(5); // e.g. 05-24
                  return Text(date, style: TextStyle(fontSize: 10));
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
          ),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              spots: List.generate(recentDates.length, (i) {
                String date = recentDates[i];
                return FlSpot(i.toDouble(), scoreHistory[date]?.toDouble() ?? 0);
              }),
              barWidth: 3,
              color: Colors.blue,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}

