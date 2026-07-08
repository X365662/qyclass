import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // 默认爬虫地址（本地开发用，端口与 scraper/main.py 一致）
  static const String _defaultBaseUrl = 'http://172.23.112.1:8007/api/v1';
  static String baseUrl = _defaultBaseUrl;

  late Dio _dio;

  ApiService() {
    _dio = _createDio();
  }

  Dio _createDio() {
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  /// 从本地加载已保存的服务器地址
  static Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('api_base_url');
    if (saved != null && saved.isNotEmpty) {
      baseUrl = saved;
    }
  }

  /// 更新服务器地址并持久化保存
  static Future<void> updateBaseUrl(String newUrl) async {
    // 确保以 /api/v1 结尾
    String url = newUrl.trim();
    if (!url.endsWith('/api/v1')) {
      if (url.endsWith('/')) {
        url = '${url}api/v1';
      } else {
        url = '$url/api/v1';
      }
    }
    baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
  }

  /// 重置为默认地址
  static Future<void> resetBaseUrl() async {
    baseUrl = _defaultBaseUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_base_url');
  }

  /// 刷新 Dio 实例（baseUrl 变化后调用）
  void refreshDio() {
    _dio = _createDio();
  }

  /// 获取验证码
  /// 返回 {captcha_id, image_base64}
  Future<Map<String, dynamic>> getCaptcha() async {
    // 确保使用最新的 baseUrl
    if (_dio.options.baseUrl != baseUrl) {
      refreshDio();
    }
    final response = await _dio.post('/captcha');
    return response.data;
  }

  /// 登录教务系统
  Future<Map<String, dynamic>> login({
    required String studentId,
    required String password,
    required String captchaId,
    required String captchaCode,
  }) async {
    if (_dio.options.baseUrl != baseUrl) refreshDio();
    final response = await _dio.post('/login', data: {
      'student_id': studentId,
      'password': password,
      'captcha_id': captchaId,
      'captcha_code': captchaCode,
    });
    return response.data;
  }

  /// 获取课表
  Future<Map<String, dynamic>> getSchedule(String token) async {
    if (_dio.options.baseUrl != baseUrl) refreshDio();
    final response = await _dio.get('/schedule', options: Options(
      headers: {'Authorization': 'Bearer $token'},
    ));
    return response.data;
  }

  /// 查询空教室
  Future<Map<String, dynamic>> getFreeClassrooms({
    required String token,
    String? building,
    required int dayOfWeek,
    required int startPeriod,
    required int duration,
  }) async {
    if (_dio.options.baseUrl != baseUrl) refreshDio();
    final response = await _dio.post('/classrooms/free', data: {
      'token': token,
      'building': building,
      'day_of_week': dayOfWeek,
      'start_period': startPeriod,
      'duration': duration,
    });
    return response.data;
  }

  /// 获取教学楼列表
  Future<Map<String, dynamic>> getBuildings() async {
    if (_dio.options.baseUrl != baseUrl) refreshDio();
    final response = await _dio.get('/buildings');
    return response.data;
  }
}
