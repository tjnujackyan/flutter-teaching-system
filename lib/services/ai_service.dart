import 'package:dio/dio.dart';
import '../models/ai_models.dart';
import 'api_service.dart';

/// AI功能服务类
class AIService {
  static final ApiService _api = ApiService();

  /// 生成学习分析
  static Future<Map<String, dynamic>> generateAnalysis({
    required String analysisType,
    required String timeRange,
    String? startDate,
    String? endDate,
  }) async {
    try {
      print('Debug: [AI] 开始生成分析 - type: $analysisType, timeRange: $timeRange');

      final request = AnalysisRequest(
        analysisType: analysisType,
        timeRange: timeRange,
        startDate: startDate,
        endDate: endDate,
      );

      // AI分析需要更长的超时时间（1分钟，DeepSeek V3 通常 5-15 秒）
      final response = await _api.post(
        '/api/ai/analysis/generate',
        data: request.toJson(),
        timeout: const Duration(seconds: 60),
      );

      print('Debug: [AI] 分析生成响应: $response');

      if (response['code'] == 200) {
        return {
          'success': true,
          'data': AIAnalysisResult.fromJson(response['data']),
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? '生成分析失败',
        };
      }
    } catch (e) {
      print('Error: [AI] 生成分析失败: $e');
      return {
        'success': false,
        'message': '生成分析失败: ${e.toString()}',
      };
    }
  }

  /// 获取最新的分析结果
  static Future<AIAnalysisResult?> getLatestAnalysis() async {
    try {
      final response = await _api.get('/api/ai/analysis/history?page=1&size=1');

      if (response['code'] == 200) {
        final records = response['data']['records'] as List;
        if (records.isNotEmpty) {
          return AIAnalysisResult.fromJson(records.first);
        }
      }
      return null;
    } catch (e) {
      print('Error: [AI] 获取最新分析失败: $e');
      return null;
    }
  }

  /// 获取历史分析记录
  static Future<Map<String, dynamic>> getHistory({
    int page = 1,
    int size = 10,
  }) async {
    try {
      final response = await _api.get(
        '/api/ai/analysis/history?page=$page&size=$size',
      );

      if (response['code'] == 200) {
        return {
          'success': true,
          'data': response['data'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? '获取历史记录失败',
        };
      }
    } catch (e) {
      print('Error: [AI] 获取历史记录失败: $e');
      return {
        'success': false,
        'message': '获取历史记录失败: ${e.toString()}',
      };
    }
  }

  /// 测试AI服务连接
  static Future<bool> testConnection() async {
    try {
      final response = await _api.post('/api/ai/analysis/test');

      return response['code'] == 200;
    } catch (e) {
      print('Error: [AI] 测试连接失败: $e');
      return false;
    }
  }
}

