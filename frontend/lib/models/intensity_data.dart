class IntensityData {
  final String imagePath;
  final double intensity;
  final DateTime timestamp;
  final int index;
  final int tubeNumber; // 试管编号 1-4

  IntensityData({
    required this.imagePath,
    required this.intensity,
    required this.timestamp,
    required this.index,
    this.tubeNumber = 0,
  });

  factory IntensityData.fromJson(Map<String, dynamic> json) {
    return IntensityData(
      imagePath: json['image_path'] ?? '',
      intensity: (json['intensity'] ?? 0).toDouble(),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      index: json['index'] ?? 0,
      tubeNumber: json['tube_number'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_path': imagePath,
      'intensity': intensity,
      'timestamp': timestamp.toIso8601String(),
      'index': index,
      'tube_number': tubeNumber,
    };
  }
}

class TubeData {
  final int tubeNumber;
  final double intensity;
  final double relativeIntensity;
  final double normalizedIntensity;

  TubeData({
    required this.tubeNumber,
    required this.intensity,
    this.relativeIntensity = 0,
    this.normalizedIntensity = 0,
  });

  factory TubeData.fromJson(Map<String, dynamic> json) {
    return TubeData(
      tubeNumber: json['tube_number'] ?? 0,
      intensity: (json['intensity'] ?? 0).toDouble(),
      relativeIntensity: (json['relative_intensity'] ?? 0).toDouble(),
      normalizedIntensity: (json['normalized_intensity'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tube_number': tubeNumber,
      'intensity': intensity,
      'relative_intensity': relativeIntensity,
      'normalized_intensity': normalizedIntensity,
    };
  }
}

class ImageAnalysis {
  final String imagePath;
  final List<TubeData> tubes;
  final double averageIntensity;
  final DateTime timestamp;

  ImageAnalysis({
    required this.imagePath,
    required this.tubes,
    required this.averageIntensity,
    required this.timestamp,
  });

  factory ImageAnalysis.fromJson(Map<String, dynamic> json) {
    List<TubeData> tubes = [];
    if (json['tubes'] != null) {
      tubes = (json['tubes'] as List)
          .map((e) => TubeData.fromJson(e))
          .toList();
    }

    // 优先使用JSON中的timestamp，如果没有则从文件路径提取
    DateTime timestamp;
    if (json['timestamp'] != null) {
      try {
        timestamp = DateTime.parse(json['timestamp']);
      } catch (e) {
        timestamp = _extractTimestampFromPath(json['image_path'] ?? '');
      }
    } else {
      timestamp = _extractTimestampFromPath(json['image_path'] ?? '');
    }

    return ImageAnalysis(
      imagePath: json['image_path'] ?? '',
      tubes: tubes,
      averageIntensity: (json['average_intensity'] ?? 0).toDouble(),
      timestamp: timestamp,
    );
  }

  // 从文件路径中提取时间戳
  static DateTime _extractTimestampFromPath(String path) {
    final fileName = path.split('/').last.split('\\').last;

    // 格式1: Screenshot_20260306-170706.jpg
    final pattern1 = RegExp(r'(\d{8})-(\d{6})');
    final match1 = pattern1.firstMatch(fileName);
    if (match1 != null) {
      final dateStr = match1.group(1)!; // 20260306
      final timeStr = match1.group(2)!; // 170706

      final year = int.parse(dateStr.substring(0, 4));
      final month = int.parse(dateStr.substring(4, 6));
      final day = int.parse(dateStr.substring(6, 8));
      final hour = int.parse(timeStr.substring(0, 2));
      final minute = int.parse(timeStr.substring(2, 4));
      final second = int.parse(timeStr.substring(4, 6));

      return DateTime(year, month, day, hour, minute, second);
    }

    // 格式2: IMG_20260306_170706.jpg
    final pattern2 = RegExp(r'(\d{8})_(\d{6})');
    final match2 = pattern2.firstMatch(fileName);
    if (match2 != null) {
      final dateStr = match2.group(1)!;
      final timeStr = match2.group(2)!;

      final year = int.parse(dateStr.substring(0, 4));
      final month = int.parse(dateStr.substring(4, 6));
      final day = int.parse(dateStr.substring(6, 8));
      final hour = int.parse(timeStr.substring(0, 2));
      final minute = int.parse(timeStr.substring(2, 4));
      final second = int.parse(timeStr.substring(4, 6));

      return DateTime(year, month, day, hour, minute, second);
    }

    // 如果无法解析，返回当前时间
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'image_path': imagePath,
      'tubes': tubes.map((e) => e.toJson()).toList(),
      'average_intensity': averageIntensity,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class AnalysisRecord {
  final String id;
  final DateTime timestamp;
  final List<ImageAnalysis> images;
  final String? note;

  AnalysisRecord({
    required this.id,
    required this.timestamp,
    required this.images,
    this.note,
  });

  // 获取指定试管在所有图片中的数据
  List<double> getTubeTrend(int tubeNumber) {
    return images
        .map((img) => img.tubes
            .firstWhere(
              (tube) => tube.tubeNumber == tubeNumber,
              orElse: () => TubeData(tubeNumber: tubeNumber, intensity: 0),
            )
            .intensity)
        .toList();
  }

  // 获取所有试管的平均强度
  double get averageIntensity {
    if (images.isEmpty) return 0;
    return images.map((e) => e.averageIntensity).reduce((a, b) => a + b) / images.length;
  }

  // 获取最大强度
  double get maxIntensity {
    if (images.isEmpty) return 0;
    return images
        .expand((img) => img.tubes.map((t) => t.intensity))
        .reduce((a, b) => a > b ? a : b);
  }

  // 获取最小强度
  double get minIntensity {
    if (images.isEmpty) return 0;
    return images
        .expand((img) => img.tubes.map((t) => t.intensity))
        .reduce((a, b) => a < b ? a : b);
  }

  factory AnalysisRecord.fromJson(Map<String, dynamic> json) {
    List<ImageAnalysis> images = [];
    
    // 支持从API返回的 'results' 字段
    if (json['results'] != null) {
      images = (json['results'] as List)
          .map((e) => ImageAnalysis.fromJson(e))
          .toList();
    } 
    // 支持从本地存储读取的 'images' 字段
    else if (json['images'] != null) {
      images = (json['images'] as List)
          .map((e) => ImageAnalysis.fromJson(e))
          .toList();
    }

    // 从JSON读取timestamp，如果没有则使用当前时间
    DateTime timestamp = DateTime.now();
    if (json['timestamp'] != null) {
      try {
        timestamp = DateTime.parse(json['timestamp']);
      } catch (e) {
        timestamp = DateTime.now();
      }
    }

    return AnalysisRecord(
      id: json['id'] ?? json['session_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: timestamp,
      images: images,
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'images': images.map((e) => e.toJson()).toList(),
      'note': note,
    };
  }
}
