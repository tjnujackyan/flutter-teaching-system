import 'package:flutter/material.dart';
import 'course_detail_page.dart';
import '../services/student_service.dart';

/// 课程状态枚举
enum CourseStatus {
  ongoing('进行中'),
  completed('已完成'),
  pending('待开始');

  const CourseStatus(this.label);
  final String label;
}

/// 课程模型
class Course {
  final String id;
  final String name;
  final String teacher;
  final String department;
  final int totalHours;
  final int completedHours;
  final CourseStatus status;
  final Color iconColor;
  final IconData iconData;
  final int studentCount;

  Course({
    required this.id,
    required this.name,
    required this.teacher,
    required this.department,
    required this.totalHours,
    required this.completedHours,
    required this.status,
    required this.iconColor,
    required this.iconData,
    required this.studentCount,
  });

  double get progress => totalHours > 0 ? completedHours / totalHours : 0.0;
}

/// 学生课程页面
class StudentCoursesPage extends StatefulWidget {
  const StudentCoursesPage({super.key});

  @override
  State<StudentCoursesPage> createState() => _StudentCoursesPageState();
}

class _StudentCoursesPageState extends State<StudentCoursesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = '全部';
  List<Course> _courses = [];
  List<Course> _filteredCourses = [];
  
  // 数据状态
  bool _isLoading = true;
  String? _error;
  int _totalCount = 0;
  int _currentPage = 1;
  bool _hasMore = false;

  final List<String> _filterTabs = ['全部', '进行中', '已完成', '待开始', '计算机', '数学'];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }
  
  /// 加载课程数据
  Future<void> _loadCourses({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        _currentPage = 1;
      }
      
      setState(() {
        if (isRefresh) {
          _courses.clear();
          _filteredCourses.clear();
        }
        _isLoading = true;
        _error = null;
      });
      
      print('Debug: [学生课程] 开始加载课程数据');
      
      // 构建查询参数
      String? statusFilter;
      String? categoryFilter;
      
      switch (_selectedFilter) {
        case '进行中':
          statusFilter = 'ongoing';
          break;
        case '已完成':
          statusFilter = 'completed';
          break;
        case '待开始':
          statusFilter = 'pending';
          break;
        case '计算机':
          categoryFilter = 'computer';
          break;
        case '数学':
          categoryFilter = 'math';
          break;
      }
      
      final response = await StudentService.getStudentCourses(
        keyword: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        status: statusFilter,
        category: categoryFilter,
        page: _currentPage,
        pageSize: 20,
      );
      
      final coursesData = response['courses'] as List<dynamic>? ?? [];
      final newCourses = coursesData.map((courseData) => _mapToCourse(courseData)).toList();
      
      // 打印课程数据，检查教师名称
      for (var courseData in coursesData) {
        print('Debug: [学生课程] 课程: ${courseData['name']}, 教师: ${courseData['teacher']}');
      }
      
      if (mounted) {
        setState(() {
          if (isRefresh) {
            _courses = newCourses;
          } else {
            _courses.addAll(newCourses);
          }
          _filteredCourses = _courses;
          _totalCount = response['totalCount'] ?? 0;
          _hasMore = response['hasNext'] ?? false;
          _isLoading = false;
        });
        print('Debug: [学生课程] 课程数据加载成功: ${_courses.length}门课程');
      }
    } catch (e) {
      print('Debug: [学生课程] 课程数据加载失败: $e');
      if (mounted) {
        setState(() {
          _error = '加载失败: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  /// 将API数据映射为Course模型
  Course _mapToCourse(Map<String, dynamic> courseData) {
    return Course(
      id: courseData['id']?.toString() ?? '',
      name: courseData['name'] ?? '',
      teacher: courseData['teacher'] ?? '',
      department: courseData['department'] ?? '',
      totalHours: courseData['totalHours'] ?? 0,
      completedHours: courseData['completedHours'] ?? 0,
      status: _mapCourseStatus(courseData['status'] ?? 'pending'),
      iconColor: _parseColor(courseData['iconColor'] ?? '#4285F4'),
      iconData: _parseIconData(courseData['iconData'] ?? 'code'),
      studentCount: courseData['studentCount'] ?? 0,
    );
  }
  
  /// 映射课程状态
  CourseStatus _mapCourseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return CourseStatus.ongoing;
      case 'completed':
        return CourseStatus.completed;
      case 'pending':
      case 'upcoming':
        return CourseStatus.pending;
      default:
        return CourseStatus.pending;
    }
  }
  
  /// 解析颜色
  Color _parseColor(String colorStr) {
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF4285F4);
    }
  }
  
  /// 解析图标
  IconData _parseIconData(String iconStr) {
    switch (iconStr.toLowerCase()) {
      case 'code':
        return Icons.code;
      case 'calculate':
        return Icons.calculate;
      case 'storage':
        return Icons.storage;
      case 'functions':
        return Icons.functions;
      case 'computer':
        return Icons.computer;
      case 'science':
        return Icons.science;
      default:
        return Icons.book;
    }
  }
  
  /// 刷新数据
  Future<void> _refreshData() async {
    await _loadCourses(isRefresh: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  /// 筛选课程
  void _filterCourses() {
    // 重新加载数据，因为筛选条件发生了变化
    _loadCourses(isRefresh: true);
  }

  /// 处理课程点击
  void _onCourseTap(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailPage(course: course),
      ),
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
          '我的课程',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF666666)),
            onPressed: () {
              // 聚焦搜索框
              FocusScope.of(context).requestFocus(FocusNode());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _filterCourses(),
              decoration: InputDecoration(
                hintText: '搜索课程名称或教师',
                hintStyle: const TextStyle(color: Color(0xFF999999)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF999999)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // 筛选标签
          Container(
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
                    _filterCourses();
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
          ),

          const SizedBox(height: 8),

          // 课程列表
          Expanded(
            child: _buildCourseList(),
          ),
        ],
      ),
    );
  }
  
  /// 构建课程列表
  Widget _buildCourseList() {
    if (_isLoading && _courses.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_error != null && _courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    
    if (_courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无课程',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredCourses.length,
        itemBuilder: (context, index) {
          final course = _filteredCourses[index];
          return _buildCourseCard(course);
        },
      ),
    );
  }

  /// 构建课程卡片
  Widget _buildCourseCard(Course course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: () => _onCourseTap(course),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // 课程图标
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: course.iconColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                course.iconData,
                color: Colors.white,
                size: 28,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // 课程信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 课程名称和状态
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          course.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(course.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          course.status.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(course.status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // 教师和院系
                  Text(
                    '${course.teacher} · ${course.department}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 学时和人数
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${course.studentCount}人',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${course.completedHours}/${course.totalHours}学时',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  // 进度条（仅进行中的课程显示）
                  if (course.status == CourseStatus.ongoing) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: course.progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(course.iconColor),
                      minHeight: 3,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取状态颜色
  Color _getStatusColor(CourseStatus status) {
    switch (status) {
      case CourseStatus.ongoing:
        return const Color(0xFF4285F4);
      case CourseStatus.completed:
        return const Color(0xFF4CAF50);
      case CourseStatus.pending:
        return const Color(0xFFFF9800);
    }
  }
}
