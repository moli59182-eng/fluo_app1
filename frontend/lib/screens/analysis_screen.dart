import 'package:flutter/material.dart';
import '../models/intensity_data.dart';
import '../widgets/trend_chart.dart';
import '../app_theme.dart';
import '../services/storage_service.dart';

class AnalysisScreen extends StatefulWidget {
  final Map<String, dynamic> analysisData;

  const AnalysisScreen({
    super.key,
    required this.analysisData,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  late AnalysisRecord _record;
  int? _selectedTube;

  @override
  void initState() {
    super.initState();
    _parseAnalysisData();
  }

  void _parseAnalysisData() {
    _record = AnalysisRecord.fromJson(widget.analysisData);
    // Sort images by timestamp to ensure chronological order
    _record.images.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  List<IntensityData> _getDisplayData() {
    List<IntensityData> dataPoints = [];

    if (_selectedTube == null) {
      // Show all tubes: x-axis is still image index (time interval)
      // First, collect baseline values (first image) for each tube
      Map<int, double> baselineValues = {};
      if (_record.images.isNotEmpty) {
        final firstImage = _record.images.first;
        for (var tube in firstImage.tubes) {
          baselineValues[tube.tubeNumber] = tube.intensity;
        }
      }
      
      for (int i = 0; i < _record.images.length; i++) {
        final image = _record.images[i];
        for (var tube in image.tubes) {
          // Normalize: divide by baseline value
          final baseline = baselineValues[tube.tubeNumber] ?? 1.0;
          final normalizedIntensity = baseline > 0 ? tube.intensity / baseline : tube.intensity;
          
          dataPoints.add(IntensityData(
            imagePath: image.imagePath,
            intensity: normalizedIntensity,
            timestamp: image.timestamp,
            index: i, // Use image index as x-axis
            tubeNumber: tube.tubeNumber,
          ));
        }
      }
    } else {
      // Show single tube: x-axis is image index
      // Get baseline value (first image)
      double baseline = 1.0;
      if (_record.images.isNotEmpty) {
        final firstImage = _record.images.first;
        final firstTube = firstImage.tubes.firstWhere(
          (t) => t.tubeNumber == _selectedTube,
          orElse: () => TubeData(tubeNumber: _selectedTube!, intensity: 1.0),
        );
        baseline = firstTube.intensity > 0 ? firstTube.intensity : 1.0;
      }
      
      for (int i = 0; i < _record.images.length; i++) {
        final image = _record.images[i];
        final tube = image.tubes.firstWhere(
          (t) => t.tubeNumber == _selectedTube,
          orElse: () => TubeData(tubeNumber: _selectedTube!, intensity: 0),
        );
        
        // Normalize: divide by baseline value
        final normalizedIntensity = baseline > 0 ? tube.intensity / baseline : tube.intensity;
        
        dataPoints.add(IntensityData(
          imagePath: image.imagePath,
          intensity: normalizedIntensity,
          timestamp: image.timestamp,
          index: i, // Image index: 1st=0, 2nd=1, etc.
          tubeNumber: tube.tubeNumber,
        ));
      }
    }

    return dataPoints;
  }

  @override
  Widget build(BuildContext context) {
    final displayData = _getDisplayData();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Analysis Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.greenGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Analysis Complete',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_record.images.length} images · ${_record.images.length * 4} data points',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tube filter
              const Text(
                'Select Tube',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTubeChip(null, 'All', AppTheme.textSecondary),
                    _buildTubeChip(1, 'Tube 1', AppTheme.primaryColor),
                    _buildTubeChip(2, 'Tube 2', AppTheme.secondaryColor),
                    _buildTubeChip(3, 'Tube 3', AppTheme.accentColor),
                    _buildTubeChip(4, 'Tube 4', AppTheme.successColor),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stats cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Avg Relative',
                      _calculateAverage(displayData).toStringAsFixed(2) + 'x',
                      Icons.analytics_rounded,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      'Max Fold',
                      _calculateMax(displayData).toStringAsFixed(2) + 'x',
                      Icons.arrow_upward_rounded,
                      AppTheme.successColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Min Fold',
                      _calculateMin(displayData).toStringAsFixed(2) + 'x',
                      Icons.arrow_downward_rounded,
                      AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      'Data Points',
                      '${displayData.length}',
                      Icons.scatter_plot_rounded,
                      AppTheme.accentColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Trend chart
              const Text(
                'Relative Intensity Trend (Normalized to First Image)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    // Legend
                    if (_selectedTube == null && _hasMultipleTubes())
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildLegendItem('Tube 1 (Positive)', const Color(0xFF2196F3), false),
                            _buildLegendItem('Tube 2 (Positive)', const Color(0xFF9C27B0), false),
                            _buildLegendItem('Tube 3 (Positive)', const Color(0xFFFF9800), false),
                            _buildLegendItem('Tube 4 (Control)', const Color(0xFF757575), true),
                          ],
                        ),
                      ),
                    SizedBox(
                      height: _selectedTube == null && _hasMultipleTubes() ? 300 : 280,
                      child: TrendChart(
                        dataPoints: displayData,
                        showAnimation: true,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Detailed data
              const Text(
                'Detailed Data',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              ..._record.images.asMap().entries.map((entry) {
                final index = entry.key;
                final image = entry.value;
                return _buildImageDataCard(image, index + 1);
              }),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.home_rounded, size: 20),
                      label: const Text('Back Home'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                            color: AppTheme.primaryColor.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveToHistory,
                      icon: const Icon(Icons.save_rounded, size: 20),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTubeChip(int? tubeNumber, String label, Color color) {
    final isSelected = _selectedTube == tubeNumber;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTube = tubeNumber;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : AppTheme.dividerColor,
              width: 1.5,
            ),
            boxShadow: isSelected ? AppTheme.cardShadow : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageDataCard(ImageAnalysis image, int imageNumber) {
    // Extract time from filename, e.g.: Screenshot_20260306-170706.jpg
    String displayTime = _extractTimeFromPath(image.imagePath);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.image_rounded,
                  color: AppTheme.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTime,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Avg: ${image.averageIntensity.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: image.tubes.map((tube) {
              final colors = [
                AppTheme.primaryColor,
                AppTheme.secondaryColor,
                AppTheme.accentColor,
                AppTheme.successColor,
              ];
              final color = colors[(tube.tubeNumber - 1) % colors.length];

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Tube ${tube.tubeNumber}',
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tube.intensity.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _extractTimeFromPath(String path) {
    // Extract filename from path
    final fileName = path.split('/').last.split('\\').last;

    // Try to match common time formats
    // Format 1: Screenshot_20260306-170706.jpg -> 2026-03-06 17:07
    final pattern1 = RegExp(r'(\d{8})-(\d{6})');
    final match1 = pattern1.firstMatch(fileName);
    if (match1 != null) {
      final dateStr = match1.group(1)!; // 20260306
      final timeStr = match1.group(2)!; // 170706

      final year = dateStr.substring(0, 4);
      final month = dateStr.substring(4, 6);
      final day = dateStr.substring(6, 8);
      final hour = timeStr.substring(0, 2);
      final minute = timeStr.substring(2, 4);

      return '$year-$month-$day $hour:$minute';
    }

    // Format 2: IMG_20260306_170706.jpg
    final pattern2 = RegExp(r'(\d{8})_(\d{6})');
    final match2 = pattern2.firstMatch(fileName);
    if (match2 != null) {
      final dateStr = match2.group(1)!;
      final timeStr = match2.group(2)!;

      final year = dateStr.substring(0, 4);
      final month = dateStr.substring(4, 6);
      final day = dateStr.substring(6, 8);
      final hour = timeStr.substring(0, 2);
      final minute = timeStr.substring(2, 4);

      return '$year-$month-$day $hour:$minute';
    }

    // If no time format matched, return filename (without extension)
    return fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
  }

  double _calculateAverage(List<IntensityData> data) {
    if (data.isEmpty) return 0;
    return data.map((e) => e.intensity).reduce((a, b) => a + b) / data.length;
  }

  double _calculateMax(List<IntensityData> data) {
    if (data.isEmpty) return 0;
    return data.map((e) => e.intensity).reduce((a, b) => a > b ? a : b);
  }

  double _calculateMin(List<IntensityData> data) {
    if (data.isEmpty) return 0;
    return data.map((e) => e.intensity).reduce((a, b) => a < b ? a : b);
  }

  bool _hasMultipleTubes() {
    if (_record.images.isEmpty) return false;
    return _record.images.first.tubes.length > 1;
  }

  Widget _buildLegendItem(String label, Color color, bool isDashed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDashed)
          // Dashed legend
          SizedBox(
            width: 16,
            height: 2,
            child: CustomPaint(
              painter: DashedLinePainter(color: color),
            ),
          )
        else
          // Solid legend
          Container(
            width: 16,
            height: 2,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  void _saveToHistory() async {
    try {
      await StorageService.saveAnalysisRecord(_record);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved to history'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
          ),
        );
      }
    }
  }
}

// Dashed line painter
class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 2.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
