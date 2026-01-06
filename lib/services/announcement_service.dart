import 'api_service.dart';

/// 公告类型枚举
enum AnnouncementType {
  normal('normal', '普通'),
  important('important', '重要'),
  urgent('urgent', '紧急'),
  system('system', '系统');

  const AnnouncementType(this.code, this.description);
  final String code;
  final String description;
}

/// 目标受众枚举
enum TargetAudience {
  all('all', '所有人'),
  students('students', '学生'),
  teachers('teachers', '教师');

  const TargetAudience(this.code, this.description);
  final String code;
  final String description;
}

/// 公告信息模型
class Announcement {
  final String id;
  final String title;
  final String content;
  final String summary;
  final AnnouncementType announcementType;
  final String announcementTypeText;
  final int priority;
  final bool isPinned;
  final bool isPublished;
  final String publishTime;
  final String? expireTime;
  final int viewCount;
  final TargetAudience targetAudience;
  final String targetAudienceText;
  final String teacherName;
  final int readCount;
  final int targetCount;
  final double readRate;
  final bool isRead;
  final bool isAcknowledged;
  final String createdAt;
  final String updatedAt;
  final bool isExpired;
  final bool isVisible;
  final List<String> attachmentUrls;
  final bool hasAttachments;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.summary,
    required this.announcementType,
    required this.announcementTypeText,
    required this.priority,
    required this.isPinned,
    required this.isPublished,
    required this.publishTime,
    this.expireTime,
    required this.viewCount,
    required this.targetAudience,
    required this.targetAudienceText,
    required this.teacherName,
    required this.readCount,
    required this.targetCount,
    required this.readRate,
    required this.isRead,
    required this.isAcknowledged,
    required this.createdAt,
    required this.updatedAt,
    required this.isExpired,
    required this.isVisible,
    required this.attachmentUrls,
    required this.hasAttachments,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      summary: json['summary'] ?? '',
      announcementType: _parseAnnouncementType(json['announcementType']),
      announcementTypeText: json['announcementTypeText'] ?? '',
      priority: json['priority'] ?? 0,
      isPinned: json['isPinned'] ?? false,
      isPublished: json['isPublished'] ?? false,
      publishTime: json['publishTime'] ?? '',
      expireTime: json['expireTime'],
      viewCount: json['viewCount'] ?? 0,
      targetAudience: _parseTargetAudience(json['targetAudience']),
      targetAudienceText: json['targetAudienceText'] ?? '',
      teacherName: json['teacherName'] ?? '',
      readCount: json['readCount'] ?? 0,
      targetCount: json['targetCount'] ?? 0,
      readRate: (json['readRate'] ?? 0.0).toDouble(),
      isRead: json['isRead'] ?? false,
      isAcknowledged: json['isAcknowledged'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      isExpired: json['isExpired'] ?? false,
      isVisible: json['isVisible'] ?? true,
      attachmentUrls: (json['attachmentUrls'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList() ?? [],
      hasAttachments: json['hasAttachments'] ?? false,
    );
  }

  static AnnouncementType _parseAnnouncementType(String? type) {
    switch (type) {
      case 'IMPORTANT':
        return AnnouncementType.important;
      case 'URGENT':
        return AnnouncementType.urgent;
      case 'SYSTEM':
        return AnnouncementType.system;
      default:
        return AnnouncementType.normal;
    }
  }

  static TargetAudience _parseTargetAudience(String? audience) {
    switch (audience) {
      case 'STUDENTS':
        return TargetAudience.students;
      case 'TEACHERS':
        return TargetAudience.teachers;
      default:
        return TargetAudience.all;
    }
  }
}

/// 公告统计信息模型
class AnnouncementStatistics {
  final int totalCount;
  final int publishedCount;
  final int pinnedCount;
  final int importantCount;
  final int expiredCount;
  final double averageReadRate;

  AnnouncementStatistics({
    required this.totalCount,
    required this.publishedCount,
    required this.pinnedCount,
    required this.importantCount,
    required this.expiredCount,
    required this.averageReadRate,
  });

  factory AnnouncementStatistics.fromJson(Map<String, dynamic> json) {
    return AnnouncementStatistics(
      totalCount: json['totalCount'] ?? 0,
      publishedCount: json['publishedCount'] ?? 0,
      pinnedCount: json['pinnedCount'] ?? 0,
      importantCount: json['importantCount'] ?? 0,
      expiredCount: json['expiredCount'] ?? 0,
      averageReadRate: (json['averageReadRate'] ?? 0.0).toDouble(),
    );
  }
}

/// 分页信息模型
class AnnouncementPagination {
  final int currentPage;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  AnnouncementPagination({
    required this.currentPage,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory AnnouncementPagination.fromJson(Map<String, dynamic> json) {
    return AnnouncementPagination(
      currentPage: json['currentPage'] ?? 0,
      pageSize: json['pageSize'] ?? 10,
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      hasNext: json['hasNext'] ?? false,
      hasPrevious: json['hasPrevious'] ?? false,
    );
  }
}

/// 公告列表响应模型
class AnnouncementListResponse {
  final List<Announcement> announcements;
  final AnnouncementStatistics statistics;
  final AnnouncementPagination pagination;

  AnnouncementListResponse({
    required this.announcements,
    required this.statistics,
    required this.pagination,
  });

  factory AnnouncementListResponse.fromJson(Map<String, dynamic> json) {
    return AnnouncementListResponse(
      announcements: (json['announcements'] as List<dynamic>?)
          ?.map((item) => Announcement.fromJson(item))
          .toList() ?? [],
      statistics: AnnouncementStatistics.fromJson(json['statistics'] ?? {}),
      pagination: AnnouncementPagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

/// 创建公告请求模型
class CreateAnnouncementRequest {
  final String courseId;
  final String title;
  final String content;
  final AnnouncementType announcementType;
  final int priority;
  final bool isPinned;
  final bool isPublished;
  final String? publishTime;
  final String? expireTime;
  final List<String>? attachmentUrls;
  final TargetAudience targetAudience;

  CreateAnnouncementRequest({
    required this.courseId,
    required this.title,
    required this.content,
    this.announcementType = AnnouncementType.normal,
    this.priority = 0,
    this.isPinned = false,
    this.isPublished = true,
    this.publishTime,
    this.expireTime,
    this.attachmentUrls,
    this.targetAudience = TargetAudience.all,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'courseId': int.parse(courseId),
      'title': title,
      'content': content,
      'announcementType': announcementType.code.toUpperCase(),
      'priority': priority,
      'isPinned': isPinned,
      'isPublished': isPublished,
      'targetAudience': targetAudience.code.toUpperCase(),
    };

    if (publishTime != null) json['publishTime'] = publishTime;
    if (expireTime != null) json['expireTime'] = expireTime;
    if (attachmentUrls != null) json['attachmentUrls'] = attachmentUrls;

    return json;
  }
}

/// 公告服务类
class AnnouncementService {
  /// 获取课程公告列表
  static Future<ApiResponse<AnnouncementListResponse>> getCourseAnnouncements(
    String courseId, {
    bool? isPublished,
    AnnouncementType? announcementType,
    int page = 0,
    int size = 10,
  }) async {
    String endpoint = '/api/announcements/course/$courseId';
    
    List<String> queryParams = [];
    if (isPublished != null) queryParams.add('isPublished=$isPublished');
    if (announcementType != null) {
      queryParams.add('announcementType=${announcementType.code.toUpperCase()}');
    }
    queryParams.add('page=$page');
    queryParams.add('size=$size');
    
    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }

    return await ApiService.request<AnnouncementListResponse>(
      endpoint,
      method: 'GET',
      fromJson: (json) => AnnouncementListResponse.fromJson(json),
    );
  }

  /// 获取公告列表（通用方法）
  static Future<ApiResponse<AnnouncementListResponse>> getAnnouncementList({
    required String courseId,
    int page = 1,
    int pageSize = 50,
    AnnouncementType? announcementType,
    bool? isPublished,
  }) async {
    return await getCourseAnnouncements(
      courseId,
      isPublished: isPublished,
      announcementType: announcementType,
      page: page - 1, // 转换为0基索引
      size: pageSize,
    );
  }

  /// 创建公告
  static Future<ApiResponse<Map<String, dynamic>>> createAnnouncement(
      CreateAnnouncementRequest request) async {
    return await ApiService.request<Map<String, dynamic>>(
      '/api/announcements/create',
      method: 'POST',
      data: request.toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// 获取公告详情
  static Future<ApiResponse<Announcement>> getAnnouncementDetail(String announcementId) async {
    return await ApiService.request<Announcement>(
      '/api/announcements/$announcementId',
      method: 'GET',
      fromJson: (json) => Announcement.fromJson(json),
    );
  }

  /// 更新公告
  static Future<ApiResponse<Announcement>> updateAnnouncement(
      String announcementId, CreateAnnouncementRequest request) async {
    return await ApiService.request<Announcement>(
      '/api/announcements/$announcementId',
      method: 'PUT',
      data: request.toJson(),
      fromJson: (json) => Announcement.fromJson(json),
    );
  }

  /// 删除公告
  static Future<ApiResponse<void>> deleteAnnouncement(String announcementId) async {
    return await ApiService.request<void>(
      '/api/announcements/$announcementId',
      method: 'DELETE',
    );
  }

  /// 标记公告为已读
  static Future<ApiResponse<void>> markAsRead(String announcementId) async {
    return await ApiService.request<void>(
      '/api/announcements/$announcementId/read',
      method: 'POST',
    );
  }

  /// 确认已读公告
  static Future<ApiResponse<void>> acknowledgeRead(String announcementId) async {
    return await ApiService.request<void>(
      '/api/announcements/$announcementId/acknowledge',
      method: 'POST',
    );
  }

  /// 获取最新公告
  static Future<ApiResponse<List<Announcement>>> getLatestAnnouncements(
      String courseId, {int limit = 5}) async {
    return await ApiService.request<List<Announcement>>(
      '/api/announcements/course/$courseId/latest?limit=$limit',
      method: 'GET',
      fromJson: (json) => (json as List<dynamic>)
          .map((item) => Announcement.fromJson(item))
          .toList(),
    );
  }

  /// 获取重要公告
  static Future<ApiResponse<List<Announcement>>> getImportantAnnouncements(String courseId) async {
    return await ApiService.request<List<Announcement>>(
      '/api/announcements/course/$courseId/important',
      method: 'GET',
      fromJson: (json) => (json as List<dynamic>)
          .map((item) => Announcement.fromJson(item))
          .toList(),
    );
  }
}
