import 'package:flutter/material.dart';
import '../services/course_service.dart';
import 'teacher_assignment_create_page.dart';
import 'teacher_quiz_create_page.dart';
import 'teacher_upload_materials_page.dart';
import 'course_resources_page.dart';
import 'teacher_student_management_page.dart';
import 'teacher_announcement_create_page.dart';
import 'teacher_announcement_list_page.dart';

/// 课程详情页面
class TeacherCourseDetailPage extends StatefulWidget {
  final String courseId;
  final String courseName;
  
  const TeacherCourseDetailPage({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<TeacherCourseDetailPage> createState() => _TeacherCourseDetailPageState();
}

class _TeacherCourseDetailPageState extends State<TeacherCourseDetailPage> {
  CourseDetailResponse? _courseDetail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  /// 加载课程详情数据
  Future<void> _loadCourseData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await CourseService.getCourseDetail(widget.courseId);
      
      if (response.isSuccess && response.body != null) {
        setState(() {
          _courseDetail = response.body;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? '获取课程详情失败';
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

  /// 解析图标
  IconData _parseIcon(String iconStr) {
    switch (iconStr) {
      case '💻':
        return Icons.computer;
      case '🗄️':
        return Icons.storage;
      case '🌐':
        return Icons.network_check;
      case '📊':
        return Icons.analytics;
      case '🤖':
        return Icons.smart_toy;
      case '🔒':
        return Icons.security;
      default:
        return Icons.computer;
    }
  }

  /// 解析颜色
  Color _parseColor(String colorStr) {
    try {
      final cleanColor = colorStr.replaceAll('#', '');
      return Color(int.parse('FF$cleanColor', radix: 16));
    } catch (e) {
      return const Color(0xFF3B82F6);
    }
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
              onPressed: _loadCourseData,
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
          '课程详情',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                  onRefresh: _loadCourseData,
                  color: const Color(0xFF4CAF50),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // 课程信息卡片
                        _buildCourseInfoCard(),
                        
                        const SizedBox(height: 16),
                        
                        // 课程进度
                        _buildProgressSection(),
                        
                        const SizedBox(height: 16),
                        
                        // 快速操作
                        _buildQuickActions(),
                        
                        const SizedBox(height: 100), // 为底部导航栏留出空间
                      ],
                    ),
                  ),
                ),
    );
  }

  /// 构建课程信息卡片
  Widget _buildCourseInfoCard() {
    if (_courseDetail == null) return const SizedBox.shrink();
    
    final courseInfo = _courseDetail!.courseInfo;
    final iconColor = _parseColor(courseInfo.color);
    final icon = _parseIcon(courseInfo.icon);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseInfo.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            courseInfo.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            courseInfo.statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '课程代码：${courseInfo.code}',
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
          
          const SizedBox(height: 20),
          
          // 统计信息
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  value: '${_courseDetail!.statistics.studentCount}',
                  label: '学生人数',
                  color: const Color(0xFF3B82F6),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  value: '${_courseDetail!.statistics.totalWeeks}',
                  label: '教学周数',
                  color: const Color(0xFF10B981),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  value: '${courseInfo.credits}',
                  label: '学分',
                  color: const Color(0xFFF59E0B),
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


  /// 构建快速操作
  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            '快速操作',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              _buildQuickActionItem(
                icon: Icons.campaign,
                label: '发布公告',
                color: const Color(0xFFEF4444),
                onTap: () => _navigateToCreateAnnouncement(),
              ),
              _buildQuickActionItem(
                icon: Icons.assignment,
                label: '发布作业',
                color: const Color(0xFF3B82F6),
                onTap: () => _navigateToCreateAssignment(),
              ),
              _buildQuickActionItem(
                icon: Icons.quiz,
                label: '创建测验',
                color: const Color(0xFF10B981),
                onTap: () => _navigateToCreateQuiz(),
              ),
              _buildQuickActionItem(
                icon: Icons.folder,
                label: '资料管理',
                color: const Color(0xFFF59E0B),
                onTap: () => _navigateToResourceManagement(),
              ),
              _buildQuickActionItem(
                icon: Icons.people,
                label: '学生管理',
                color: const Color(0xFF8B5CF6),
                onTap: () => _navigateToStudentManagement(),
              ),
              _buildQuickActionItem(
                icon: Icons.list_alt,
                label: '公告列表',
                color: const Color(0xFFEC4899),
                onTap: () => _navigateToAnnouncementList(),
              ),
            ],
          ),
        ],
      ),
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
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }




  /// 导航到发布公告页面
  void _navigateToCreateAnnouncement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherAnnouncementCreatePage(
          courseId: widget.courseId,
          courseName: widget.courseName,
        ),
      ),
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('公告发布成功'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    });
  }

  /// 导航到公告列表页面
  void _navigateToAnnouncementList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherAnnouncementListPage(
          courseId: widget.courseId,
          courseName: widget.courseName,
        ),
      ),
    );
  }

  /// 导航到发布作业页面
  void _navigateToCreateAssignment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherAssignmentCreatePage(
          courseId: widget.courseId,
          courseName: widget.courseName,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // 作业发布成功，可以刷新页面数据
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('作业发布成功，学生将收到通知'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    });
  }

  /// 导航到创建测验页面
  void _navigateToCreateQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherQuizCreatePage(
          courseId: int.tryParse(widget.courseId) ?? 0,
          courseName: widget.courseName,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // 测验创建成功，可以刷新页面数据
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('测验创建成功，学生将收到通知'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    });
  }

  /// 导航到资料管理页面
  void _navigateToResourceManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseResourcesPage(
          courseId: int.parse(widget.courseId),
          courseName: widget.courseName,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // 资料管理操作完成，可以刷新页面数据
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('资料管理操作完成'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    });
  }

  /// 导航到学生管理页面
  void _navigateToStudentManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherStudentManagementPage(
          courseId: widget.courseId,
          courseName: widget.courseName,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // 学生管理操作完成，可以刷新页面数据
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('学生管理操作完成'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    });
  }



  /// 构建课程进度部分
  Widget _buildProgressSection() {
    if (_courseDetail == null) return const SizedBox.shrink();
    
    final statistics = _courseDetail!.statistics;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '课程进度',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              Text(
                '第${statistics.currentWeek}周 / 共${statistics.totalWeeks}周',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          LinearProgressIndicator(
            value: statistics.totalWeeks > 0 ? statistics.currentWeek / statistics.totalWeeks : 0.0,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            minHeight: 8,
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '已完成周数：${statistics.currentWeek}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              Text(
                '剩余周数：${statistics.totalWeeks - statistics.currentWeek}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ],
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
