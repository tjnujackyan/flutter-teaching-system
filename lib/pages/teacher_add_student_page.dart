import 'package:flutter/material.dart';
import '../services/student_management_service.dart';

/// 添加学生页面
class TeacherAddStudentPage extends StatefulWidget {
  final String? courseId;
  final String? courseName;
  
  const TeacherAddStudentPage({
    super.key,
    this.courseId,
    this.courseName,
  });

  @override
  State<TeacherAddStudentPage> createState() => _TeacherAddStudentPageState();
}

class _TeacherAddStudentPageState extends State<TeacherAddStudentPage> {
  final _searchController = TextEditingController();
  final _studentService = StudentManagementService();
  
  // 搜索结果
  List<StudentInfo> _searchResults = [];
  Set<int> _selectedStudents = {};
  
  // 加载状态
  bool _isSearching = false;
  bool _isAdding = false;
  String? _errorMessage;

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
          '添加学生',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildSearchSection(),
      ),
    );
  }

  /// 构建搜索学生区域
  Widget _buildSearchSection() {
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
          const Text(
            '搜索学生',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 搜索框
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '输入学号或姓名搜索...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF666666)),
              suffixIcon: _isSearching 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF3B82F6)),
              ),
            ),
            onChanged: (value) {
              // 延迟搜索以减少API调用
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_searchController.text == value && value.isNotEmpty) {
                  _performSearch(value);
                }
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // 错误信息
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // 搜索结果
          if (_searchResults.isNotEmpty) ...[
            const Text(
              '搜索结果',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            ..._searchResults.map((student) => _buildSearchResultItem(student)),
            _buildAddSelectedButton(),
          ] else if (_searchController.text.isNotEmpty && !_isSearching) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  '未找到匹配的学生',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建搜索结果项目
  Widget _buildSearchResultItem(StudentInfo student) {
  final isSelected = _selectedStudents.contains(int.parse(student.id));
    final isInCourse = student.isInCourse ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
          if (!isInCourse)
            Checkbox(
              value: isSelected,
              onChanged: (value) => _toggleStudentSelection(int.parse(student.id)),
              activeColor: const Color(0xFF4CAF50),
            ),
          
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
                    fontSize: 14,
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
          
          // 状态标签
          if (isInCourse)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF666666),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '已在课程中',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 添加选中的学生按钮
  Widget _buildAddSelectedButton() {
    if (_selectedStudents.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isAdding ? null : _addSelectedStudents,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isAdding
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text('添加选中的学生 (${_selectedStudents.length})')
      ),
    );
  }


  /// 切换学生选择
  void _toggleStudentSelection(int studentId) {
    setState(() {
      if (_selectedStudents.contains(studentId)) {
        _selectedStudents.remove(studentId);
      } else {
        _selectedStudents.add(studentId);
      }
    });
  }

  /// 执行搜索
  Future<void> _performSearch(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _searchResults.clear();
        _selectedStudents.clear();
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final courseId = widget.courseId != null ? int.parse(widget.courseId!) : null;
      final response = await _studentService.searchStudents(
        keyword: query.trim(),
        excludeCourseId: courseId,
        limit: 20,
      );

      setState(() {
        // 修复数据解析：API返回的是 {data: {students: [...]}} 结构
        final data = response['data'] ?? {};
        final students = data['students'] ?? [];
        _searchResults = students.map<StudentInfo>((json) => StudentInfo.fromJson(json)).toList();
        _selectedStudents.clear();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '搜索失败: $e';
        _searchResults.clear();
        _selectedStudents.clear();
        _isSearching = false;
      });
    }
  }

  /// 添加选中的学生
  Future<void> _addSelectedStudents() async {
    if (_selectedStudents.isEmpty || widget.courseId == null) return;

    setState(() {
      _isAdding = true;
      _errorMessage = null;
    });

    try {
      final response = await _studentService.addStudentsToCourse(
        courseId: int.parse(widget.courseId!),
       studentIds: _selectedStudents.map((id) => id.toString()).toList(),
        enrollmentType: 'manual',
        sendNotification: true,
      );

      // 修复API响应数据解析
      print('添加学生API响应: $response');
      final data = response['data'] ?? response;
      final successCount = data['successCount'] ?? data['addedCount'] ?? _selectedStudents.length;
      final failureCount = data['failureCount'] ?? data['failedCount'] ?? 0;
      print('解析结果 - 成功: $successCount, 失败: $failureCount');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功添加 $successCount 个学生' +
                (failureCount > 0 ? '，$failureCount 个失败' : '')),
            backgroundColor: successCount > 0 ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
          ),
        );

        if (successCount > 0) {
          // 返回true表示成功添加了学生，父页面需要刷新
          Navigator.pop(context, {'success': true, 'addedCount': successCount});
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '添加学生失败: $e';
      });
    } finally {
      setState(() {
        _isAdding = false;
      });
    }
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
