import 'package:flutter/material.dart';
import '../services/announcement_service.dart';

/// 发布公告页面
class TeacherAnnouncementCreatePage extends StatefulWidget {
  final String? courseId;
  final String? courseName;
  
  const TeacherAnnouncementCreatePage({
    super.key,
    this.courseId,
    this.courseName,
  });

  @override
  State<TeacherAnnouncementCreatePage> createState() => _TeacherAnnouncementCreatePageState();
}

class _TeacherAnnouncementCreatePageState extends State<TeacherAnnouncementCreatePage> {
  final _formKey = GlobalKey<FormState>();
  
  // 表单控制器
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  // 选择的值
  String _selectedType = 'important';
  DateTime? _publishTime;
  DateTime? _expireTime;
  
  // 公告类型选项
  final List<Map<String, dynamic>> _announcementTypes = [
    {
      'value': 'important',
      'label': '重要公告',
      'subtitle': '紧急或重要事项',
      'icon': Icons.warning,
      'color': const Color(0xFFEF4444),
    },
    {
      'value': 'general',
      'label': '一般通知',
      'subtitle': '日常通知事项',
      'icon': Icons.info,
      'color': const Color(0xFF3B82F6),
    },
    {
      'value': 'activity',
      'label': '活动通知',
      'subtitle': '课程活动安排',
      'icon': Icons.event,
      'color': const Color(0xFF10B981),
    },
    {
      'value': 'reminder',
      'label': '提醒事项',
      'subtitle': '作业或考试提醒',
      'icon': Icons.notifications,
      'color': const Color(0xFFF59E0B),
    },
  ];

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
          '发布公告',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _saveDraft,
            icon: const Icon(Icons.save, color: Color(0xFF333333)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 公告类型
              _buildAnnouncementTypeSection(),
              
              const SizedBox(height: 16),
              
              // 公告标题
              _buildTitleSection(),
              
              const SizedBox(height: 16),
              
              // 公告内容
              _buildContentSection(),
              
              const SizedBox(height: 16),
              
              // 发布设置
              _buildPublishSettingsSection(),
              
              const SizedBox(height: 100), // 为底部按钮留空间
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  /// 构建公告类型区域
  Widget _buildAnnouncementTypeSection() {
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
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.label,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '公告类型',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 类型选择网格
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _announcementTypes.length,
            itemBuilder: (context, index) {
              final type = _announcementTypes[index];
              final isSelected = _selectedType == type['value'];
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedType = type['value'];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? type['color'].withOpacity(0.1) : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? type['color'] : const Color(0xFFE2E8F0),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      // 单选按钮和图标
                      Row(
                        children: [
                          Radio<String>(
                            value: type['value'],
                            groupValue: _selectedType,
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value!;
                              });
                            },
                            activeColor: type['color'],
                          ),
                          const Spacer(),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: type['color'],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              type['icon'],
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // 标题和描述
                      Text(
                        type['label'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? type['color'] : const Color(0xFF333333),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        type['subtitle'],
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF666666),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 构建公告标题区域
  Widget _buildTitleSection() {
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
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.title,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '公告标题',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: '请输入公告标题，简洁明了地概括公告',
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
                borderSide: const BorderSide(color: Color(0xFF10B981)),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _clearTitle,
                    icon: const Icon(Icons.clear, color: Color(0xFF666666), size: 20),
                  ),
                ],
              ),
            ),
            maxLength: 100,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入公告标题';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  /// 构建公告内容区域
  Widget _buildContentSection() {
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
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '公告内容',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _contentController,
            decoration: InputDecoration(
              hintText: '请详细描述公告内容，可以包括：\n• 具体事项说明\n• 时间地点安排\n• 注意事项提醒\n• 相关要求说明...',
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
                borderSide: const BorderSide(color: Color(0xFFF59E0B)),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _useTemplate,
                    icon: const Icon(Icons.edit_note, color: Color(0xFF666666), size: 20),
                  ),
                  IconButton(
                    onPressed: _clearContent,
                    icon: const Icon(Icons.clear, color: Color(0xFF666666), size: 20),
                  ),
                ],
              ),
            ),
            maxLines: 8,
            maxLength: 2000,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入公告内容';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  /// 构建发布设置区域
  Widget _buildPublishSettingsSection() {
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
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '发布设置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 发布时间和过期时间
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '发布时间',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectPublishTime(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _publishTime != null 
                                    ? '${_publishTime!.year}/${_publishTime!.month}/${_publishTime!.day} ${_publishTime!.hour.toString().padLeft(2, '0')}:${_publishTime!.minute.toString().padLeft(2, '0')}'
                                    : '2025/10/21 04:17',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _publishTime != null 
                                      ? const Color(0xFF333333)
                                      : const Color(0xFF999999),
                                ),
                              ),
                            ),
                            const Icon(Icons.calendar_today, size: 16, color: Color(0xFF666666)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '过期时间',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectExpireTime(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _expireTime != null 
                                    ? '${_expireTime!.year}/${_expireTime!.month}/${_expireTime!.day}'
                                    : '2025/11/20',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _expireTime != null 
                                      ? const Color(0xFF333333)
                                      : const Color(0xFF999999),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建底部按钮
  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _saveDraft,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4CAF50),
                side: const BorderSide(color: Color(0xFF4CAF50)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('保存草稿'),
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _publishAnnouncement,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('发布公告'),
            ),
          ),
        ],
      ),
    );
  }

  /// 选择发布时间
  Future<void> _selectPublishTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _publishTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_publishTime ?? DateTime.now()),
      );
      
      if (time != null) {
        setState(() {
          _publishTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  /// 选择过期时间
  Future<void> _selectExpireTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expireTime ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _expireTime = date;
      });
    }
  }

  /// 清空标题
  void _clearTitle() {
    _titleController.clear();
    setState(() {});
  }

  /// 清空内容
  void _clearContent() {
    _contentController.clear();
    setState(() {});
  }

  /// 使用模板
  void _useTemplate() {
    final template = '''请详细描述公告内容，可以包括：
• 具体事项说明
• 时间地点安排
• 注意事项提醒
• 相关要求说明...''';
    
    _contentController.text = template;
    setState(() {});
  }

  /// 保存草稿
  void _saveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('草稿已保存'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  /// 发布公告
  void _publishAnnouncement() {
    if (_formKey.currentState!.validate()) {
      // 显示确认对话框
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认发布'),
          content: const Text('确定要发布这个公告吗？发布后学生将收到通知。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performPublish();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }

  /// 执行发布操作
  void _performPublish() async {
    if (widget.courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('课程ID不能为空'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
    
    try {
      // 创建公告请求
      final request = CreateAnnouncementRequest(
        courseId: widget.courseId!,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        announcementType: _getAnnouncementTypeFromValue(_selectedType),
        priority: _getPriorityFromType(_selectedType),
        isPinned: _selectedType == 'important',
        isPublished: true,
        publishTime: _publishTime?.toIso8601String(),
        expireTime: _expireTime?.toIso8601String(),
        targetAudience: TargetAudience.all,
      );
      
      // 调用API创建公告
      final response = await AnnouncementService.createAnnouncement(request);
      
      Navigator.pop(context); // 关闭加载对话框
      
      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('公告发布成功！'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        
        // 返回上一页，传递成功标志
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发布失败：${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // 关闭加载对话框
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('发布失败：$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// 根据类型值获取公告类型枚举
  AnnouncementType _getAnnouncementTypeFromValue(String value) {
    switch (value) {
      case 'important':
        return AnnouncementType.important;
      case 'activity':
        return AnnouncementType.urgent;
      case 'general':
      default:
        return AnnouncementType.normal;
    }
  }
  
  /// 根据类型获取优先级
  int _getPriorityFromType(String type) {
    switch (type) {
      case 'important':
        return 10;
      case 'activity':
        return 5;
      case 'general':
      default:
        return 0;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
