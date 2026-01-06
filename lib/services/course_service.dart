import 'dart:io';
import 'api_service.dart';
import '../models/course_models.dart';

/// 课程统计信息模型
class CourseStatistics {
  final int totalCourses;
  final int totalStudents;
  final double averageRating;

  CourseStatistics({
    required this.totalCourses,
    required this.totalStudents,
    required this.averageRating,
  });

  factory CourseStatistics.fromJson(Map<String, dynamic> json) {
    return CourseStatistics(
      totalCourses: json['totalCourses'] ?? 0,
      totalStudents: json['totalStudents'] ?? 0,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
    );
  }
}

/// 课程信息模型
class Course {
  final String id;
  final String name;
  final String code;
  final String icon;
  final String color;
  final String status;
  final String statusText;
  final int studentCount;
  final double rating;
  final double progress;
  final int totalWeeks;
  final int currentWeek;
  final int credits;
  final String semester;
  final String classroom;
  final String schedule;
  final String createdAt;
  final String updatedAt;

  Course({
    required this.id,
    required this.name,
    required this.code,
    required this.icon,
    required this.color,
    required this.status,
    required this.statusText,
    required this.studentCount,
    required this.rating,
    required this.progress,
    required this.totalWeeks,
    required this.currentWeek,
    required this.credits,
    required this.semester,
    required this.classroom,
    required this.schedule,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      icon: json['icon'] ?? '💻',
      color: json['color'] ?? '#4285F4',
      status: json['status'] ?? 'upcoming',
      statusText: json['statusText'] ?? '待开始',
      studentCount: json['studentCount'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      progress: (json['progress'] ?? 0.0).toDouble(),
      totalWeeks: json['totalWeeks'] ?? 0,
      currentWeek: json['currentWeek'] ?? 0,
      credits: json['credits'] ?? 0,
      semester: json['semester'] ?? '',
      classroom: json['classroom'] ?? '',
      schedule: json['schedule'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}

/// 课程列表响应模型
class CourseListResponse {
  final CourseStatistics statistics;
  final List<Course> courses;

  CourseListResponse({
    required this.statistics,
    required this.courses,
  });

  factory CourseListResponse.fromJson(Map<String, dynamic> json) {
    return CourseListResponse(
      statistics: CourseStatistics.fromJson(json['statistics'] ?? {}),
      courses: (json['courses'] as List<dynamic>?)
          ?.map((item) => Course.fromJson(item))
          .toList() ?? [],
    );
  }
}

/// 课程图标配置模型
class CourseIconConfig {
  final String id;
  final String icon;
  final String name;
  final String color;

  CourseIconConfig({
    required this.id,
    required this.icon,
    required this.name,
    required this.color,
  });

  factory CourseIconConfig.fromJson(Map<String, dynamic> json) {
    return CourseIconConfig(
      id: json['id'] ?? '',
      icon: json['icon'] ?? '',
      name: json['name'] ?? '',
      color: json['color'] ?? '',
    );
  }
}

/// 课程类型配置模型
class CourseTypeConfig {
  final String id;
  final String name;

  CourseTypeConfig({
    required this.id,
    required this.name,
  });

  factory CourseTypeConfig.fromJson(Map<String, dynamic> json) {
    return CourseTypeConfig(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

/// 课程分类配置模型
class CourseCategoryConfig {
  final String id;
  final String name;

  CourseCategoryConfig({
    required this.id,
    required this.name,
  });

  factory CourseCategoryConfig.fromJson(Map<String, dynamic> json) {
    return CourseCategoryConfig(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

/// 星期配置模型
class WeekdayConfig {
  final String id;
  final String name;

  WeekdayConfig({
    required this.id,
    required this.name,
  });

  factory WeekdayConfig.fromJson(Map<String, dynamic> json) {
    return WeekdayConfig(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

/// 课程创建配置响应模型
class CourseCreateConfigResponse {
  final List<CourseIconConfig> icons;
  final List<CourseTypeConfig> courseTypes;
  final List<CourseCategoryConfig> categories;
  final List<int> credits;
  final List<WeekdayConfig> weekdays;

  CourseCreateConfigResponse({
    required this.icons,
    required this.courseTypes,
    required this.categories,
    required this.credits,
    required this.weekdays,
  });

  factory CourseCreateConfigResponse.fromJson(Map<String, dynamic> json) {
    return CourseCreateConfigResponse(
      icons: (json['icons'] as List<dynamic>?)
          ?.map((item) => CourseIconConfig.fromJson(item))
          .toList() ?? [],
      courseTypes: (json['courseTypes'] as List<dynamic>?)
          ?.map((item) => CourseTypeConfig.fromJson(item))
          .toList() ?? [],
      categories: (json['categories'] as List<dynamic>?)
          ?.map((item) => CourseCategoryConfig.fromJson(item))
          .toList() ?? [],
      credits: (json['credits'] as List<dynamic>?)
          ?.map((item) => item as int)
          .toList() ?? [],
      weekdays: (json['weekdays'] as List<dynamic>?)
          ?.map((item) => WeekdayConfig.fromJson(item))
          .toList() ?? [],
    );
  }
}

/// 上课时间安排模型
class ScheduleItem {
  final String weekday;
  final String startTime;
  final String endTime;

  ScheduleItem({
    required this.weekday,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'weekday': weekday,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

/// 创建课程请求模型
class CreateCourseRequest {
  final String name;
  final String code;
  final String iconId;
  final int credits;
  final String courseType;
  final String category;
  final String? description;
  final String startDate;
  final String endDate;
  final String? classroom;
  final List<ScheduleItem>? schedule;
  final bool isDraft;

  CreateCourseRequest({
    required this.name,
    required this.code,
    required this.iconId,
    required this.credits,
    required this.courseType,
    required this.category,
    this.description,
    required this.startDate,
    required this.endDate,
    this.classroom,
    this.schedule,
    this.isDraft = false,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'name': name,
      'code': code,
      'iconId': iconId,
      'credits': credits,
      'courseType': courseType,
      'category': category,
      'startDate': startDate,
      'endDate': endDate,
      'isDraft': isDraft,
    };

    if (description != null) json['description'] = description;
    if (classroom != null) json['classroom'] = classroom;
    if (schedule != null) {
      json['schedule'] = schedule!.map((item) => item.toJson()).toList();
    }

    return json;
  }
}

/// 更新课程请求模型
class UpdateCourseRequest {
  final String? name;
  final String? description;
  final String? classroom;
  final List<ScheduleItem>? schedule;

  UpdateCourseRequest({
    this.name,
    this.description,
    this.classroom,
    this.schedule,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (name != null) json['name'] = name;
    if (description != null) json['description'] = description;
    if (classroom != null) json['classroom'] = classroom;
    if (schedule != null) {
      json['schedule'] = schedule!.map((item) => item.toJson()).toList();
    }

    return json;
  }
}

/// 课程详情响应模型
class CourseDetailResponse {
  final CourseInfo courseInfo;
  final CourseDetailStatistics statistics;
  final QuickActions quickActions;
  final List<RecentActivity> recentActivities;

  CourseDetailResponse({
    required this.courseInfo,
    required this.statistics,
    required this.quickActions,
    required this.recentActivities,
  });

  factory CourseDetailResponse.fromJson(Map<String, dynamic> json) {
    return CourseDetailResponse(
      courseInfo: CourseInfo.fromJson(json['courseInfo'] ?? {}),
      statistics: CourseDetailStatistics.fromJson(json['statistics'] ?? {}),
      quickActions: QuickActions.fromJson(json['quickActions'] ?? {}),
      recentActivities: (json['recentActivities'] as List<dynamic>?)
          ?.map((item) => RecentActivity.fromJson(item))
          .toList() ?? [],
    );
  }
}

/// 课程详情信息模型
class CourseInfo {
  final String id;
  final String name;
  final String code;
  final String icon;
  final String color;
  final String status;
  final String statusText;
  final int credits;
  final String courseType;
  final String category;
  final String description;
  final String semester;
  final String classroom;
  final String schedule;
  final String startDate;
  final String endDate;
  final String inviteCode;

  CourseInfo({
    required this.id,
    required this.name,
    required this.code,
    required this.icon,
    required this.color,
    required this.status,
    required this.statusText,
    required this.credits,
    required this.courseType,
    required this.category,
    required this.description,
    required this.semester,
    required this.classroom,
    required this.schedule,
    required this.startDate,
    required this.endDate,
    required this.inviteCode,
  });

  factory CourseInfo.fromJson(Map<String, dynamic> json) {
    return CourseInfo(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '',
      status: json['status'] ?? '',
      statusText: json['statusText'] ?? '',
      credits: json['credits'] ?? 0,
      courseType: json['courseType'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      semester: json['semester'] ?? '',
      classroom: json['classroom'] ?? '',
      schedule: json['schedule'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      inviteCode: json['inviteCode'] ?? '',
    );
  }
}

/// 课程详情统计模型
class CourseDetailStatistics {
  final int studentCount;
  final int totalWeeks;
  final int currentWeek;
  final double progress;
  final int completedChapters;
  final int totalChapters;
  final double averageScore;
  final double attendanceRate;

  CourseDetailStatistics({
    required this.studentCount,
    required this.totalWeeks,
    required this.currentWeek,
    required this.progress,
    required this.completedChapters,
    required this.totalChapters,
    required this.averageScore,
    required this.attendanceRate,
  });

  factory CourseDetailStatistics.fromJson(Map<String, dynamic> json) {
    return CourseDetailStatistics(
      studentCount: json['studentCount'] ?? 0,
      totalWeeks: json['totalWeeks'] ?? 0,
      currentWeek: json['currentWeek'] ?? 0,
      progress: (json['progress'] ?? 0.0).toDouble(),
      completedChapters: json['completedChapters'] ?? 0,
      totalChapters: json['totalChapters'] ?? 0,
      averageScore: (json['averageScore'] ?? 0.0).toDouble(),
      attendanceRate: (json['attendanceRate'] ?? 0.0).toDouble(),
    );
  }
}

/// 快速操作模型
class QuickActions {
  final bool canPublishAssignment;
  final bool canCreateQuiz;
  final bool canUploadMaterial;
  final bool canManageStudents;

  QuickActions({
    required this.canPublishAssignment,
    required this.canCreateQuiz,
    required this.canUploadMaterial,
    required this.canManageStudents,
  });

  factory QuickActions.fromJson(Map<String, dynamic> json) {
    return QuickActions(
      canPublishAssignment: json['canPublishAssignment'] ?? false,
      canCreateQuiz: json['canCreateQuiz'] ?? false,
      canUploadMaterial: json['canUploadMaterial'] ?? false,
      canManageStudents: json['canManageStudents'] ?? false,
    );
  }
}

/// 最近活动模型
class RecentActivity {
  final String type;
  final String title;
  final String time;

  RecentActivity({
    required this.type,
    required this.title,
    required this.time,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      time: json['time'] ?? '',
    );
  }
}

/// 课程服务类
class CourseService {
  /// 获取教师课程列表
  static Future<ApiResponse<CourseListResponse>> getTeacherCourses({
    String? status,
  }) async {
    String endpoint = '/api/teacher/courses/list';
    if (status != null) {
      endpoint += '?status=$status';
    }

    return await ApiService.request<CourseListResponse>(
      endpoint,
      method: 'GET',
      fromJson: (json) => CourseListResponse.fromJson(json),
    );
  }

  /// 获取课程创建配置
  static Future<ApiResponse<CourseCreateConfigResponse>> getCourseCreateConfig() async {
    return await ApiService.request<CourseCreateConfigResponse>(
      '/api/teacher/courses/create-config',
      method: 'GET',
      fromJson: (json) => CourseCreateConfigResponse.fromJson(json),
    );
  }

  /// 创建课程
  static Future<ApiResponse<Map<String, dynamic>>> createCourse(
    CreateCourseRequest request,
  ) async {
    return await ApiService.request<Map<String, dynamic>>(
      '/api/teacher/courses/create',
      method: 'POST',
      data: request.toJson(),
      fromJson: (json) => json,
    );
  }

  /// 获取课程详情
  static Future<ApiResponse<CourseDetailResponse>> getCourseDetail(
    String courseId,
  ) async {
    return await ApiService.request<CourseDetailResponse>(
      '/api/teacher/courses/$courseId/detail',
      method: 'GET',
      fromJson: (json) => CourseDetailResponse.fromJson(json),
    );
  }

  /// 更新课程信息
  static Future<ApiResponse<Map<String, dynamic>>> updateCourse(
    String courseId,
    UpdateCourseRequest request,
  ) async {
    return await ApiService.request<Map<String, dynamic>>(
      '/api/teacher/courses/$courseId/update',
      method: 'PUT',
      data: request.toJson(),
      fromJson: (json) => json,
    );
  }

  /// 获取课程统计
  static Future<ApiResponse<Map<String, dynamic>>> getCourseStatistics(
    String courseId,
  ) async {
    return await ApiService.request<Map<String, dynamic>>(
      '/api/teacher/courses/$courseId/statistics',
      method: 'GET',
      fromJson: (json) => json,
    );
  }

  /// 获取教师课程列表（用于测验创建页面）
  static Future<List<CourseListItem>> getTeacherCoursesForQuiz() async {
    try {
      final response = await getTeacherCourses();
      if (response.isSuccess && response.body != null) {
        return response.body!.courses.map((course) => CourseListItem(
          id: int.tryParse(course.id) ?? 0,
          courseName: course.name,
          courseCode: course.code,
          description: null,
          icon: course.icon,
          color: course.color,
          status: TeacherCourseStatus.values.firstWhere(
            (e) => e.name == course.status,
            orElse: () => TeacherCourseStatus.ongoing,
          ),
          studentCount: course.studentCount,
          rating: course.rating,
          progress: course.progress,
          totalHours: course.totalWeeks * 2, // 假设每周2学时
          className: '',
        )).toList();
      }
      return [];
    } catch (e) {
      print('获取教师课程列表失败: $e');
      return [];
    }
  }
}
