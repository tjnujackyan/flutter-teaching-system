/// 课程相关数据模型
/// 
/// 包含课程信息、状态、统计等数据结构
/// 用于前后端数据交互和UI展示

/// 课程状态枚举
enum CourseStatus {
  ongoing('进行中'),
  upcoming('待开始'),
  completed('已完成'),
  archived('已归档');

  const CourseStatus(this.displayName);
  final String displayName;
}

/// 教师课程状态枚举
enum TeacherCourseStatus {
  ongoing('进行中'),
  upcoming('待开始'),
  ended('已结束');

  const TeacherCourseStatus(this.displayName);
  final String displayName;
}

/// 课程基础信息模型
class Course {
  final int id;
  final String courseName;
  final String courseCode;
  final String? description;
  final String icon;
  final String color;
  final String teacherName;
  final String department;
  final int totalHours;
  final int studentCount;
  final CourseStatus status;
  final double progress;
  final double rating;

  Course({
    required this.id,
    required this.courseName,
    required this.courseCode,
    this.description,
    required this.icon,
    required this.color,
    required this.teacherName,
    required this.department,
    required this.totalHours,
    required this.studentCount,
    required this.status,
    required this.progress,
    required this.rating,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? 0,
      courseName: json['courseName'] ?? '',
      courseCode: json['courseCode'] ?? '',
      description: json['description'],
      icon: json['icon'] ?? '📚',
      color: json['color'] ?? '#2196F3',
      teacherName: json['teacherName'] ?? '',
      department: json['department'] ?? '',
      totalHours: json['totalHours'] ?? 0,
      studentCount: json['studentCount'] ?? 0,
      status: CourseStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CourseStatus.ongoing,
      ),
      progress: (json['progress'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseName': courseName,
      'courseCode': courseCode,
      'description': description,
      'icon': icon,
      'color': color,
      'teacherName': teacherName,
      'department': department,
      'totalHours': totalHours,
      'studentCount': studentCount,
      'status': status.name,
      'progress': progress,
      'rating': rating,
    };
  }
}

/// 教师课程列表项模型
class CourseListItem {
  final int id;
  final String courseName;
  final String courseCode;
  final String? description;
  final String icon;
  final String color;
  final TeacherCourseStatus status;
  final int studentCount;
  final double rating;
  final double progress;
  final int totalHours;
  final String className;

  CourseListItem({
    required this.id,
    required this.courseName,
    required this.courseCode,
    this.description,
    required this.icon,
    required this.color,
    required this.status,
    required this.studentCount,
    required this.rating,
    required this.progress,
    required this.totalHours,
    required this.className,
  });

  factory CourseListItem.fromJson(Map<String, dynamic> json) {
    return CourseListItem(
      id: json['id'] ?? 0,
      courseName: json['courseName'] ?? '',
      courseCode: json['courseCode'] ?? '',
      description: json['description'],
      icon: json['icon'] ?? '📚',
      color: json['color'] ?? '#4CAF50',
      status: TeacherCourseStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TeacherCourseStatus.ongoing,
      ),
      studentCount: json['studentCount'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      progress: (json['progress'] ?? 0).toDouble(),
      totalHours: json['totalHours'] ?? 0,
      className: json['className'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseName': courseName,
      'courseCode': courseCode,
      'description': description,
      'icon': icon,
      'color': color,
      'status': status.name,
      'studentCount': studentCount,
      'rating': rating,
      'progress': progress,
      'totalHours': totalHours,
      'className': className,
    };
  }
}

/// 课程资源模型
class CourseResource {
  final int id;
  final String title;
  final String type;
  final String? description;
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final DateTime uploadTime;
  final String uploaderName;

  CourseResource({
    required this.id,
    required this.title,
    required this.type,
    this.description,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.uploadTime,
    required this.uploaderName,
  });

  factory CourseResource.fromJson(Map<String, dynamic> json) {
    return CourseResource(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      description: json['description'],
      fileName: json['fileName'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      uploadTime: DateTime.parse(json['uploadTime'] ?? DateTime.now().toIso8601String()),
      uploaderName: json['uploaderName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'description': description,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'uploadTime': uploadTime.toIso8601String(),
      'uploaderName': uploaderName,
    };
  }
}

/// 课程公告模型
class CourseAnnouncement {
  final int id;
  final String title;
  final String content;
  final bool isImportant;
  final DateTime publishTime;
  final String publisherName;
  final int viewCount;

  CourseAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    required this.isImportant,
    required this.publishTime,
    required this.publisherName,
    required this.viewCount,
  });

  factory CourseAnnouncement.fromJson(Map<String, dynamic> json) {
    return CourseAnnouncement(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      isImportant: json['isImportant'] ?? false,
      publishTime: DateTime.parse(json['publishTime'] ?? DateTime.now().toIso8601String()),
      publisherName: json['publisherName'] ?? '',
      viewCount: json['viewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'isImportant': isImportant,
      'publishTime': publishTime.toIso8601String(),
      'publisherName': publisherName,
      'viewCount': viewCount,
    };
  }
}

/// 今日课程模型（教师端）
class TodayClass {
  final int id;
  final String courseName;
  final String courseCode;
  final String className;
  final String timeSlot;
  final String location;
  final int studentCount;
  final String status;

  TodayClass({
    required this.id,
    required this.courseName,
    required this.courseCode,
    required this.className,
    required this.timeSlot,
    required this.location,
    required this.studentCount,
    required this.status,
  });

  factory TodayClass.fromJson(Map<String, dynamic> json) {
    return TodayClass(
      id: json['id'] ?? 0,
      courseName: json['courseName'] ?? '',
      courseCode: json['courseCode'] ?? '',
      className: json['className'] ?? '',
      timeSlot: json['timeSlot'] ?? '',
      location: json['location'] ?? '',
      studentCount: json['studentCount'] ?? 0,
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseName': courseName,
      'courseCode': courseCode,
      'className': className,
      'timeSlot': timeSlot,
      'location': location,
      'studentCount': studentCount,
      'status': status,
    };
  }
}

/// 教师课程模型
class TeacherCourse {
  final int id;
  final String courseName;
  final String courseCode;
  final String className;
  final TeacherCourseStatus status;
  final int studentCount;
  final int totalHours;
  final double rating;
  final double progress;
  final String icon;
  final String color;

  TeacherCourse({
    required this.id,
    required this.courseName,
    required this.courseCode,
    required this.className,
    required this.status,
    required this.studentCount,
    required this.totalHours,
    required this.rating,
    required this.progress,
    required this.icon,
    required this.color,
  });

  factory TeacherCourse.fromJson(Map<String, dynamic> json) {
    return TeacherCourse(
      id: json['id'] ?? 0,
      courseName: json['courseName'] ?? '',
      courseCode: json['courseCode'] ?? '',
      className: json['className'] ?? '',
      status: TeacherCourseStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TeacherCourseStatus.ongoing,
      ),
      studentCount: json['studentCount'] ?? 0,
      totalHours: json['totalHours'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      progress: (json['progress'] ?? 0).toDouble(),
      icon: json['icon'] ?? '📚',
      color: json['color'] ?? '#4CAF50',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseName': courseName,
      'courseCode': courseCode,
      'className': className,
      'status': status.name,
      'studentCount': studentCount,
      'totalHours': totalHours,
      'rating': rating,
      'progress': progress,
      'icon': icon,
      'color': color,
    };
  }
}
