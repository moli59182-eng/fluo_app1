import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/intensity_data.dart';
import '../services/storage_service.dart';
import '../widgets/trend_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<AnalysisRecord> _history = [];
  bool _isLoading = true;
  int? _selectedTube; // null = overview, 1-4 = individual tube
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final history = await StorageService.getAnalysisHistory();
    final stats = await StorageService.getStatistics();
    setState(() {
      _history = history;
      _stats = stats;
      _isLoading = false;
    });
  }

  List<IntensityData> _getChartData() {
    List<IntensityData> dataPoints = [];
    
    // Show only the latest analysis data
    if (_history.isEmpty) return dataPoints;
    
    final latestRecord = _history.first;
    
    if (_selectedTube == null) {
      // Overview: show all tubes
      // First, collect baseline values (first image) for each tube
      Map<int, double> baselineValues = {};
      if (latestRecord.images.isNotEmpty) {
        final firstImage = latestRecord.images.first;
        for (var tube in firstImage.tubes) {
          baselineValues[tube.tubeNumber] = tube.intensity;
        }
      }
      
      for (int i = 0; i < latestRecord.images.length; i++) {
        final image = latestRecord.images[i];
        for (var tube in image.tubes) {
          // Normalize: divide by baseline value
          final baseline = baselineValues[tube.tubeNumber] ?? 1.0;
          final normalizedIntensity = baseline > 0 ? tube.intensity / baseline : tube.intensity;
          
          dataPoints.add(IntensityData(
            imagePath: image.imagePath,
            intensity: normalizedIntensity,
            timestamp: image.timestamp,
            index: i,
            tubeNumber: tube.tubeNumber,
          ));
        }
      }
    } else {
      // Individual tube
      // Get baseline value (first image)
      double baseline = 1.0;
      if (latestRecord.images.isNotEmpty) {
        final firstImage = latestRecord.images.first;
        final firstTube = firstImage.tubes.firstWhere(
          (t) => t.tubeNumber == _selectedTube,
          orElse: () => TubeData(tubeNumber: _selectedTube!, intensity: 1.0),
        );
        baseline = firstTube.intensity > 0 ? firstTube.intensity : 1.0;
      }
      
      for (int i = 0; i < latestRecord.images.length; i++) {
        final image = latestRecord.images[i];
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
          index: i,
          tubeNumber: tube.tubeNumber,
        ));
      }
    }
    
    return dataPoints;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      letterSpacing: -1,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'View overall data trends',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _history.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Stats cards
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        'Total Records',
                                        '${_stats['totalRecords'] ?? 0}',
                                        Icons.folder_rounded,
                                        AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildStatCard(
                                        'Total Images',
                                        '${_stats['totalImages'] ?? 0}',
                                        Icons.image_rounded,
                                        AppTheme.secondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        'Avg Intensity',
                                        (_stats['avgIntensity'] ?? 0.0).toStringAsFixed(1),
                                        Icons.analytics_rounded,
                                        AppTheme.accentColor,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildStatCard(
                                        'Max Intensity',
                                        (_stats['maxIntensity'] ?? 0.0).toStringAsFixed(1),
                                        Icons.arrow_upward_rounded,
                                        AppTheme.successColor,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Tube selector
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
                                      _buildTubeChip(null, 'Overview (All)', AppTheme.textSecondary),
                                      _buildTubeChip(1, 'Tube 1 (Positive)', AppTheme.primaryColor),
                                      _buildTubeChip(2, 'Tube 2 (Positive)', AppTheme.secondaryColor),
                                      _buildTubeChip(3, 'Tube 3 (Positive)', AppTheme.accentColor),
                                      _buildTubeChip(4, 'Tube 4 (Control)', const Color(0xFF9E9E9E)),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Trend chart
                                const Text(
                                  'Trend Analysis',
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
                                      // Legend (only show in overview mode)
                                      if (_selectedTube == null)
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
                                        height: _selectedTube == null ? 320 : 300,
                                        child: TrendChart(
                                          dataPoints: _getChartData(),
                                          showAnimation: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Data description
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        color: AppTheme.primaryColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _selectedTube == null
                                              ? 'Overview mode shows relative intensity trends (normalized to first image) for all tubes'
                                              : 'Currently showing relative intensity trend for Tube $_selectedTube (normalized to first image)',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              size: 64,
              color: AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Statistics Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete a test to view statistics',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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

  Widget _buildLegendItem(String label, Color color, bool isDashed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDashed)
          SizedBox(
            width: 16,
            height: 2,
            child: CustomPaint(
              painter: DashedLinePainter(color: color),
            ),
          )
        else
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
