import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/assignment_service.dart';
import '../services/file_upload_service.dart';

/// 作业批改页面
class TeacherAssignmentGradingPage extends StatefulWidget {
  final Map<String, dynamic>? assignment;
  
  const TeacherAssignmentGradingPage({
    super.key,
    this.assignment,
  });

  @override
  State<TeacherAssignmentGradingPage> createState() => _TeacherAssignmentGradingPageState();
}

class _TeacherAssignmentGradingPageState extends State<TeacherAssignmentGradingPage> {
  PageController _pageController = PageController();
  
  // 当前批改的学生索引
  int _currentStudentIndex = 0;
  
  // 评分控制器
  final Map<String, TextEditingController> _scoreControllers = {};
  final TextEditingController _totalScoreController = TextEditingController();
  
  // 加载状态
  bool _isLoading = true;
  String? _error;
  
  // 学生提交列表
  List<Map<String, dynamic>> _submissions = [];

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  /// 加载作业提交列表
  Future<void> _loadSubmissions() async {
    if (widget.assignment == null) {
      setState(() {
        _error = '作业信息不存在';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final token = await ApiService.getAuthToken();
      
      if (token == null) {
        throw Exception('用户未登录');
      }

      final assignmentId = widget.assignment!['id'];
      final assignmentIdInt = assignmentId is int ? assignmentId : int.parse(assignmentId.toString());
      print('Debug: 加载作业提交列表，assignmentId: $assignmentId (转换为: $assignmentIdInt)');

      final response = await AssignmentService.getAssignmentSubmissions(
        token: token,
        assignmentId: assignmentIdInt,
        status: 'all',
        page: 1,
        pageSize: 100,
      );

      print('Debug: 提交列表API响应: $response');

      if (response['error'] == 0) {
        final List<dynamic> submissionList = response['body']['submissions'] ?? [];
        print('Debug: 解析到的提交列表: $submissionList');
        print('Debug: 提交数量: ${submissionList.length}');
        
        setState(() {
          _submissions = submissionList.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
        
        _initializeControllers();
        
        // 如果有提交记录，加载第一个提交的详情
        if (_submissions.isNotEmpty) {
          _loadCurrentSubmissionDetail();
        }
      } else {
        throw Exception(response['message'] ?? '获取提交列表失败');
      }
    } catch (e) {
      print('Debug: 加载提交列表失败: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  /// 初始化控制器
  void _initializeControllers() {
    // 暂时跳过控制器初始化，因为提交列表数据不包含评分标准
    // 当切换到具体提交时，会调用详情API获取完整数据
    _totalScoreController.text = '0';
  }

  /// 为评分标准初始化控制器
  void _initializeCriteriaControllers(int submissionIndex, List<dynamic> criteria) {
    for (final criterion in criteria) {
      final key = '${submissionIndex}_${criterion['name']}';
      if (!_scoreControllers.containsKey(key)) {
        _scoreControllers[key] = TextEditingController();
        print('Debug: 创建controller: $key');
      }
    }
  }

  /// 加载当前提交的详情
  Future<void> _loadCurrentSubmissionDetail() async {
    if (_submissions.isEmpty || _currentStudentIndex >= _submissions.length) {
      return;
    }

    try {
      final token = await ApiService.getAuthToken();
      if (token == null) {
        throw Exception('用户未登录');
      }

      final submission = _submissions[_currentStudentIndex];
      final submissionId = submission['id'];
      final submissionIdInt = submissionId is int ? submissionId : int.parse(submissionId.toString());
      
      print('Debug: 加载提交详情，submissionId: $submissionIdInt');

      final response = await AssignmentService.getSubmissionDetail(
        token: token,
        submissionId: submissionIdInt,
      );

      print('Debug: 提交详情API响应: $response');

      if (response['error'] == 0) {
        final submissionDetail = response['body']['submission'] ?? {};
        final attachments = response['body']['attachments'] ?? [];
        final grades = response['body']['grades'] ?? [];
        final criteria = response['body']['criteria'] ?? [];
        
        // 更新当前提交的详细信息
        setState(() {
          _submissions[_currentStudentIndex].addAll({
            'content': submissionDetail['content'] ?? '学生提交了作业，等待批改。',
            'files': attachments,
            'grades': grades,
            'criteria': criteria,
            'feedback': submissionDetail['feedback'],
            'gradedAt': submissionDetail['gradedAt'],
            'graderName': submissionDetail['graderName'],
          });
        });
        
        // 为评分标准创建controllers
        _initializeCriteriaControllers(_currentStudentIndex, criteria);
        
        print('Debug: 提交详情更新完成');
      } else {
        print('Debug: 获取提交详情失败: ${response['message']}');
      }
    } catch (e) {
      print('Debug: 加载提交详情失败: $e');
    }
  }

  /// 提交批改结果
  Future<void> _submitGrade(int submissionIndex) async {
    if (_submissions.isEmpty || _currentStudentIndex >= _submissions.length) {
      return;
    }

    try {
      final token = await ApiService.getAuthToken();
      
      if (token == null) {
        throw Exception('用户未登录');
      }

      final submission = _submissions[_currentStudentIndex];
      final submissionId = submission['id'];
      final submissionIdInt = submissionId is int ? submissionId : int.parse(submissionId.toString());
      
      // 从总分输入框获取分数
      final key = 'total_$submissionIndex';
      final totalScoreController = _scoreControllers[key];
      final totalScore = double.tryParse(totalScoreController?.text ?? '0') ?? 0.0;
      
      // 从评语输入框获取评语
      final commentKey = 'comment_$submissionIndex';
      final commentController = _scoreControllers[commentKey];
      final comment = commentController?.text ?? '批改完成';
      
      // 构建评分数据
      final gradeData = {
        'totalScore': totalScore,
        'comment': comment,
        'grades': [], // 不再使用评分标准
      };

      print('Debug: 提交批改，submissionId: $submissionId (转换为: $submissionIdInt)');
      print('Debug: 评分数据: $gradeData');

      final response = await AssignmentService.gradeAssignment(
        token: token,
        submissionId: submissionIdInt,
        gradeData: gradeData,
      );

      print('Debug: 批改API响应: $response');

      if (response['error'] == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('批改成功')),
          );
        }
        
        // 标记为已批改
        setState(() {
          _submissions[_currentStudentIndex]['isGraded'] = true;
          _submissions[_currentStudentIndex]['score'] = totalScore;
          _submissions[_currentStudentIndex]['comment'] = comment;
        });
      } else {
        throw Exception(response['message'] ?? '批改失败');
      }
    } catch (e) {
      print('Debug: 批改失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('批改失败: $e')),
        );
      }
    }
  }

  /// 上一个学生
  void _previousStudent() {
    if (_currentStudentIndex > 0) {
      setState(() {
        _currentStudentIndex--;
      });
      _pageController.animateToPage(
        _currentStudentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 下一个学生
  void _nextStudent() {
    if (_currentStudentIndex < _submissions.length - 1) {
      setState(() {
        _currentStudentIndex++;
      });
      _pageController.animateToPage(
        _currentStudentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
        title: Column(
          children: [
            Text(
              '作业批改',
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.assignment?['title'] ?? '数据结构课程设计',
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _currentStudentIndex > 0 ? _previousStudent : null,
            icon: Icon(
              Icons.chevron_left,
              color: _currentStudentIndex > 0 ? const Color(0xFF333333) : const Color(0xFFCCCCCC),
            ),
          ),
          IconButton(
            onPressed: _currentStudentIndex < _submissions.length - 1 ? _nextStudent : null,
            icon: Icon(
              Icons.chevron_right,
              color: _currentStudentIndex < _submissions.length - 1 ? const Color(0xFF333333) : const Color(0xFFCCCCCC),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('加载失败: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSubmissions,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _submissions.isEmpty
                  ? const Center(
                      child: Text('暂无提交记录'),
                    )
                  : Column(
                      children: [
                        // 学生信息和批改进度
                        _buildStudentHeader(),
                        
                        // 批改内容
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _submissions.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentStudentIndex = index;
                              });
                              // 加载新选中提交的详情
                              _loadCurrentSubmissionDetail();
                            },
                            itemBuilder: (context, index) {
                              return _buildGradingContent(_submissions[index], index);
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  /// 构建学生头部信息
  Widget _buildStudentHeader() {
    final submission = _submissions[_currentStudentIndex];
    
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // 学生头像
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: submission['avatarColor'] ?? const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                submission['avatar'] ?? (submission['studentName']?.toString().isNotEmpty == true 
                    ? submission['studentName'].toString().substring(0, 1) 
                    : '学'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 学生信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  submission['studentName'] ?? '未知学生',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${submission['studentNumber'] ?? submission['studentId'] ?? '未知学号'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          
          // 提交时间
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '提交时间',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                submission['submissionTime'] ?? submission['submitTime'] ?? '未知时间',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建批改内容
  Widget _buildGradingContent(Map<String, dynamic> submission, int index) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 批改进度
          _buildGradingProgress(index),
          
          const SizedBox(height: 16),
          
          // 提交内容
          _buildSubmissionContent(submission),
          
          const SizedBox(height: 16),
          
          // 提交文件
          _buildSubmissionFiles(submission),
          
          const SizedBox(height: 16),
          
          // 总分
          _buildTotalScore(submission, index),
          
          const SizedBox(height: 16),
          
          // 评语
          _buildComment(submission, index),
          
          const SizedBox(height: 100), // 为底部按钮留空间
        ],
      ),
    );
  }

  /// 构建批改进度
  Widget _buildGradingProgress(int index) {
    final submission = _submissions[index];
    
    return Container(
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
          const Text(
            '批改进度',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Text(
                '${index + 1}/${_submissions.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B82F6),
                ),
              ),
              
              const SizedBox(width: 8),
              
              Text(
                '(第${index + 1}份)',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
              
              const Spacer(),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (submission['isGraded'] ?? false)
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (submission['isGraded'] ?? false) ? '已批改' : '待批改',
                  style: TextStyle(
                    color: (submission['isGraded'] ?? false)
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建提交内容
  Widget _buildSubmissionContent(Map<String, dynamic> submission) {
    return Container(
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
          const Text(
            '提交信息',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          
          const SizedBox(height: 12),
          
          const Text(
            '文字说明',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              submission['content'] ?? '学生未填写文字说明',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF333333),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建提交文件
  Widget _buildSubmissionFiles(Map<String, dynamic> submission) {
    return Container(
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
          const Text(
            '提交文件',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          
          const SizedBox(height: 12),
          
          ...(submission['files'] as List<dynamic>? ?? []).map<Widget>((file) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: file['color'],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      file['icon'],
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file['fileName'] ?? file['name'] ?? '未知文件',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${file['formattedFileSize'] ?? file['size'] ?? '未知大小'} · ${(file['fileType'] ?? file['type'] ?? 'unknown').toString().toUpperCase()}文件',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _viewFile(file),
                        icon: const Icon(Icons.visibility, size: 16),
                        style: IconButton.styleFrom(
                          foregroundColor: const Color(0xFF666666),
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                      
                      const SizedBox(width: 4),
                      
                      const Text(
                        '查看',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// 构建评分标准
  Widget _buildGradingCriteria(Map<String, dynamic> submission, int index) {
    return Container(
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
          const Text(
            '评分标准',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          
          const SizedBox(height: 16),
          
          ...(submission['criteria'] as List<dynamic>? ?? []).map<Widget>((criterion) {
            final key = '${index}_${criterion['name']}';
            final controller = _scoreControllers[key] ?? TextEditingController();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${criterion['name']} (${criterion['maxScore'] ?? 100}分)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    criterion['description'] ?? '评分标准描述',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '0-${criterion['maxScore'] ?? 100}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onChanged: (value) => _updateTotalScore(index),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      Text(
                        '/ ${criterion['maxScore'] ?? 100}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// 构建总分
  Widget _buildTotalScore(Map<String, dynamic> submission, int index) {
    // 为每个提交创建一个总分控制器
    final key = 'total_$index';
    if (!_scoreControllers.containsKey(key)) {
      final currentScore = submission['score'] ?? 0;
      _scoreControllers[key] = TextEditingController(text: currentScore.toString());
    }
    final totalScoreController = _scoreControllers[key]!;
    
    return Container(
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
          const Text(
            '总分',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              // 分数输入框
              SizedBox(
                width: 120,
                child: TextField(
                  controller: totalScoreController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '0',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              Text(
                '/ ${submission['maxScore'] ?? 100}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                ),
              ),
              
              const Spacer(),
              
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () => _saveGrade(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('保存评分'),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  OutlinedButton(
                    onPressed: () => _resetGrade(index),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF666666),
                      side: const BorderSide(color: Color(0xFF666666)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('重置'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建评语
  Widget _buildComment(Map<String, dynamic> submission, int index) {
    // 为每个提交创建一个评语控制器
    final key = 'comment_$index';
    if (!_scoreControllers.containsKey(key)) {
      final currentComment = submission['comment'] ?? '';
      _scoreControllers[key] = TextEditingController(text: currentComment);
    }
    final commentController = _scoreControllers[key]!;
    
    return Container(
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
          const Text(
            '评语',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextField(
            controller: commentController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: '请输入评语...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF3B82F6)),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  /// 计算总分
  int _calculateTotalScore(int index) {
    int total = 0;
    final submission = _submissions[index];
    
    for (final criterion in (submission['criteria'] as List<dynamic>? ?? [])) {
      final key = '${index}_${criterion['name']}';
      final controller = _scoreControllers[key];
      if (controller != null) {
        final score = int.tryParse(controller.text) ?? 0;
        total += score;
      }
    }
    
    return total;
  }

  /// 更新总分
  void _updateTotalScore(int index) {
    setState(() {
      final total = _calculateTotalScore(index);
      _totalScoreController.text = total.toString();
    });
  }


  /// 查看文件
  Future<void> _viewFile(Map<String, dynamic> file) async {
    try {
      final attachmentId = file['id'];
      final fileName = file['name'] ?? file['fileName'] ?? 'file';
      
      if (attachmentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('文件ID不存在'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // 下载文件
      await FileUploadService.downloadAssignmentAttachment(
        attachmentId: attachmentId,
        fileName: fileName,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('文件下载成功: $fileName'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下载失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 保存评分
  void _saveGrade(int index) async {
    // 从总分输入框获取分数
    final key = 'total_$index';
    final totalScoreController = _scoreControllers[key];
    final total = int.tryParse(totalScoreController?.text ?? '0') ?? 0;
    
    // 验证分数范围
    final maxScore = _submissions[index]['maxScore'] ?? 100;
    if (total < 0 || total > maxScore) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('分数必须在 0-$maxScore 之间'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // 先更新本地状态
    setState(() {
      _submissions[index]['totalScore'] = total;
      _submissions[index]['isGraded'] = true;
    });
    
    // 显示保存中提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('正在保存 ${_submissions[index]['studentName']} 的评分...'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 1),
      ),
    );
    
    // 调用后端API保存到数据库
    await _submitGrade(index);
  }

  /// 重置评分
  void _resetGrade(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认重置'),
        content: const Text('确定要重置当前学生的评分吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performReset(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 执行重置
  void _performReset(int index) {
    // 重置总分输入框
    final scoreKey = 'total_$index';
    final scoreController = _scoreControllers[scoreKey];
    if (scoreController != null) {
      scoreController.text = '0';
    }
    
    // 重置评语输入框
    final commentKey = 'comment_$index';
    final commentController = _scoreControllers[commentKey];
    if (commentController != null) {
      commentController.text = '';
    }
    
    setState(() {
      _submissions[index]['totalScore'] = 0;
      _submissions[index]['isGraded'] = false;
      _submissions[index]['comment'] = '';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('评分已重置'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scoreControllers.values.forEach((controller) => controller.dispose());
    _totalScoreController.dispose();
    super.dispose();
  }
}
