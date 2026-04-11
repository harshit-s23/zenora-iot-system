import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LiveHeartRateGraph extends StatelessWidget {
  final List<double> data;
  final Color lineColor;
  final double height;
  final bool showDots;

  const LiveHeartRateGraph({
    super.key,
    required this.data,
    this.lineColor = AppTheme.accentRed,
    this.height = 80,
    this.showDots = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(height: height);
    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final minY = data.reduce((a, b) => a < b ? a : b) - 5;
    final maxY = data.reduce((a, b) => a > b ? a : b) + 5;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          clipData: const FlClipData.all(),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: lineColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: showDots,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3,
                  color: lineColor,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lineColor.withOpacity(0.25),
                    lineColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 250),
      ),
    );
  }
}

class MultiLineGraph extends StatelessWidget {
  final List<double> hrData;
  final List<double> gsrData;
  final List<double> tempData;
  final bool showHr;
  final bool showGsr;
  final bool showTemp;
  final double height;

  const MultiLineGraph({
    super.key,
    required this.hrData,
    required this.gsrData,
    required this.tempData,
    this.showHr = true,
    this.showGsr = true,
    this.showTemp = false,
    this.height = 160,
  });

  List<FlSpot> _normalize(List<double> data) {
    if (data.isEmpty) return [];
    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final range = max - min == 0 ? 1.0 : max - min;
    return data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), (e.value - min) / range))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bars = <LineChartBarData>[];

    if (showHr && hrData.isNotEmpty) {
      bars.add(LineChartBarData(
        spots: _normalize(hrData),
        isCurved: true,
        curveSmoothness: 0.35,
        color: AppTheme.accentRed,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: AppTheme.accentRed.withOpacity(0.05),
        ),
      ));
    }

    if (showGsr && gsrData.isNotEmpty) {
      bars.add(LineChartBarData(
        spots: _normalize(gsrData),
        isCurved: true,
        curveSmoothness: 0.35,
        color: AppTheme.accentCyan,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: AppTheme.accentCyan.withOpacity(0.05),
        ),
      ));
    }

    if (showTemp && tempData.isNotEmpty) {
      bars.add(LineChartBarData(
        spots: _normalize(tempData),
        isCurved: true,
        curveSmoothness: 0.35,
        color: AppTheme.accentOrange,
        barWidth: 2,
        dotData: const FlDotData(show: false),
      ));
    }

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 1,
          gridData: FlGridData(
            show: true,
            horizontalInterval: 0.25,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppTheme.borderColor,
              strokeWidth: 0.5,
            ),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          clipData: const FlClipData.all(),
          lineBarsData: bars,
        ),
        duration: const Duration(milliseconds: 250),
      ),
    );
  }
}
