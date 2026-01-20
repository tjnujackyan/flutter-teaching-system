import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

// Web 平台条件导入
import 'dart:html' as html show Blob, Url, AnchorElement;

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
      if (kIsWeb) {
        // Web 平台使用 Blob 下载
        await _downloadResourceWeb(courseId, resourceId);
        return 'downloaded';
      } else {
        // 移动端使用文件系统下载
        final response = await _apiService.download(
          '/api/courses/$courseId/resources/$resourceId/download',
          savePath,
          onReceiveProgress: onReceiveProgress,
        );
        return savePath;
      }
    } catch (e) {
      debugPrint('下载课程资料失败: $e');
      rethrow;
    }
  }

  /// Web 平台下载资料
  Future<void> _downloadResourceWeb(int courseId, int resourceId) async {
    try {
      // 创建新的 Dio 实例并复制认证头
      final dio = Dio(BaseOptions(
        baseUrl: ApiService.baseUrl,
        headers: {
          'auth': await _getAuthToken(),
        },
      ));
      
      final response = await dio.get(
        '/api/courses/$courseId/resources/$resourceId/download',
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      if (kIsWeb) {
        // 从响应头获取文件名
        final contentDisposition = response.headers.value('content-disposition') ?? '';
        debugPrint('Content-Disposition: $contentDisposition');
        
        String fileName = 'download';
        if (contentDisposition.isNotEmpty) {
          // 简化的文件名提取
          final filenameMatch = RegExp(r'filename="?([^";\n]+)"?').firstMatch(contentDisposition);
          if (filenameMatch != null && filenameMatch.group(1) != null) {
            fileName = filenameMatch.group(1)!;
            debugPrint('Extracted filename: $fileName');
            // URL 解码文件名
            try {
              fileName = Uri.decodeComponent(fileName);
              debugPrint('Decoded filename: $fileName');
            } catch (e) {
              debugPrint('Failed to decode filename: $e');
              // 解码失败则使用原文件名
            }
          }
        }

        debugPrint('Final filename: $fileName');
        
        // 创建 Blob 并触发下载
        final bytes = response.data as List<int>;
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      }
    } catch (e) {
      debugPrint('Web 下载失败: $e');
      rethrow;
    }
  }

  /// 获取认证 token
  Future<String> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token') ?? '';
    } catch (e) {
      return '';
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
