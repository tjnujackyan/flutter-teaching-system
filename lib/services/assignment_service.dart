import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// 作业管理服务
class AssignmentService {
  static String get baseUrl => ApiService.baseUrl;

  /// 获取教师作业列表
  static Future<Map<String, dynamic>> getTeacherAssignments({
    required String token,
    int? courseId,
    String status = 'all',
    String? keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'status': status,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };
      
      if (courseId != null) {
        queryParams['courseId'] = courseId.toString();
      }
      
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }

      final uri = Uri.parse('$baseUrl/api/teacher/assignments/list')
          .replace(queryParameters: queryParams);

      print('Debug: 请求URL: $uri');
      print('Debug: 请求参数: $queryParams');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'auth': token,
        },
      );

      print('Debug: HTTP状态码: ${response.statusCode}');
      print('Debug: 响应内容: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      throw Exception('获取作业列表失败: $e');
    }
  }

  /// 获取作业创建配置
  static Future<Map<String, dynamic>> getCreateConfig({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/teacher/assignments/create-config'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'auth': token,
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('获取作业创建配置失败: $e');
    }
  }

  /// 创建作业
  static Future<Map<String, dynamic>> createAssignment({
    required String token,
    required Map<String, dynamic> assignmentData,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/teacher/assignments/create');
      
      print('Debug: [创建作业] 请求URL: $uri');
      print('Debug: [创建作业] Token: ${token.substring(0, 20)}...');
      print('Debug: [创建作业] 作业数据: $assignmentData');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'auth': token,
        },
        body: json.encode(assignmentData),
      );

      print('Debug: [创建作业] HTTP状态码: ${response.statusCode}');
      print('Debug: [创建作业] 响应内容: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('Debug: [创建作业] 捕获异常: $e');
      throw Exception('创建作业失败: $e');
    }
  }

  /// 获取作业详情
  static Future<Map<String, dynamic>> getAssignmentDetail({
    required String token,
    required int assignmentId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/student/assignments/$assignmentId/detail'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'auth': token,
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('获取作业详情失败: $e');
    }
  }

  /// 更新作业信息
  static Future<Map<String, dynamic>> updateAssignment({
    required String token,
    required int assignmentId,
    required Map<String, dynamic> assignmentData,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/teacher/assignments/$assignmentId/update'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'auth': token,
        },
        body: json.encode(assignmentData),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('更新作业失败: $e');
    }
  }

  /// 删除作业
  static Future<Map<String, dynamic>> deleteAssignment({
    required String token,
    required int assignmentId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/teacher/assignments/$assignmentId/delete'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'auth': token,
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('删除作业失败: $e');
    }
  }

  /// 获取作业提交列表
  static Future<Map<String, dynamic>> getAssignmentSubmissions({
    required String token,
    required int assignmentId,
    String status = 'all',
    String? keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'status': status,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };
      
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }

      final uri = Uri.parse('$baseUrl/api/teacher/assignments/$assignmentId/submissions')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'auth': token,
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('获取作业提交列表失败: $e');
    }
  }

  /// 获取作业提交详情
  static Future<Map<String, dynamic>> getSubmissionDetail({
    required String token,
    required int submissionId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/teacher/assignments/submissions/$submissionId/detail'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'auth': token,
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('获取提交详情失败: $e');
    }
  }

  /// 批改作业
  static Future<Map<String, dynamic>> gradeAssignment({
    required String token,
    required int submissionId,
    required Map<String, dynamic> gradeData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/teacher/assignments/submissions/$submissionId/grade'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'auth': token,
        },
        body: json.encode(gradeData),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('批改作业失败: $e');
    }
  }

  /// 获取学生作业列表
  static Future<Map<String, dynamic>> getStudentAssignments({
    required String token,
    int? courseId,
    String status = 'all',
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'status': status,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };
      
      if (courseId != null) {
        queryParams['courseId'] = courseId.toString();
      }

      final uri = Uri.parse('$baseUrl/api/student/assignments/list')
          .replace(queryParameters: queryParams);

      print('Debug: [学生作业列表] 请求URL: $uri');
      print('Debug: [学生作业列表] 请求参数: $queryParams');
      print('Debug: [学生作业列表] Token: ${token.substring(0, 20)}...');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'auth': token,
        },
      );

      print('Debug: [学生作业列表] HTTP状态码: ${response.statusCode}');
      print('Debug: [学生作业列表] 响应内容: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      throw Exception('获取学生作业列表失败: $e');
    }
  }

  /// 提交作业
  static Future<Map<String, dynamic>> submitAssignment({
    required String token,
    required int assignmentId,
    String? content,
    List<File>? files,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/assignments/$assignmentId/submit');
      
      print('Debug: [提交作业] 请求URL: $uri');
      print('Debug: [提交作业] 作业ID: $assignmentId');
      print('Debug: [提交作业] Token: ${token.substring(0, 20)}...');
      print('Debug: [提交作业] 内容: ${content ?? "无内容"}');
      print('Debug: [提交作业] 文件数量: ${files?.length ?? 0}');
      
      final request = http.MultipartRequest('POST', uri);
      request.headers['auth'] = token;
      
      if (content != null && content.isNotEmpty) {
        request.fields['content'] = content;
      }
      
      if (files != null && files.isNotEmpty) {
        for (int i = 0; i < files.length; i++) {
          final file = files[i];
          print('Debug: [提交作业] 添加文件: ${file.path}');
          final multipartFile = await http.MultipartFile.fromPath(
            'files',
            file.path,
          );
          request.files.add(multipartFile);
        }
      }

      print('Debug: [提交作业] 开始发送请求...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Debug: [提交作业] HTTP状态码: ${response.statusCode}');
      print('Debug: [提交作业] 响应内容: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      throw Exception('提交作业失败: $e');
    }
  }

  /// 下载作业附件
  static Future<List<int>> downloadAttachment({
    required String token,
    required int attachmentId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/assignments/attachments/$attachmentId/download'),
        headers: {
          'auth': token,
        },
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(responseData['message'] ?? '下载附件失败');
      }
    } catch (e) {
      throw Exception('下载附件失败: $e');
    }
  }

  /// 获取附件下载URL
  static String getAttachmentDownloadUrl({
    required String token,
    required int attachmentId,
  }) {
    return '$baseUrl/api/assignments/attachments/$attachmentId/download?auth=$token';
  }

  /// 处理HTTP响应
  static Map<String, dynamic> _handleResponse(http.Response response) {
    print('Debug: [响应处理] 状态码: ${response.statusCode}');
    print('Debug: [响应处理] 响应体长度: ${response.body.length}');
    
    if (response.statusCode == 200) {
      try {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        print('Debug: [响应处理] JSON解析成功');
        print('Debug: [响应处理] 解析结果类型: ${responseData.runtimeType}');
        
        if (responseData is Map<String, dynamic>) {
          print('Debug: [响应处理] 返回有效响应数据');
          return responseData;
        } else {
          print('Debug: [响应处理] 响应格式错误，不是Map类型');
          return {
            'error': 500,
            'message': '响应格式错误',
            'body': null,
          };
        }
      } catch (e) {
        print('Debug: [响应处理] JSON解析失败: $e');
        return {
          'error': 500,
          'message': '解析响应失败: $e',
          'body': null,
        };
      }
    } else {
      print('Debug: [响应处理] HTTP状态码非200: ${response.statusCode}');
      try {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        print('Debug: [响应处理] 错误响应解析成功');
        return responseData is Map<String, dynamic> ? responseData : {
          'error': response.statusCode,
          'message': '请求失败',
          'body': null,
        };
      } catch (e) {
        print('Debug: [响应处理] 错误响应解析失败: $e');
        return {
          'error': response.statusCode,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          'body': null,
        };
      }
    }
  }
}
