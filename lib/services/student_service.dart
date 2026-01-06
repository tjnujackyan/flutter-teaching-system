import 'api_service.dart';
import '../models/course_models.dart';

/// 学生端服务类
class StudentService {
  // ==================== 学生主页相关接口 ====================
  
  /// 获取学生主页概览数据
  static Future<Map<String, dynamic>> getDashboardOverview() async {
    try {
      print('Debug: [StudentService] 获取学生主页概览数据');
      
      final response = await ApiService.request<Map<String, dynamic>>(
        '/api/student/dashboard/overview',
        method: 'GET',
        fromJson: (json) => json,
      );
      
      print('Debug: [StudentService] 主页概览响应: ${response.body}');
      
      if (response.error == 0 && response.body != null) {
        return response.body!;
      } else {
        throw Exception(response.message ?? '获取主页数据失败');
      }
    } catch (e) {
      print('Debug: [StudentService] 获取主页概览失败: $e');
      rethrow;
    }
  }
  
  /// 获取最新公告列表
  static Future<List<Map<String, dynamic>>> getLatestAnnouncements({
    int limit = 5,
  }) async {
    try {
      print('Debug: [StudentService] 获取最新公告列表');
      
      final response = await ApiService.request<Map<String, dynamic>>(
        '/api/student/announcements/latest?limit=$limit',
        method: 'GET',
        fromJson: (json) => json,
      );
      
      print('Debug: [StudentService] 公告列表响应: ${response.body}');
      
      if (response.error == 0 && response.body != null) {
        final announcements = response.body!['announcements'] as List<dynamic>?;
        return announcements?.cast<Map<String, dynamic>>() ?? [];
      } else {
        throw Exception(response.message ?? '获取公告列表失败');
      }
    } catch (e) {
      print('Debug: [StudentService] 获取公告列表失败: $e');
      rethrow;
    }
  }
  
  // ==================== 学生课程相关接口 ====================
  
  /// 获取学生课程列表
  static Future<Map<String, dynamic>> getStudentCourses({
    String? keyword,
    String? status,
    String? category,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      print('Debug: [StudentService] 获取学生课程列表');
      
      final queryParams = <String, String>{
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (status != null && status.isNotEmpty) 'status': status,
        if (category != null && category.isNotEmpty) 'category': category,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };
      
      // 构建查询字符串
      final queryString = queryParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      
      final url = '/api/student/courses/list?$queryString';
      
      final response = await ApiService.request<Map<String, dynamic>>(
        url,
        method: 'GET',
        fromJson: (json) => json,
      );
      
      print('Debug: [StudentService] 课程列表响应: ${response.body}');
      
      if (response.error == 0 && response.body != null) {
        return response.body!;
      } else {
        throw Exception(response.message ?? '获取课程列表失败');
      }
    } catch (e) {
      print('Debug: [StudentService] 获取课程列表失败: $e');
      rethrow;
    }
  }
  
  /// 获取学生课程详情
  static Future<Map<String, dynamic>> getCourseDetail(String courseId) async {
    try {
      print('Debug: [StudentService] 获取课程详情: $courseId');
      
      final response = await ApiService.request<Map<String, dynamic>>(
        '/api/student/courses/$courseId/detail',
        method: 'GET',
        fromJson: (json) => json,
      );
      
      print('Debug: [StudentService] 课程详情响应: ${response.body}');
      
      if (response.error == 0 && response.body != null) {
        return response.body!;
      } else {
        throw Exception(response.message ?? '获取课程详情失败');
      }
    } catch (e) {
      print('Debug: [StudentService] 获取课程详情失败: $e');
      rethrow;
    }
  }
  
  // ==================== 辅助方法 ====================
  
  /// 格式化课程状态文本
  static String getCourseStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return '进行中';
      case 'completed':
        return '已完成';
      case 'pending':
      case 'upcoming':
        return '待开始';
      case 'archived':
        return '已归档';
      default:
        return '未知状态';
    }
  }
  
  /// 获取课程状态颜色
  static String getCourseStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return '#4285F4'; // 蓝色
      case 'completed':
        return '#4CAF50'; // 绿色
      case 'pending':
      case 'upcoming':
        return '#FF9800'; // 橙色
      case 'archived':
        return '#9E9E9E'; // 灰色
      default:
        return '#757575'; // 默认灰色
    }
  }
  
  /// 计算课程进度百分比
  static double calculateProgress(int completedHours, int totalHours) {
    if (totalHours <= 0) return 0.0;
    return (completedHours / totalHours).clamp(0.0, 1.0);
  }
  
  /// 格式化公告时间
  static String formatAnnouncementTime(String timeStr) {
    try {
      final time = DateTime.parse(timeStr);
      final now = DateTime.now();
      final difference = now.difference(time);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}天前';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}小时前';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}分钟前';
      } else {
        return '刚刚';
      }
    } catch (e) {
      return timeStr;
    }
  }
  
  /// 判断公告是否重要
  static bool isImportantAnnouncement(Map<String, dynamic> announcement) {
    final isImportant = announcement['isImportant'] as bool?;
    final priority = announcement['priority'] as String?;
    return isImportant == true || priority == 'high' || priority == 'urgent';
  }
}
