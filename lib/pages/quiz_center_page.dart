import 'package:flutter/material.dart';
import 'quiz_taking_page.dart';
import '../models/quiz_models.dart';
import '../services/quiz_service.dart';

/// 测验状态枚举
enum QuizStatus {
  upcoming('待参加', Color(0xFF4285F4)),
  ongoing('进行中', Color(0xFFFF9800)),
  completed('已完成', Color(0xFF4CAF50));

  const QuizStatus(this.label, this.color);
  final String label;
  final Color color;
  
  /// 从字符串状态转换
  static QuizStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'not_started':
      case 'upcoming':
        return QuizStatus.upcoming;
      case 'in_progress':
      case 'ongoing':
        return QuizStatus.ongoing;
      case 'ended':
      case 'completed':
        return QuizStatus.completed;
      default:
        return QuizStatus.upcoming;
    }
  }
}

/// 测验中心页面
class QuizCenterPage extends StatefulWidget {
  const QuizCenterPage({super.key});

  @override
  State<QuizCenterPage> createState() => _QuizCenterPageState();
}

class _QuizCenterPageState extends State<QuizCenterPage> {
  final QuizService _quizService = QuizService();
  
  String _selectedFilter = '全部';
  List<StudentQuizListItem> _quizzes = [];
  List<StudentQuizListItem> _filteredQuizzes = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _filterTabs = ['全部', '待参加', '进行中', '已完成'];

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  /// 加载测验列表
  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📚 开始加载学生测验列表...');
      
      final result = await _quizService.getStudentQuizzes(
        page: 1,
        pageSize: 100, // 加载足够多的数据
      );
      
      print('✅ 测验列表加载成功');
      print('   总数: ${result.total}');
      print('   当前页: ${result.page}');
      print('   每页数量: ${result.pageSize}');
      print('   测验数量: ${result.items.length}');
      
      if (result.items.isNotEmpty) {
        print('   第一个测验: ${result.items[0].title}');
        print('   状态: ${result.items[0].status}');
      }
      
      setState(() {
        _quizzes = result.items;
        _filteredQuizzes = _quizzes;
        _isLoading = false;
      });
      
      print('🔄 状态更新完成，测验列表数量: ${_quizzes.length}');
      print('🔄 过滤后测验列表数量: ${_filteredQuizzes.length}');
    } catch (e, stackTrace) {
      print('❌ 加载测验列表失败: $e');
      print('堆栈跟踪: $stackTrace');
      
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 筛选测验
  void _filterQuizzes() {
    setState(() {
      if (_selectedFilter == '全部') {
        _filteredQuizzes = _quizzes;
      } else {
        _filteredQuizzes = _quizzes.where((quiz) {
          final status = QuizStatus.fromString(quiz.status);
          switch (_selectedFilter) {
            case '待参加':
              return status == QuizStatus.upcoming;
            case '进行中':
              return status == QuizStatus.ongoing;
            case '已完成':
              return status == QuizStatus.completed;
            default:
              return true;
          }
        }).toList();
      }
    });
  }

  /// 获取统计数据
  Map<QuizStatus, int> _getStatistics() {
    final stats = <QuizStatus, int>{};
    for (final status in QuizStatus.values) {
      stats[status] = _quizzes.where((q) => QuizStatus.fromString(q.status) == status).length;
    }
    return stats;
  }

  /// 处理测验点击
  void _onQuizTap(StudentQuizListItem quiz) {
    final status = QuizStatus.fromString(quiz.status);
    if (status == QuizStatus.ongoing) {
      _startQuiz(quiz);
    } else if (status == QuizStatus.upcoming) {
      _showQuizDialog(quiz, '测验尚未开始');
    } else {
      _showQuizDialog(quiz, '查看测验结果');
    }
  }

  /// 开始测验
  Future<void> _startQuiz(StudentQuizListItem quiz) async {
    try {
      // 显示加载提示
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 调用开始测验API
      final startRequest = StartQuizRequest(quizId: quiz.id);
      final startResponse = await _quizService.startQuiz(startRequest);

      if (!mounted) return;
      Navigator.pop(context); // 关闭加载提示

      // 跳转到答题页面
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizTakingPage(
            quizId: quiz.id,
            submissionId: startResponse.submissionId,
            quizTitle: quiz.title,
            duration: quiz.durationMinutes,
            questions: startResponse.questions.map((q) => Question(
              id: q.id,
              type: _convertQuestionType(q.type),
              content: q.content,
              description: q.description ?? '',
              options: q.options.map((o) => o.content).toList(),
              score: q.score.toInt(),
            )).toList(),
          ),
        ),
      );
      
      // 如果返回值为true，表示需要刷新列表
      if (result == true) {
        _loadQuizzes();
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // 关闭加载提示
      
      // 解析错误信息，提供友好提示
      String errorMessage;
      final errorStr = e.toString();
      
      if (errorStr.contains('已达到最大尝试次数')) {
        errorMessage = '已经参加过测验，不能二次参加！';
      } else if (errorStr.contains('测验尚未开始')) {
        errorMessage = '测验尚未开始，请等待开始时间';
      } else if (errorStr.contains('测验已结束')) {
        errorMessage = '测验已结束，无法再参加';
      } else if (errorStr.contains('测验未开放')) {
        errorMessage = '测验未开放，暂时无法参加';
      } else {
        errorMessage = '开始测验失败，请稍后重试';
      }
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('提示'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _loadQuizzes(); // 刷新列表
              },
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }
  
  /// 转换题目类型
  QuestionType _convertQuestionType(String type) {
    switch (type.toLowerCase()) {
      case 'single_choice':
        return QuestionType.singleChoice;
      case 'multiple_choice':
        return QuestionType.multipleChoice;
      case 'true_false':
        return QuestionType.trueOrFalse;
      case 'fill_blank':
        return QuestionType.fillBlank;
      default:
        return QuestionType.singleChoice;
    }
  }

  /// 显示测验对话框
  void _showQuizDialog(StudentQuizListItem quiz, String action) {
    String content = '$action\n\n课程：${quiz.courseName}\n教师：${quiz.teacherName}';
    
    final status = QuizStatus.fromString(quiz.status);
    final submission = quiz.mySubmission;
    
    // 如果是已完成的测验且有提交记录，显示成绩信息
    if (status == QuizStatus.completed && submission != null) {
      content += '\n\n📊 成绩详情：';
      content += '\n得分：${submission.score}分/${quiz.totalScore}分';
      content += '\n正确率：${submission.correctCount}/${quiz.questionCount} (${(submission.accuracy * 100).toStringAsFixed(1)}%)';
      if (submission.rank != null) {
        content += '\n班级排名：第${submission.rank}名';
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(quiz.title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$action功能开发中')),
              );
            },
            child: Text(action.contains('继续') ? '进入' : '确定'),
          ),
        ],
      ),
    );
  }

  /// 设置提醒
  void _setReminder(StudentQuizListItem quiz) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已为"${quiz.title}"设置提醒')),
    );
  }

  /// 显示筛选菜单
  void _showFilterMenu() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('筛选功能开发中')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '在线测验',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF666666)),
            onPressed: _loadQuizzes,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// 构建页面主体
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQuizzes,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final stats = _getStatistics();
    
    return Column(
      children: [
        // 统计卡片
        _buildStatsCards(stats),
        
        // 筛选标签
        _buildFilterTabs(),
        
        // 测验列表
        Expanded(
          child: _buildQuizzesList(),
        ),
      ],
    );
  }

  /// 构建统计卡片
  Widget _buildStatsCards(Map<QuizStatus, int> stats) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              value: stats[QuizStatus.upcoming] ?? 0,
              label: '待参加',
              color: QuizStatus.upcoming.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              value: stats[QuizStatus.ongoing] ?? 0,
              label: '进行中',
              color: QuizStatus.ongoing.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              value: stats[QuizStatus.completed] ?? 0,
              label: '已完成',
              color: QuizStatus.completed.color,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计卡片项
  Widget _buildStatCard({
    required int value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建筛选标签
  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filterTabs.length,
        itemBuilder: (context, index) {
          final tab = _filterTabs[index];
          final isSelected = tab == _selectedFilter;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = tab;
              });
              _filterQuizzes();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF4285F4) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isSelected ? null : Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF666666),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建测验列表
  Widget _buildQuizzesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredQuizzes.length,
      itemBuilder: (context, index) {
        final quiz = _filteredQuizzes[index];
        return _buildQuizCard(quiz);
      },
    );
  }

  /// 构建测验卡片
  Widget _buildQuizCard(StudentQuizListItem quiz) {
    final status = QuizStatus.fromString(quiz.status);
    final submission = quiz.mySubmission;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: status.color, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _onQuizTap(quiz),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和状态
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quiz.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        color: status.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // 课程和教师
              Text(
                '${quiz.courseName} · ${quiz.teacherName}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 测验信息
              Row(
                children: [
                  _buildQuizInfo(Icons.schedule, '${quiz.durationMinutes}分钟'),
                  const SizedBox(width: 16),
                  _buildQuizInfo(Icons.quiz, '${quiz.questionCount}题'),
                  const SizedBox(width: 16),
                  _buildQuizInfo(Icons.star, '${quiz.totalScore}分'),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 时间信息
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '开始时间',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                        Text(
                          _formatDateTime(quiz.startTime),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '结束时间',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                        Text(
                          _formatDateTime(quiz.endTime),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 成绩信息（已完成的测验）
              if (status == QuizStatus.completed && submission != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // 得分信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '得分',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFFF9800),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${submission.score}分',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFFFF9800),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // 正确率信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '正确率',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${submission.correctCount}/${quiz.questionCount} (${(submission.accuracy * 100).toStringAsFixed(1)}%)',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF333333),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // 班级排名信息
                      if (submission.rank != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '班级排名',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF4CAF50),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '第${submission.rank}名',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF333333),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              
              // 操作按钮
              if (status == QuizStatus.upcoming) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _setReminder(quiz),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.notifications, size: 20),
                    label: const Text(
                      '设置提醒',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
              
              // 查看详情按钮（已完成的测验）
              if (status == QuizStatus.completed) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _onQuizTap(quiz),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF666666),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.visibility, size: 20),
                    label: const Text(
                      '查看详情',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  /// 格式化日期时间
  String _formatDateTime(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr);
      return '${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  /// 构建测验信息项
  Widget _buildQuizInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF999999)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }
}
