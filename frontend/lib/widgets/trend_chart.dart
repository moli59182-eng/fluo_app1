import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../models/intensity_data.dart';
import '../app_theme.dart';

class TrendChart extends StatefulWidget {
  final List<IntensityData> dataPoints;
  final bool showAnimation;

  const TrendChart({
    super.key,
    required this.dataPoints,
    this.showAnimation = true,
  });

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  @override
  Widget build(BuildContext context) {
    if (widget.dataPoints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 48,
              color: AppTheme.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No Data',
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final uniqueIndices = widget.dataPoints.map((e) => e.index).toSet().length;

    if (uniqueIndices > 10) {
      return _buildScrollableChart();
    }

    return _buildFixedChart();
  }

  Widget _buildScrollableChart() {
    final uniqueIndices = widget.dataPoints.map((e) => e.index).toSet().length;
    final chartWidth =
        max(MediaQuery.of(context).size.width - 100, uniqueIndices * 60.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.swipe_rounded,
                size: 16,
                color: AppTheme.textSecondary.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                'Swipe to view full data',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 20),
            child: SizedBox(
              width: chartWidth,
              child: _buildChartContent(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFixedChart() {
    return _buildChartContent();
  }

  Widget _buildChartContent() {
    final maxY = _getMaxY();
    final minY = _getMinY();
    final range = maxY - minY;
    final yInterval = _calculateInterval(range);
    final uniqueIndices = widget.dataPoints.map((e) => e.index).toSet().length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 纵轴标题
        Padding(
          padding: const EdgeInsets.only(top: 80, left: 56),
          child: Transform.rotate(
            angle: -pi / 2,
            child: const Text(
              'Normalized Fluorescence',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // 图表
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 16, bottom: 50),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: yInterval,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.dividerColor.withOpacity(0.15),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: AppTheme.dividerColor.withOpacity(0.08),
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
                      reservedSize: uniqueIndices <= 8 ? 60 : 50,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        final dataPoint = widget.dataPoints.firstWhere(
                          (d) => d.index == index,
                          orElse: () => widget.dataPoints.first,
                        );

                        if (widget.dataPoints.any((d) => d.index == index)) {
                          final time = dataPoint.timestamp;

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (uniqueIndices <= 8) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${time.month}/${time.day}',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary
                                          .withOpacity(0.7),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                    axisNameWidget: const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Time (min)',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: yInterval,
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(
                      color: AppTheme.dividerColor.withOpacity(0.3),
                      width: 2,
                    ),
                    bottom: BorderSide(
                      color: AppTheme.dividerColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
                minX: 0,
                maxX: max(
                    0,
                    (widget.dataPoints.map((e) => e.index).reduce(max))
                        .toDouble()),
                minY: minY,
                maxY: maxY,
                lineBarsData: _buildLineBars(),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black.withOpacity(0.85),
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    tooltipMargin: 12,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final dataPoint = widget.dataPoints.firstWhere(
                          (d) => d.index == barSpot.x.toInt(),
                          orElse: () => widget.dataPoints.first,
                        );

                        final time = dataPoint.timestamp;
                        final tubeNumber = dataPoint.tubeNumber;
                        final isControl = tubeNumber == 4;
                        final tubeName = isControl
                            ? 'Tube 4 (Control)'
                            : 'Tube $tubeNumber (Positive)';

                        return LineTooltipItem(
                          '$tubeName\nTime: ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}\nIntensity: ${barSpot.y.toStringAsFixed(2)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                  getTouchedSpotIndicator:
                      (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((index) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: Colors.black.withOpacity(0.2),
                          strokeWidth: 2,
                          dashArray: [6, 4],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 7,
                              color: Colors.white,
                              strokeWidth: 3,
                              strokeColor:
                                  barData.color ?? AppTheme.primaryColor,
                            );
                          },
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              duration: widget.showAnimation
                  ? const Duration(milliseconds: 1500)
                  : Duration.zero,
              curve: Curves.easeInOutCubicEmphasized,
            ),
          ),
        ),
      ],
    );
  }

  List<LineChartBarData> _buildLineBars() {
    final Map<int, List<FlSpot>> tubeSpots = {};

    for (final point in widget.dataPoints) {
      final tubeNum = point.tubeNumber > 0 ? point.tubeNumber : 1;

      if (!tubeSpots.containsKey(tubeNum)) {
        tubeSpots[tubeNum] = [];
      }
      tubeSpots[tubeNum]!.add(FlSpot(point.index.toDouble(), point.intensity));
    }

    final uniqueIndices = widget.dataPoints.map((e) => e.index).toSet().length;
    final showDots = uniqueIndices <= 15;

    if (tubeSpots.length == 1) {
      final spots = tubeSpots.values.first;
      return [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.4,
          preventCurveOverShooting: true,
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
            ],
          ),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: showDots,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 5,
                color: Colors.white,
                strokeWidth: 3,
                strokeColor: AppTheme.primaryColor,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(0.25),
                AppTheme.primaryColor.withOpacity(0.05),
                AppTheme.primaryColor.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          shadow: Shadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ),
      ];
    }

    final tubeColors = {
      1: const Color(0xFF2196F3),
      2: const Color(0xFF9C27B0),
      3: const Color(0xFFFF9800),
      4: const Color(0xFF757575),
    };

    return tubeSpots.entries.map((entry) {
      final tubeNum = entry.key;
      final spots = entry.value;
      final isControl = tubeNum == 4;
      final color = tubeColors[tubeNum] ?? AppTheme.primaryColor;

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.35,
        preventCurveOverShooting: true,
        color: color,
        barWidth: isControl ? 3 : 3.5,
        isStrokeCapRound: true,
        dashArray: isControl ? [8, 4] : null,
        dotData: FlDotData(
          show: showDots,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: isControl ? 4 : 4.5,
              color: Colors.white,
              strokeWidth: 2.5,
              strokeColor: color,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: !isControl,
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
              color.withOpacity(0.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        shadow: Shadow(
          color: color.withOpacity(isControl ? 0.1 : 0.2),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      );
    }).toList();
  }

  double _getMaxY() {
    if (widget.dataPoints.isEmpty) return 2.5;
    double max = widget.dataPoints
        .map((e) => e.intensity)
        .reduce((a, b) => a > b ? a : b);
    return min(2.5, (max * 1.15).ceilToDouble());
  }

  double _getMinY() {
    if (widget.dataPoints.isEmpty) return 0;
    double min = widget.dataPoints
        .map((e) => e.intensity)
        .reduce((a, b) => a < b ? a : b);
    return max(0, (min * 0.92).floorToDouble());
  }

  double _calculateInterval(double range) {
    return 0.5;
  }
}

class MiniTrendChart extends StatelessWidget {
  final List<IntensityData> dataPoints;
  final Color color;

  const MiniTrendChart({
    super.key,
    required this.dataPoints,
    this.color = AppTheme.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 50,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (dataPoints.length - 1).toDouble(),
          minY: _getMinY(),
          maxY: _getMaxY(),
          lineBarsData: [
            LineChartBarData(
              spots: dataPoints.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  entry.value.intensity,
                );
              }).toList(),
              isCurved: true,
              curveSmoothness: 0.4,
              preventCurveOverShooting: true,
              color: color,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.25),
                    color.withOpacity(0.05),
                    color.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ],
          lineTouchData: const LineTouchData(enabled: false),
        ),
      ),
    );
  }

  double _getMaxY() {
    if (dataPoints.isEmpty) return 100;
    double max =
        dataPoints.map((e) => e.intensity).reduce((a, b) => a > b ? a : b);
    return (max * 1.15).ceilToDouble();
  }

  double _getMinY() {
    if (dataPoints.isEmpty) return 0;
    double min =
        dataPoints.map((e) => e.intensity).reduce((a, b) => a < b ? a : b);
    return (min * 0.9).floorToDouble().clamp(0, double.infinity);
  }
}
