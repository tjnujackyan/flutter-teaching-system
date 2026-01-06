import 'package:flutter/material.dart';
import 'student_courses_page.dart';
import 'assignment_center_page.dart';
import 'quiz_center_page.dart';
import 'profile_center_page.dart';
import '../services/student_service.dart';

/// 学生主页
class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  int _currentIndex = 0;
  
  // 数据状态
  Map<String, dynamic>? _dashboardData;
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  /// 加载主页数据
  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      print('Debug: [学生主页] 开始加载数据');
      
      // 并行加载主页概览和公告数据
      final dashboardFuture = StudentService.getDashboardOverview();
      final announcementsFuture = StudentService.getLatestAnnouncements(limit: 5);
      
      final results = await Future.wait([dashboardFuture, announcementsFuture]);
      
      if (mounted) {
        setState(() {
          _dashboardData = results[0] as Map<String, dynamic>;
          _announcements = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
        print('Debug: [学生主页] 数据加载成功');
      }
    } catch (e) {
      print('Debug: [学生主页] 数据加载失败: $e');
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
    await _loadDashboardData();
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部欢迎卡片
            _buildWelcomeCard(),
            const SizedBox(height: 16),
            
            // 统计卡片
            _buildStatsCards(),
            const SizedBox(height: 24),
            
            // 快速操作
            _buildQuickActions(),
            const SizedBox(height: 24),
            
            // 最新公告
            _buildLatestAnnouncements(),
          ],
        ),
      ),
    );
  }

  /// 构建欢迎卡片
  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4285F4), Color(0xFF6FA8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
                  _dashboardData?['studentInfo']?['greeting'] != null 
                    ? '${_dashboardData!['studentInfo']['greeting']}，${_dashboardData!['studentInfo']['name'] ?? '同学'}'
                    : '你好，同学',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '今天也要努力学习哦！',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计卡片
  Widget _buildStatsCards() {
    final statistics = _dashboardData?['statistics'] ?? {};
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: '进行中课程',
            value: '${statistics['courseCount'] ?? 0}',
            color: const Color(0xFF4285F4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: '已完成作业',
            value: '${statistics['completedAssignments'] ?? 0}',
            color: const Color(0xFF34A853),
          ),
        ),
      ],
    );
  }

  /// 构建单个统计卡片
  Widget _buildStatCard({
    required String title,
    required String value,
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
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建快速操作区域
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快速操作',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickActionItem(
              icon: Icons.menu_book,
              label: '我的课程',
              color: const Color(0xFF4285F4),
              onTap: () {
                setState(() {
                  _currentIndex = 1; // 切换到课程标签
                });
              },
            ),
            _buildQuickActionItem(
              icon: Icons.assignment,
              label: '作业中心',
              color: const Color(0xFFFF9800),
              onTap: () {
                setState(() {
                  _currentIndex = 2; // 切换到作业标签
                });
              },
            ),
            _buildQuickActionItem(
              icon: Icons.quiz,
              label: '在线测验',
              color: const Color(0xFF4CAF50),
              onTap: () {
                setState(() {
                  _currentIndex = 3; // 切换到测验标签
                });
              },
            ),
          ],
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
            width: 56,
            height: 56,
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

  /// 构建最新公告区域
  Widget _buildLatestAnnouncements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '最新公告',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 16),
        if (_announcements.isEmpty)
          Container(
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
                '暂无公告',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          )
        else
          ..._announcements.take(3).map((announcement) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildAnnouncementItem(
              title: announcement['title'] ?? '无标题',
              content: announcement['content'] ?? '',
              author: announcement['author'] ?? '未知作者',
              time: StudentService.formatAnnouncementTime(announcement['publishTime'] ?? ''),
              isImportant: StudentService.isImportantAnnouncement(announcement),
            ),
          )).toList(),
      ],
    );
  }

  /// 构建公告项目
  Widget _buildAnnouncementItem({
    required String title,
    required String content,
    required String author,
    required String time,
    required bool isImportant,
  }) {
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
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isImportant ? const Color(0xFFFF5722) : const Color(0xFF2196F3),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                author,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
            ],
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
      },
      selectedItemColor: const Color(0xFF4285F4),
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
    
    // 如果是课程页面，显示课程页面
    if (_currentIndex == 1) {
      return const StudentCoursesPage();
    }
    
    // 如果是作业页面，显示作业中心页面
    if (_currentIndex == 2) {
      return const AssignmentCenterPage();
    }
    
    // 如果是测验页面，显示测验中心页面
    if (_currentIndex == 3) {
      return const QuizCenterPage();
    }
    
    // 如果是个人中心页面，显示个人中心页面
    if (_currentIndex == 4) {
      return const ProfileCenterPage();
    }
    
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
