import 'package:flutter/material.dart';
import 'teacher_course_create_page.dart';
import 'teacher_course_detail_page.dart';
import '../services/course_service.dart';

/// 教师课程状态枚举
enum TeacherCourseStatus {
  ongoing('进行中', Color(0xFF4CAF50)),
  pending('待开始', Color(0xFFFF9800)),
  completed('已结束', Color(0xFF666666));

  const TeacherCourseStatus(this.label, this.color);
  final String label;
  final Color color;
}

/// 教师课程模型
class TeacherCourse {
  final String id;
  final String name;
  final String code;
  final int studentCount;
  final double rating;
  final int totalHours;
  final TeacherCourseStatus status;
  final Color iconColor;
  final IconData icon;
  final double progress;

  TeacherCourse({
    required this.id,
    required this.name,
    required this.code,
    required this.studentCount,
    required this.rating,
    required this.totalHours,
    required this.status,
    required this.iconColor,
    required this.icon,
    required this.progress,
  });
}

/// 教师课程管理页面
class TeacherCoursesPage extends StatefulWidget {
  const TeacherCoursesPage({super.key});

  @override
  State<TeacherCoursesPage> createState() => _TeacherCoursesPageState();
}

class _TeacherCoursesPageState extends State<TeacherCoursesPage> {
  List<TeacherCourse> _courses = [];
  CourseStatistics? _statistics;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  /// 加载课程列表
  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await CourseService.getTeacherCourses();
      
      if (response.isSuccess && response.body != null) {
        setState(() {
          _statistics = response.body!.statistics;
          _courses = response.body!.courses.map((course) => _convertToCourseModel(course)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? '获取课程列表失败';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '网络错误：$e';
        _isLoading = false;
      });
    }
  }

  /// 转换API课程数据为UI模型
  TeacherCourse _convertToCourseModel(Course course) {
    // 解析图标
    IconData icon = Icons.computer;
    switch (course.icon) {
      case '💻':
        icon = Icons.computer;
        break;
      case '🗄️':
        icon = Icons.storage;
        break;
      case '🌐':
        icon = Icons.network_check;
        break;
      case '📊':
        icon = Icons.analytics;
        break;
      case '🤖':
        icon = Icons.smart_toy;
        break;
      case '🔒':
        icon = Icons.security;
        break;
    }

    // 解析状态
    TeacherCourseStatus status = TeacherCourseStatus.pending;
    switch (course.status) {
      case 'ongoing':
        status = TeacherCourseStatus.ongoing;
        break;
      case 'upcoming':
        status = TeacherCourseStatus.pending;
        break;
      case 'completed':
        status = TeacherCourseStatus.completed;
        break;
    }

    // 解析颜色
    Color iconColor = const Color(0xFF3B82F6);
    try {
      final colorStr = course.color.replaceAll('#', '');
      iconColor = Color(int.parse('FF$colorStr', radix: 16));
    } catch (e) {
      // 使用默认颜色
    }

    return TeacherCourse(
      id: course.id,
      name: course.name,
      code: course.code,
      studentCount: course.studentCount,
      rating: course.rating,
      totalHours: course.totalWeeks * 2, // 假设每周2学时
      status: status,
      iconColor: iconColor,
      icon: icon,
      progress: course.progress / 100.0,
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
          '课程管理',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: FloatingActionButton(
              onPressed: _showCreateCourseDialog,
              backgroundColor: const Color(0xFF4CAF50),
              mini: true,
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            )
          : _errorMessage != null
              ? _buildErrorWidget()
              : RefreshIndicator(
                  onRefresh: _loadCourses,
                  color: const Color(0xFF4CAF50),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // 统计卡片
                        _buildStatsCards(),
                        
                        // 课程列表
                        _buildCoursesList(),
                        
                        const SizedBox(height: 100), // 为底部导航栏留出空间
                      ],
                    ),
                  ),
                ),
    );
  }

  /// 构建统计卡片
  Widget _buildStatsCards() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              value: _statistics?.totalCourses.toString() ?? '0',
              label: '授课课程',
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              value: _statistics?.totalStudents.toString() ?? '0',
              label: '学生总数',
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              value: _statistics?.averageRating.toStringAsFixed(1) ?? '0.0',
              label: '平均评分',
              color: const Color(0xFFFF9800),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计卡片项
  Widget _buildStatCard({
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建课程列表
  Widget _buildCoursesList() {
    return Column(
      children: List.generate(_courses.length, (index) {
        final course = _courses[index];
        return _buildCourseItem(course);
      }),
    );
  }

  /// 构建课程项目
  Widget _buildCourseItem(TeacherCourse course) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          // 课程头部信息
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: course.iconColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  course.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            course.name,
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
                            color: course.status.color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            course.status.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${course.code} · ${course.totalHours}学时',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 课程统计信息
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
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              if (course.rating > 0) ...[
                Icon(
                  Icons.star,
                  size: 16,
                  color: Colors.amber[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${course.rating}分',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '下周开始',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const Spacer(),
              if (course.status == TeacherCourseStatus.ongoing)
                SizedBox(
                  width: 80,
                  child: LinearProgressIndicator(
                    value: course.progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(course.iconColor),
                    minHeight: 4,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 操作按钮
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _manageCourse(course),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text(
                    '查看详情',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _viewStatistics(course),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4CAF50),
                    side: const BorderSide(color: Color(0xFF4CAF50)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '查看统计',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建错误提示组件
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              _errorMessage ?? '加载失败',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadCourses,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示创建课程页面
  void _showCreateCourseDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TeacherCourseCreatePage(),
      ),
    ).then((result) {
      if (result == true) {
        // 课程创建成功，刷新列表
        _loadCourses();
      }
    });
  }

  /// 管理课程 - 直接进入课程详情页面
  void _manageCourse(TeacherCourse course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherCourseDetailPage(
          courseId: course.id,
          courseName: course.name,
        ),
      ),
    );
  }

  /// 查看统计
  void _viewStatistics(TeacherCourse course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${course.name} 统计'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('学生人数', '${course.studentCount}人'),
            _buildStatRow('课程评分', course.rating > 0 ? '${course.rating}分' : '暂无评分'),
            _buildStatRow('总学时', '${course.totalHours}学时'),
            _buildStatRow('完成进度', '${(course.progress * 100).toInt()}%'),
            _buildStatRow('课程状态', course.status.label),
          ],
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

  /// 构建统计行
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}
