import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/assignment_service.dart';
import '../models/assignment_models.dart';
import 'assignment_detail_page.dart';

/// 作业中心作业模型
class CenterAssignment {
  final String id;
  final String title;
  final String courseName;
  final String teacherName;
  final String description;
  final DateTime deadline;
  final AssignmentStatus status;
  final AssignmentType type;
  final bool isUrgent;
  final int totalScore;

  CenterAssignment({
    required this.id,
    required this.title,
    required this.courseName,
    required this.teacherName,
    required this.description,
    required this.deadline,
    required this.status,
    required this.type,
    required this.isUrgent,
    required this.totalScore,
  });

  /// 获取剩余时间文本
  String get timeLeftText {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    if (difference.isNegative) {
      return '已逾期';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天后 ${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时后';
    } else {
      return '${difference.inMinutes}分钟后';
    }
  }
}

/// 作业中心页面
class AssignmentCenterPage extends StatefulWidget {
  const AssignmentCenterPage({super.key});

  @override
  State<AssignmentCenterPage> createState() => _AssignmentCenterPageState();
}

class _AssignmentCenterPageState extends State<AssignmentCenterPage> {
  String _selectedFilter = '全部';
  List<StudentAssignment> _assignments = [];
  List<StudentAssignment> _filteredAssignments = [];
  bool _isLoading = true;
  String? _error;

  final List<String> _filterTabs = ['全部', '待提交', '待批改', '已完成', '已逾期'];

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
      
      print('Debug: [作业中心] 开始加载作业数据');
      print('Debug: [作业中心] Token获取结果: ${token != null ? "成功" : "失败"}');
      
      if (token == null) {
        throw Exception('用户未登录');
      }

      print('Debug: [作业中心] 调用AssignmentService.getStudentAssignments');
      final response = await AssignmentService.getStudentAssignments(
        token: token,
        status: 'all',
        page: 1,
        pageSize: 50,
      );

      print('Debug: [作业中心] API响应: $response');
      
      if (response['error'] == 0) {
        final List<dynamic> assignmentList = response['body']['assignments'] ?? [];
        print('Debug: [作业中心] 解析到作业数量: ${assignmentList.length}');
        
        setState(() {
          _assignments = [];
          for (int i = 0; i < assignmentList.length; i++) {
            try {
              final json = assignmentList[i];
              print('Debug: [作业中心] 解析作业数据 $i: $json');
              final assignment = StudentAssignment.fromJson(json);
              _assignments.add(assignment);
              print('Debug: [作业中心] 作业 $i 解析成功: ${assignment.assignment.title}');
            } catch (e) {
              print('Debug: [作业中心] 作业 $i 解析失败: $e');
              print('Debug: [作业中心] 失败的数据: ${assignmentList[i]}');
            }
          }
          print('Debug: [作业中心] 转换完成，总作业数: ${_assignments.length}');
          _filterAssignments();
          _isLoading = false;
        });
      } else {
        print('Debug: [作业中心] API返回错误: ${response['message']}');
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
    setState(() {
      if (_selectedFilter == '全部') {
        _filteredAssignments = _assignments;
      } else {
        _filteredAssignments = _assignments.where((assignment) {
          switch (_selectedFilter) {
            case '待提交':
              return assignment.submissionStatus == SubmissionStatus.notSubmitted;
            case '待批改':
              return assignment.submissionStatus == SubmissionStatus.submitted ||
                     assignment.submissionStatus == SubmissionStatus.grading;
            case '已完成':
              return assignment.submissionStatus == SubmissionStatus.graded;
            case '已逾期':
              return assignment.submissionStatus == SubmissionStatus.overdue;
            default:
              return true;
          }
        }).toList();
      }
    });
  }

  /// 获取统计数据
  Map<SubmissionStatus, int> _getStatistics() {
    final stats = <SubmissionStatus, int>{};
    for (final status in SubmissionStatus.values) {
      stats[status] = _assignments.where((a) => a.submissionStatus == status).length;
    }
    return stats;
  }

  /// 处理作业点击
  void _onAssignmentTap(StudentAssignment assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentDetailPage(
          assignmentId: assignment.assignment.id.toString(),
          assignmentTitle: assignment.assignment.title,
          courseName: assignment.assignment.courseName,
          teacherName: assignment.assignment.teacherName,
        ),
      ),
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
    final stats = _getStatistics();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '作业中心',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF666666)),
            onPressed: _showFilterMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          // 统计卡片
          _buildStatsCards(stats),
          
          // 筛选标签
          _buildFilterTabs(),
          
          // 作业列表
          Expanded(
            child: _buildAssignmentsList(),
          ),
        ],
      ),
    );
  }

  /// 构建统计卡片
  Widget _buildStatsCards(Map<SubmissionStatus, int> stats) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              value: stats[SubmissionStatus.notSubmitted] ?? 0,
              label: '待提交',
              color: const Color(0xFFFF9800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              value: (stats[SubmissionStatus.submitted] ?? 0) + (stats[SubmissionStatus.grading] ?? 0),
              label: '待批改',
              color: const Color(0xFF4285F4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              value: stats[SubmissionStatus.graded] ?? 0,
              label: '已完成',
              color: const Color(0xFF4CAF50),
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
              _filterAssignments();
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

  /// 构建作业列表
  Widget _buildAssignmentsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
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

    if (_filteredAssignments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '暂无作业',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssignments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredAssignments.length,
        itemBuilder: (context, index) {
          final assignment = _filteredAssignments[index];
          return _buildAssignmentCard(assignment);
        },
      ),
    );
  }

  /// 构建作业卡片
  Widget _buildAssignmentCard(StudentAssignment assignment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: (assignment.assignment.remainingHours <= 24 && !assignment.isOverdue)
            ? const Border(left: BorderSide(color: Color(0xFFE53935), width: 4))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _onAssignmentTap(assignment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和紧急标识
              Row(
                children: [
                  Expanded(
                    child: Text(
                      assignment.assignment.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  if (assignment.assignment.remainingHours <= 24 && !assignment.isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '紧急',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // 课程和教师
              Text(
                '${assignment.assignment.courseName} · ${assignment.assignment.teacherName}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // 作业描述
              Text(
                assignment.assignment.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // 底部信息
              Row(
                children: [
                  // 截止时间
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: assignment.isOverdue 
                        ? const Color(0xFFE53935)
                        : const Color(0xFF999999),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimeLeft(assignment),
                    style: TextStyle(
                      fontSize: 12,
                      color: assignment.isOverdue 
                          ? const Color(0xFFE53935)
                          : const Color(0xFF999999),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // 作业类型
                  Icon(
                    _getTypeIcon(assignment.assignment.type),
                    size: 16,
                    color: const Color(0xFF999999),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    assignment.assignment.type.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // 状态按钮
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(assignment.submissionStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      assignment.submissionStatus.label,
                      style: TextStyle(
                        color: _getStatusColor(assignment.submissionStatus),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 格式化剩余时间
  String _formatTimeLeft(StudentAssignment assignment) {
    if (assignment.isOverdue) {
      return '已逾期';
    }

    final now = DateTime.now();
    final dueTime = assignment.assignment.dueTime;
    final difference = dueTime.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays}天后截止';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时后截止';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟后截止';
    } else {
      return '即将截止';
    }
  }

  /// 获取作业类型图标
  IconData _getTypeIcon(AssignmentType type) {
    switch (type) {
      case AssignmentType.homework:
        return Icons.assignment;
      case AssignmentType.report:
        return Icons.description;
      case AssignmentType.project:
        return Icons.code;
      case AssignmentType.exam:
        return Icons.quiz;
    }
  }

  /// 获取状态颜色
  Color _getStatusColor(SubmissionStatus status) {
    switch (status) {
      case SubmissionStatus.notSubmitted:
        return const Color(0xFFFF9800);
      case SubmissionStatus.submitted:
      case SubmissionStatus.grading:
        return const Color(0xFF4285F4);
      case SubmissionStatus.graded:
        return const Color(0xFF4CAF50);
      case SubmissionStatus.overdue:
        return const Color(0xFFE53935);
    }
  }
}
