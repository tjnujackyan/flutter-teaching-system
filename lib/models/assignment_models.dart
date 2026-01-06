// 作业相关数据模型

/// 作业状态枚举
enum AssignmentStatus {
  draft('draft', '草稿'),
  published('published', '已发布'),
  closed('closed', '已关闭'),
  archived('archived', '已归档');

  const AssignmentStatus(this.value, this.label);
  final String value;
  final String label;

  static AssignmentStatus fromValue(String value) {
    return AssignmentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => AssignmentStatus.draft,
    );
  }
}

/// 作业类型枚举
enum AssignmentType {
  homework('homework', '作业'),
  report('report', '报告'),
  project('project', '项目'),
  exam('exam', '考试');

  const AssignmentType(this.value, this.label);
  final String value;
  final String label;

  static AssignmentType fromValue(String value) {
    return AssignmentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AssignmentType.homework,
    );
  }
}

/// 提交状态枚举
enum SubmissionStatus {
  notSubmitted('not_submitted', '未提交'),
  submitted('submitted', '已提交'),
  grading('grading', '批改中'),
  graded('graded', '已批改'),
  overdue('overdue', '已逾期');

  const SubmissionStatus(this.value, this.label);
  final String value;
  final String label;

  static SubmissionStatus fromValue(String value) {
    return SubmissionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SubmissionStatus.notSubmitted,
    );
  }
}

/// 作业基本信息
class Assignment {
  final int id;
  final int courseId;
  final String courseName;
  final int teacherId;
  final String teacherName;
  final String title;
  final String description;
  final AssignmentType type;
  final int totalScore;
  final int? chapterId;
  final String? chapterName;
  final DateTime publishTime;
  final DateTime dueTime;
  final bool allowLateSubmission;
  final double latePenaltyRate;
  final int maxAttempts;
  final bool autoGrade;
  final bool showScoreImmediately;
  final bool attachmentRequired;
  final AssignmentStatus status;
  final int submissionCount;
  final int gradedCount;
  final double? averageScore;
  final DateTime? deletedAt;

  Assignment({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.teacherId,
    required this.teacherName,
    required this.title,
    required this.description,
    required this.type,
    required this.totalScore,
    this.chapterId,
    this.chapterName,
    required this.publishTime,
    required this.dueTime,
    required this.allowLateSubmission,
    required this.latePenaltyRate,
    required this.maxAttempts,
    required this.autoGrade,
    required this.showScoreImmediately,
    required this.attachmentRequired,
    required this.status,
    required this.submissionCount,
    required this.gradedCount,
    this.averageScore,
    this.deletedAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      courseId: json['courseId'],
      courseName: json['courseName'] ?? '',
      teacherId: json['teacherId'] ?? 0,
      teacherName: json['teacherName'] ?? '',
      title: json['title'],
      description: json['description'] ?? '',
      type: AssignmentType.fromValue(json['assignmentType']),
      totalScore: json['totalScore'],
      chapterId: json['chapterId'],
      chapterName: json['chapterName'],
      publishTime: DateTime.parse(json['publishTime']),
      dueTime: DateTime.parse(json['dueTime']),
      allowLateSubmission: json['allowLateSubmission'] ?? false,
      latePenaltyRate: (json['latePenaltyRate'] ?? 0.0).toDouble(),
      maxAttempts: json['maxAttempts'] ?? 1,
      autoGrade: json['autoGrade'] ?? false,
      showScoreImmediately: json['showScoreImmediately'] ?? false,
      attachmentRequired: json['attachmentRequired'] ?? false,
      status: AssignmentStatus.fromValue(json['status']),
      submissionCount: json['submissionCount'] ?? 0,
      gradedCount: json['gradedCount'] ?? 0,
      averageScore: json['averageScore']?.toDouble(),
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  /// 是否已过期
  bool get isOverdue => DateTime.now().isAfter(dueTime);

  /// 是否已发布
  bool get isPublished => status == AssignmentStatus.published;

  /// 完成率
  double get completionRate {
    if (submissionCount == 0) return 0.0;
    return (gradedCount / submissionCount) * 100;
  }

  /// 剩余时间（小时）
  int get remainingHours {
    if (isOverdue) return 0;
    return dueTime.difference(DateTime.now()).inHours;
  }

  /// 剩余天数
  int get remainingDays {
    if (isOverdue) return 0;
    return dueTime.difference(DateTime.now()).inDays;
  }
}

/// 作业提交信息
class AssignmentSubmission {
  final int id;
  final int assignmentId;
  final String assignmentTitle;
  final int studentId;
  final String studentName;
  final String studentStudentId;
  final String? content;
  final DateTime submitTime;
  final String ipAddress;
  final SubmissionStatus status;
  final int? totalScore;
  final String? feedback;
  final DateTime? gradedTime;
  final int? gradedBy;
  final String? graderName;
  final bool isLate;
  final int attemptNumber;
  final List<AssignmentAttachment> attachments;

  AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.studentId,
    required this.studentName,
    required this.studentStudentId,
    this.content,
    required this.submitTime,
    required this.ipAddress,
    required this.status,
    this.totalScore,
    this.feedback,
    this.gradedTime,
    this.gradedBy,
    this.graderName,
    required this.isLate,
    required this.attemptNumber,
    required this.attachments,
  });

  factory AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmission(
      id: json['id'],
      assignmentId: json['assignmentId'],
      assignmentTitle: json['assignmentTitle'] ?? '',
      studentId: json['studentId'],
      studentName: json['studentName'] ?? '',
      studentStudentId: json['studentStudentId'] ?? '',
      content: json['content'],
      submitTime: DateTime.parse(json['submitTime']),
      ipAddress: json['ipAddress'],
      status: SubmissionStatus.fromValue(json['status']),
      totalScore: json['totalScore'],
      feedback: json['feedback'],
      gradedTime: json['gradedTime'] != null ? DateTime.parse(json['gradedTime']) : null,
      gradedBy: json['gradedBy'],
      graderName: json['graderName'],
      isLate: json['isLate'],
      attemptNumber: json['attemptNumber'],
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((item) => AssignmentAttachment.fromJson(item))
          .toList() ?? [],
    );
  }

  /// 是否已批改
  bool get isGraded => status == SubmissionStatus.graded;

  /// 是否正在批改
  bool get isGrading => status == SubmissionStatus.grading;

  /// 得分率
  double get scoreRate {
    if (totalScore == null) return 0.0;
    return totalScore! / 100.0;
  }
}

/// 作业附件
class AssignmentAttachment {
  final int id;
  final int? assignmentId;
  final int? submissionId;
  final String fileName;
  final String originalName;
  final String filePath;
  final String fileType;
  final int fileSize;
  final String attachmentType; // assignment, submission
  final DateTime uploadTime;
  final int uploadedBy;
  final String? uploaderName;

  AssignmentAttachment({
    required this.id,
    this.assignmentId,
    this.submissionId,
    required this.fileName,
    required this.originalName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.attachmentType,
    required this.uploadTime,
    required this.uploadedBy,
    this.uploaderName,
  });

  factory AssignmentAttachment.fromJson(Map<String, dynamic> json) {
    return AssignmentAttachment(
      id: json['id'],
      assignmentId: json['assignmentId'],
      submissionId: json['submissionId'],
      fileName: json['fileName'],
      originalName: json['originalName'],
      filePath: json['filePath'],
      fileType: json['fileType'],
      fileSize: json['fileSize'],
      attachmentType: json['attachmentType'],
      uploadTime: DateTime.parse(json['uploadTime']),
      uploadedBy: json['uploadedBy'],
      uploaderName: json['uploaderName'],
    );
  }

  /// 格式化文件大小
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// 是否是图片文件
  bool get isImage {
    final imageTypes = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageTypes.contains(fileType.toLowerCase());
  }

  /// 是否是文档文件
  bool get isDocument {
    final docTypes = ['pdf', 'doc', 'docx', 'txt', 'md'];
    return docTypes.contains(fileType.toLowerCase());
  }
}

/// 评分标准
class GradingCriteria {
  final int id;
  final int assignmentId;
  final String criteriaName;
  final String? description;
  final int maxScore;
  final double weight;
  final int displayOrder;

  GradingCriteria({
    required this.id,
    required this.assignmentId,
    required this.criteriaName,
    this.description,
    required this.maxScore,
    required this.weight,
    required this.displayOrder,
  });

  factory GradingCriteria.fromJson(Map<String, dynamic> json) {
    return GradingCriteria(
      id: json['id'],
      assignmentId: json['assignmentId'],
      criteriaName: json['criteriaName'],
      description: json['description'],
      maxScore: json['maxScore'],
      weight: (json['weight'] ?? 0.0).toDouble(),
      displayOrder: json['displayOrder'],
    );
  }
}

/// 评分详情
class AssignmentGrade {
  final int id;
  final int submissionId;
  final int criteriaId;
  final String criteriaName;
  final int score;
  final int maxScore;
  final String? feedback;
  final DateTime gradedTime;
  final int gradedBy;
  final String? graderName;

  AssignmentGrade({
    required this.id,
    required this.submissionId,
    required this.criteriaId,
    required this.criteriaName,
    required this.score,
    required this.maxScore,
    this.feedback,
    required this.gradedTime,
    required this.gradedBy,
    this.graderName,
  });

  factory AssignmentGrade.fromJson(Map<String, dynamic> json) {
    return AssignmentGrade(
      id: json['id'],
      submissionId: json['submissionId'],
      criteriaId: json['criteriaId'],
      criteriaName: json['criteriaName'] ?? '',
      score: json['score'],
      maxScore: json['maxScore'],
      feedback: json['feedback'],
      gradedTime: DateTime.parse(json['gradedTime']),
      gradedBy: json['gradedBy'],
      graderName: json['graderName'],
    );
  }

  /// 得分率
  double get scoreRate => score / maxScore;

  /// 得分等级
  String get gradeLevel {
    final rate = scoreRate;
    if (rate >= 0.9) return 'A';
    if (rate >= 0.8) return 'B';
    if (rate >= 0.7) return 'C';
    if (rate >= 0.6) return 'D';
    return 'F';
  }
}

/// 作业统计信息
class AssignmentStatistics {
  final int totalAssignments;
  final int publishedAssignments;
  final int draftAssignments;
  final int pendingGrade;
  final int completedGrade;
  final double averageScore;
  final double completionRate;

  AssignmentStatistics({
    required this.totalAssignments,
    required this.publishedAssignments,
    required this.draftAssignments,
    required this.pendingGrade,
    required this.completedGrade,
    required this.averageScore,
    required this.completionRate,
  });

  factory AssignmentStatistics.fromJson(Map<String, dynamic> json) {
    return AssignmentStatistics(
      totalAssignments: json['totalAssignments'] ?? 0,
      publishedAssignments: json['publishedAssignments'] ?? 0,
      draftAssignments: json['draftAssignments'] ?? 0,
      pendingGrade: json['pendingGrade'] ?? 0,
      completedGrade: json['completedGrade'] ?? 0,
      averageScore: (json['averageScore'] ?? 0.0).toDouble(),
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
    );
  }
}

/// 学生作业信息（学生端使用）
class StudentAssignment {
  final Assignment assignment;
  final AssignmentSubmission? submission;
  final List<AssignmentGrade> grades;
  final bool canSubmit;
  final int remainingAttempts;

  StudentAssignment({
    required this.assignment,
    this.submission,
    required this.grades,
    required this.canSubmit,
    required this.remainingAttempts,
  });

  factory StudentAssignment.fromJson(Map<String, dynamic> json) {
    // 根据后端返回的实际数据结构进行解析
    return StudentAssignment(
      assignment: Assignment.fromJson({
        'id': json['id'],
        'courseId': json['courseId'] ?? 1,
        'courseName': json['courseName'] ?? '未知课程',
        'teacherId': json['teacherId'] ?? 0,
        'teacherName': json['teacherName'] ?? '未知教师',
        'title': json['title'] ?? '',
        'description': json['description'] ?? '',
        'assignmentType': json['assignmentType'] ?? 'assignment',
        'totalScore': json['totalScore'] ?? 100,
        'chapterId': json['chapterId'],
        'chapterName': json['chapterName'],
        'publishTime': json['publishTime'] ?? DateTime.now().toIso8601String(),
        'dueTime': json['dueTime'] ?? DateTime.now().toIso8601String(),
        'allowLateSubmission': json['allowLateSubmission'] ?? false,
        'latePenaltyRate': json['latePenaltyRate'] ?? 0.0,
        'maxAttempts': json['maxAttempts'] ?? 1,
        'autoGrade': json['autoGrade'] ?? false,
        'showScoreImmediately': json['showScoreImmediately'] ?? false,
        'attachmentRequired': json['attachmentRequired'] ?? false,
        'status': json['status'] ?? 'pending',
        'submissionCount': json['submissionCount'] ?? 0,
        'gradedCount': json['gradedCount'] ?? 0,
        'averageScore': json['averageScore'],
        'deletedAt': json['deletedAt'],
      }),
      submission: json['hasSubmission'] == true ? AssignmentSubmission.fromJson({
        'id': json['submissionId'] ?? 0,
        'assignmentId': json['id'],
        'assignmentTitle': json['title'] ?? '',
        'studentId': json['studentId'] ?? 0,
        'studentName': json['studentName'] ?? '',
        'studentStudentId': json['studentStudentId'] ?? '',
        'content': json['content'],
        'submitTime': json['submissionTime'] ?? DateTime.now().toIso8601String(),
        'ipAddress': json['ipAddress'] ?? '127.0.0.1',
        'status': json['status'] ?? 'submitted',
        'totalScore': json['score'],
        'feedback': json['feedback'],
        'gradedTime': json['gradedTime'],
        'gradedBy': json['gradedBy'],
        'graderName': json['graderName'],
        'isLate': json['isOverdue'] ?? false,
        'attemptNumber': json['attemptNumber'] ?? 1,
        'attachments': [],
      }) : null,
      grades: [], // 暂时为空，后续可以从详情API获取
      canSubmit: json['status'] == 'pending' && json['hasSubmission'] != true,
      remainingAttempts: (json['maxAttempts'] ?? 1) - (json['attemptNumber'] ?? 0),
    );
  }

  /// 提交状态
  SubmissionStatus get submissionStatus {
    if (submission == null) {
      return assignment.isOverdue ? SubmissionStatus.overdue : SubmissionStatus.notSubmitted;
    }
    return submission!.status;
  }

  /// 是否已提交
  bool get isSubmitted => submission != null;

  /// 是否已批改
  bool get isGraded => submission?.isGraded ?? false;

  /// 总分
  int? get totalScore => submission?.totalScore;

  /// 是否逾期
  bool get isOverdue => assignment.isOverdue;
}
