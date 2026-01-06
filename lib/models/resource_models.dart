/// 资料分类模型
class ResourceCategory {
  final String categoryKey;
  final String categoryName;
  final String icon;
  final String color;
  final String allowedTypes;
  final int maxFileSize;
  final String description;
  final int displayOrder;
  final bool isEnabled;

  ResourceCategory({
    required this.categoryKey,
    required this.categoryName,
    required this.icon,
    required this.color,
    required this.allowedTypes,
    required this.maxFileSize,
    required this.description,
    required this.displayOrder,
    required this.isEnabled,
  });

  factory ResourceCategory.fromJson(Map<String, dynamic> json) {
    return ResourceCategory(
      categoryKey: json['categoryKey'] ?? '',
      categoryName: json['categoryName'] ?? '',
      icon: json['icon'] ?? '📎',
      color: json['color'] ?? '#6B7280',
      allowedTypes: json['allowedTypes'] ?? '',
      maxFileSize: json['maxFileSize'] ?? 0,
      description: json['description'] ?? '',
      displayOrder: json['displayOrder'] ?? 0,
      isEnabled: json['isEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryKey': categoryKey,
      'categoryName': categoryName,
      'icon': icon,
      'color': color,
      'allowedTypes': allowedTypes,
      'maxFileSize': maxFileSize,
      'description': description,
      'displayOrder': displayOrder,
      'isEnabled': isEnabled,
    };
  }
}

/// 课程资料模型
class CourseResource {
  final int id;
  final int courseId;
  final int uploaderId;
  final String title;
  final String? description;
  final String fileName;
  final String filePath;
  final int fileSize;
  final String fileType;
  final String mimeType;
  final String fileExtension;
  final String category;
  final String? chapterName;
  final int displayOrder;
  final bool isPublic;
  final bool isDownloadable;
  final int viewCount;
  final int downloadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UploaderInfo? uploader;

  CourseResource({
    required this.id,
    required this.courseId,
    required this.uploaderId,
    required this.title,
    this.description,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.fileType,
    required this.mimeType,
    required this.fileExtension,
    required this.category,
    this.chapterName,
    required this.displayOrder,
    required this.isPublic,
    required this.isDownloadable,
    required this.viewCount,
    required this.downloadCount,
    required this.createdAt,
    required this.updatedAt,
    this.uploader,
  });

  factory CourseResource.fromJson(Map<String, dynamic> json) {
    return CourseResource(
      id: json['id'] ?? 0,
      courseId: json['courseId'] ?? 0,
      uploaderId: json['uploaderId'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      fileName: json['fileName'] ?? '',
      filePath: json['filePath'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      fileType: json['fileType'] ?? '',
      mimeType: json['mimeType'] ?? '',
      fileExtension: json['fileExtension'] ?? '',
      category: json['category'] ?? '',
      chapterName: json['chapterName'],
      displayOrder: json['displayOrder'] ?? 0,
      isPublic: json['isPublic'] ?? true,
      isDownloadable: json['isDownloadable'] ?? true,
      viewCount: json['viewCount'] ?? 0,
      downloadCount: json['downloadCount'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      uploader: json['uploader'] != null 
        ? UploaderInfo.fromJson(json['uploader']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'uploaderId': uploaderId,
      'title': title,
      'description': description,
      'fileName': fileName,
      'filePath': filePath,
      'fileSize': fileSize,
      'fileType': fileType,
      'mimeType': mimeType,
      'fileExtension': fileExtension,
      'category': category,
      'chapterName': chapterName,
      'displayOrder': displayOrder,
      'isPublic': isPublic,
      'isDownloadable': isDownloadable,
      'viewCount': viewCount,
      'downloadCount': downloadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'uploader': uploader?.toJson(),
    };
  }
}

/// 上传者信息模型
class UploaderInfo {
  final int id;
  final String name;
  final String? avatar;
  final String userType;

  UploaderInfo({
    required this.id,
    required this.name,
    this.avatar,
    required this.userType,
  });

  factory UploaderInfo.fromJson(Map<String, dynamic> json) {
    return UploaderInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      avatar: json['avatar'],
      userType: json['userType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'userType': userType,
    };
  }
}

/// 资料列表响应模型
class ResourceListResponse {
  final List<CourseResource> resources;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final Map<String, int> categoryStats;

  ResourceListResponse({
    required this.resources,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
    required this.categoryStats,
  });

  factory ResourceListResponse.fromJson(Map<String, dynamic> json) {
    return ResourceListResponse(
      resources: (json['resources'] as List<dynamic>?)
          ?.map((item) => CourseResource.fromJson(item))
          .toList() ?? [],
      totalCount: json['totalCount'] ?? 0,
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      hasMore: json['hasMore'] ?? false,
      categoryStats: Map<String, int>.from(json['categoryStats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resources': resources.map((r) => r.toJson()).toList(),
      'totalCount': totalCount,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'hasMore': hasMore,
      'categoryStats': categoryStats,
    };
  }
}

/// 资料详情响应模型
class ResourceDetailResponse {
  final CourseResource resource;
  final UploaderInfo uploader;
  final CourseInfo course;
  final AccessStats accessStats;
  final List<CourseResource> relatedResources;

  ResourceDetailResponse({
    required this.resource,
    required this.uploader,
    required this.course,
    required this.accessStats,
    required this.relatedResources,
  });

  factory ResourceDetailResponse.fromJson(Map<String, dynamic> json) {
    return ResourceDetailResponse(
      resource: CourseResource.fromJson(json['resource'] ?? {}),
      uploader: UploaderInfo.fromJson(json['uploader'] ?? {}),
      course: CourseInfo.fromJson(json['course'] ?? {}),
      accessStats: AccessStats.fromJson(json['accessStats'] ?? {}),
      relatedResources: (json['relatedResources'] as List<dynamic>?)
          ?.map((item) => CourseResource.fromJson(item))
          .toList() ?? [],
    );
  }
}

/// 课程信息模型
class CourseInfo {
  final int id;
  final String courseName;
  final String courseCode;
  final String icon;
  final String color;

  CourseInfo({
    required this.id,
    required this.courseName,
    required this.courseCode,
    required this.icon,
    required this.color,
  });

  factory CourseInfo.fromJson(Map<String, dynamic> json) {
    return CourseInfo(
      id: json['id'] ?? 0,
      courseName: json['courseName'] ?? '',
      courseCode: json['courseCode'] ?? '',
      icon: json['icon'] ?? '📚',
      color: json['color'] ?? '#3B82F6',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseName': courseName,
      'courseCode': courseCode,
      'icon': icon,
      'color': color,
    };
  }
}

/// 访问统计模型
class AccessStats {
  final int totalViews;
  final int totalDownloads;
  final int todayViews;
  final int todayDownloads;
  final List<AccessRecord> recentAccess;

  AccessStats({
    required this.totalViews,
    required this.totalDownloads,
    required this.todayViews,
    required this.todayDownloads,
    required this.recentAccess,
  });

  factory AccessStats.fromJson(Map<String, dynamic> json) {
    return AccessStats(
      totalViews: json['totalViews'] ?? 0,
      totalDownloads: json['totalDownloads'] ?? 0,
      todayViews: json['todayViews'] ?? 0,
      todayDownloads: json['todayDownloads'] ?? 0,
      recentAccess: (json['recentAccess'] as List<dynamic>?)
          ?.map((item) => AccessRecord.fromJson(item))
          .toList() ?? [],
    );
  }
}

/// 访问记录模型
class AccessRecord {
  final String userName;
  final String userType;
  final String actionType;
  final DateTime accessTime;

  AccessRecord({
    required this.userName,
    required this.userType,
    required this.actionType,
    required this.accessTime,
  });

  factory AccessRecord.fromJson(Map<String, dynamic> json) {
    return AccessRecord(
      userName: json['userName'] ?? '',
      userType: json['userType'] ?? '',
      actionType: json['actionType'] ?? '',
      accessTime: DateTime.tryParse(json['accessTime'] ?? '') ?? DateTime.now(),
    );
  }
}

/// 上传资料响应模型
class UploadResourceResponse {
  final int resourceId;
  final String fileName;
  final int fileSize;
  final String downloadUrl;

  UploadResourceResponse({
    required this.resourceId,
    required this.fileName,
    required this.fileSize,
    required this.downloadUrl,
  });

  factory UploadResourceResponse.fromJson(Map<String, dynamic> json) {
    return UploadResourceResponse(
      resourceId: json['resourceId'] ?? 0,
      fileName: json['fileName'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      downloadUrl: json['downloadUrl'] ?? '',
    );
  }
}
