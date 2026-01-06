import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

/// 学生信息模型
class StudentInfo {
  final String id;
  final String studentId;
  final String name;
  final String? avatar;
  final String gender;
  final String major;
  final String className;
  final String? phone;
  final String? email;
  final DateTime enrollmentDate;
  final String status;
  final StudentPerformance? performance;
  final bool? isInCourse;
  final String? matchType;

  StudentInfo({
    required this.id,
    required this.studentId,
    required this.name,
    this.avatar,
    required this.gender,
    required this.major,
    required this.className,
    this.phone,
    this.email,
    required this.enrollmentDate,
    required this.status,
    this.performance,
    this.isInCourse,
    this.matchType,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      gender: json['gender'] ?? '',
      major: json['major'] ?? '',
      className: json['className'] ?? json['class'] ?? '',
      phone: json['phone'],
      email: json['email'],
      enrollmentDate: DateTime.tryParse(json['enrollmentDate'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'active',
      performance: json['performance'] != null 
        ? StudentPerformance.fromJson(json['performance']) 
        : null,
      isInCourse: json['isInCourse'],
      matchType: json['matchType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'name': name,
      'avatar': avatar,
      'gender': gender,
      'major': major,
      'class': className,
      'phone': phone,
      'email': email,
      'enrollmentDate': enrollmentDate.toIso8601String(),
      'status': status,
      'performance': performance?.toJson(),
      'isInCourse': isInCourse,
      'matchType': matchType,
    };
  }
}

/// 学生表现模型
class StudentPerformance {
  final double currentScore;
  final double attendanceRate;
  final double assignmentCompletion;
  final DateTime? lastActiveTime;

  StudentPerformance({
    required this.currentScore,
    required this.attendanceRate,
    required this.assignmentCompletion,
    this.lastActiveTime,
  });

  factory StudentPerformance.fromJson(Map<String, dynamic> json) {
    return StudentPerformance(
      currentScore: (json['currentScore'] ?? 0.0).toDouble(),
      attendanceRate: (json['attendanceRate'] ?? 0.0).toDouble(),
      assignmentCompletion: (json['assignmentCompletion'] ?? 0.0).toDouble(),
      lastActiveTime: DateTime.tryParse(json['lastActiveTime'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentScore': currentScore,
      'attendanceRate': attendanceRate,
      'assignmentCompletion': assignmentCompletion,
      'lastActiveTime': lastActiveTime?.toIso8601String(),
    };
  }
}

/// 学生统计信息模型
class StudentStatistics {
  final int totalStudents;
  final int activeStudents;
  final double averageScore;
  final double attendanceRate;

  StudentStatistics({
    required this.totalStudents,
    required this.activeStudents,
    required this.averageScore,
    required this.attendanceRate,
  });

  factory StudentStatistics.fromJson(Map<String, dynamic> json) {
    return StudentStatistics(
      totalStudents: json['totalStudents'] ?? 0,
      activeStudents: json['activeStudents'] ?? 0,
      averageScore: (json['averageScore'] ?? 0.0).toDouble(),
      attendanceRate: (json['attendanceRate'] ?? 0.0).toDouble(),
    );
  }
}

/// 分页信息模型
class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasMore;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasMore,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalCount: json['totalCount'] ?? 0,
      hasMore: json['hasMore'] ?? false,
    );
  }
}

/// 学生列表响应模型
class StudentListResponse {
  final StudentStatistics statistics;
  final List<StudentInfo> students;
  final PaginationInfo pagination;

  StudentListResponse({
    required this.statistics,
    required this.students,
    required this.pagination,
  });

  factory StudentListResponse.fromJson(Map<String, dynamic> json) {
    return StudentListResponse(
      statistics: StudentStatistics.fromJson(json['statistics'] ?? {}),
      students: (json['students'] as List<dynamic>?)
          ?.map((item) => StudentInfo.fromJson(item))
          .toList() ?? [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}

/// 学生搜索响应模型
class StudentSearchResponse {
  final List<StudentInfo> students;
  final int totalCount;
  final bool hasMore;

  StudentSearchResponse({
    required this.students,
    required this.totalCount,
    required this.hasMore,
  });

  factory StudentSearchResponse.fromJson(Map<String, dynamic> json) {
    return StudentSearchResponse(
      students: (json['students'] as List<dynamic>?)
          ?.map((item) => StudentInfo.fromJson(item))
          .toList() ?? [],
      totalCount: json['totalCount'] ?? 0,
      hasMore: json['hasMore'] ?? false,
    );
  }
}

/// 操作结果模型
class OperationResult {
  final String studentId;
  final String studentName;
  final bool success;
  final String message;

  OperationResult({
    required this.studentId,
    required this.studentName,
    required this.success,
    required this.message,
  });

  factory OperationResult.fromJson(Map<String, dynamic> json) {
    return OperationResult(
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

/// 批量操作响应模型
class BatchOperationResponse {
  final int successCount;
  final int failureCount;
  final List<OperationResult> results;
  final Map<String, dynamic> courseStatistics;

  BatchOperationResponse({
    required this.successCount,
    required this.failureCount,
    required this.results,
    required this.courseStatistics,
  });

  factory BatchOperationResponse.fromJson(Map<String, dynamic> json) {
    return BatchOperationResponse(
      successCount: json['successCount'] ?? 0,
      failureCount: json['failureCount'] ?? 0,
      results: (json['results'] as List<dynamic>?)
          ?.map((item) => OperationResult.fromJson(item))
          .toList() ?? [],
      courseStatistics: Map<String, dynamic>.from(json['courseStatistics'] ?? {}),
    );
  }
}

/// 学生管理服务类
class StudentManagementService {
  final ApiService _apiService = ApiService();

  /// 获取课程学生列表
  Future<Map<String, dynamic>> getCourseStudents({
    required int courseId,
    String? keyword,
    String status = 'active',
    int page = 1,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'status': status,
        'page': page,
        'size': size,
      };
      
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }

      final response = await _apiService.get(
        '/api/teacher/courses/$courseId/students',
        queryParameters: queryParams,
      );

      return response;
    } catch (e) {
      debugPrint('获取课程学生列表失败: $e');
      rethrow;
    }
  }

  /// 搜索学生
  Future<Map<String, dynamic>> searchStudents({
    required String keyword,
    int? excludeCourseId,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'keyword': keyword,
        'limit': limit,
      };
      
      if (excludeCourseId != null) {
        queryParams['excludeCourseId'] = excludeCourseId;
      }

      final response = await _apiService.get(
        '/api/teacher/students/search',
        queryParameters: queryParams,
      );

      return response;
    } catch (e) {
      debugPrint('搜索学生失败: $e');
      rethrow;
    }
  }

  /// 添加学生到课程
  Future<Map<String, dynamic>> addStudentsToCourse({
    required int courseId,
    required List<String> studentIds,
    String enrollmentType = 'manual',
    bool sendNotification = true,
  }) async {
    try {
      final data = {
        'studentIds': studentIds,
        'enrollmentType': enrollmentType,
        'sendNotification': sendNotification,
      };

      final response = await _apiService.post(
        '/api/teacher/courses/$courseId/students/add',
        data: data,
      );

      return response;
    } catch (e) {
      debugPrint('添加学生到课程失败: $e');
      rethrow;
    }
  }

  /// 从课程移除学生
  Future<Map<String, dynamic>> removeStudentsFromCourse({
    required int courseId,
    required List<String> studentIds,
    String removeType = 'dropout',
    String? reason,
    bool sendNotification = true,
  }) async {
    try {
      final data = {
        'studentIds': studentIds,
        'removeType': removeType,
        'sendNotification': sendNotification,
      };
      
      if (reason != null && reason.isNotEmpty) {
        data['reason'] = reason;
      }

      final response = await _apiService.post(
        '/api/teacher/courses/$courseId/students/remove',
        data: data,
      );

      return response;
    } catch (e) {
      debugPrint('从课程移除学生失败: $e');
      rethrow;
    }
  }

  /// 获取学生详情
  Future<Map<String, dynamic>> getStudentDetail({
    required int courseId,
    required String studentId,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/teacher/courses/$courseId/students/$studentId/detail',
      );

      return response;
    } catch (e) {
      debugPrint('获取学生详情失败: $e');
      rethrow;
    }
  }

  /// 批量导入学生
  Future<Map<String, dynamic>> importStudents({
    required int courseId,
    required File excelFile,
    bool skipDuplicates = true,
    bool sendNotification = false,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          excelFile.path,
          filename: excelFile.path.split('/').last,
        ),
        'skipDuplicates': skipDuplicates,
        'sendNotification': sendNotification,
      });

      final response = await _apiService.post(
        '/api/teacher/courses/$courseId/students/import',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      return response;
    } catch (e) {
      debugPrint('批量导入学生失败: $e');
      rethrow;
    }
  }

  /// 格式化学生状态
  String getStatusText(String status) {
    switch (status) {
      case 'active':
        return '正常';
      case 'inactive':
        return '暂停';
      case 'dropout':
        return '退课';
      case 'completed':
        return '已完成';
      default:
        return '未知';
    }
  }

  /// 获取状态颜色
  Color getStatusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF4CAF50);
      case 'inactive':
        return const Color(0xFFFF9800);
      case 'dropout':
        return const Color(0xFFF44336);
      case 'completed':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  /// 格式化性别
  String getGenderText(String gender) {
    switch (gender) {
      case 'male':
        return '男';
      case 'female':
        return '女';
      default:
        return '未知';
    }
  }

  /// 格式化分数
  String formatScore(double score) {
    return score.toStringAsFixed(1);
  }

  /// 格式化百分比
  String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }
}
