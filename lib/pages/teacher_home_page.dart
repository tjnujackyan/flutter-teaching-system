import 'package:flutter/material.dart';
import 'teacher_courses_page.dart';
import 'teacher_assignment_management_page.dart';
import 'teacher_quiz_management_page.dart';
import 'teacher_profile_page.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../services/assignment_service.dart';
import '../services/api_service.dart';

/// 教师主页
class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  int _currentIndex = 0;

  // 数据状态
  Map<String, dynamic>? _profileData;
  List<dynamic> _courses = [];
  int _courseCount = 0;
  int _pendingAssignmentCount = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  /// 加载首页数据
  Future<void> _loadHomeData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('Debug: [教师首页] 开始加载数据');

      // 获取 token
      final token = await ApiService.getAuthToken();
      if (token == null) {
        throw Exception('未登录');
      }

      // 并行加载教师信息、课程列表和作业数据
      final profileResponse = await AuthService.getProfileInfo();
      final coursesResponse = await CourseService.getTeacherCourses();
      final assignmentsResponse = await AssignmentService.getTeacherAssignments(token: token);

      print('Debug: [教师首页] 作业API完整响应: $assignmentsResponse');

      if (mounted) {
        // 处理个人信息
        if (profileResponse.isSuccess && profileResponse.body != null) {
          _profileData = profileResponse.body as Map<String, dynamic>?;
          print('Debug: [教师首页] 教师信息加载成功: ${_profileData?['name']}');
          print('Debug: [教师首页] 头像URL: ${_profileData?['avatar']}');
        } else {
          print('Debug: [教师首页] 教师信息加载失败');
        }

        // 处理课程列表
        if (coursesResponse.isSuccess && coursesResponse.body != null) {
          _courses = coursesResponse.body!.courses;
          _courseCount = _courses.length;
          print('Debug: [教师首页] 课程数量: $_courseCount');
        }

        // 处理待批改作业数量（计算有待批改提交的作业数量）
        if (assignmentsResponse['error'] == 0) {
          final assignments = assignmentsResponse['body']?['assignments'] as List? ?? [];
          print('Debug: [教师首页] 作业列表: $assignments');
          print('Debug: [教师首页] 作业总数: ${assignments.length}');
          
          int pendingCount = 0;
          for (var assignment in assignments) {
            final submissionCount = assignment['submissionCount'] ?? 0;
            final gradedCount = assignment['gradedCount'] ?? 0;
            print('Debug: [教师首页] 作业 "${assignment['title']}": 总提交=$submissionCount, 已批改=$gradedCount');
            if (submissionCount > gradedCount) {
              pendingCount++;
            }
          }
          _pendingAssignmentCount = pendingCount;
          print('Debug: [教师首页] 待批改作业数量: $pendingCount');
        } else {
          print('Debug: [教师首页] 作业数据加载失败: ${assignmentsResponse['message']}');
        }

        setState(() {
          _isLoading = false;
        });
        print('Debug: [教师首页] 数据加载成功');
      }
    } catch (e) {
      print('Debug: [教师首页] 数据加载失败: $e');
      if (mounted) {
        setState(() {
          _error = '加载失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// 刷新数据
  Future<void> _refreshData() async {
    await _loadHomeData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: _currentIndex == 0 ? _buildHomePage() : _buildPlaceholderPage(),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// 构建主页内容
  Widget _buildHomePage() {
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

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 欢迎卡片
          _buildWelcomeCard(),
          
          // 统计卡片
          _buildStatsCards(),
          
          // 快速操作
          _buildQuickActions(),
          
            // 执教课程
            _buildTeachingCourses(),
          
          const SizedBox(height: 100), // 为底部导航栏留出空间
        ],
        ),
      ),
    );
  }

  /// 构建欢迎卡片
  Widget _buildWelcomeCard() {
    // 获取当前时间段的问候语
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = '早上好';
    } else if (hour < 18) {
      greeting = '下午好';
    } else {
      greeting = '晚上好';
    }

    final teacherName = _profileData?['name'] ?? '老师';
    final courseCount = _courseCount;
    final avatarUrl = _profileData?['avatar'];
    
    print('Debug: [欢迎卡片] 教师姓名: $teacherName');
    print('Debug: [欢迎卡片] 头像URL: $avatarUrl');
    print('Debug: [欢迎卡片] 完整profileData: $_profileData');

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$teacherName，$greeting',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '今天有${courseCount}门课程',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: avatarUrl != null && avatarUrl.toString().isNotEmpty
                  ? Image.network(
                      'http://localhost:8081$avatarUrl',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Debug: [欢迎卡片] 头像加载失败: $error');
                        return _buildDefaultAvatar();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          print('Debug: [欢迎卡片] 头像加载成功');
                          return child;
                        }
                        print('Debug: [欢迎卡片] 头像加载中...');
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        );
                      },
                    )
                  : _buildDefaultAvatar(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建默认头像
  Widget _buildDefaultAvatar() {
    final name = _profileData?['name'] ?? '教';
    return Center(
      child: Text(
        name.isNotEmpty ? name[0] : '教',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 构建统计卡片
  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              value: _courseCount.toString(),
              label: '授课课程',
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              value: _pendingAssignmentCount.toString(),
              label: '待批改作业',
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
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建快速操作
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '快速操作',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickActionItem(
                icon: Icons.school,
                label: '课程管理',
                color: const Color(0xFF4CAF50),
                onTap: () {
                  setState(() {
                    _currentIndex = 1; // 切换到课程标签
                  });
                },
              ),
              _buildQuickActionItem(
                icon: Icons.assignment,
                label: '作业管理',
                color: const Color(0xFFFF9800),
                onTap: () {
                  setState(() {
                    _currentIndex = 2; // 切换到作业标签
                  });
                },
              ),
              _buildQuickActionItem(
                icon: Icons.quiz,
                label: '测验管理',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  setState(() {
                    _currentIndex = 3; // 切换到测验标签
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建快速操作项目
  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建执教课程
  Widget _buildTeachingCourses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '执教课程',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ),
        if (_courses.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            child: Center(
              child: Text(
                '暂无课程',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          )
        else
          ...List.generate(_courses.length, (index) {
            final course = _courses[index];
            return _buildCourseItem(course);
        }),
      ],
    );
  }

  /// 构建课程项目
  Widget _buildCourseItem(dynamic course) {
    // 从course对象中获取数据
    final courseName = course.name ?? '未命名课程';
    final courseCode = course.code ?? '';
    final classroom = course.classroom ?? '';
    final schedule = course.schedule ?? '';
    final studentCount = course.studentCount ?? 0;
    final statusText = course.statusText ?? '待开始';
    final status = course.status ?? 'upcoming';
    
    // 根据状态设置颜色
    Color statusColor;
    if (status == 'active') {
      statusColor = const Color(0xFF4CAF50);
    } else if (status == 'upcoming') {
      statusColor = const Color(0xFFFF9800);
    } else {
      statusColor = const Color(0xFF666666);
    }

    // 图标颜色（从课程模型中获取或使用默认）
    Color iconColor = const Color(0xFF3B82F6);
    try {
      final colorStr = course.color ?? '#3B82F6';
      iconColor = Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (e) {
      // 使用默认颜色
    }

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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                course.icon ?? '📚',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                if (courseCode.isNotEmpty || classroom.isNotEmpty)
                Text(
                    classroom.isNotEmpty ? '$courseCode · $classroom' : courseCode,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.people,
                      size: 16,
                      color: Color(0xFF666666),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$studentCount人',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                    if (schedule.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Color(0xFF666666),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          schedule,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                          overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              statusText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部导航栏
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
        // 当切换到首页时，重新加载数据以获取最新的头像
        if (index == 0) {
          _loadHomeData();
        }
      },
      selectedItemColor: const Color(0xFF4CAF50),
      unselectedItemColor: const Color(0xFF999999),
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '首页',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school),
          label: '课程',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: '作业',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.quiz),
          label: '测验',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '我的',
        ),
      ],
    );
  }

  /// 构建占位页面
  Widget _buildPlaceholderPage() {
    final titles = ['首页', '课程', '作业', '测验', '我的'];
    
    // 根据当前索引显示对应页面
    switch (_currentIndex) {
      case 1:
        return const TeacherCoursesPage();
      case 2:
        return const TeacherAssignmentManagementPage();
      case 3:
        return const TeacherQuizManagementPage();
      case 4:
        return const TeacherProfilePage();
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '${titles[_currentIndex]}页面开发中',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
    }
  }


  /// 显示功能未就绪提示
  void _showFeatureNotReady(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature功能开发中'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
