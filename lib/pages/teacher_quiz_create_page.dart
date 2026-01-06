import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/quiz_service.dart';
import '../services/course_service.dart';
import '../models/course_models.dart';
import 'teacher_quiz_questions_page.dart';

/// 发布测验页面
class TeacherQuizCreatePage extends StatefulWidget {
  final int? courseId;
  final String? courseName;
  final int? quizId; // 如果是编辑模式
  
  const TeacherQuizCreatePage({
    super.key,
    this.courseId,
    this.courseName,
    this.quizId,
  });

  @override
  State<TeacherQuizCreatePage> createState() => _TeacherQuizCreatePageState();
}

class _TeacherQuizCreatePageState extends State<TeacherQuizCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _quizService = QuizService();
  
  // 表单控制器
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scoreController = TextEditingController(text: '100');
  final _durationController = TextEditingController(text: '90');
  
  // 选择的值
  String _selectedType = '';
  DateTime? _startTime;
  DateTime? _endTime;
  int? _selectedCourseId;
  String? _selectedCourseName;
  
  // 题目列表（从题目编辑页面返回）
  List<Map<String, dynamic>> _questions = [];
  
  // 加载状态
  bool _isLoading = false;
  bool _isLoadingCourses = false;
  List<CourseListItem> _courses = [];
  
  // 测验类型选项
  final List<Map<String, String>> _quizTypes = [
    {'value': 'midterm', 'label': '期中考试'},
    {'value': 'final', 'label': '期末考试'},
    {'value': 'chapter', 'label': '章节测试'},
    {'value': 'practice', 'label': '练习测验'},
    {'value': 'quiz', 'label': '随堂测验'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.courseId;
    _selectedCourseName = widget.courseName;
    _loadCourses();
  }

  /// 加载课程列表
  Future<void> _loadCourses() async {
    if (_selectedCourseId != null) {
      // 如果已经指定了课程，不需要加载列表
      return;
    }
    
    setState(() {
      _isLoadingCourses = true;
    });
    
    try {
      final courses = await CourseService.getTeacherCoursesForQuiz();
      
      if (mounted) {
        setState(() {
          _courses = courses;
          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCourses = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载课程列表失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
        ),
        title: const Text(
          '发布测验',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _saveDraft,
            icon: const Icon(Icons.save, color: Color(0xFF333333)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 基本信息
              _buildBasicInfoSection(),
              
              const SizedBox(height: 16),
              
              // 题目设置
              _buildQuestionSection(),
              
              const SizedBox(height: 16),
              
              // 时间设置
              _buildTimeSection(),
              
              const SizedBox(height: 100), // 为底部按钮留空间
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  /// 构建基本信息区域
  Widget _buildBasicInfoSection() {
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
          Row(
            children: [
              Icon(Icons.info, color: const Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 8),
              const Text(
                '基本信息',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 测验标题
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: '测验标题 *',
              hintText: '请输入测验标题',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixText: '${_titleController.text.length}/100',
            ),
            maxLength: 100,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入测验标题';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {});
            },
          ),
          
          const SizedBox(height: 16),
          
          // 课程选择（如果未指定课程）
          if (_selectedCourseId == null) ...[
            DropdownButtonFormField<int>(
              value: _selectedCourseId,
              decoration: InputDecoration(
                labelText: '选择课程 *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _courses.map<DropdownMenuItem<int>>((course) {
                return DropdownMenuItem<int>(
                  value: course.id,
                  child: Text('${course.courseName} (${course.courseCode})'),
                );
              }).toList(),
              onChanged: _isLoadingCourses ? null : (value) {
                setState(() {
                  _selectedCourseId = value;
                  final course = _courses.firstWhere((c) => c.id == value);
                  _selectedCourseName = course.courseName;
                });
              },
              validator: (value) {
                if (value == null) {
                  return '请选择课程';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ] else ...[
            // 显示已选择的课程
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3B82F6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Color(0xFF3B82F6), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '课程：$_selectedCourseName',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // 测验类型和总分
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedType.isEmpty ? null : _selectedType,
                  decoration: InputDecoration(
                    labelText: '测验类型 *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _quizTypes.map((type) {
                    return DropdownMenuItem(
                      value: type['value'],
                      child: Text(type['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请选择类型';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: TextFormField(
                  controller: _scoreController,
                  decoration: InputDecoration(
                    labelText: '总分 *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入总分';
                    }
                    final score = int.tryParse(value);
                    if (score == null || score <= 0) {
                      return '请输入有效分数';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 测验说明
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: '测验说明',
              hintText: '请输入测验说明、注意事项等...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixText: '${_descriptionController.text.length}/500',
            ),
            maxLines: 3,
            maxLength: 500,
            onChanged: (value) {
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  /// 构建题目设置区域
  Widget _buildQuestionSection() {
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
          Row(
            children: [
              Icon(Icons.quiz, color: const Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              const Text(
                '题目设置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 进入题目编辑页面的按钮
          GestureDetector(
            onTap: _navigateToQuestionEdit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3B82F6)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit, color: Color(0xFF3B82F6)),
                  SizedBox(width: 8),
                  Text(
                    '编辑题目',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Color(0xFF3B82F6)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          if (_questions.isEmpty)
            const Text(
              '点击上方按钮进入题目编辑页面，添加单选题、多选题、判断题等',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '已添加 ${_questions.length} 道题目',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 构建时间设置区域
  Widget _buildTimeSection() {
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
          Row(
            children: [
              Icon(Icons.schedule, color: const Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 8),
              const Text(
                '时间设置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 开始时间和结束时间
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '开始时间',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const Text(
                          ' *',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectStartTime(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _startTime != null 
                                    ? '${_startTime!.year}/${_startTime!.month}/${_startTime!.day} ${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                                    : '2025/10/22 04:06',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _startTime != null 
                                      ? const Color(0xFF333333)
                                      : const Color(0xFF999999),
                                ),
                              ),
                            ),
                            const Icon(Icons.calendar_today, size: 16, color: Color(0xFF666666)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '结束时间',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const Text(
                          ' *',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectEndTime(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _endTime != null 
                                    ? '${_endTime!.year}/${_endTime!.month}/${_endTime!.day}'
                                    : '2025/10/29',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _endTime != null 
                                      ? const Color(0xFF333333)
                                      : const Color(0xFF999999),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 答题时长
          Row(
            children: [
              const Text(
                '答题时长',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _durationController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入答题时长';
                    }
                    final duration = int.tryParse(value);
                    if (duration == null || duration <= 0) {
                      return '请输入有效时长';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '分钟',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 时间说明
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: const Color(0xFF3B82F6), size: 16),
                const SizedBox(width: 8),
                const Text(
                  '时间说明',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          const Text(
            '学生在开放时间内随时开始测验，一旦开始将有90分钟完成',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部按钮
  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _saveDraft,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4CAF50),
                side: const BorderSide(color: Color(0xFF4CAF50)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('保存草稿'),
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _publishQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('发布测验'),
            ),
          ),
        ],
      ),
    );
  }

  /// 选择开始时间
  Future<void> _selectStartTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startTime ?? DateTime.now()),
      );
      
      if (time != null) {
        setState(() {
          _startTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  /// 选择结束时间
  Future<void> _selectEndTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endTime ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _endTime = date;
      });
    }
  }

  /// 导航到题目编辑页面
  void _navigateToQuestionEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherQuizQuestionsPage(
          existingQuestions: _questions,
        ),
      ),
    ).then((result) {
      if (result != null && result is List) {
        // 题目编辑完成，更新题目列表
        setState(() {
          _questions = List<Map<String, dynamic>>.from(result);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已添加 ${_questions.length} 道题目'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    });
  }

  /// 保存草稿
  Future<void> _saveDraft() async {
    // TODO: 实现草稿保存功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('草稿保存功能开发中'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// 发布测验
  Future<void> _publishQuiz() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // 验证课程选择
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请选择课程'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // 验证时间
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请选择开始和结束时间'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_startTime!.isAfter(_endTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('结束时间必须晚于开始时间'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // 验证题目
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请至少添加一道题目'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // 显示确认对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认发布'),
        content: Text('确定要发布测验"${_titleController.text}"吗？\n\n包含${_questions.length}道题目，总分${_scoreController.text}分。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performPublish();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 执行发布操作
  Future<void> _performPublish() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 转换题目格式
      final questionsData = _convertQuestionsToApiFormat();
      
      // 格式化时间
      final startTimeStr = _formatDateTime(_startTime!);
      final endTimeStr = _formatDateTime(_endTime!);
      
      print('📤 发布测验请求:');
      print('  courseId: $_selectedCourseId');
      print('  title: ${_titleController.text}');
      print('  quizType: $_selectedType');
      print('  totalScore: ${_scoreController.text}');
      print('  durationMinutes: ${_durationController.text}');
      print('  startTime: $startTimeStr');
      print('  endTime: $endTimeStr');
      print('  questions: ${questionsData.length} 道');
      
      // 调用API创建测验
      final response = await _quizService.createQuiz(
        courseId: _selectedCourseId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        quizType: _selectedType,
        totalScore: int.parse(_scoreController.text),
        durationMinutes: int.parse(_durationController.text),
        startTime: startTimeStr,
        endTime: endTimeStr,
        allowReview: true,
        shuffleQuestions: false,
        shuffleOptions: false,
        maxAttempts: 1,
        showScoreImmediately: true,
        questions: questionsData,
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (response.error == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('测验发布成功！'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          
          // 返回上一页
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('发布失败: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ 发布测验失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发布失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// 格式化时间为API所需格式
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:00';
  }
  
  /// 转换题目数据为API格式
  List<Map<String, dynamic>> _convertQuestionsToApiFormat() {
    return _questions.asMap().entries.map((entry) {
      final index = entry.key;
      final question = entry.value;
      
      // 转换题目类型
      String questionType;
      switch (question['type']) {
        case 'single':
          questionType = 'single_choice';
          break;
        case 'multiple':
          questionType = 'multiple_choice';
          break;
        case 'judge':
          questionType = 'true_false';
          break;
        default:
          questionType = 'single_choice';
      }
      
      final result = <String, dynamic>{
        'questionType': questionType,
        'questionContent': question['title'],
        'questionExplanation': question['explanation'] ?? '',
        'score': question['score'],
        'difficultyLevel': 2, // 默认中等难度
        'questionOrder': index + 1,
      };
      
      // 处理选项
      if (question['type'] != 'judge') {
        final options = question['options'] as List;
        final correctIndexes = (question['correct'] as List).cast<int>();
        
        result['options'] = options.asMap().entries.map((optEntry) {
          final optIndex = optEntry.key;
          final optContent = optEntry.value as String;
          
          return {
            'optionLabel': String.fromCharCode(65 + optIndex), // A, B, C, D
            'optionContent': optContent,
            'isCorrect': correctIndexes.contains(optIndex),
            'optionOrder': optIndex + 1,
          };
        }).toList();
      } else {
        // 判断题
        final isTrue = question['correct'] as bool;
        result['options'] = [
          {
            'optionLabel': 'A',
            'optionContent': '正确',
            'isCorrect': isTrue,
            'optionOrder': 1,
          },
          {
            'optionLabel': 'B',
            'optionContent': '错误',
            'isCorrect': !isTrue,
            'optionOrder': 2,
          },
        ];
      }
      
      return result;
    }).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _scoreController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}
