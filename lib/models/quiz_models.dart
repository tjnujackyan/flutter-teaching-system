/// 测验模型类
library;

/// 测验信息
class QuizInfo {
  final int id;
  final String title;
  final String? description;
  final String quizType;
  final String quizTypeName;
  final String status;
  final String statusName;
  final int totalScore;
  final int durationMinutes;
  final int questionCount;
  final String startTime;
  final String endTime;
  final String courseName;
  final String courseCode;
  final int totalParticipants;
  final int submittedCount;
  final double averageScore;
  final double completionRate;
  final String createdAt;

  QuizInfo({
    required this.id,
    required this.title,
    this.description,
    required this.quizType,
    required this.quizTypeName,
    required this.status,
    required this.statusName,
    required this.totalScore,
    required this.durationMinutes,
    required this.questionCount,
    required this.startTime,
    required this.endTime,
    required this.courseName,
    required this.courseCode,
    required this.totalParticipants,
    required this.submittedCount,
    required this.averageScore,
    required this.completionRate,
    required this.createdAt,
  });

  factory QuizInfo.fromJson(Map<String, dynamic> json) {
    return QuizInfo(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      quizType: json['quizType'] ?? '',
      quizTypeName: json['quizTypeName'] ?? '',
      status: json['status'] ?? '',
      statusName: json['statusName'] ?? '',
      totalScore: json['totalScore'] ?? 0,
      durationMinutes: json['durationMinutes'] ?? 0,
      questionCount: json['questionCount'] ?? 0,
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      courseName: json['courseName'] ?? '',
      courseCode: json['courseCode'] ?? '',
      totalParticipants: json['totalParticipants'] ?? 0,
      submittedCount: json['submittedCount'] ?? 0,
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      completionRate: (json['completionRate'] ?? 0).toDouble(),
      createdAt: json['createdAt'] ?? '',
    );
  }
}

/// 测验详情
class QuizDetail {
  final int id;
  final String title;
  final String? description;
  final String quizType;
  final String quizTypeName;
  final String status;
  final String statusName;
  final int totalScore;
  final int durationMinutes;
  final int questionCount;
  final String startTime;
  final String endTime;
  final bool allowReview;
  final bool shuffleQuestions;
  final bool shuffleOptions;
  final int maxAttempts;
  final bool showScoreImmediately;
  final CourseInfo course;
  final TeacherInfo teacher;
  final QuizStatistics statistics;
  final List<QuestionInfo> questions;
  final String createdAt;
  final String updatedAt;

  QuizDetail({
    required this.id,
    required this.title,
    this.description,
    required this.quizType,
    required this.quizTypeName,
    required this.status,
    required this.statusName,
    required this.totalScore,
    required this.durationMinutes,
    required this.questionCount,
    required this.startTime,
    required this.endTime,
    required this.allowReview,
    required this.shuffleQuestions,
    required this.shuffleOptions,
    required this.maxAttempts,
    required this.showScoreImmediately,
    required this.course,
    required this.teacher,
    required this.statistics,
    required this.questions,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // 兼容getter
  String get courseName => course.name;
  int get totalParticipants => statistics.totalParticipants;
  double get averageScore => statistics.averageScore;
  double get passRate => statistics.passRate;

  factory QuizDetail.fromJson(Map<String, dynamic> json) {
    return QuizDetail(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      quizType: json['quizType'] ?? '',
      quizTypeName: json['quizTypeName'] ?? '',
      status: json['status'] ?? '',
      statusName: json['statusName'] ?? '',
      totalScore: (json['totalScore'] is int) 
          ? json['totalScore'] 
          : (json['totalScore'] as num?)?.toInt() ?? 0,
      durationMinutes: json['durationMinutes'] ?? 0,
      questionCount: json['questionCount'] ?? 0,
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      allowReview: json['allowReview'] ?? false,
      shuffleQuestions: json['shuffleQuestions'] ?? false,
      shuffleOptions: json['shuffleOptions'] ?? false,
      maxAttempts: json['maxAttempts'] ?? 1,
      showScoreImmediately: json['showScoreImmediately'] ?? true,
      course: CourseInfo.fromJson(json['course'] ?? {}),
      teacher: TeacherInfo.fromJson(json['teacher'] ?? {}),
      statistics: QuizStatistics.fromJson(json['statistics'] ?? {}),
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => QuestionInfo.fromJson(q))
              .toList() ??
          [],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}

/// 课程信息
class CourseInfo {
  final int id;
  final String name;
  final String code;
  final String icon;
  final String color;

  CourseInfo({
    required this.id,
    required this.name,
    required this.code,
    required this.icon,
    required this.color,
  });

  factory CourseInfo.fromJson(Map<String, dynamic> json) {
    return CourseInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      icon: json['icon'] ?? '📚',
      color: json['color'] ?? '#4285F4',
    );
  }
}

/// 教师信息
class TeacherInfo {
  final int id;
  final String name;
  final String title;
  final String avatar;

  TeacherInfo({
    required this.id,
    required this.name,
    required this.title,
    required this.avatar,
  });

  factory TeacherInfo.fromJson(Map<String, dynamic> json) {
    return TeacherInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }
}

/// 测验统计
class QuizStatistics {
  final int totalParticipants;
  final int submittedCount;
  final double completionRate;
  final double averageScore;
  final double highestScore;
  final double lowestScore;
  final int averageDurationMinutes;
  final Map<String, dynamic>? scoreDistribution;
  final String lastUpdated;

  QuizStatistics({
    required this.totalParticipants,
    required this.submittedCount,
    required this.completionRate,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.averageDurationMinutes,
    this.scoreDistribution,
    required this.lastUpdated,
  });
  
  // 兼容getter：计算及格率（使用完成率作为临时替代）
  double get passRate => completionRate;
  
  // 便捷访问器：分数段统计
  int get range0to59 => _getDistributionValue('range0to59');
  int get range60to69 => _getDistributionValue('range60to69');
  int get range70to79 => _getDistributionValue('range70to79');
  int get range80to89 => _getDistributionValue('range80to89');
  int get range90to100 => _getDistributionValue('range90to100');
  
  int _getDistributionValue(String key) {
    if (scoreDistribution == null) return 0;
    final value = scoreDistribution![key];
    if (value is int) return value;
    if (value is double) return value.toInt();
    return 0;
  }

  factory QuizStatistics.fromJson(Map<String, dynamic> json) {
    return QuizStatistics(
      totalParticipants: json['totalParticipants'] ?? 0,
      submittedCount: json['submittedCount'] ?? 0,
      completionRate: (json['completionRate'] ?? 0).toDouble(),
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      highestScore: (json['highestScore'] ?? 0).toDouble(),
      lowestScore: (json['lowestScore'] ?? 0).toDouble(),
      averageDurationMinutes: json['averageDurationMinutes'] ?? 0,
      scoreDistribution: json['scoreDistribution'] as Map<String, dynamic>?,
      lastUpdated: json['lastUpdated'] ?? '',
    );
  }
}

/// 题目信息
class QuestionInfo {
  final int id;
  final String questionType;
  final String questionTypeName;
  final String questionContent;
  final String? questionExplanation;
  final double score;
  final int difficultyLevel;
  final String difficultyName;
  final int questionOrder;
  final List<OptionInfo> options;

  QuestionInfo({
    required this.id,
    required this.questionType,
    required this.questionTypeName,
    required this.questionContent,
    this.questionExplanation,
    required this.score,
    required this.difficultyLevel,
    required this.difficultyName,
    required this.questionOrder,
    required this.options,
  });
  
  // 兼容性getter
  String get type => questionType;
  String get content => questionContent;
  String? get description => questionExplanation;

  factory QuestionInfo.fromJson(Map<String, dynamic> json) {
    return QuestionInfo(
      id: json['id'] ?? 0,
      questionType: json['questionType'] ?? '',
      questionTypeName: json['questionTypeName'] ?? '',
      questionContent: json['questionContent'] ?? '',
      questionExplanation: json['questionExplanation'],
      score: (json['score'] ?? 0).toDouble(),
      difficultyLevel: json['difficultyLevel'] ?? 1,
      difficultyName: json['difficultyName'] ?? '',
      questionOrder: json['questionOrder'] ?? 0,
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => OptionInfo.fromJson(o))
              .toList() ??
          [],
    );
  }
}

/// 选项信息
class OptionInfo {
  final int id;
  final String optionLabel;
  final String optionContent;
  final bool? isCorrect; // 学生端可能为null
  final int optionOrder;

  OptionInfo({
    required this.id,
    required this.optionLabel,
    required this.optionContent,
    this.isCorrect,
    required this.optionOrder,
  });
  
  // 兼容性getter
  String get content => optionContent;

  factory OptionInfo.fromJson(Map<String, dynamic> json) {
    return OptionInfo(
      id: json['id'] ?? 0,
      optionLabel: json['optionLabel'] ?? '',
      optionContent: json['optionContent'] ?? '',
      isCorrect: json['isCorrect'],
      optionOrder: json['optionOrder'] ?? 0,
    );
  }
}

/// 教师测验列表项
class QuizListItem {
  final int id;
  final String title;
  final String description;
  final String quizType;
  final String quizTypeName;
  final String status;
  final String statusName;
  final int totalScore;
  final int durationMinutes;
  final int questionCount;
  final String startTime;
  final String endTime;
  final String courseName;
  final String courseCode;

  QuizListItem({
    required this.id,
    required this.title,
    required this.description,
    required this.quizType,
    required this.quizTypeName,
    required this.status,
    required this.statusName,
    required this.totalScore,
    required this.durationMinutes,
    required this.questionCount,
    required this.startTime,
    required this.endTime,
    required this.courseName,
    required this.courseCode,
  });

  factory QuizListItem.fromJson(Map<String, dynamic> json) {
    return QuizListItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      quizType: json['quizType'] ?? '',
      quizTypeName: json['quizTypeName'] ?? '',
      status: json['status'] ?? '',
      statusName: json['statusName'] ?? '',
      totalScore: (json['totalScore'] is int) 
          ? json['totalScore'] 
          : (json['totalScore'] as double?)?.toInt() ?? 0,
      durationMinutes: json['durationMinutes'] ?? 0,
      questionCount: json['questionCount'] ?? 0,
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      courseName: json['courseName'] ?? '未指定课程',
      courseCode: json['courseCode'] ?? '',
    );
  }
}

/// 学生测验列表项
class StudentQuizListItem {
  final int id;
  final String title;
  final String description;
  final String quizType;
  final String quizTypeName;
  final String status;
  final String statusName;
  final int totalScore;
  final int durationMinutes;
  final int questionCount;
  final String startTime;
  final String endTime;
  final String courseName;
  final String courseCode;
  final String courseIcon;
  final String courseColor;
  final String teacherName;
  final int maxAttempts;
  final bool showScoreImmediately;
  final MySubmissionInfo? mySubmission;
  final String timeRemaining;
  final bool canStart;
  final bool canContinue;
  final bool canViewResult;

  StudentQuizListItem({
    required this.id,
    required this.title,
    required this.description,
    required this.quizType,
    required this.quizTypeName,
    required this.status,
    required this.statusName,
    required this.totalScore,
    required this.durationMinutes,
    required this.questionCount,
    required this.startTime,
    required this.endTime,
    required this.courseName,
    required this.courseCode,
    required this.courseIcon,
    required this.courseColor,
    required this.teacherName,
    required this.maxAttempts,
    required this.showScoreImmediately,
    this.mySubmission,
    required this.timeRemaining,
    required this.canStart,
    required this.canContinue,
    required this.canViewResult,
  });

  factory StudentQuizListItem.fromJson(Map<String, dynamic> json) {
    // 安全地将 double 转换为 int
    int parseTotalScore(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    return StudentQuizListItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      quizType: json['quizType'] ?? '',
      quizTypeName: json['quizTypeName'] ?? json['quizType'] ?? '',
      status: json['status'] ?? '',
      statusName: json['statusName'] ?? json['status'] ?? '',
      totalScore: parseTotalScore(json['totalScore']),
      durationMinutes: json['durationMinutes'] ?? 0,
      questionCount: json['questionCount'] ?? 0,
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      courseName: json['courseName'] ?? '',
      courseCode: json['courseCode'] ?? '',
      courseIcon: json['courseIcon'] ?? '📚',
      courseColor: json['courseColor'] ?? '#4285F4',
      teacherName: json['teacherName'] ?? '',
      maxAttempts: json['maxAttempts'] ?? 1,
      showScoreImmediately: json['showScoreImmediately'] ?? true,
      mySubmission: json['mySubmission'] != null
          ? MySubmissionInfo.fromJson(json['mySubmission'])
          : null,
      timeRemaining: json['timeRemaining'] ?? '',
      canStart: json['canStart'] ?? false,
      canContinue: json['canContinue'] ?? false,
      canViewResult: json['canViewResult'] ?? false,
    );
  }
}

/// 我的提交信息
class MySubmissionInfo {
  final int id;
  final int attemptNumber;
  final String status;
  final String statusName;
  final String startTime;
  final String submitTime;
  final double totalScore;
  final int correctCount;
  final int wrongCount;
  final int unansweredCount;
  final bool isOvertime;
  final int ranking;
  final String grade;

  MySubmissionInfo({
    required this.id,
    required this.attemptNumber,
    required this.status,
    required this.statusName,
    required this.startTime,
    required this.submitTime,
    required this.totalScore,
    required this.correctCount,
    required this.wrongCount,
    required this.unansweredCount,
    required this.isOvertime,
    required this.ranking,
    required this.grade,
  });

  // 兼容性getter
  double get score => totalScore;
  int? get rank => ranking > 0 ? ranking : null;
  double get accuracy {
    final total = correctCount + wrongCount;
    return total > 0 ? correctCount / total : 0.0;
  }

  factory MySubmissionInfo.fromJson(Map<String, dynamic> json) {
    // 安全地将数值转换为 double
    double parseTotalScore(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    
    return MySubmissionInfo(
      id: json['id'] ?? 0,
      attemptNumber: json['attemptNumber'] ?? 1,
      status: json['status'] ?? '',
      statusName: json['statusName'] ?? json['status'] ?? '',
      startTime: json['startTime'] ?? '',
      submitTime: json['submitTime'] ?? '',
      totalScore: parseTotalScore(json['totalScore']),
      correctCount: json['correctCount'] ?? 0,
      wrongCount: json['wrongCount'] ?? 0,
      unansweredCount: json['unansweredCount'] ?? 0,
      isOvertime: json['isOvertime'] ?? false,
      ranking: json['ranking'] ?? 0,
      grade: json['grade'] ?? '',
    );
  }
}

/// 开始答题响应
class StartQuizResponse {
  final int submissionId;
  final int attemptNumber;
  final String startTime;
  final int durationMinutes;
  final String endTime;
  final List<QuestionInfo> questions;

  StartQuizResponse({
    required this.submissionId,
    required this.attemptNumber,
    required this.startTime,
    required this.durationMinutes,
    required this.endTime,
    required this.questions,
  });

  factory StartQuizResponse.fromJson(Map<String, dynamic> json) {
    return StartQuizResponse(
      submissionId: json['submissionId'] ?? 0,
      attemptNumber: json['attemptNumber'] ?? 1,
      startTime: json['startTime'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 0,
      endTime: json['endTime'] ?? '',
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => QuestionInfo.fromJson(q))
              .toList() ??
          [],
    );
  }
}

/// 提交测验响应
class SubmitQuizResponse {
  final int submissionId;
  final String submitTime;
  final int durationSeconds;
  final double totalScore;
  final int correctCount;
  final int wrongCount;
  final int unansweredCount;
  final String status;
  final bool isOvertime;
  final List<QuestionResult> questionResults;

  SubmitQuizResponse({
    required this.submissionId,
    required this.submitTime,
    required this.durationSeconds,
    required this.totalScore,
    required this.correctCount,
    required this.wrongCount,
    required this.unansweredCount,
    required this.status,
    required this.isOvertime,
    required this.questionResults,
  });
  
  // 兼容性getter
  double get score => totalScore;

  factory SubmitQuizResponse.fromJson(Map<String, dynamic> json) {
    return SubmitQuizResponse(
      submissionId: json['submissionId'] ?? 0,
      submitTime: json['submitTime'] ?? '',
      durationSeconds: json['durationSeconds'] ?? 0,
      totalScore: (json['totalScore'] ?? 0).toDouble(),
      correctCount: json['correctCount'] ?? 0,
      wrongCount: json['wrongCount'] ?? 0,
      unansweredCount: json['unansweredCount'] ?? 0,
      status: json['status'] ?? '',
      isOvertime: json['isOvertime'] ?? false,
      questionResults: (json['questionResults'] as List<dynamic>?)
              ?.map((r) => QuestionResult.fromJson(r))
              .toList() ??
          [],
    );
  }
}

/// 题目结果
class QuestionResult {
  final int questionId;
  final String questionContent;
  final List<String> studentAnswer;
  final List<String> correctAnswer;
  final bool isCorrect;
  final double scoreEarned;
  final double maxScore;
  final int timeSpentSeconds;
  final String explanation;

  QuestionResult({
    required this.questionId,
    required this.questionContent,
    required this.studentAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.scoreEarned,
    required this.maxScore,
    required this.timeSpentSeconds,
    required this.explanation,
  });

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      questionId: json['questionId'] ?? 0,
      questionContent: json['questionContent'] ?? '',
      studentAnswer: List<String>.from(json['studentAnswer'] ?? []),
      correctAnswer: List<String>.from(json['correctAnswer'] ?? []),
      isCorrect: json['isCorrect'] ?? false,
      scoreEarned: (json['scoreEarned'] ?? 0).toDouble(),
      maxScore: (json['maxScore'] ?? 0).toDouble(),
      timeSpentSeconds: json['timeSpentSeconds'] ?? 0,
      explanation: json['explanation'] ?? '',
    );
  }
}

/// 测验分页响应
class QuizPageResponse {
  final List<QuizListItem> items;
  final int total;
  final int page;
  final int pageSize;

  QuizPageResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory QuizPageResponse.fromJson(Map<String, dynamic> json) {
    // 兼容后端返回的 quizzes 字段
    final quizzesList = json['quizzes'] ?? json['items'];
    
    return QuizPageResponse(
      items: (quizzesList as List<dynamic>?)
              ?.map((item) => QuizListItem.fromJson(item))
              .toList() ??
          [],
      total: json['total'] ?? (quizzesList as List?)?.length ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
    );
  }
}

/// 学生测验分页响应
class StudentQuizPageResponse {
  final List<StudentQuizListItem> items;
  final int total;
  final int page;
  final int pageSize;

  StudentQuizPageResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory StudentQuizPageResponse.fromJson(Map<String, dynamic> json) {
    // 支持 items 或 quizzes 字段（兼容不同后端返回格式）
    final List<dynamic> itemsList = (json['items'] as List<dynamic>?) ?? 
                                     (json['quizzes'] as List<dynamic>?) ?? 
                                     [];
    
    return StudentQuizPageResponse(
      items: itemsList
              .map((item) => StudentQuizListItem.fromJson(item))
              .toList(),
      total: json['total'] ?? itemsList.length,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? itemsList.length,
    );
  }
}

/// 提交记录列表项
class SubmissionListItem {
  final int id;
  final int studentId;
  final String studentName;
  final String studentNumber;
  final String status;
  final double score;
  final int timeUsed;  // 用时（分钟）
  final String submitTime;
  
  SubmissionListItem({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentNumber,
    required this.status,
    required this.score,
    required this.timeUsed,
    required this.submitTime,
  });
  
  // 兼容getter
  int get submissionId => id;
  
  factory SubmissionListItem.fromJson(Map<String, dynamic> json) {
    // 计算用时（分钟），优先使用timeUsed，否则从durationSeconds转换
    int calculatedTimeUsed = json['timeUsed'] ?? 0;
    if (calculatedTimeUsed == 0 && json['durationSeconds'] != null) {
      calculatedTimeUsed = (json['durationSeconds'] / 60).round();
    }
    
    return SubmissionListItem(
      id: json['id'] ?? 0,
      studentId: json['studentId'] ?? 0,
      studentName: json['studentName'] ?? '学生${json['studentId'] ?? '未知'}',
      studentNumber: json['studentNumber'] ?? json['studentId']?.toString() ?? '',
      status: json['status'] ?? '',
      score: (json['totalScore'] ?? json['score'] ?? 0).toDouble(),
      timeUsed: calculatedTimeUsed,
      submitTime: json['submitTime'] ?? '',
    );
  }
}

/// 提交记录分页响应
class SubmissionPageResponse {
  final List<SubmissionListItem> items;
  final int total;
  final int page;
  final int pageSize;

  SubmissionPageResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory SubmissionPageResponse.fromJson(Map<String, dynamic> json) {
    // 兼容后端返回的 submissions 字段
    final submissionsList = json['submissions'] ?? json['items'];
    
    return SubmissionPageResponse(
      items: (submissionsList as List<dynamic>?)
              ?.map((item) => SubmissionListItem.fromJson(item))
              .toList() ??
          [],
      total: json['totalCount'] ?? json['total'] ?? (submissionsList as List?)?.length ?? 0,
      page: json['currentPage'] ?? json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
    );
  }
}

/// 开始测验请求
class StartQuizRequest {
  final int quizId;
  
  StartQuizRequest({required this.quizId});
}

/// 提交答案请求
class SubmitAnswerRequest {
  final int submissionId;
  final int questionId;
  final List<String> studentAnswer;  // 修改：使用 List<String> 和正确的字段名
  final int? timeSpentSeconds;
  
  SubmitAnswerRequest({
    required this.submissionId,
    required this.questionId,
    required this.studentAnswer,
    this.timeSpentSeconds,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'submissionId': submissionId,
      'questionId': questionId,
      'studentAnswer': studentAnswer,
      'timeSpentSeconds': timeSpentSeconds,
    };
  }
}

/// 答案项（用于批量提交测验）
class AnswerItem {
  final int questionId;
  final List<String> studentAnswer;  // 修改：使用List<String>和正确的字段名
  final int? timeSpentSeconds;
  
  AnswerItem({
    required this.questionId,
    required this.studentAnswer,
    this.timeSpentSeconds,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'studentAnswer': studentAnswer,
      'timeSpentSeconds': timeSpentSeconds,
    };
  }
}

/// 提交测验请求
class SubmitQuizRequest {
  final int submissionId;
  final List<AnswerItem> answers;
  
  SubmitQuizRequest({
    required this.submissionId,
    required this.answers,
  });
}

/// 测验统计概览
class QuizOverview {
  final int totalQuizzes;
  final int publishedQuizzes;
  final int ongoingQuizzes;
  final int endedQuizzes;
  final int totalParticipants;
  final int totalSubmissions;
  final double averageScore;
  final double passRate;
  
  QuizOverview({
    required this.totalQuizzes,
    required this.publishedQuizzes,
    required this.ongoingQuizzes,
    required this.endedQuizzes,
    required this.totalParticipants,
    required this.totalSubmissions,
    required this.averageScore,
    required this.passRate,
  });
  
  factory QuizOverview.fromJson(Map<String, dynamic> json) {
    return QuizOverview(
      totalQuizzes: json['totalQuizzes'] ?? 0,
      publishedQuizzes: json['publishedQuizzes'] ?? 0,
      ongoingQuizzes: json['ongoingQuizzes'] ?? 0,
      endedQuizzes: json['endedQuizzes'] ?? 0,
      totalParticipants: json['totalParticipants'] ?? 0,
      totalSubmissions: json['totalSubmissions'] ?? 0,
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      passRate: (json['passRate'] ?? 0).toDouble(),
    );
  }
}

