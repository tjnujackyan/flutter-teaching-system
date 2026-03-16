import 'package:flutter/material.dart';
import 'student_courses_page.dart';
import 'assignment_center_page.dart';
import '../services/student_service.dart';
import '../services/resource_service.dart';
import '../services/announcement_service.dart';

/// 课程详情页面
class CourseDetailPage extends StatefulWidget {
  final Course course;

  const CourseDetailPage({
    super.key,
    required this.course,
  });

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  // 数据状态
  Map<String, dynamic>? _courseDetail;
  List<Map<String, dynamic>> _resources = [];
  List<Announcement> _announcements = [];
  bool _isLoading = true;
  String? _error;
  
  // 资源分类
  String? _selectedCategory;
  final ResourceService _resourceService = ResourceService();

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  /// 加载课程数据
  Future<void> _loadCourseData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('Debug: [课程详情] 开始加载课程数据: ${widget.course.id}');

      // 并行加载课程详情和课程资料
      final detailFuture = StudentService.getCourseDetail(widget.course.id);
      final resourcesFuture = _resourceService.getCourseResources(
        courseId: int.parse(widget.course.id),
        category: _selectedCategory,
      );

      final results = await Future.wait([detailFuture, resourcesFuture]);

      // 单独加载公告
      final announcementsResponse = await AnnouncementService.getCourseAnnouncements(
        widget.course.id,
        isPublished: true,
        page: 0,
        size: 10,
      );

      if (mounted) {
        setState(() {
          _courseDetail = results[0] as Map<String, dynamic>;
          _resources = _parseResources(results[1] as Map<String, dynamic>);
          _announcements = announcementsResponse.body?.announcements ?? [];
          _isLoading = false;
        });
        print('Debug: [课程详情] 数据加载成功');
        print('Debug: [课程详情] 课程名称: ${_courseDetail?['name']}');
        print('Debug: [课程详情] 教师姓名: ${_courseDetail?['teacher']}');
        print('Debug: [课程详情] 当前周次: ${_courseDetail?['currentWeek']}');
        print('Debug: [课程详情] 总周数: ${_courseDetail?['totalWeeks']}');
        print('Debug: [课程详情] 进度: ${_courseDetail?['progress']}');
        print('Debug: [课程详情] 公告数量: ${_announcements.length}');
        print('Debug: [课程详情] 完整数据: $_courseDetail');
      }
    } catch (e) {
      print('Debug: [课程详情] 数据加载失败: $e');
      if (mounted) {
        setState(() {
          _error = '加载失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// 解析资源数据
  List<Map<String, dynamic>> _parseResources(Map<String, dynamic> response) {
    if (response['error'] == 0 && response['body'] != null) {
      final body = response['body'];
      final resourcesList = body['resources'] as List<dynamic>? ?? [];
      return resourcesList.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// 刷新数据
  Future<void> _refreshData() async {
    await _loadCourseData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // 顶部AppBar
          _buildSliverAppBar(),
          
          // 主体内容
          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(50.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _error != null
                    ? _buildErrorView()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  /// 构建AppBar
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: widget.course.iconColor,
        leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _courseDetail?['name'] ?? widget.course.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
              colors: [
                widget.course.iconColor,
                widget.course.iconColor.withOpacity(0.7),
              ],
        ),
      ),
      child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Icon(
                  widget.course.iconData,
                size: 60,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(height: 8),
                    Text(
                _courseDetail?['teacher'] ?? widget.course.teacher,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /// 构建错误视图
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(50.0),
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
      ),
    );
  }

  /// 构建内容
  Widget _buildContent() {
    return Column(
      children: [
        // 课程信息卡片
        _buildCourseInfoCard(),
        
        // 课程进度
        _buildProgressCard(),
        
        // 课程公告
        if (_announcements.isNotEmpty) _buildAnnouncementsSection(),
        
        // 课程资料标题
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: const Row(
            children: [
              Text(
                '课程资料',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
        
        // 课程资料列表
        _buildResourcesList(),
      ],
    );
  }

  /// 构建课程信息卡片
  Widget _buildCourseInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
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
          _buildInfoRow(Icons.school, '课程代码', _courseDetail?['code'] ?? widget.course.id),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, '上课地点', _courseDetail?['classroom'] ?? '-'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.schedule, '上课时间', _courseDetail?['schedule'] ?? '-'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.people, '选课人数', '${_courseDetail?['studentCount'] ?? 0}人'),
          if (_courseDetail?['description'] != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              '课程简介',
              style: TextStyle(
                fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
            const SizedBox(height: 8),
                Text(
              _courseDetail!['description'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                height: 1.5,
                  ),
                ),
              ],
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF666666)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 构建进度卡片
  Widget _buildProgressCard() {
    final progress = _courseDetail?['progress'] ?? widget.course.progress;
    final currentWeek = _courseDetail?['currentWeek'] ?? widget.course.currentWeek;
    final totalWeeks = _courseDetail?['totalWeeks'] ?? widget.course.totalWeeks;
    
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '课程进度',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                '${(progress * 100).toInt()}%',
                  style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.course.iconColor,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(widget.course.iconColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '第 $currentWeek 周 / 共 $totalWeeks 周',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }



  /// 构建公告区域
  Widget _buildAnnouncementsSection() {
    return Column(
      children: [
        // 公告标题
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: const Row(
            children: [
              Icon(Icons.campaign, size: 20, color: Color(0xFF4285F4)),
              SizedBox(width: 8),
              Text(
                '课程公告',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
        
        // 公告列表
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _announcements.length,
            itemBuilder: (context, index) {
              final announcement = _announcements[index];
              return _buildAnnouncementItem(announcement);
            },
          ),
        ),
      ],
    );
  }

  /// 构建公告项
  Widget _buildAnnouncementItem(Announcement announcement) {
    Color typeColor;
    IconData typeIcon;
    
    switch (announcement.announcementType) {
      case AnnouncementType.urgent:
        typeColor = const Color(0xFFE53935);
        typeIcon = Icons.priority_high;
        break;
      case AnnouncementType.important:
        typeColor = const Color(0xFFFF9800);
        typeIcon = Icons.star;
        break;
      case AnnouncementType.system:
        typeColor = const Color(0xFF9C27B0);
        typeIcon = Icons.settings;
        break;
      default:
        typeColor = const Color(0xFF4285F4);
        typeIcon = Icons.info_outline;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: announcement.isPinned ? typeColor.withOpacity(0.3) : Colors.grey[200]!,
          width: announcement.isPinned ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _showAnnouncementDetail(announcement);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行
                Row(
                  children: [
                    // 类型图标
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(typeIcon, size: 16, color: typeColor),
                    ),
                    const SizedBox(width: 8),
                    
                    // 标题
                    Expanded(
                      child: Text(
                        announcement.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // 置顶标签
                    if (announcement.isPinned)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '置顶',
                          style: TextStyle(
                            fontSize: 10,
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // 内容预览
                Text(
                  announcement.summary.isNotEmpty 
                      ? announcement.summary 
                      : announcement.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // 底部信息
                Row(
                  children: [
                    // 类型标签
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        announcement.announcementTypeText,
                        style: TextStyle(
                          fontSize: 12,
                          color: typeColor,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // 发布时间
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _formatPublishTime(announcement.publishTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // 查看详情
                    Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 格式化发布时间
  String _formatPublishTime(String publishTime) {
    try {
      final dateTime = DateTime.parse(publishTime);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 7) {
        return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}天前';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}小时前';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}分钟前';
      } else {
        return '刚刚';
      }
    } catch (e) {
      return publishTime;
    }
  }

  /// 显示公告详情
  void _showAnnouncementDetail(Announcement announcement) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.course.iconColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        announcement.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              // 内容区域
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 元信息
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            announcement.teacherName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            announcement.publishTime,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),
                      
                      // 正文内容
                      Text(
                        announcement.content,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF333333),
                          height: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 底部按钮
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.course.iconColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('知道了', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  /// 构建资料列表
  Widget _buildResourcesList() {
    if (_resources.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '暂无课程资料',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _resources.length,
        itemBuilder: (context, index) {
          final resource = _resources[index];
          return _buildResourceItem(resource);
        },
      ),
    );
  }

  /// 构建资料项
  Widget _buildResourceItem(Map<String, dynamic> resource) {
    final fileType = resource['fileType'] ?? '';
    final fileSize = resource['fileSize'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // 文件图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getFileTypeColor(fileType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _resourceService.getFileTypeIcon(fileType),
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // 文件信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Text(
                  resource['title'] ?? resource['fileName'] ?? '未命名',
            style: const TextStyle(
              fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _resourceService.formatFileSize(fileSize),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                    if (resource['categoryName'] != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
            ),
                        child: Text(
                          resource['categoryName'],
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // 下载按钮
          IconButton(
            icon: const Icon(Icons.download, size: 20),
            color: const Color(0xFF4285F4),
            onPressed: () {
              _showDownloadDialog(resource);
            },
          ),
        ],
      ),
    );
  }

  /// 获取文件类型颜色
  Color _getFileTypeColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'ppt':
      case 'pptx':
        return const Color(0xFFE53935);
      case 'pdf':
        return const Color(0xFFD32F2F);
      case 'doc':
      case 'docx':
        return const Color(0xFF1976D2);
      case 'mp4':
      case 'avi':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF666666);
    }
  }

  /// 显示下载对话框
  void _showDownloadDialog(Map<String, dynamic> resource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('下载资料'),
        content: Text('确定要下载 ${resource['title'] ?? resource['fileName']} 吗?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadResource(resource);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 下载资料
  Future<void> _downloadResource(Map<String, dynamic> resource) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正在准备下载...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      await _resourceService.downloadResource(
        courseId: int.parse(widget.course.id),
        resourceId: resource['id'],
        savePath: '', // Web 不需要路径
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('下载完成'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下载失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


}
