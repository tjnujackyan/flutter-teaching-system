import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/assignment_service.dart';
import '../models/assignment_models.dart';
import 'teacher_assignment_grading_page.dart';

/// 作业管理页面
class TeacherAssignmentManagementPage extends StatefulWidget {
  final String? courseId;
  final String? courseName;
  
  const TeacherAssignmentManagementPage({
    super.key,
    this.courseId,
    this.courseName,
  });

  @override
  State<TeacherAssignmentManagementPage> createState() => _TeacherAssignmentManagementPageState();
}

class _TeacherAssignmentManagementPageState extends State<TeacherAssignmentManagementPage> {
  final _searchController = TextEditingController();
  
  // 筛选条件
  String _sortBy = 'deadline';
  String _selectedStatus = 'all';
  
  // 作业列表
  List<Assignment> _assignments = [];
  List<Assignment> _filteredAssignments = [];
  
  // 加载状态
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  /// 加载作业数据
  Future<void> _loadAssignments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final token = await ApiService.getAuthToken();
      
      if (token == null) {
        throw Exception('用户未登录');
      }

      final courseIdInt = widget.courseId != null ? int.tryParse(widget.courseId!) : null;
      print('Debug: widget.courseId=${widget.courseId}, courseIdInt=$courseIdInt');
      
      final response = await AssignmentService.getTeacherAssignments(
        token: token,
        courseId: courseIdInt,
        status: _selectedStatus,
        keyword: _searchController.text.isNotEmpty ? _searchController.text : null,
        page: 1,
        pageSize: 50,
      );

      print('Debug: API响应完整数据: $response');
      
      if (response['error'] == 0) {
        print('Debug: 响应成功，body内容: ${response['body']}');
        final List<dynamic> assignmentList = response['body']['assignments'] ?? [];
        print('Debug: 解析到的作业列表: $assignmentList');
        print('Debug: 作业数量: ${assignmentList.length}');
        
        setState(() {
          try {
            _assignments = assignmentList
                .map((json) {
                  print('Debug: 正在转换作业数据: $json');
                  final assignment = Assignment.fromJson(json);
                  print('Debug: 转换成功: ${assignment.title}');
                  return assignment;
                })
                .toList();
            print('Debug: 所有作业转换完成，总数: ${_assignments.length}');
            _filterAssignments();
            _isLoading = false;
          } catch (e) {
            print('Debug: 作业数据转换失败: $e');
            _isLoading = false;
            _error = '数据解析失败: $e';
          }
        });
      } else {
        throw Exception(response['message'] ?? '获取作业列表失败');
      }
    } catch (e) {
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

  /// 筛选作业
  void _filterAssignments() {
    print('Debug: 开始筛选作业，原始数量: ${_assignments.length}');
    print('Debug: 搜索关键词: "${_searchController.text}"');
    
    setState(() {
      _filteredAssignments = _assignments.where((assignment) {
        // 搜索关键词筛选
        if (_searchController.text.isNotEmpty) {
          final keyword = _searchController.text.toLowerCase();
          if (!assignment.title.toLowerCase().contains(keyword)) {
            print('Debug: 作业 "${assignment.title}" 被搜索过滤掉');
            return false;
          }
        }
        return true;
      }).toList();
      
      print('Debug: 筛选后作业数量: ${_filteredAssignments.length}');
      
      // 排序
      _filteredAssignments.sort((a, b) {
        switch (_sortBy) {
          case 'deadline':
            return a.dueTime.compareTo(b.dueTime);
          case 'title':
            return a.title.compareTo(b.title);
          case 'status':
            return a.status.value.compareTo(b.status.value);
          default:
            return 0;
        }
      });
    });
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
          '作业管理',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // 作业概览
          _buildAssignmentOverview(),
          
          // 搜索和筛选
          _buildSearchAndFilter(),
          
          // 作业列表
          Expanded(
            child: _buildAssignmentList(),
          ),
        ],
      ),
    );
  }

  /// 构建作业概览
  Widget _buildAssignmentOverview() {
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
            '作业概览',
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
                  value: _assignments.length.toString(),
                  label: '总作业数',
                  color: const Color(0xFF3B82F6),
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  value: _getPendingGradeCount().toString(),
                  label: '待批改',
                  color: const Color(0xFFF59E0B),
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  value: '${_getAverageSubmissionRate().toStringAsFixed(0)}%',
                  label: '提交率',
                  color: const Color(0xFF10B981),
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
                hintText: '搜索作业标题...',
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
              onChanged: (value) => _filterAssignments(),
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

  /// 构建作业列表
  Widget _buildAssignmentList() {
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
                  '作业列表',
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
                      _filterAssignments();
                    });
                  },
                  items: const [
                    DropdownMenuItem(value: 'deadline', child: Text('按截止时间')),
                    DropdownMenuItem(value: 'status', child: Text('按状态')),
                    DropdownMenuItem(value: 'title', child: Text('按标题')),
                  ],
                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  underline: Container(),
                ),
              ],
            ),
          ),
          
          // 作业列表内容
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _filteredAssignments.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadAssignments,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredAssignments.length,
                              itemBuilder: (context, index) {
                                return _buildAssignmentItem(_filteredAssignments[index]);
                              },
                            ),
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
            Icons.assignment_outlined,
            size: 64,
            color: Color(0xFF666666),
          ),
          SizedBox(height: 16),
          Text(
            '暂无作业',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '点击右上角添加作业',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
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
              title: const Text('按截止时间'),
              onTap: () {
                setState(() {
                  _sortBy = 'deadline';
                  _filterAssignments();
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
                  _filterAssignments();
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
                  _filterAssignments();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 导航到创建作业页面
  void _navigateToCreateAssignment() {
    // 这里应该导航到作业创建页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('跳转到创建作业页面'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 导航到作业批改页面
  void _navigateToGrading(Assignment assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherAssignmentGradingPage(
          assignment: {
            'id': assignment.id.toString(),
            'title': assignment.title,
            'courseName': assignment.courseName,
          },
        ),
      ),
    ).then((result) {
      if (result == true) {
        // 批改完成，可以刷新页面数据
        _loadAssignments();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('作业批改完成'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    });
  }

  /// 获取待批改作业数量
  int _getPendingGradeCount() {
    return _assignments.where((assignment) => 
      assignment.submissionCount > assignment.gradedCount
    ).length;
  }

  /// 获取平均提交率
  double _getAverageSubmissionRate() {
    if (_assignments.isEmpty) return 0.0;
    
    double totalRate = 0.0;
    int validAssignments = 0;
    
    for (final assignment in _assignments) {
      if (assignment.submissionCount > 0) {
        totalRate += assignment.completionRate;
        validAssignments++;
      }
    }
    
    return validAssignments > 0 ? totalRate / validAssignments : 0.0;
  }

  /// 构建错误状态
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadAssignments,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 构建作业项目
  Widget _buildAssignmentItem(Assignment assignment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  assignment.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(assignment.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  assignment.status.label,
                  style: TextStyle(
                    color: _getStatusColor(assignment.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '截止时间: ${_formatDateTime(assignment.dueTime)}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Text(
                '总分: ${assignment.totalScore}分',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _navigateToGrading(assignment),
                child: const Text('批改作业'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 获取状态颜色
  Color _getStatusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.draft:
        return const Color(0xFF6B7280);
      case AssignmentStatus.published:
        return const Color(0xFF3B82F6);
      case AssignmentStatus.closed:
        return const Color(0xFF10B981);
      case AssignmentStatus.archived:
        return const Color(0xFF9CA3AF);
    }
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
