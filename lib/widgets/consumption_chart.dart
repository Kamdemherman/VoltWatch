import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:voltwatch/models/consumption_model.dart';

class ConsumptionChart extends StatelessWidget {
  final List<ConsumptionReading> readings;
  final bool showCost;

  const ConsumptionChart({
    super.key,
    required this.readings,
    this.showCost = false,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée de consommation',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Sort readings by date (ascending)
    final sortedReadings = [...readings]
      ..sort((a, b) => a.readingDate.compareTo(b.readingDate));

    // Create chart data points
    final spots = <FlSpot>[];
    final averageSpots = <FlSpot>[];
    
    for (int i = 0; i < sortedReadings.length; i++) {
      final reading = sortedReadings[i];
      final value = showCost ? reading.costFcfa : reading.kwhConsumed;
      spots.add(FlSpot(i.toDouble(), value));
      
      if (reading.localAverageKwh != null && !showCost) {
        averageSpots.add(FlSpot(i.toDouble(), reading.localAverageKwh!));
      }
    }

    // Calculate max Y value for proper scaling
    final values = showCost 
        ? sortedReadings.map((r) => r.costFcfa).toList()
        : sortedReadings.map((r) => r.kwhConsumed).toList();
    
    final maxValue = values.isNotEmpty 
        ? values.reduce((a, b) => a > b ? a : b)
        : 0.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue > 0 ? maxValue / 5 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedReadings.length) {
                  return const Text('');
                }
                
                final date = sortedReadings[index].readingDate;
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    DateFormat('dd/MM').format(date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxValue > 0 ? maxValue / 4 : 1,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                String text;
                if (showCost) {
                  if (value >= 1000) {
                    text = '${(value / 1000).toStringAsFixed(1)}k';
                  } else {
                    text = value.toStringAsFixed(0);
                  }
                } else {
                  text = value.toStringAsFixed(1);
                }
                
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
            left: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        minX: 0,
        maxX: (sortedReadings.length - 1).toDouble(),
        minY: 0,
        maxY: maxValue * 1.1,
        lineBarsData: [
          // Main consumption line
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: showCost 
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: showCost 
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: (showCost 
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.primary).withValues(alpha: 0.1),
            ),
          ),
          // Local average line (only for kWh charts)
          if (averageSpots.isNotEmpty && !showCost)
            LineChartBarData(
              spots: averageSpots,
              isCurved: true,
              color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.7),
              barWidth: 2,
              isStrokeCapRound: true,
              dashArray: [5, 5],
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Theme.of(context).colorScheme.surfaceContainerHighest,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final index = touchedSpot.x.toInt();
                if (index < 0 || index >= sortedReadings.length) {
                  return null;
                }
                
                final reading = sortedReadings[index];
                final date = DateFormat('dd/MM/yyyy').format(reading.readingDate);
                
                String mainValue;
                String unit;
                if (showCost) {
                  mainValue = NumberFormat('#,###', 'fr_FR').format(reading.costFcfa);
                  unit = 'FCFA';
                } else {
                  mainValue = reading.kwhConsumed.toStringAsFixed(1);
                  unit = 'kWh';
                }
                
                String tooltipText = '$date\n$mainValue $unit';
                
                // Add local average info for kWh charts
                if (!showCost && reading.localAverageKwh != null) {
                  tooltipText += '\nMoyenne locale: ${reading.localAverageKwh!.toStringAsFixed(1)} kWh';
                }
                
                return LineTooltipItem(
                  tooltipText,
                  TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
      ),
    );
  }
}

class ConsumptionComparisonChart extends StatelessWidget {
  final List<ConsumptionReading> currentPeriodReadings;
  final List<ConsumptionReading> previousPeriodReadings;
  final String periodLabel;

  const ConsumptionComparisonChart({
    super.key,
    required this.currentPeriodReadings,
    required this.previousPeriodReadings,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (currentPeriodReadings.isEmpty && previousPeriodReadings.isEmpty) {
      return const Center(
        child: Text('Aucune donnée de comparaison disponible'),
      );
    }

    // Create bar chart data
    final currentTotal = currentPeriodReadings.fold<double>(
      0, (sum, reading) => sum + reading.kwhConsumed);
    final previousTotal = previousPeriodReadings.fold<double>(
      0, (sum, reading) => sum + reading.kwhConsumed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparaison $periodLabel',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: [currentTotal, previousTotal].reduce((a, b) => a > b ? a : b) * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Theme.of(context).colorScheme.surfaceContainerHighest,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final value = rod.toY;
                    final period = groupIndex == 0 ? 'Période précédente' : 'Période actuelle';
                    return BarTooltipItem(
                      '$period\n${value.toStringAsFixed(1)} kWh',
                      TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      switch (value.toInt()) {
                        case 0:
                          return const Text('Précédent');
                        case 1:
                          return const Text('Actuel');
                        default:
                          return const Text('');
                      }
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: previousTotal,
                      color: Theme.of(context).colorScheme.outline,
                      width: 40,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: currentTotal,
                      color: Theme.of(context).colorScheme.primary,
                      width: 40,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}