import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';
// Web平台需要的导入
import 'dart:html' as html show Blob, Url, AnchorElement;

/// 跨平台文件模型
class CrossPlatformFile {
  final String name;
  final int size;
  final Uint8List? bytes;
  final String? path;
  final String extension;

  CrossPlatformFile({
    required this.name,
    required this.size,
    this.bytes,
    this.path,
    required this.extension,
  });

  /// 从 PlatformFile 创建
  factory CrossPlatformFile.fromPlatformFile(PlatformFile file) {
    // Web平台不能访问path属性，会抛出异常
    String? filePath;
    if (!kIsWeb) {
      try {
        filePath = file.path;
      } catch (e) {
        filePath = null;
      }
    }
    
    return CrossPlatformFile(
      name: file.name,
      size: file.size,
      bytes: file.bytes,
      path: filePath,
      extension: file.extension ?? '',
    );
  }

  /// 获取格式化的文件大小
  String get formattedSize {
    if (size < 1024) {
      return '${size}B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)}KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }

  /// 获取文件类型图标
  String get typeIcon {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'ppt':
      case 'pptx':
        return '📖';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return '🖼️';
      case 'mp4':
      case 'avi':
      case 'mov':
        return '🎥';
      case 'mp3':
      case 'wav':
        return '🎵';
      case 'zip':
      case 'rar':
      case '7z':
        return '📦';
      case 'cpp':
      case 'c':
      case 'java':
      case 'py':
      case 'js':
        return '💻';
      default:
        return '📎';
    }
  }

  /// 转换为 MultipartFile（用于上传）
  Future<MultipartFile> toMultipartFile({String fieldName = 'file'}) async {
    if (kIsWeb) {
      // Web 平台使用 bytes
      if (bytes == null) {
        throw Exception('Web平台文件bytes为空');
      }
      return MultipartFile.fromBytes(
        bytes!,
        filename: name,
      );
    } else {
      // 移动端优先使用 path，如果没有则使用 bytes
      if (path != null) {
        return await MultipartFile.fromFile(path!, filename: name);
      } else if (bytes != null) {
        return MultipartFile.fromBytes(bytes!, filename: name);
      } else {
        throw Exception('文件数据为空');
      }
    }
  }
}

/// 文件上传服务 - 处理跨平台文件选择和上传
class FileUploadService {
  static final ApiService _apiService = ApiService();

  /// 选择单个文件
  static Future<CrossPlatformFile?> pickSingleFile({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : type,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
        withData: true, // 关键：确保获取 bytes 数据
      );

      if (result != null && result.files.isNotEmpty) {
        return CrossPlatformFile.fromPlatformFile(result.files.first);
      }
      return null;
    } catch (e) {
      debugPrint('选择文件失败: $e');
      rethrow;
    }
  }

  /// 选择多个文件
  static Future<List<CrossPlatformFile>> pickMultipleFiles({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : type,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
        withData: true, // 关键：确保获取 bytes 数据
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .map((f) => CrossPlatformFile.fromPlatformFile(f))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('选择文件失败: $e');
      rethrow;
    }
  }

  /// 选择图片 - Web平台使用FileType.image
  static Future<CrossPlatformFile?> pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,  // 使用 image 类型而不是 custom
        allowMultiple: false,
        withData: true, // 关键：确保获取 bytes 数据
      );

      if (result != null && result.files.isNotEmpty) {
        return CrossPlatformFile.fromPlatformFile(result.files.first);
      }
      return null;
    } catch (e) {
      debugPrint('选择图片失败: $e');
      rethrow;
    }
  }

  /// 选择文档
  static Future<CrossPlatformFile?> pickDocument() async {
    return pickSingleFile(
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt'],
    );
  }

  /// 选择视频
  static Future<CrossPlatformFile?> pickVideo() async {
    return pickSingleFile(
      allowedExtensions: ['mp4', 'avi', 'mov', 'wmv', 'flv'],
    );
  }

  /// 上传单个文件
  static Future<Map<String, dynamic>> uploadFile({
    required String endpoint,
    required CrossPlatformFile file,
    Map<String, dynamic>? extraFields,
    Function(int, int)? onProgress,
  }) async {
    try {
      final multipartFile = await file.toMultipartFile();
      
      final formData = FormData.fromMap({
        'file': multipartFile,
        ...?extraFields,
      });

      final response = await _apiService.post(
        endpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
        onSendProgress: onProgress,
      );

      return response;
    } catch (e) {
      debugPrint('上传文件失败: $e');
      rethrow;
    }
  }

  /// 上传多个文件
  static Future<Map<String, dynamic>> uploadMultipleFiles({
    required String endpoint,
    required List<CrossPlatformFile> files,
    Map<String, dynamic>? extraFields,
    Function(int, int)? onProgress,
  }) async {
    try {
      final List<MultipartFile> multipartFiles = [];
      for (var file in files) {
        multipartFiles.add(await file.toMultipartFile());
      }

      final formData = FormData.fromMap({
        'files': multipartFiles,
        ...?extraFields,
      });

      final response = await _apiService.post(
        endpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
        onSendProgress: onProgress,
      );

      return response;
    } catch (e) {
      debugPrint('上传文件失败: $e');
      rethrow;
    }
  }

  /// 上传头像
  static Future<Map<String, dynamic>> uploadAvatar(CrossPlatformFile file) async {
    try {
      final multipartFile = await file.toMultipartFile();
      
      final formData = FormData.fromMap({
        'avatar': multipartFile,  // 后端期望的字段名是 'avatar'
      });

      final response = await _apiService.post(
        '/api/user/profile/avatar',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      return response;
    } catch (e) {
      debugPrint('上传头像失败: $e');
      rethrow;
    }
  }

  /// 上传作业附件
  static Future<Map<String, dynamic>> uploadAssignmentAttachment({
    required int assignmentId,
    required CrossPlatformFile file,
  }) async {
    return uploadFile(
      endpoint: '/api/assignments/$assignmentId/attachments/upload',
      file: file,
    );
  }

  /// 上传作业提交文件
  static Future<Map<String, dynamic>> uploadSubmissionFile({
    required int assignmentId,
    required CrossPlatformFile file,
  }) async {
    return uploadFile(
      endpoint: '/api/student/assignments/$assignmentId/submit/file',
      file: file,
    );
  }

  /// 上传课程资料
  static Future<Map<String, dynamic>> uploadCourseResource({
    required int courseId,
    required CrossPlatformFile file,
    required String title,
    String? description,
    required String category,
    String? chapterName,
    bool isPublic = true,
    bool isDownloadable = true,
  }) async {
    return uploadFile(
      endpoint: '/api/teacher/courses/$courseId/resources/upload',
      file: file,
      extraFields: {
        'title': title,
        'category': category,
        'isPublic': isPublic,
        'isDownloadable': isDownloadable,
        if (description != null && description.isNotEmpty) 'description': description,
        if (chapterName != null && chapterName.isNotEmpty) 'chapterName': chapterName,
      },
    );
  }

  /// 下载作业附件
  static Future<void> downloadAssignmentAttachment({
    required int attachmentId,
    required String fileName,
  }) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) {
        throw Exception('用户未登录');
      }

      final url = '${ApiService.baseUrl}/api/assignments/attachments/$attachmentId/download';
      
      if (kIsWeb) {
        // Web平台使用Blob下载
        await _downloadFileWeb(url, fileName, token);
      } else {
        // 移动端使用Dio下载
        await _downloadFileMobile(url, fileName, token);
      }
    } catch (e) {
      debugPrint('下载附件失败: $e');
      rethrow;
    }
  }

  /// Web平台下载文件
  static Future<void> _downloadFileWeb(String url, String fileName, String token) async {
    try {
      // 使用Dio下载文件
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          headers: {'auth': token},
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        // 使用dart:html创建下载链接
        final bytes = response.data as List<int>;
        final blob = html.Blob([bytes]);
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: blobUrl)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(blobUrl);
      } else {
        throw Exception('下载失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Web下载失败: $e');
      rethrow;
    }
  }

  /// 移动端下载文件
  static Future<void> _downloadFileMobile(String url, String fileName, String token) async {
    try {
      // 移动端下载逻辑（需要权限和路径处理）
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          headers: {'auth': token},
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        // 这里简化处理，实际应该保存到下载目录
        debugPrint('文件下载成功: $fileName');
      } else {
        throw Exception('下载失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('移动端下载失败: $e');
      rethrow;
    }
  }
}
