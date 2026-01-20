import 'package:flutter/material.dart';
import 'teacher_profile_info_page.dart';
import 'teacher_account_security_page.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';

/// 教师个人中心页面
class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  int _courseCount = 0;
  int _studentCount = 0;
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  /// 加载个人信息和课程统计信息
  Future<void> _loadProfileData() async {
    try {
      // 并行加载个人信息和课程列表
      final profileResponse = await AuthService.getProfileInfo();
      final coursesResponse = await CourseService.getTeacherCourses();
      
      if (profileResponse.isSuccess && profileResponse.body != null && mounted) {
        setState(() {
          _profileData = profileResponse.body as Map<String, dynamic>?;
        });
      }
      
      // 从课程列表计算统计数据
      if (coursesResponse.isSuccess && coursesResponse.body != null && mounted) {
        final courses = coursesResponse.body!.courses;
        int totalStudents = 0;
        
        for (var course in courses) {
          totalStudents += course.studentCount;
        }
        
        setState(() {
          _courseCount = courses.length;
          _studentCount = totalStudents;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
      
      if (!profileResponse.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败: ${profileResponse.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('网络错误，请检查网络连接')),
        );
      }
    }
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
          '我的',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 用户信息卡片
            _buildUserInfoCard(),
            
            const SizedBox(height: 16),
            
            // 功能菜单
            _buildFunctionMenu(),
            
            const SizedBox(height: 32),
            
            // 退出登录
            _buildLogoutButton(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// 构建用户信息卡片
  Widget _buildUserInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF66BB6A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 头像和基本信息
          Row(
            children: [
              // 头像
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: _profileData?['avatar'] != null && _profileData!['avatar'].toString().isNotEmpty
                      ? Image.network(
                          'http://localhost:8081${_profileData!['avatar']}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // 用户信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profileData?['name'] ?? '加载中...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '工号：${_profileData?['teacherId'] ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_profileData?['department'] ?? ''}·${_profileData?['title'] ?? ''}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 统计数据
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    _courseCount.toString(),
                    '授课课程',
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    _studentCount.toString(),
                    '学生总数',
                  ),
                ),
              ],
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

  /// 构建统计项目
  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// 构建功能菜单
  Widget _buildFunctionMenu() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          _buildMenuItem(
            icon: Icons.person_outline,
            title: '个人信息',
            subtitle: '查看和编辑个人资料',
            onTap: () => _navigateToProfileInfo(),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildMenuItem(
            icon: Icons.security_outlined,
            title: '账号安全',
            subtitle: '密码、验证、设备管理',
            onTap: () => _navigateToAccountSecurity(),
          ),
        ],
      ),
    );
  }

  /// 构建菜单项
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF4CAF50),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF666666),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xFF666666),
      ),
      onTap: onTap,
    );
  }

  /// 构建退出登录按钮
  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showLogoutDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFEF4444),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFEF4444)),
          ),
        ),
        child: const Text(
          '退出登录',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 导航到个人信息页面
  void _navigateToProfileInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TeacherProfileInfoPage(),
      ),
    ).then((result) {
      if (result == true) {
        // 个人信息更新成功，重新加载数据
        _loadProfileData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('个人信息更新成功'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    });
  }

  /// 导航到账号安全页面
  void _navigateToAccountSecurity() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TeacherAccountSecurityPage(),
      ),
    );
  }


  /// 显示退出登录对话框
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 执行退出登录
  void _performLogout() {
    // 这里应该清除用户登录状态并跳转到登录页面
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/teacher-login',
      (route) => false,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已退出登录'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }
}
