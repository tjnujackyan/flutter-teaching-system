import 'api_service.dart';
import '../models/quiz_models.dart';

/// 测验管理服务
class QuizService {
  // ==================== 教师端接口 ====================
  
  /// 获取教师测验列表
  Future<QuizPageResponse> getTeacherQuizzes({
    int? courseId,
    String? keyword,
    String? status,
    String? quizType,
    int page = 1,
    int pageSize = 10,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    final queryParams = <String, String>{
      if (courseId != null) 'courseId': courseId.toString(),
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (status != null && status.isNotEmpty) 'status': status,
      if (quizType != null && quizType.isNotEmpty) 'quizType': quizType,
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };

    // 构建查询字符串
    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    final url = '/api/teacher/quizzes/list?$queryString';

    final response = await ApiService.request<Map<String, dynamic>>(
      url,
      method: 'GET',
      fromJson: (json) => json,
    );

    if (response.error == 0 && response.body != null) {
      return QuizPageResponse.fromJson(response.body!);
    } else {
      throw Exception(response.message);
    }
  }

  /// 获取测验创建配置
  Future<ApiResponse<Map<String, dynamic>>> getQuizConfig() async {
    return await ApiService.request<Map<String, dynamic>>(
      '/api/teacher/quizzes/create-config',
      method: 'GET',
      fromJson: (json) => json,
    );
  }

  /// 创建测验
  Future<ApiResponse<Map<String, dynamic>>> createQuiz({
    required int courseId,
    required String title,
    String? description,
    required String quizType,
    required int totalScore,
    required int durationMinutes,
    required String startTime,
    required String endTime,
    bool allowReview = true,
    bool shuffleQuestions = false,
    bool shuffleOptions = false,
    int maxAttempts = 1,
    bool showScoreImmediately = true,
    required List<Map<String, dynamic>> questions,
  }) async {
    final data = {
      'courseId': courseId,
      'title': title,
      'description': description,
      'quizType': quizType,
      'totalScore': totalScore,
      'durationMinutes': durationMinutes,
      'startTime': startTime,
      'endTime': endTime,
      'allowReview': allowReview,
      'shuffleQuestions': shuffleQuestions,
      'shuffleOptions': shuffleOptions,
      'maxAttempts': maxAttempts,
      'showScoreImmediately': showScoreImmediately,
      'questions': questions,
    };

    return await ApiService.request<Map<String, dynamic>>(
      '/api/teacher/quizzes/create',
      data: data,
      fromJson: (json) => json,
    );
  }

  /// 获取测验详情
  Future<QuizDetail> getQuizDetail(int quizId) async {
    final response = await ApiService.request<Map<String, dynamic>>(
      '/api/teacher/quizzes/$quizId/detail',
      method: 'GET',
      fromJson: (json) => json,
    );
    
    if (response.error == 0 && response.body != null) {
      return QuizDetail.fromJson(response.body!);
    } else {
      throw Exception(response.message);
    }
  }

  /// 更新测验信息
  Future<ApiResponse<void>> updateQuiz({
    required int quizId,
    String? title,
    String? description,
    String? quizType,
    int? totalScore,
    int? durationMinutes,
    String? startTime,
    String? endTime,
    bool? allowReview,
    bool? shuffleQuestions,
    bool? shuffleOptions,
    int? maxAttempts,
    bool? showScoreImmediately,
  }) async {
    final data = <String, dynamic>{};
    
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (quizType != null) data['quizType'] = quizType;
    if (totalScore != null) data['totalScore'] = totalScore;
    if (durationMinutes != null) data['durationMinutes'] = durationMinutes;
    if (startTime != null) data['startTime'] = startTime;
    if (endTime != null) data['endTime'] = endTime;
    if (allowReview != null) data['allowReview'] = allowReview;
    if (shuffleQuestions != null) data['shuffleQuestions'] = shuffleQuestions;
    if (shuffleOptions != null) data['shuffleOptions'] = shuffleOptions;
    if (maxAttempts != null) data['maxAttempts'] = maxAttempts;
    if (showScoreImmediately != null) data['showScoreImmediately'] = showScoreImmediately;

    return await ApiService.request<void>(
      '/api/teacher/quizzes/$quizId/update',
      method: 'PUT',
      data: data,
      fromJson: (json) => null,
    );
  }

  /// 删除测验
  Future<void> deleteQuiz(int quizId) async {
    final response = await ApiService.request<void>(
      '/api/teacher/quizzes/$quizId/delete',
      method: 'DELETE',
      fromJson: (json) => null,
    );
    
    if (response.error != 0) {
      throw Exception(response.message ?? '删除测验失败');
    }
  }

  /// 获取测验提交列表
  Future<SubmissionPageResponse> getQuizSubmissions({
    required int quizId,
    String keyword = '',
    String status = '',
    int page = 1,
    int pageSize = 10,
    String sortBy = 'submitTime',
    String sortOrder = 'desc',
  }) async {
    final queryParams = <String, String>{
      if (keyword.isNotEmpty) 'keyword': keyword,
      if (status.isNotEmpty) 'status': status,
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };

    // 构建查询字符串
    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    final url = '/api/teacher/quizzes/$quizId/submissions?$queryString';

    final response = await ApiService.request<Map<String, dynamic>>(
      url,
      method: 'GET',
      fromJson: (json) => json,
    );
    
    if (response.error == 0 && response.body != null) {
      return SubmissionPageResponse.fromJson(response.body!);
    } else {
      throw Exception(response.message);
    }
  }

  /// 获取教师测验统计
  Future<QuizOverview> getTeacherQuizOverview() async {
    final response = await ApiService.request<Map<String, dynamic>>(
      '/api/teacher/quizzes/overview',
      method: 'GET',
      fromJson: (json) => json,
    );
    
    if (response.error == 0 && response.body != null) {
      return QuizOverview.fromJson(response.body!);
    } else {
      throw Exception(response.message);
    }
  }

  // ==================== 学生端接口 ====================

  /// 获取学生测验列表
  Future<StudentQuizPageResponse> getStudentQuizzes({
    int? courseId,
    String? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = <String, String>{
      if (courseId != null) 'courseId': courseId.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    // 构建查询字符串
    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    final url = '/api/student/quizzes/list?$queryString';

    print('📤 请求学生测验列表: $url');
    
    final response = await ApiService.request<Map<String, dynamic>>(
      url,
      method: 'GET',
      fromJson: (json) => json,
    );

    print('📥 收到响应: error=${response.error}, message=${response.message}');
    
    if (response.error == 0 && response.body != null) {
      print('📋 解析响应体: ${response.body}');
      final result = StudentQuizPageResponse.fromJson(response.body!);
      print('✅ 解析成功: ${result.items.length} 个测验');
      return result;
    } else {
      print('❌ 响应错误: ${response.message}');
      throw Exception(response.message ?? '获取测验列表失败');
    }
  }

  /// 开始答题
  Future<StartQuizResponse> startQuiz(StartQuizRequest request) async {
    final data = {'quizId': request.quizId};

    final response = await ApiService.request<Map<String, dynamic>>(
      '/api/student/quizzes/start',
      method: 'POST',
      data: data,
      fromJson: (json) => json,
    );

    if (response.error == 0 && response.body != null) {
      return StartQuizResponse.fromJson(response.body!);
    } else {
      throw Exception(response.message ?? '开始测验失败');
    }
  }

  /// 提交单个题目答案
  Future<void> submitAnswer(SubmitAnswerRequest request) async {
    final data = {
      'submissionId': request.submissionId,
      'questionId': request.questionId,
      'studentAnswer': request.studentAnswer,  // 修复：使用正确的字段名
      'timeSpentSeconds': request.timeSpentSeconds,
    };

    final response = await ApiService.request<void>(
      '/api/student/quizzes/submit-answer',
      method: 'POST',
      data: data,
      fromJson: (json) => null,
    );

    if (response.error != 0) {
      throw Exception(response.message ?? '提交答案失败');
    }
  }

  /// 提交测验
  Future<SubmitQuizResponse> submitQuiz(SubmitQuizRequest request) async {
    final data = {
      'submissionId': request.submissionId,
      'answers': request.answers.map((a) => {
        'questionId': a.questionId,
        'studentAnswer': a.studentAnswer,  // 修复：使用正确的字段名
        'timeSpentSeconds': a.timeSpentSeconds,
      }).toList(),
    };

    final response = await ApiService.request<Map<String, dynamic>>(
      '/api/student/quizzes/submit',
      method: 'POST',
      data: data,
      fromJson: (json) => json,
    );

    if (response.error == 0 && response.body != null) {
      return SubmitQuizResponse.fromJson(response.body!);
    } else {
      throw Exception(response.message ?? '提交测验失败');
    }
  }

  // ==================== 辅助方法 ====================

  /// 格式化时间为API所需格式
  static String formatDateTime(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  /// 解析API返回的时间
  static DateTime? parseDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return null;
    try {
      return DateTime.parse(dateTimeStr);
    } catch (e) {
      print('解析时间失败: $dateTimeStr, error: $e');
      return null;
    }
  }

  /// 获取测验状态文本
  static String getQuizStatusText(String status) {
    switch (status) {
      case 'draft':
        return '草稿';
      case 'published':
        return '已发布';
      case 'ongoing':
        return '进行中';
      case 'ended':
        return '已结束';
      case 'closed':
        return '已关闭';
      default:
        return '未知';
    }
  }

  /// 获取测验类型文本
  static String getQuizTypeText(String quizType) {
    switch (quizType) {
      case 'practice':
        return '练习测验';
      case 'chapter':
        return '章节测试';
      case 'midterm':
        return '期中测验';
      case 'final':
        return '期末考试';
      default:
        return '测验';
    }
  }

  /// 获取题目类型文本
  static String getQuestionTypeText(String questionType) {
    switch (questionType) {
      case 'single_choice':
        return '单选题';
      case 'multiple_choice':
        return '多选题';
      case 'true_false':
        return '判断题';
      case 'fill_blank':
        return '填空题';
      case 'short_answer':
        return '简答题';
      default:
        return '未知题型';
    }
  }

  /// 获取难度等级文本
  static String getDifficultyText(int level) {
    switch (level) {
      case 1:
        return '简单';
      case 2:
        return '中等';
      case 3:
        return '困难';
      default:
        return '未知';
    }
  }

  /// 计算剩余时间（分钟）
  static int calculateRemainingMinutes(String endTime) {
    try {
      final end = DateTime.parse(endTime);
      final now = DateTime.now();
      final diff = end.difference(now);
      return diff.inMinutes;
    } catch (e) {
      return 0;
    }
  }

  /// 判断测验是否可以开始
  static bool canStartQuiz(String startTime, String endTime) {
    try {
      final start = DateTime.parse(startTime);
      final end = DateTime.parse(endTime);
      final now = DateTime.now();
      return now.isAfter(start) && now.isBefore(end);
    } catch (e) {
      return false;
    }
  }

  /// 判断测验是否已结束
  static bool isQuizEnded(String endTime) {
    try {
      final end = DateTime.parse(endTime);
      final now = DateTime.now();
      return now.isAfter(end);
    } catch (e) {
      return false;
    }
  }

  /// 获取答卷详情
  Future<Map<String, dynamic>> getSubmissionDetail({
    required String token,
    required int submissionId,
  }) async {
    final url = '/api/teacher/quizzes/submissions/$submissionId/detail';

    final response = await ApiService.request<Map<String, dynamic>>(
      url,
      method: 'GET',
      fromJson: (json) => json,
    );

    return {
      'error': response.error,
      'message': response.message,
      'body': response.body,
    };
  }
}

