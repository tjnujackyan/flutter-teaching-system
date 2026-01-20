import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API响应模型
class ApiResponse<T> {
  final int error;
  final T? body;
  final String message;

  ApiResponse({
    required this.error,
    this.body,
    required this.message,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJson) {
    return ApiResponse<T>(
      error: json['error'] ?? 0,
      body: fromJson != null && json['body'] != null ? fromJson(json['body']) : json['body'],
      message: json['message'] ?? '',
    );
  }

  /// 是否成功
  bool get isSuccess => error == 0;
  
  /// 是否需要登录
  bool get needLogin => error == 401;
  
  /// 是否系统异常
  bool get isSystemError => error == 500;
  
  /// 是否业务异常
  bool get isBusinessError => error != 0 && error != 401 && error != 500;
}

/// API服务类
class ApiService {
  static const Duration timeout = Duration(seconds: 30);
  late final Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
    ));
    
    // 添加拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 添加认证头
        final token = await getAuthToken();
        if (token != null) {
          options.headers['auth'] = token;
        }
        
        if (kDebugMode) {
          print('请求: ${options.method} ${options.uri}');
          print('请求头: ${options.headers}');
          if (options.data != null) {
            print('请求体: ${options.data}');
          }
        }
        
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('响应状态: ${response.statusCode}');
          print('响应数据: ${response.data}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          print('请求错误: ${error.message}');
        }
        handler.next(error);
      },
    ));
  }
  
  /// 获取API基础URL
  static String get baseUrl {
    if (kIsWeb) {
      // Web平台使用localhost，后端端口是8081
      return 'http://localhost:8081';
    } else if (Platform.isAndroid) {
      // Android模拟器使用10.0.2.2访问宿主机
      return 'http://10.0.2.2:8081';
    } else {
      // iOS模拟器和其他平台使用localhost
      return 'http://localhost:8081';
    }
  }

  /// GET请求
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST请求
  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
    Options? options,
    Duration? timeout,
    Function(int, int)? onSendProgress,
  }) async {
    try {
      // 如果指定了超时时间，合并到options中
      Options finalOptions = options ?? Options();
      if (timeout != null) {
        finalOptions = finalOptions.copyWith(
          sendTimeout: timeout,
          receiveTimeout: timeout,
        );
      }
      
      final response = await _dio.post(
        path,
        data: data,
        options: finalOptions,
        onSendProgress: onSendProgress,
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// PUT请求
  Future<Map<String, dynamic>> put(
    String path, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE请求
  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// 文件下载
  Future<void> download(
    String path,
    String savePath, {
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      await _dio.download(
        path,
        savePath,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      throw Exception('下载失败: $e');
    }
  }

  /// 处理响应
  Map<String, dynamic> _handleResponse(Response response) {
    if (response.statusCode == 200) {
      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        return {'error': 0, 'body': response.data, 'message': '请求成功'};
      }
    } else {
      return {
        'error': response.statusCode ?? 500,
        'message': '请求失败: ${response.statusMessage}',
      };
    }
  }

  /// 处理错误
  Map<String, dynamic> _handleError(dynamic error) {
    String errorMessage = '网络连接异常';
    int errorCode = 500;

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = '请求超时，请检查网络连接';
          break;
        case DioExceptionType.badResponse:
          errorCode = error.response?.statusCode ?? 500;
          errorMessage = '服务器错误: ${error.response?.statusMessage}';
          break;
        case DioExceptionType.connectionError:
          errorMessage = '无法连接到服务器，请检查网络设置';
          break;
        case DioExceptionType.cancel:
          errorMessage = '请求已取消';
          break;
        default:
          errorMessage = '网络异常: ${error.message}';
      }
    }

    return {
      'error': errorCode,
      'message': errorMessage,
    };
  }

  /// 保存认证token
  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// 清除认证token
  static Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  /// 获取认证token
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// 通用API请求处理函数（保持兼容性）
  static Future<ApiResponse<T>> request<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    String method = 'POST',
    T Function(dynamic)? fromJson,
  }) async {
    final apiService = ApiService();
    
    try {
      Map<String, dynamic> response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await apiService.get(endpoint);
          break;
        case 'POST':
          response = await apiService.post(endpoint, data: data);
          break;
        case 'PUT':
          response = await apiService.put(endpoint, data: data);
          break;
        case 'DELETE':
          response = await apiService.delete(endpoint);
          break;
        default:
          response = await apiService.post(endpoint, data: data);
      }
      
      return ApiResponse.fromJson(response, fromJson);
    } catch (e) {
      return ApiResponse<T>(
        error: 500,
        message: e.toString(),
      );
    }
  }
}
