import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../services/api_service.dart';

/// 答卷详情页面
class TeacherQuizSubmissionDetailPage extends StatefulWidget {
  final int submissionId;
  final String studentName;

  const TeacherQuizSubmissionDetailPage({
    super.key,
    required this.submissionId,
    required this.studentName,
  });

  @override
  State<TeacherQuizSubmissionDetailPage> createState() =>
      _TeacherQuizSubmissionDetailPageState();
}

class _TeacherQuizSubmissionDetailPageState
    extends State<TeacherQuizSubmissionDetailPage> {
  final QuizService _quizService = QuizService();

  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic> _submission = {};
  List<Map<String, dynamic>> _answers = [];

  @override
  void initState() {
    super.initState();
    _loadSubmissionDetail();
  }

  /// 加载答卷详情
  Future<void> _loadSubmissionDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await ApiService.getAuthToken();
      if (token == null) {
        throw Exception('未登录');
      }

      final response = await _quizService.getSubmissionDetail(
        token: token,
        submissionId: widget.submissionId,
      );

      if (response['error'] == 0) {
        final body = response['body'];
        setState(() {
          _submission = body['submission'] ?? {};
          _answers = List<Map<String, dynamic>>.from(body['answers'] ?? []);
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? '加载失败');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('${widget.studentName} 的答卷'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildContent(),
    );
  }

  /// 构建错误视图
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(_errorMessage ?? '加载失败'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSubmissionDetail,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 构建内容
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 答卷概览
          _buildSubmissionOverview(),

          const SizedBox(height: 16),

          // 答题详情
          _buildAnswersSection(),
        ],
      ),
    );
  }

  /// 构建答卷概览
  Widget _buildSubmissionOverview() {
    final quiz = _submission['quiz'] ?? {};
    final student = _submission['student'] ?? {};
    final totalScore = _submission['totalScore'] ?? 0;
    final maxScore = quiz['totalScore'] ?? 100;
    final correctCount = _submission['correctCount'] ?? 0;
    final wrongCount = _submission['wrongCount'] ?? 0;
    final unansweredCount = _submission['unansweredCount'] ?? 0;
    final durationSeconds = _submission['durationSeconds'] ?? 0;
    final isOvertime = _submission['isOvertime'] ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 学生信息
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF4285F4),
                child: Text(
                  student['name']?.substring(0, 1) ?? '学',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '学号: ${student['studentId'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 32),

          // 测验信息
          Text(
            quiz['title'] ?? '',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          // 成绩统计
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '得分',
                  '$totalScore / $maxScore',
                  const Color(0xFF4CAF50),
                  Icons.star,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '正确',
                  '$correctCount 题',
                  const Color(0xFF4CAF50),
                  Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '错误',
                  '$wrongCount 题',
                  const Color(0xFFF44336),
                  Icons.cancel,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '未答',
                  '$unansweredCount 题',
                  const Color(0xFF9E9E9E),
                  Icons.help_outline,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 用时信息
          Row(
            children: [
              const Icon(Icons.timer, size: 16, color: Color(0xFF666666)),
              const SizedBox(width: 4),
              Text(
                '用时: ${_formatDuration(durationSeconds)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              if (isOvertime) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '超时',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  /// 构建答题详情部分
  Widget _buildAnswersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '答题详情',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._answers.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildAnswerCard(entry.value, entry.key + 1),
          );
        }).toList(),
      ],
    );
  }

  /// 构建答案卡片
  Widget _buildAnswerCard(Map<String, dynamic> answer, int index) {
    final questionType = answer['questionType'] ?? '';
    final questionContent = answer['questionContent'] ?? '';
    final options = List<Map<String, dynamic>>.from(answer['options'] ?? []);
    final studentAnswer = List<String>.from(answer['studentAnswer'] ?? []);
    final correctAnswer = List<String>.from(answer['correctAnswer'] ?? []);
    final isCorrect = answer['isCorrect'] ?? false;
    final scoreEarned = answer['scoreEarned'] ?? 0;
    final maxScore = answer['maxScore'] ?? 0;
    final explanation = answer['questionExplanation'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? const Color(0xFF4CAF50)
              : (studentAnswer.isEmpty
                  ? const Color(0xFF9E9E9E)
                  : const Color(0xFFF44336)),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 题目标题
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getQuestionTypeColor(questionType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getQuestionTypeName(questionType),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getQuestionTypeColor(questionType),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '第 $index 题',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$scoreEarned / $maxScore 分',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 题目内容
          Text(
            questionContent,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          // 选项
          if (options.isNotEmpty) ...[
            ...options.map((option) {
              final optionLabel = option['optionLabel'] ?? '';
              final optionContent = option['optionContent'] ?? '';
              final isOptionCorrect = option['isCorrect'] ?? false;
              final isSelected = studentAnswer.contains(optionLabel);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isCorrect
                          ? const Color(0xFF4CAF50).withOpacity(0.1)
                          : const Color(0xFFF44336).withOpacity(0.1))
                      : (isOptionCorrect
                          ? const Color(0xFF4CAF50).withOpacity(0.05)
                          : Colors.grey.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? (isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFF44336))
                        : (isOptionCorrect ? const Color(0xFF4CAF50) : Colors.transparent),
                    width: isSelected || isOptionCorrect ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? (isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFF44336))
                            : (isOptionCorrect
                                ? const Color(0xFF4CAF50)
                                : Colors.grey.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(
                          optionLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        optionContent,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                        size: 20,
                      ),
                    if (!isSelected && isOptionCorrect)
                      const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF4CAF50),
                        size: 20,
                      ),
                  ],
                ),
              );
            }).toList(),
          ],

          // 答案信息
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '学生答案: ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      studentAnswer.isEmpty ? '未作答' : studentAnswer.join(', '),
                      style: TextStyle(
                        fontSize: 13,
                        color: studentAnswer.isEmpty
                            ? const Color(0xFF999999)
                            : const Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      '正确答案: ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      correctAnswer.join(', '),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 解析
          if (explanation != null && explanation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: Color(0xFFFF9800),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '题目解析',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF9800),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          explanation,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 获取题型名称
  String _getQuestionTypeName(String type) {
    switch (type) {
      case 'single_choice':
        return '单选题';
      case 'multiple_choice':
        return '多选题';
      case 'true_false':
        return '判断题';
      case 'fill_blank':
        return '填空题';
      default:
        return '未知';
    }
  }

  /// 获取题型颜色
  Color _getQuestionTypeColor(String type) {
    switch (type) {
      case 'single_choice':
        return const Color(0xFF4285F4);
      case 'multiple_choice':
        return const Color(0xFF4CAF50);
      case 'true_false':
        return const Color(0xFFFF9800);
      case 'fill_blank':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  /// 格式化时长
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes 分 $remainingSeconds 秒';
  }
}
