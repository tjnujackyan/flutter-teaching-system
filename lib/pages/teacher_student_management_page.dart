import 'package:flutter/material.dart';
import '../services/student_management_service.dart';
import 'teacher_add_student_page.dart';

/// 学生管理页面
class TeacherStudentManagementPage extends StatefulWidget {
  final String? courseId;
  final String? courseName;
  
  const TeacherStudentManagementPage({
    super.key,
    this.courseId,
    this.courseName,
  });

  @override
  State<TeacherStudentManagementPage> createState() => _TeacherStudentManagementPageState();
}

class _TeacherStudentManagementPageState extends State<TeacherStudentManagementPage> {
  final _searchController = TextEditingController();
  final _studentService = StudentManagementService();
  
  // 学生列表数据
  List<StudentInfo> _students = [];
  List<StudentInfo> _filteredStudents = [];
  StudentStatistics? _statistics;
  
  // 选中的学生
  Set<String> _selectedStudents = {};
  bool _isAllSelected = false;
  
  // 加载状态
  bool _isLoading = true;
  String? _errorMessage;
  
  // 分页参数
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  /// 加载学生数据
  Future<void> _loadStudentData() async {
    if (widget.courseId == null) {
      setState(() {
        _errorMessage = '课程ID不能为空';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _studentService.getCourseStudents(
        courseId: int.parse(widget.courseId!),
        keyword: _searchController.text.trim(),
        status: 'active',
        page: _currentPage,
        size: _pageSize,
      );

      setState(() {
        // 修复数据解析：API返回的是 {data: {students: [...], statistics: {...}}} 结构
        print('学生管理页面 - API响应: $response');
        final data = response['data'] ?? {};
        final studentsJson = data['students'] ?? [];
        print('学生管理页面 - 解析到 ${studentsJson.length} 个学生');
        _students = studentsJson.map<StudentInfo>((json) => StudentInfo.fromJson(json)).toList();
        _filteredStudents = List.from(_students);
        _statistics = data['statistics'] != null ? StudentStatistics.fromJson(data['statistics']) : null;
        print('学生管理页面 - 最终学生列表长度: ${_students.length}');
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载学生数据失败: $e';
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
        title: const Text(
          '学生管理',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _exportStudentList,
            icon: const Icon(Icons.download, color: Color(0xFF333333)),
          ),
          IconButton(
            onPressed: _navigateToAddStudent,
            icon: const Icon(Icons.add, color: Color(0xFF333333)),
          ),
        ],
      ),
      body: Column(
        children: [
          // 课程统计
          _buildCourseStats(),
          
          // 搜索和筛选
          _buildSearchAndFilter(),
          
          // 学生列表
          Expanded(
            child: _buildStudentList(),
          ),
        ],
      ),
    );
  }

  /// 构建课程统计
  Widget _buildCourseStats() {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
            '课程统计',
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
                child: _buildStatItem(
                  value: _statistics?.totalStudents?.toString() ?? '0',
                  label: '总学生数',
                  color: const Color(0xFF3B82F6),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  value: _statistics?.activeStudents?.toString() ?? '0',
                  label: '活跃学生',
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建统计项目
  Widget _buildStatItem({
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
                hintText: '搜索学生姓名或学号...',
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
              onChanged: (value) {
                // 延迟搜索以减少API调用
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _filterStudents(value);
                  }
                });
              },
            ),
          ),
          
          const SizedBox(width: 12),
          
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list, color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }

  /// 构建学生列表
  Widget _buildStudentList() {
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
                  '学生列表',
                  style: TextStyle(
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
          
          // 学生列表内容
          Expanded(
            child: _buildStudentListContent(),
          ),
        ],
      ),
    );
  }

  /// 构建学生列表内容
  Widget _buildStudentListContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFF666666),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStudentData,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_filteredStudents.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        return _buildStudentItem(_filteredStudents[index]);
      },
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Color(0xFF666666),
          ),
          SizedBox(height: 16),
          Text(
            '暂无学生',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '点击右上角添加学生',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建学生项目
  Widget _buildStudentItem(StudentInfo student) {
    final isSelected = _selectedStudents.contains(student.id);
    
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
            onChanged: (value) => _toggleStudentSelection(student.id),
            activeColor: const Color(0xFF4CAF50),
          ),
          
          const SizedBox(width: 12),
          
          // 头像
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getAvatarColor(student.name),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                student.name.isNotEmpty ? student.name[0] : '?',
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
                  student.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${student.studentId} · ${student.className ?? '未知班级'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          
          
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
    // 如果是空查询，重新加载数据
    if (query.isEmpty) {
      _loadStudentData();
      return;
    }
    
    // 本地筛选
    setState(() {
      _filteredStudents = _students.where((student) {
        return student.name.toLowerCase().contains(query.toLowerCase()) ||
               student.studentId.contains(query);
      }).toList();
    });
  }

  /// 切换全选
  void _toggleSelectAll(bool? value) {
    setState(() {
      _isAllSelected = value ?? false;
      if (_isAllSelected) {
        _selectedStudents = _filteredStudents.map((s) => s.id).toSet();
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

  /// 显示筛选对话框
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '筛选条件',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('全部学生'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('活跃学生'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('成绩优秀'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
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
              leading: const Icon(Icons.message),
              title: const Text('发送通知'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('导出名单'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('移除学生', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示学生操作
  void _showStudentActions(StudentInfo student) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              student.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('查看详情'),
              onTap: () {
                Navigator.pop(context);
                _showStudentDetail(student);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('发送消息'),
              onTap: () {
                Navigator.pop(context);
                _sendMessageToStudent(student);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑信息'),
              onTap: () {
                Navigator.pop(context);
                _editStudentInfo(student);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('移除学生', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _removeStudent(student);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示学生详情
  void _showStudentDetail(StudentInfo student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getAvatarColor(student.name),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  student.name.isNotEmpty ? student.name[0] : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(student.name),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('学号', student.studentId),
              _buildDetailRow('班级', student.className ?? '未知'),
              _buildDetailRow('邮箱', student.email ?? '未设置'),
              _buildDetailRow('手机', student.phone ?? '未设置'),
              const Divider(),
              const Text('学习情况', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildDetailRow('作业完成率', '${student.assignmentCompletionRate ?? 0}%'),
              _buildDetailRow('测验平均分', '${student.quizAverageScore ?? 0}分'),
              _buildDetailRow('出勤率', '${student.attendanceRate ?? 0}%'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF666666))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// 发送消息给学生
  void _sendMessageToStudent(StudentInfo student) {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('发送消息给 ${student.name}'),
        content: TextField(
          controller: messageController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: '请输入消息内容...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('消息已发送给 ${student.name}'), backgroundColor: const Color(0xFF4CAF50)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }

  /// 编辑学生信息
  void _editStudentInfo(StudentInfo student) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('编辑学生信息功能开发中')),
    );
  }

  /// 移除学生
  void _removeStudent(StudentInfo student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认移除'),
        content: Text('确定要将 ${student.name} 从本课程移除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _studentService.removeStudentFromCourse(
                  courseId: int.parse(widget.courseId!),
                  studentId: int.parse(student.id),
                );
                _loadStudentData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已移除 ${student.name}'), backgroundColor: const Color(0xFF4CAF50)),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('移除失败: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确认移除'),
          ),
        ],
      ),
    );
  }

  /// 导航到添加学生页面
  void _navigateToAddStudent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherAddStudentPage(
          courseId: widget.courseId,
          courseName: widget.courseName,
        ),
      ),
    ).then((result) {
      if (result != null && result is Map && result['success'] == true) {
        // 学生添加成功，刷新页面数据
        _loadStudentData();
        final addedCount = result['addedCount'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功添加 $addedCount 个学生'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    });
  }

  /// 导出学生名单
  void _exportStudentList() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('学生名单导出功能开发中'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 获取头像颜色
  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFFF97316),
      const Color(0xFFEC4899),
    ];
    
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
