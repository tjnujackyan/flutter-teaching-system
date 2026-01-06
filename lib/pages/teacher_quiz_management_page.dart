import 'package:flutter/material.dart';
import 'teacher_quiz_detail_page.dart';
import '../models/quiz_models.dart';
import '../services/quiz_service.dart';

/// 测验管理页面
class TeacherQuizManagementPage extends StatefulWidget {
  final int? courseId;
  final String? courseName;
  
  const TeacherQuizManagementPage({
    super.key,
    this.courseId,
    this.courseName,
  });

  @override
  State<TeacherQuizManagementPage> createState() => _TeacherQuizManagementPageState();
}

class _TeacherQuizManagementPageState extends State<TeacherQuizManagementPage> {
  final QuizService _quizService = QuizService();
  final _searchController = TextEditingController();
  
  // 筛选条件
  String _sortBy = 'startTime';
  String? _statusFilter;
  
  // 测验列表
  List<QuizListItem> _quizzes = [];
  List<QuizListItem> _filteredQuizzes = [];
  
  // 状态
  bool _isLoading = true;
  String? _errorMessage;
  
  // 统计数据
  int _totalCount = 0;
  int _notStartedCount = 0;
  int _inProgressCount = 0;
  int _endedCount = 0;

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
      final result = await _quizService.getTeacherQuizzes(
        courseId: widget.courseId,
        status: _statusFilter,
        page: 1,
        pageSize: 100,
      );
      
      setState(() {
        _quizzes = result.items;
        _totalCount = result.total;
        _filteredQuizzes = _quizzes;
        _calculateStatistics();
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }
  
  /// 计算统计数据
  void _calculateStatistics() {
    _notStartedCount = _quizzes.where((q) => 
        q.status.toUpperCase() == 'NOT_STARTED' || 
        q.status.toUpperCase() == 'PUBLISHED').length;
    _inProgressCount = _quizzes.where((q) => 
        q.status.toUpperCase() == 'IN_PROGRESS' || 
        q.status.toUpperCase() == 'ONGOING').length;
    _endedCount = _quizzes.where((q) => 
        q.status.toUpperCase() == 'ENDED').length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          '测验管理',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadQuizzes,
            icon: const Icon(Icons.refresh, color: Color(0xFF333333)),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  /// 构建主体内容
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

    return Column(
      children: [
        // 测验概览
        _buildQuizOverview(),
        
        // 搜索和筛选
        _buildSearchAndFilter(),
        
        // 测验列表
        Expanded(
          child: _buildQuizList(),
        ),
      ],
    );
  }

  /// 构建测验概览
  Widget _buildQuizOverview() {
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
          const Text(
            '测验概览',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  value: _totalCount.toString(),
                  label: '总测验数',
                  color: const Color(0xFF3B82F6),
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  value: _endedCount.toString(),
                  label: '已完成',
                  color: const Color(0xFF10B981),
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  value: _inProgressCount.toString(),
                  label: '进行中',
                  color: const Color(0xFFF59E0B),
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  value: _notStartedCount.toString(),
                  label: '待开始',
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建概览项目
  Widget _buildOverviewItem({
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
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
            fontSize: 12,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  /// 构建搜索和筛选
  Widget _buildSearchAndFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                hintText: '搜索测验标题...',
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
              onChanged: _filterQuizzes,
            ),
          ),
          
          const SizedBox(width: 12),
          
          IconButton(
            onPressed: _showSortDialog,
            icon: const Icon(Icons.filter_list, color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }

  /// 构建测验列表
  Widget _buildQuizList() {
    return Container(
      margin: const EdgeInsets.all(16),
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
                const Text(
                  '测验列表',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                
                const Spacer(),
                
                DropdownButton<String>(
                  value: _sortBy,
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                      _applyFilters();
                    });
                  },
                  items: const [
                    DropdownMenuItem(value: 'startTime', child: Text('按开始时间')),
                    DropdownMenuItem(value: 'status', child: Text('按状态')),
                    DropdownMenuItem(value: 'title', child: Text('按标题')),
                  ],
                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  underline: Container(),
                ),
              ],
            ),
          ),
          
          // 测验列表内容
          Expanded(
            child: _filteredQuizzes.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredQuizzes.length,
                    itemBuilder: (context, index) {
                      return _buildQuizItem(_filteredQuizzes[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 64,
            color: Color(0xFF666666),
          ),
          SizedBox(height: 16),
          Text(
            '暂无测验',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '点击右上角添加测验',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建测验项目
  Widget _buildQuizItem(QuizListItem quiz) {
    final statusInfo = _getStatusInfo(quiz.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 测验标题和状态
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${quiz.courseName} · ${_formatDateTime(quiz.startTime)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusInfo['color'] as Color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusInfo['label'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 统计信息
          Row(
            children: [
              _buildStatChip(
                '${quiz.questionCount}题',
                '题目数',
                const Color(0xFF3B82F6),
              ),
              
              const SizedBox(width: 8),
              
              _buildStatChip(
                '${quiz.durationMinutes}分钟',
                '时长',
                const Color(0xFF10B981),
              ),
              
              const SizedBox(width: 8),
              
              _buildStatChip(
                '${quiz.totalScore}分',
                '总分',
                const Color(0xFFF59E0B),
              ),
              
              const Spacer(),
              
              // 操作按钮
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'detail') {
                    _navigateToQuizDetail(quiz);
                  } else if (value == 'delete') {
                    _deleteQuiz(quiz);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'detail', child: Text('查看详情')),
                  const PopupMenuItem(value: 'delete', child: Text('删除测验')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 获取状态信息
  Map<String, dynamic> _getStatusInfo(String status) {
    // 转换为大写以支持后端的小写状态值
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
  
  /// 格式化日期时间
  String _formatDateTime(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr);
      return '${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }
  
  /// 删除测验
  Future<void> _deleteQuiz(QuizListItem quiz) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除测验"${quiz.title}"吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _quizService.deleteQuiz(quiz.id);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('删除成功')),
      );
      
      _loadQuizzes(); // 重新加载列表
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    }
  }

  /// 构建统计芯片
  Widget _buildStatChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  /// 应用筛选
  void _applyFilters() {
    String query = _searchController.text;
    setState(() {
      _filteredQuizzes = _quizzes.where((quiz) {
        final matchesQuery = query.isEmpty || 
            quiz.title.toLowerCase().contains(query.toLowerCase());
        return matchesQuery;
      }).toList();
      
      _sortQuizzes();
    });
  }

  /// 筛选测验
  void _filterQuizzes(String query) {
    _applyFilters();
  }

  /// 排序测验
  void _sortQuizzes() {
    _filteredQuizzes.sort((a, b) {
      switch (_sortBy) {
        case 'startTime':
          return a.startTime.compareTo(b.startTime);
        case 'status':
          return a.status.compareTo(b.status);
        case 'title':
          return a.title.compareTo(b.title);
        default:
          return 0;
      }
    });
  }

  /// 显示排序对话框
  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '排序方式',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('按开始时间'),
              onTap: () {
                setState(() {
                  _sortBy = 'startTime';
                  _applyFilters();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.label),
              title: const Text('按状态'),
              onTap: () {
                setState(() {
                  _sortBy = 'status';
                  _applyFilters();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('按标题'),
              onTap: () {
                setState(() {
                  _sortBy = 'title';
                  _applyFilters();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 导航到创建测验页面
  void _navigateToCreateQuiz() {
    // 这里应该导航到测验创建页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('跳转到创建测验页面'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 导航到测验详情页面
  void _navigateToQuizDetail(QuizListItem quiz) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('测验详情页面开发中'),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherQuizDetailPage(quizId: quiz.id),
      ),
    ).then((_) => _loadQuizzes()); // 返回后刷新列表
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
