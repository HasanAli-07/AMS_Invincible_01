import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../tokens/color_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/radius_tokens.dart';

/// Design System chart component using fl_chart.
/// All colors and styling come from tokens.
class DSLineChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final String unit;
  final double? maxY;

  const DSLineChart({
    super.key,
    required this.values,
    required this.labels,
    required this.unit,
    this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final maxValue = maxY ?? (values.reduce((a, b) => a > b ? a : b) * 1.1);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxValue / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: colors.borderSubtle,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: SpacingTokens.space8),
                      child: Text(
                        labels[index],
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: maxValue / 5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}$unit',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: colors.borderSubtle),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: values.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value);
              }).toList(),
              isCurved: true,
              color: colors.accentPrimary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: colors.accentPrimary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bar chart component using design tokens.
class DSBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final String unit;
  final double? maxY;

  const DSBarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.unit,
    this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final maxValue = maxY ?? (values.reduce((a, b) => a > b ? a : b) * 1.1);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxValue / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: colors.borderSubtle,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: SpacingTokens.space8),
                      child: Text(
                        labels[index],
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: maxValue / 5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}$unit',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: colors.borderSubtle),
          ),
          barGroups: values.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value,
                  color: e.value < 75
                      ? colors.danger
                      : e.value < 85
                          ? colors.warning
                          : colors.success,
                  width: 20,
                  borderRadius: RadiusTokens.pillSmall,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

