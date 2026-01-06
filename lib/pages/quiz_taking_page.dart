import 'package:flutter/material.dart';
import 'dart:async';
import '../models/quiz_models.dart';
import '../services/quiz_service.dart';

/// 题目类型枚举
enum QuestionType {
  singleChoice('单选题', Color(0xFF4285F4)),
  multipleChoice('多选题', Color(0xFF4CAF50)),
  trueOrFalse('判断题', Color(0xFFFF9800)),
  fillBlank('填空题', Color(0xFF9C27B0));

  const QuestionType(this.label, this.color);
  final String label;
  final Color color;
}

/// 答题状态枚举
enum AnswerStatus {
  answered('已答', Color(0xFF4CAF50)),
  current('当前', Color(0xFF4285F4)),
  unanswered('未答', Color(0xFFE0E0E0));

  const AnswerStatus(this.label, this.color);
  final String label;
  final Color color;
}

/// 题目模型
class Question {
  final int id;
  final QuestionType type;
  final String content;
  final String description;
  final List<String> options;
  final int score;
  String? selectedAnswer;
  List<String>? selectedAnswers; // 多选题用

  Question({
    required this.id,
    required this.type,
    required this.content,
    required this.description,
    required this.options,
    required this.score,
    this.selectedAnswer,
    this.selectedAnswers,
  });

  /// 获取答题状态
  AnswerStatus getStatus(int currentQuestionIndex) {
    if (id - 1 == currentQuestionIndex) {
      return AnswerStatus.current;
    } else if (selectedAnswer != null || (selectedAnswers != null && selectedAnswers!.isNotEmpty)) {
      return AnswerStatus.answered;
    } else {
      return AnswerStatus.unanswered;
    }
  }

  /// 是否已答题
  bool get isAnswered {
    return selectedAnswer != null || (selectedAnswers != null && selectedAnswers!.isNotEmpty);
  }
}

/// 学生测验页面
class QuizTakingPage extends StatefulWidget {
  final int quizId;
  final int submissionId;
  final String quizTitle;
  final int duration; // 分钟
  final List<Question> questions;

  const QuizTakingPage({
    super.key,
    required this.quizId,
    required this.submissionId,
    required this.quizTitle,
    required this.duration,
    required this.questions,
  });

  @override
  State<QuizTakingPage> createState() => _QuizTakingPageState();
}

class _QuizTakingPageState extends State<QuizTakingPage> {
  final QuizService _quizService = QuizService();
  
  int _currentQuestionIndex = 0;
  bool _showAnswerSheet = false;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isSubmittingAnswer = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.duration * 60;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 启动计时器
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _submitQuiz();
        }
      });
    });
  }

  /// 格式化时间显示
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// 获取当前题目
  Question get _currentQuestion => widget.questions[_currentQuestionIndex];

  /// 选择答案
  Future<void> _selectAnswer(String answer) async {
    if (_isSubmittingAnswer) return;
    
    setState(() {
      if (_currentQuestion.type == QuestionType.multipleChoice) {
        _currentQuestion.selectedAnswers ??= [];
        if (_currentQuestion.selectedAnswers!.contains(answer)) {
          _currentQuestion.selectedAnswers!.remove(answer);
        } else {
          _currentQuestion.selectedAnswers!.add(answer);
        }
      } else {
        _currentQuestion.selectedAnswer = answer;
      }
    });

    // 调用API提交答案
    try {
      setState(() => _isSubmittingAnswer = true);
      
      // 构建答案列表（修复：使用List<String>而不是字符串）
      List<String> studentAnswer;
      if (_currentQuestion.type == QuestionType.multipleChoice) {
        // 多选题：使用selectedAnswers列表
        studentAnswer = _currentQuestion.selectedAnswers ?? [];
      } else {
        // 单选题/判断题：将selectedAnswer包装成列表
        if (_currentQuestion.selectedAnswer != null && _currentQuestion.selectedAnswer!.isNotEmpty) {
          studentAnswer = [_currentQuestion.selectedAnswer!];
        } else {
          studentAnswer = [];  // 未作答
        }
      }
      
      final request = SubmitAnswerRequest(
        submissionId: widget.submissionId,
        questionId: _currentQuestion.id,
        studentAnswer: studentAnswer,
        timeSpentSeconds: 0,  // TODO: 计算实际答题时间
      );
      
      await _quizService.submitAnswer(request);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交答案失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingAnswer = false);
      }
    }
  }

  /// 跳转到指定题目
  void _goToQuestion(int index) {
    setState(() {
      _currentQuestionIndex = index;
      _showAnswerSheet = false;
    });
  }

  /// 下一题
  void _nextQuestion() {
    if (_currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  /// 上一题
  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  /// 提交测验
  Future<void> _submitQuiz() async {
    final unansweredCount = widget.questions.length - _getAnsweredCount();
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: _remainingSeconds > 0,
      builder: (context) => AlertDialog(
        title: const Text('提交测验'),
        content: Text(
          unansweredCount > 0
              ? '还有 $unansweredCount 道题未作答，确定要提交测验吗？提交后将无法修改答案。'
              : '确定要提交测验吗？提交后将无法修改答案。'
        ),
        actions: [
          if (_remainingSeconds > 0)
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定提交'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 显示加载提示
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // 构建答案列表
      final answers = widget.questions.map((q) {
        List<String> studentAnswer;
        if (q.type == QuestionType.multipleChoice) {
          // 多选题：使用答案列表
          studentAnswer = q.selectedAnswers ?? [];
        } else {
          // 单选题/判断题：将答案包装成列表
          if (q.selectedAnswer != null && q.selectedAnswer!.isNotEmpty) {
            studentAnswer = [q.selectedAnswer!];
          } else {
            studentAnswer = [];
          }
        }
        return AnswerItem(
          questionId: q.id, 
          studentAnswer: studentAnswer,
          timeSpentSeconds: 0,
        );
      }).toList();

      final request = SubmitQuizRequest(
        submissionId: widget.submissionId,
        answers: answers,
      );

      final result = await _quizService.submitQuiz(request);

      if (!mounted) return;
      Navigator.pop(context); // 关闭加载提示
      
      // 返回测验列表页，传递true表示需要刷新
      Navigator.pop(context, true);

      // 显示提交结果
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('测验已提交！得分: ${result.totalScore.toStringAsFixed(1)}分'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // 关闭加载提示
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('提交测验失败: $e')),
      );
    }
  }

  /// 获取已答题数量
  int _getAnsweredCount() {
    return widget.questions.where((q) => q.isAnswered).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('退出测验'),
                content: const Text('确定要退出测验吗？当前答题进度将会丢失。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('确定退出'),
                  ),
                ],
              ),
            );
          },
        ),
        title: Text(
          widget.quizTitle,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _remainingSeconds < 300 ? const Color(0xFFFF5722) : const Color(0xFFFF9800),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_remainingSeconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _showAnswerSheet ? _buildAnswerSheet() : _buildQuestionView(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  /// 构建题目视图
  Widget _buildQuestionView() {
    return Column(
      children: [
        // 进度条
        _buildProgressBar(),
        
        // 题目内容
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 题目信息
                _buildQuestionInfo(),
                
                const SizedBox(height: 16),
                
                // 题目内容
                _buildQuestionContent(),
                
                const SizedBox(height: 20),
                
                // 选项列表
                _buildOptionsList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建进度条
  Widget _buildProgressBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '答题进度',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              Text(
                '${_currentQuestionIndex + 1}/${widget.questions.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4285F4),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.questions.length,
            backgroundColor: const Color(0xFFE0E0E0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  /// 构建题目信息
  Widget _buildQuestionInfo() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _currentQuestion.type.color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _currentQuestion.type.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '第${_currentQuestion.id}题',
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF333333),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            const Icon(
              Icons.star,
              color: Color(0xFFFF9800),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '${_currentQuestion.score}分',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFFF9800),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建题目内容
  Widget _buildQuestionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentQuestion.content,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentQuestion.description,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// 构建选项列表
  Widget _buildOptionsList() {
    return Column(
      children: _currentQuestion.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final optionLabel = String.fromCharCode(65 + index); // A, B, C, D
        
        bool isSelected = false;
        if (_currentQuestion.type == QuestionType.multipleChoice) {
          isSelected = _currentQuestion.selectedAnswers?.contains(optionLabel) ?? false;
        } else {
          isSelected = _currentQuestion.selectedAnswer == optionLabel;
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _selectAnswer(optionLabel),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: isSelected ? const Color(0xFF4285F4) : const Color(0xFFE0E0E0),
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: _currentQuestion.type == QuestionType.multipleChoice 
                          ? BoxShape.rectangle 
                          : BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF4285F4) : const Color(0xFFCCCCCC),
                        width: 2,
                      ),
                      color: isSelected ? const Color(0xFF4285F4) : Colors.transparent,
                      borderRadius: _currentQuestion.type == QuestionType.multipleChoice 
                          ? BorderRadius.circular(4) 
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$optionLabel. ${option.split('。')[0]}',
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected ? const Color(0xFF4285F4) : const Color(0xFF333333),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (option.contains('。') && option.split('。').length > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              option.split('。').skip(1).join('。'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建答题卡
  Widget _buildAnswerSheet() {
    // 按题型分组
    final singleChoice = widget.questions.where((q) => q.type == QuestionType.singleChoice).toList();
    final multipleChoice = widget.questions.where((q) => q.type == QuestionType.multipleChoice).toList();
    final trueOrFalse = widget.questions.where((q) => q.type == QuestionType.trueOrFalse).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (singleChoice.isNotEmpty) _buildQuestionTypeSection('单选题 (1-${singleChoice.length})', singleChoice),
          if (multipleChoice.isNotEmpty) _buildQuestionTypeSection('多选题 (${singleChoice.length + 1}-${singleChoice.length + multipleChoice.length})', multipleChoice),
          if (trueOrFalse.isNotEmpty) _buildQuestionTypeSection('判断题 (${singleChoice.length + multipleChoice.length + 1}-${widget.questions.length})', trueOrFalse),
        ],
      ),
    );
  }

  /// 构建题型分组
  Widget _buildQuestionTypeSection(String title, List<Question> questions) {
    final answeredCount = questions.where((q) => q.isAnswered).length;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              Text(
                '已答: $answeredCount/${questions.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              final status = question.getStatus(_currentQuestionIndex);
              
              return InkWell(
                onTap: () => _goToQuestion(question.id - 1),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: status.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${question.id}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: status == AnswerStatus.unanswered ? const Color(0xFF999999) : Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 构建底部操作栏
  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: _showAnswerSheet ? _buildAnswerSheetBottomBar() : _buildQuestionBottomBar(),
    );
  }

  /// 构建题目页面底部栏
  Widget _buildQuestionBottomBar() {
    return Row(
      children: [
        // 答题卡按钮
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _showAnswerSheet = true;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF666666),
              side: const BorderSide(color: Color(0xFFE0E0E0)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.grid_view, size: 20),
            label: const Text('答题卡'),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // 上一题按钮
        if (_currentQuestionIndex > 0)
          ElevatedButton(
            onPressed: _previousQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE0E0E0),
              foregroundColor: const Color(0xFF666666),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('上一题'),
          ),
        
        if (_currentQuestionIndex > 0) const SizedBox(width: 8),
        
        // 下一题/提交按钮
        ElevatedButton(
          onPressed: _currentQuestionIndex < widget.questions.length - 1 ? _nextQuestion : _submitQuiz,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4285F4),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(_currentQuestionIndex < widget.questions.length - 1 ? '下一题' : '提交'),
        ),
      ],
    );
  }

  /// 构建答题卡页面底部栏
  Widget _buildAnswerSheetBottomBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 状态图例
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatusLegend(AnswerStatus.answered),
            _buildStatusLegend(AnswerStatus.current),
            _buildStatusLegend(AnswerStatus.unanswered),
          ],
        ),
        const SizedBox(height: 12),
        // 返回按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _showAnswerSheet = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4285F4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('返回答题'),
          ),
        ),
      ],
    );
  }

  /// 构建状态图例
  Widget _buildStatusLegend(AnswerStatus status) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: status.color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          status.label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }
}
