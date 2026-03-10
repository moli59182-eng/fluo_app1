import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000"; 
  
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Accept': 'application/json'},
    ));
    
    // 添加网络日志拦截器，方便你在控制台追踪上传进度
    _dio.interceptors.add(LogInterceptor(
      requestBody: false, 
      responseBody: true, 
      logPrint: (obj) => print("[API_LOG] $obj")
    ));
  }

  Future<bool> checkConnection() async {
    try {
      final response = await _dio.get("$baseUrl/health");
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> uploadImages(List<String> imagePaths) =>
      uploadBatch(imagePaths);

  Future<Map<String, dynamic>?> uploadBatch(List<String> imagePaths) async {
    try {
      FormData formData = FormData();
      for (String path in imagePaths) {
        String fileName = path.split('/').last;
        formData.files.add(MapEntry(
          "files", 
          await MultipartFile.fromFile(path, filename: fileName, contentType: MediaType("image", "jpeg")),
        ));
      }
      
      final response = await _dio.post(
        "$baseUrl/process_images/", 
        data: formData,
        onSendProgress: (int sent, int total) {
          print("Upload Progress: ${(sent / total * 100).toStringAsFixed(0)}%");
        },
      );
      
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
    } on DioException catch (e) {
      print("Dio Error Details: ${e.response?.statusCode} - ${e.message}");
    } catch (e) {
      print("Unknown Error: $e");
    }
    return null;
  }
}
