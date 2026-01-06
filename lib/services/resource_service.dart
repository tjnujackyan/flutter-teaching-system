import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// 课程资料管理服务
class ResourceService {
  final ApiService _apiService = ApiService();

  /// 获取资料分类配置
  Future<Map<String, dynamic>> getResourceCategories() async {
    try {
      final response = await _apiService.get('/api/teacher/resources/categories');
      return response;
    } catch (e) {
      debugPrint('获取资料分类配置失败: $e');
      rethrow;
    }
  }

  /// 获取课程资料列表
  Future<Map<String, dynamic>> getCourseResources({
    required int courseId,
    String? category,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final response = await _apiService.get(
        '/api/teacher/courses/$courseId/resources',
        queryParameters: queryParams,
      );
      return response;
    } catch (e) {
      debugPrint('获取课程资料列表失败: $e');
      rethrow;
    }
  }

  /// 上传课程资料
  Future<Map<String, dynamic>> uploadResource({
    required int courseId,
    required File file,
    required String title,
    String? description,
    required String category,
    String? chapterName,
    bool isPublic = true,
    bool isDownloadable = true,
  }) async {
    try {
      // 创建FormData
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'title': title,
        'category': category,
        'isPublic': isPublic,
        'isDownloadable': isDownloadable,
      });

      // 添加可选参数
      if (description != null && description.isNotEmpty) {
        formData.fields.add(MapEntry('description', description));
      }
      if (chapterName != null && chapterName.isNotEmpty) {
        formData.fields.add(MapEntry('chapterName', chapterName));
      }

      final response = await _apiService.post(
        '/api/teacher/courses/$courseId/resources/upload',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      return response;
    } catch (e) {
      debugPrint('上传课程资料失败: $e');
      rethrow;
    }
  }

  /// 更新资料信息
  Future<Map<String, dynamic>> updateResource({
    required int resourceId,
    String? title,
    String? description,
    String? category,
    String? chapterName,
    bool? isPublic,
    bool? isDownloadable,
  }) async {
    try {
      final data = <String, dynamic>{};
      
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (category != null) data['category'] = category;
      if (chapterName != null) data['chapterName'] = chapterName;
      if (isPublic != null) data['isPublic'] = isPublic;
      if (isDownloadable != null) data['isDownloadable'] = isDownloadable;

      final response = await _apiService.put(
        '/api/teacher/resources/$resourceId/update',
        data: data,
      );
      return response;
    } catch (e) {
      debugPrint('更新资料信息失败: $e');
      rethrow;
    }
  }

  /// 删除课程资料
  Future<Map<String, dynamic>> deleteResource(int resourceId) async {
    try {
      final response = await _apiService.delete(
        '/api/teacher/resources/$resourceId/delete',
      );
      return response;
    } catch (e) {
      debugPrint('删除课程资料失败: $e');
      rethrow;
    }
  }

  /// 获取资料详情
  Future<Map<String, dynamic>> getResourceDetail({
    required int courseId,
    required int resourceId,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/courses/$courseId/resources/$resourceId/detail',
      );
      return response;
    } catch (e) {
      debugPrint('获取资料详情失败: $e');
      rethrow;
    }
  }

  /// 下载课程资料
  Future<String> downloadResource({
    required int courseId,
    required int resourceId,
    required String savePath,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      final response = await _apiService.download(
        '/api/courses/$courseId/resources/$resourceId/download',
        savePath,
        onReceiveProgress: onReceiveProgress,
      );
      return savePath;
    } catch (e) {
      debugPrint('下载课程资料失败: $e');
      rethrow;
    }
  }

  /// 格式化文件大小
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }

  /// 获取文件类型图标
  String getFileTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'ppt':
      case 'pptx':
        return '📖';
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'mp4':
      case 'avi':
      case 'mov':
        return '🎥';
      case 'mp3':
      case 'wav':
      case 'aac':
        return '🎵';
      case 'zip':
      case 'rar':
      case '7z':
        return '📦';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return '🖼️';
      default:
        return '📎';
    }
  }

  /// 获取分类颜色
  String getCategoryColor(String category) {
    switch (category) {
      case 'courseware':
        return '#3B82F6';
      case 'reference':
        return '#10B981';
      case 'template':
        return '#F59E0B';
      case 'video':
        return '#EF4444';
      case 'audio':
        return '#8B5CF6';
      case 'code':
        return '#06B6D4';
      default:
        return '#6B7280';
    }
  }

  /// 获取分类名称
  String getCategoryName(String category) {
    switch (category) {
      case 'courseware':
        return '课件';
      case 'reference':
        return '参考资料';
      case 'template':
        return '作业模板';
      case 'video':
        return '视频';
      case 'audio':
        return '音频';
      case 'code':
        return '代码';
      case 'other':
        return '其他';
      default:
        return '未知';
    }
  }
}
