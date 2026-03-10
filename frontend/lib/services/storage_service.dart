import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/intensity_data.dart';

class StorageService {
  static const String _historyKey = 'analysis_history';
  
  // 保存分析记录
  static Future<void> saveAnalysisRecord(AnalysisRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getAnalysisHistory();
    
    // 添加新记录到列表开头
    history.insert(0, record);
    
    // 只保留最近50条记录
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }
    
    // 保存到本地
    final jsonList = history.map((r) => r.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }
  
  // 获取所有历史记录
  static Future<List<AnalysisRecord>> getAnalysisHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);
    
    if (jsonString == null) return [];
    
    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => AnalysisRecord.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
  
  // 删除指定记录
  static Future<void> deleteRecord(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getAnalysisHistory();
    
    history.removeWhere((record) => record.id == id);
    
    final jsonList = history.map((r) => r.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }
  
  // 清空所有记录
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
  
  // 获取统计数据
  static Future<Map<String, dynamic>> getStatistics() async {
    final history = await getAnalysisHistory();
    
    if (history.isEmpty) {
      return {
        'totalRecords': 0,
        'totalImages': 0,
        'avgIntensity': 0.0,
        'maxIntensity': 0.0,
        'minIntensity': 0.0,
      };
    }
    
    int totalImages = 0;
    List<double> allIntensities = [];
    
    for (var record in history) {
      totalImages += record.images.length;
      for (var image in record.images) {
        for (var tube in image.tubes) {
          allIntensities.add(tube.intensity);
        }
      }
    }
    
    return {
      'totalRecords': history.length,
      'totalImages': totalImages,
      'avgIntensity': allIntensities.isEmpty ? 0.0 : 
          allIntensities.reduce((a, b) => a + b) / allIntensities.length,
      'maxIntensity': allIntensities.isEmpty ? 0.0 : 
          allIntensities.reduce((a, b) => a > b ? a : b),
      'minIntensity': allIntensities.isEmpty ? 0.0 : 
          allIntensities.reduce((a, b) => a < b ? a : b),
    };
  }
}
