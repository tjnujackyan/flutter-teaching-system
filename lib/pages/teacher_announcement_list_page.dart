import 'package:flutter/material.dart';
import '../services/announcement_service.dart';
import 'teacher_announcement_create_page.dart';

/// 教师公告列表页面
class TeacherAnnouncementListPage extends StatefulWidget {
  final String courseId;
  final String courseName;
  
  const TeacherAnnouncementListPage({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<TeacherAnnouncementListPage> createState() => _TeacherAnnouncementListPageState();
}

class _TeacherAnnouncementListPageState extends State<TeacherAnnouncementListPage> {
  List<Announcement> _announcements = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // 筛选条件
  String _selectedType = 'all';
  String _selectedStatus = 'all';
  
  final List<Map<String, dynamic>> _typeFilters = [
    {'value': 'all', 'label': '全部类型'},
    {'value': 'important', 'label': '重要公告'},
    {'value': 'normal', 'label': '一般通知'},
    {'value': 'urgent', 'label': '紧急通知'},
  ];
  
  final List<Map<String, dynamic>> _statusFilters = [
    {'value': 'all', 'label': '全部状态'},
    {'value': 'published', 'label': '已发布'},
    {'value': 'draft', 'label': '草稿'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  /// 加载公告列表
  Future<void> _loadAnnouncements() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await AnnouncementService.getAnnouncementList(
        courseId: widget.courseId,
        page: 1,
        pageSize: 50,
        announcementType: _selectedType == 'all' ? null : _getAnnouncementTypeFromValue(_selectedType),
        isPublished: _selectedStatus == 'all' ? null : _selectedStatus == 'published',
      );

      if (response.isSuccess) {
        setState(() {
          _announcements = response.body?.announcements ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载公告列表失败：$e';
        _isLoading = false;
      });
    }
  }

  /// 根据类型值获取公告类型枚举
  AnnouncementType _getAnnouncementTypeFromValue(String value) {
    switch (value) {
      case 'important':
        return AnnouncementType.important;
      case 'urgent':
        return AnnouncementType.urgent;
      case 'normal':
      default:
        return AnnouncementType.normal;
    }
  }

  /// 删除公告
  Future<void> _deleteAnnouncement(String announcementId, String title) async {
    final confirmed = await _showDeleteConfirmDialog(title);
    if (!confirmed) return;

    try {
      // 显示加载状态
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          ),
        ),
      );

      final response = await AnnouncementService.deleteAnnouncement(announcementId);
      
      Navigator.pop(context); // 关闭加载对话框

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('公告删除成功'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        
        // 重新加载公告列表
        _loadAnnouncements();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败：${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // 关闭加载对话框
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('删除失败：$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 显示删除确认对话框
  Future<bool> _showDeleteConfirmDialog(String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除公告"$title"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// 导航到创建公告页面
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
        // 公告创建成功，重新加载列表
        _loadAnnouncements();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('公告发布成功'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    });
  }

  /// 获取公告类型显示文本
  String _getAnnouncementTypeText(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.important:
        return '重要';
      case AnnouncementType.urgent:
        return '紧急';
      case AnnouncementType.normal:
      default:
        return '通知';
    }
  }

  /// 获取公告类型颜色
  Color _getAnnouncementTypeColor(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.important:
        return const Color(0xFFEF4444);
      case AnnouncementType.urgent:
        return const Color(0xFFF59E0B);
      case AnnouncementType.normal:
      default:
        return const Color(0xFF3B82F6);
    }
  }

  /// 格式化时间
  String _formatTime(String timeStr) {
    try {
      final time = DateTime.parse(timeStr);
      final now = DateTime.now();
      final difference = now.difference(time);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}天前';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}小时前';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}分钟前';
      } else {
        return '刚刚';
      }
    } catch (e) {
      return timeStr;
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '课程公告',
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.courseName,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _navigateToCreateAnnouncement,
            icon: const Icon(Icons.add, color: Color(0xFF4CAF50)),
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选条件
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: '公告类型',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _typeFilters.map((filter) {
                      return DropdownMenuItem<String>(
                        value: filter['value'],
                        child: Text(filter['label']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedType = value;
                        });
                        _loadAnnouncements();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: '发布状态',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _statusFilters.map((filter) {
                      return DropdownMenuItem<String>(
                        value: filter['value'],
                        child: Text(filter['label']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedStatus = value;
                        });
                        _loadAnnouncements();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // 公告列表
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                    ),
                  )
                : _errorMessage != null
                    ? Center(
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
                                color: Color(0xFF666666),
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadAnnouncements,
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      )
                    : _announcements.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.campaign_outlined,
                                  size: 64,
                                  color: Color(0xFF666666),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '暂无公告',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadAnnouncements,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _announcements.length,
                              itemBuilder: (context, index) {
                                final announcement = _announcements[index];
                                return _buildAnnouncementCard(announcement);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  /// 构建公告卡片
  Widget _buildAnnouncementCard(Announcement announcement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 公告头部
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 公告类型标签
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getAnnouncementTypeColor(announcement.announcementType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getAnnouncementTypeText(announcement.announcementType),
                    style: TextStyle(
                      color: _getAnnouncementTypeColor(announcement.announcementType),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                if (announcement.isPinned) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '置顶',
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                
                const Spacer(),
                
                // 删除按钮
                IconButton(
                  onPressed: () => _deleteAnnouncement(announcement.id, announcement.title),
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          
          // 公告标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              announcement.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ),
          
          // 公告内容预览
          if (announcement.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                announcement.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          
          // 公告底部信息
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(announcement.publishTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Icon(
                  Icons.visibility,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  '${announcement.viewCount}次查看',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                
                const Spacer(),
                
                // 发布状态
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: announcement.isPublished 
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    announcement.isPublished ? '已发布' : '草稿',
                    style: TextStyle(
                      color: announcement.isPublished 
                          ? const Color(0xFF10B981)
                          : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
