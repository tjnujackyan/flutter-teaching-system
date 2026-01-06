import 'package:flutter/material.dart';
import '../models/quiz_models.dart';
import '../services/quiz_service.dart';

/// 测验详情页面
class TeacherQuizDetailPage extends StatefulWidget {
  final int quizId;
  
  const TeacherQuizDetailPage({
    super.key,
    required this.quizId,
  });

  @override
  State<TeacherQuizDetailPage> createState() => _TeacherQuizDetailPageState();
}

class _TeacherQuizDetailPageState extends State<TeacherQuizDetailPage> {
  final QuizService _quizService = QuizService();
  final _searchController = TextEditingController();
  
  // 数据
  QuizDetail? _quizDetail;
  List<SubmissionListItem> _submissions = [];
  List<SubmissionListItem> _filteredSubmissions = [];
  QuizOverview? _overview;
  
  // 状态
  bool _isLoading = true;
  String? _errorMessage;
  
  // 排序方式
  String _sortBy = 'score';
  
  // 学生成绩列表（保留作为后备数据）
  List<Map<String, dynamic>> _studentScores = [
    {
      'studentId': '20210001',
      'studentName': '张三',
      'studentClass': '计算机21-1班',
      'score': 92,
      'timeUsed': 78,
      'status': '优秀',
      'statusColor': const Color(0xFF10B981),
      'avatar': '张',
      'avatarColor': const Color(0xFF3B82F6),
    },
    {
      'studentId': '20210002',
      'studentName': '李四',
      'studentClass': '计算机21-1班',
      'score': 88,
      'timeUsed': 85,
      'status': '良好',
      'statusColor': const Color(0xFF10B981),
      'avatar': '李',
      'avatarColor': const Color(0xFF10B981),
    },
    {
      'studentId': '20210003',
      'studentName': '王五',
      'studentClass': '计算机21-2班',
      'score': 75,
      'timeUsed': 90,
      'status': '中等',
      'statusColor': const Color(0xFF3B82F6),
      'avatar': '王',
      'avatarColor': const Color(0xFFF59E0B),
    },
    {
      'studentId': '20210004',
      'studentName': '赵六',
      'studentClass': '计算机21-2班',
      'score': 58,
      'timeUsed': 90,
      'status': '不及格',
      'statusColor': const Color(0xFFEF4444),
      'avatar': '赵',
      'avatarColor': const Color(0xFFEF4444),
    },
  ];
  
  // 筛选的学生列表
  List<Map<String, dynamic>> _filteredStudents = [];
  
  // 选中的学生
  Set<String> _selectedStudents = {};
  
  // 是否全选
  bool _isAllSelected = false;

  @override
  void initState() {
    super.initState();
    _filteredStudents = List.from(_studentScores);
    _loadData();
  }
  
  /// 加载所有数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔍 开始加载测验详情，quizId: ${widget.quizId}');
      
      // 加载测验详情和提交列表（必需）
      final detail = await _quizService.getQuizDetail(widget.quizId);
      print('✅ 测验详情加载成功: ${detail.title}');
      print('📊 统计数据: 总人数=${detail.statistics.totalParticipants}, 平均分=${detail.statistics.averageScore}');
      print('📈 分数分布: 0-59=${detail.statistics.range0to59}, 60-69=${detail.statistics.range60to69}, 70-79=${detail.statistics.range70to79}, 80-89=${detail.statistics.range80to89}, 90-100=${detail.statistics.range90to100}');
      
      final submissionResponse = await _quizService.getQuizSubmissions(
        quizId: widget.quizId, 
        pageSize: 100,
      );
      print('✅ 提交列表加载成功: ${submissionResponse.items.length}条记录');

      setState(() {
        _quizDetail = detail;
        _submissions = submissionResponse.items;
        _filteredSubmissions = _submissions;
        _isLoading = false;
      });
      
      print('✅ 数据已设置到状态，准备显示');
      
      // 尝试加载overview（可选，失败不影响主流程）
      try {
        final overview = await _quizService.getTeacherQuizOverview(widget.quizId);
        setState(() {
          _overview = overview;
        });
        print('✅ Overview加载成功');
      } catch (e) {
        print('⚠️ 加载overview失败（非关键错误）: $e');
        // overview失败不影响主流程，继续显示
      }
      
      _sortStudents();
    } catch (e, stackTrace) {
      print('❌ 加载失败: $e');
      print('堆栈: $stackTrace');
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
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
            const Text(
              '测验详情',
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _quizDetail?.title ?? '加载中...',
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: Color(0xFF333333)),
          ),
          IconButton(
            onPressed: _exportResults,
            icon: const Icon(Icons.download, color: Color(0xFF333333)),
          ),
          IconButton(
            onPressed: _editQuiz,
            icon: const Icon(Icons.edit, color: Color(0xFF333333)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
        child: Column(
          children: [
            // 测验信息
            _buildQuizInfo(),
            
            // 成绩分布
            _buildScoreDistribution(),
            
            // 搜索和筛选
            _buildSearchAndFilter(),
            
            // 学生成绩
            _buildStudentScores(),
          ],
        ),
      ),
    );
  }

  /// 构建测验信息
  Widget _buildQuizInfo() {
    if (_quizDetail == null) return const SizedBox.shrink();
    
    final statusInfo = _getStatusInfo(_quizDetail!.status);
    // 修复：统计已提交的学生数（包括submitted和graded状态）
    final submittedCount = _submissions.where((s) {
      final status = s.status.toUpperCase();
      return status == 'SUBMITTED' || status == 'GRADED';
    }).length;
    
    print('📊 统计信息计算: submittedCount=$submittedCount, totalParticipants=${_quizDetail!.totalParticipants}');
    print('📊 通过率: passRate=${_quizDetail!.passRate}');
    
    return Container(
      margin: const EdgeInsets.all(16),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _quizDetail!.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_quizDetail!.courseName} · ${_formatDateTimeRange(_quizDetail!.startTime, _quizDetail!.endTime)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusInfo['color'],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  statusInfo['label'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  value: '$submittedCount/${_quizDetail!.totalParticipants}',
                  label: '参与人数',
                  color: const Color(0xFF3B82F6),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  value: _quizDetail!.averageScore.toStringAsFixed(1),
                  label: '平均分',
                  color: const Color(0xFF10B981),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  value: '${_quizDetail!.passRate.toStringAsFixed(0)}%',
                  label: '通过率',
                  color: const Color(0xFFF59E0B),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  value: '${_quizDetail!.durationMinutes}\n分钟',
                  label: '测验时长',
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 获取状态信息
  Map<String, dynamic> _getStatusInfo(String status) {
    final normalizedStatus = status.toUpperCase();
    
    switch (normalizedStatus) {
      case 'NOT_STARTED':
      case 'PUBLISHED':
        return {'label': '待开始', 'color': const Color(0xFF8B5CF6)};
      case 'IN_PROGRESS':
      case 'ONGOING':
        return {'label': '进行中', 'color': const Color(0xFFF59E0B)};
      case 'ENDED':
        return {'label': '已结束', 'color': const Color(0xFF10B981)};
      default:
        return {'label': '未知', 'color': const Color(0xFF666666)};
    }
  }
  
  /// 格式化日期时间范围
  String _formatDateTimeRange(String startTime, String endTime) {
    try {
      final start = DateTime.parse(startTime);
      final end = DateTime.parse(endTime);
      return '${start.month}-${start.day} ${start.hour}:${start.minute.toString().padLeft(2, '0')}-${end.hour}:${end.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '$startTime-$endTime';
    }
  }

  /// 构建信息项目
  Widget _buildInfoItem({
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  /// 构建成绩分布
  Widget _buildScoreDistribution() {
    if (_quizDetail == null) return const SizedBox.shrink();
    
    final stats = _quizDetail!.statistics;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          const Text(
            '成绩分布',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 简化的柱状图
          SizedBox(
            height: 200,
            child: _buildSimpleBarChart(),
          ),
          
          const SizedBox(height: 16),
          
          // 分布统计（使用真实数据）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDistributionItem('${stats.range0to59}', '0-59分', const Color(0xFFEF4444)),
              _buildDistributionItem('${stats.range60to69}', '60-69分', const Color(0xFFF59E0B)),
              _buildDistributionItem('${stats.range70to79}', '70-79分', const Color(0xFF3B82F6)),
              _buildDistributionItem('${stats.range80to89}', '80-89分', const Color(0xFF10B981)),
              _buildDistributionItem('${stats.range90to100}', '90-100分', const Color(0xFF8B5CF6)),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建简单的柱状图
  Widget _buildSimpleBarChart() {
    if (_quizDetail == null) {
      return const Center(child: Text('暂无数据'));
    }
    
    final stats = _quizDetail!.statistics;
    final data = [
      {'value': stats.range0to59, 'color': const Color(0xFFEF4444), 'label': '0-59'},
      {'value': stats.range60to69, 'color': const Color(0xFFF59E0B), 'label': '60-69'},
      {'value': stats.range70to79, 'color': const Color(0xFF3B82F6), 'label': '70-79'},
      {'value': stats.range80to89, 'color': const Color(0xFF10B981), 'label': '80-89'},
      {'value': stats.range90to100, 'color': const Color(0xFF8B5CF6), 'label': '90-100'},
    ];
    
    final maxValue = data.map((d) => d['value'] as int).reduce((a, b) => a > b ? a : b).toDouble();
    final displayMaxValue = maxValue > 0 ? ((maxValue / 5).ceil() * 5).toDouble() : 10.0;
    
    return Column(
      children: [
        // Y轴标签
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Y轴
              SizedBox(
                width: 30,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${displayMaxValue.toInt()}', style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
                    Text('${(displayMaxValue * 0.75).toInt()}', style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
                    Text('${(displayMaxValue * 0.5).toInt()}', style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
                    Text('${(displayMaxValue * 0.25).toInt()}', style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
                    const Text('0', style: TextStyle(fontSize: 10, color: Color(0xFF666666))),
                  ],
                ),
              ),
              
              // 柱状图
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: data.map((item) {
                    final value = (item['value'] as int).toDouble();
                    final height = displayMaxValue > 0 ? (value / displayMaxValue * 150) : 0.0;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 40,
                          height: height,
                          decoration: BoxDecoration(
                            color: item['color'] as Color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // X轴标签
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: data.map((item) {
              return Text(
                item['label'] as String,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF666666),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 构建分布项目
  Widget _buildDistributionItem(String count, String range, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          range,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  /// 构建搜索和筛选
  Widget _buildSearchAndFilter() {
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
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索学生姓名',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF666666)),
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
              onChanged: _filterStudents,
            ),
          ),
          
          const SizedBox(width: 12),
          
          DropdownButton<String>(
            value: _sortBy,
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
                _sortStudents();
              });
            },
            items: const [
              DropdownMenuItem(value: 'score', child: Text('分数从高到低')),
              DropdownMenuItem(value: 'name', child: Text('按姓名')),
              DropdownMenuItem(value: 'time', child: Text('按用时')),
            ],
            style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
            underline: Container(),
          ),
        ],
      ),
    );
  }

  /// 构建学生成绩
  Widget _buildStudentScores() {
    // 如果有真实数据，使用真实数据；否则使用假数据
    final displayData = _submissions.isNotEmpty ? _filteredSubmissions : _filteredStudents;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
        children: [
          // 列表头部
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Text(
                  '学生成绩 (${displayData.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                
                const Spacer(),
                
                // 全选
                Row(
                  children: [
                    Checkbox(
                      value: _isAllSelected,
                      onChanged: _toggleSelectAll,
                      activeColor: const Color(0xFF4CAF50),
                    ),
                    const Text(
                      '全选',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                // 批量操作
                TextButton.icon(
                  onPressed: _selectedStudents.isNotEmpty ? _showBatchActions : null,
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('批量操作'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4CAF50),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // 学生列表
          if (displayData.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Text(
                '暂无学生提交',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else if (_submissions.isNotEmpty)
            // 使用真实submission数据
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _filteredSubmissions.length,
              itemBuilder: (context, index) {
                return _buildSubmissionItem(_filteredSubmissions[index]);
              },
            )
          else
            // 使用假数据（向后兼容）
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _filteredStudents.length,
              itemBuilder: (context, index) {
                return _buildStudentItem(_filteredStudents[index]);
              },
            ),
        ],
      ),
    );
  }
  
  /// 构建提交项（使用真实API数据）
  Widget _buildSubmissionItem(SubmissionListItem submission) {
    final isSelected = _selectedStudents.contains(submission.studentId.toString());
    
    // 根据分数确定颜色和状态
    Color scoreColor;
    String status;
    if (submission.score >= 90) {
      scoreColor = const Color(0xFF10B981);
      status = '优秀';
    } else if (submission.score >= 80) {
      scoreColor = const Color(0xFF3B82F6);
      status = '良好';
    } else if (submission.score >= 60) {
      scoreColor = const Color(0xFFF59E0B);
      status = '及格';
    } else {
      scoreColor = const Color(0xFFEF4444);
      status = '不及格';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4CAF50).withOpacity(0.1) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          // 选择框
          Checkbox(
            value: isSelected,
            onChanged: (value) => _toggleStudentSelection(submission.studentId.toString()),
            activeColor: const Color(0xFF4CAF50),
          ),
          
          const SizedBox(width: 12),
          
          // 头像
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scoreColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                submission.studentName.isNotEmpty ? submission.studentName[0] : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
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
                  submission.studentName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${submission.studentNumber}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          
          // 成绩和用时
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${submission.score.toStringAsFixed(1)}分',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: scoreColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              Text(
                '用时: ${submission.timeUsed}分钟',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 12),
          
          // 查看答卷
          IconButton(
            onPressed: () => _viewAnswerSheet(submission.submissionId),
            icon: const Icon(Icons.visibility_outlined, size: 20),
            color: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  /// 构建学生项目
  Widget _buildStudentItem(Map<String, dynamic> student) {
    final isSelected = _selectedStudents.contains(student['studentId']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4CAF50).withOpacity(0.1) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          // 选择框
          Checkbox(
            value: isSelected,
            onChanged: (value) => _toggleStudentSelection(student['studentId']),
            activeColor: const Color(0xFF4CAF50),
          ),
          
          const SizedBox(width: 12),
          
          // 头像
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: student['avatarColor'],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                student['avatar'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
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
                  student['studentName'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${student['studentId']} · ${student['studentClass']}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          
          // 成绩和用时
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${student['score']}分',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: student['statusColor'],
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: student['statusColor'],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      student['status'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              Text(
                '用时: ${student['timeUsed']}分钟',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 8),
          
          // 更多操作
          IconButton(
            onPressed: () => _showStudentActions(student),
            icon: const Icon(Icons.chevron_right, color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }

  /// 筛选学生
  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = List.from(_studentScores);
      } else {
        _filteredStudents = _studentScores.where((student) {
          return student['studentName'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
      _sortStudents();
    });
  }

  /// 排序学生
  void _sortStudents() {
    setState(() {
      // 如果有真实数据，对submission排序
      if (_submissions.isNotEmpty) {
        switch (_sortBy) {
          case 'score':
            _filteredSubmissions.sort((a, b) => b.score.compareTo(a.score));
            break;
          case 'name':
            _filteredSubmissions.sort((a, b) => a.studentName.compareTo(b.studentName));
            break;
          case 'time':
            _filteredSubmissions.sort((a, b) => a.timeUsed.compareTo(b.timeUsed));
            break;
        }
      } else {
        // 否则对假数据排序
        switch (_sortBy) {
          case 'score':
            _filteredStudents.sort((a, b) => b['score'].compareTo(a['score']));
            break;
          case 'name':
            _filteredStudents.sort((a, b) => a['studentName'].compareTo(b['studentName']));
            break;
          case 'time':
            _filteredStudents.sort((a, b) => a['timeUsed'].compareTo(b['timeUsed']));
            break;
        }
      }
    });
  }
  
  /// 查看答卷
  void _viewAnswerSheet(int submissionId) {
    // TODO: 导航到答卷详情页
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('查看答卷 ID: $submissionId'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 切换全选
  void _toggleSelectAll(bool? value) {
    setState(() {
      _isAllSelected = value ?? false;
      if (_isAllSelected) {
        _selectedStudents = _filteredStudents.map((s) => s['studentId'] as String).toSet();
      } else {
        _selectedStudents.clear();
      }
    });
  }

  /// 切换学生选择
  void _toggleStudentSelection(String studentId) {
    setState(() {
      if (_selectedStudents.contains(studentId)) {
        _selectedStudents.remove(studentId);
      } else {
        _selectedStudents.add(studentId);
      }
      _isAllSelected = _selectedStudents.length == _filteredStudents.length;
    });
  }

  /// 显示批量操作
  void _showBatchActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '批量操作 (${_selectedStudents.length}个学生)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('导出成绩'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('发送通知'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示学生操作
  void _showStudentActions(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              student['studentName'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('查看答题详情'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('发送消息'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 导出结果
  void _exportResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('测验结果导出功能开发中'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 编辑测验
  void _editQuiz() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('编辑测验功能开发中'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
