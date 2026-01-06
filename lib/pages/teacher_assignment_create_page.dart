import 'package:flutter/material.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/assignment_service.dart';

/// 发布作业页面
class TeacherAssignmentCreatePage extends StatefulWidget {
  final String? courseId;
  final String? courseName;
  
  const TeacherAssignmentCreatePage({
    super.key,
    this.courseId,
    this.courseName,
  });

  @override
  State<TeacherAssignmentCreatePage> createState() => _TeacherAssignmentCreatePageState();
}

class _TeacherAssignmentCreatePageState extends State<TeacherAssignmentCreatePage> {
  final _formKey = GlobalKey<FormState>();
  
  // 表单控制器
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _scoreController = TextEditingController(text: '100');
  
  // 选择的值
  String _selectedType = '';
  String _selectedChapter = '';
  DateTime? _publishTime;
  DateTime? _deadline;
  bool _allowLateSubmission = false;
  bool _isPublishing = false;
  
  // 附件列表
  List<Map<String, dynamic>> _attachments = [];
  
  // 作业类型选项
  final List<Map<String, String>> _assignmentTypes = [
    {'value': 'homework', 'label': '作业'},
    {'value': 'report', 'label': '报告'},
    {'value': 'project', 'label': '项目'},
    {'value': 'experiment', 'label': '实验'},
    {'value': 'essay', 'label': '论文'},
  ];
  
  // 章节选项
  final List<Map<String, String>> _chapters = [
    {'value': 'chapter1', 'label': '第1章 - 绪论'},
    {'value': 'chapter2', 'label': '第2章 - 线性表'},
    {'value': 'chapter3', 'label': '第3章 - 栈和队列'},
    {'value': 'chapter4', 'label': '第4章 - 串'},
    {'value': 'chapter5', 'label': '第5章 - 数组和广义表'},
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
          '发布作业',
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
              // 基本信息
              _buildBasicInfoSection(),
              
              const SizedBox(height: 16),
              
              // 作业内容
              _buildContentSection(),
              
              const SizedBox(height: 16),
              
              // 时间设置
              _buildTimeSection(),
              
              const SizedBox(height: 16),
              
              // 附件资料
              _buildAttachmentSection(),
              
              const SizedBox(height: 100), // 为底部按钮留空间
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  /// 构建基本信息区域
  Widget _buildBasicInfoSection() {
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
              Icon(Icons.info, color: const Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 8),
              const Text(
                '基本信息',
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
          
          // 作业标题
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: '作业标题 *',
              hintText: '请输入作业标题',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixText: '${_titleController.text.length}/100',
            ),
            maxLength: 100,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入作业标题';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {});
            },
          ),
          
          const SizedBox(height: 16),
          
          // 作业类型和总分
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedType.isEmpty ? null : _selectedType,
                  decoration: InputDecoration(
                    labelText: '作业类型 *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _assignmentTypes.map((type) {
                    return DropdownMenuItem(
                      value: type['value'],
                      child: Text(type['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请选择类型';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: TextFormField(
                  controller: _scoreController,
                  decoration: InputDecoration(
                    labelText: '总分 *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入总分';
                    }
                    final score = int.tryParse(value);
                    if (score == null || score <= 0) {
                      return '请输入有效分数';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 所属章节
          DropdownButtonFormField<String>(
            value: _selectedChapter.isEmpty ? null : _selectedChapter,
            decoration: InputDecoration(
              labelText: '所属章节',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _chapters.map((chapter) {
              return DropdownMenuItem(
                value: chapter['value'],
                child: Text(chapter['label']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedChapter = value ?? '';
              });
            },
          ),
        ],
      ),
    );
  }

  /// 构建作业内容区域
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
              Icon(Icons.edit, color: const Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              const Text(
                '作业内容',
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
              hintText: '请详细描述作业要求、完成标准、注意事项等...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 8,
            maxLength: 1000,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入作业内容';
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

  /// 构建时间设置区域
  Widget _buildTimeSection() {
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
          // 发布时间和截止时间
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
                        color: Color(0xFF666666),
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
                                    : '2025/10/21 05:06',
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
                    Row(
                      children: [
                        const Text(
                          '截止时间',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const Text(
                          ' *',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectDeadline(),
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
                                _deadline != null 
                                    ? '${_deadline!.year}/${_deadline!.month}/${_deadline!.day}'
                                    : '2025/10/28',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _deadline != null 
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
          
          const SizedBox(height: 16),
          
          // 时间提醒
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: const Color(0xFF3B82F6), size: 16),
                const SizedBox(width: 8),
                const Text(
                  '时间提醒',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          const Text(
            '学生将有 7 天时间完成作业',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 允许逾期提交
          Row(
            children: [
              Checkbox(
                value: _allowLateSubmission,
                onChanged: (value) {
                  setState(() {
                    _allowLateSubmission = value ?? false;
                  });
                },
                activeColor: const Color(0xFF4CAF50),
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '允许逾期提交',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Text(
                      '超过截止时间后仍可提交，但会标记为逾期',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
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

  /// 构建附件资料区域
  Widget _buildAttachmentSection() {
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
              Icon(Icons.attach_file, color: const Color(0xFF8B5CF6), size: 20),
              const SizedBox(width: 8),
              const Text(
                '附件资料',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '(可选)',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 上传区域
          GestureDetector(
            onTap: _selectAttachment,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  style: BorderStyle.solid,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.cloud_upload,
                      color: Color(0xFF666666),
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  const Text(
                    '点击上传附件',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  const Text(
                    '支持文档、图片、压缩包等格式，单个文件最大 50MB',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // 已上传的附件列表
          if (_attachments.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._attachments.map((attachment) => _buildAttachmentItem(attachment)),
          ],
        ],
      ),
    );
  }

  /// 构建附件项目
  Widget _buildAttachmentItem(Map<String, dynamic> attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(attachment['type']),
            color: const Color(0xFF666666),
            size: 20,
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  attachment['size'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          
          IconButton(
            onPressed: () => _removeAttachment(attachment),
            icon: const Icon(Icons.close, color: Color(0xFF666666), size: 20),
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
              onPressed: _publishAssignment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('发布作业'),
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

  /// 选择截止时间
  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _deadline = date;
      });
    }
  }

  /// 选择附件
  void _selectAttachment() {
    // 模拟文件选择
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '选择文件类型',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('图片'),
              onTap: () {
                Navigator.pop(context);
                _addMockAttachment('image');
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('文档'),
              onTap: () {
                Navigator.pop(context);
                _addMockAttachment('document');
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('压缩包'),
              onTap: () {
                Navigator.pop(context);
                _addMockAttachment('archive');
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 添加模拟附件
  void _addMockAttachment(String type) {
    final Map<String, dynamic> attachment;
    
    switch (type) {
      case 'image':
        attachment = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': '示例图片.jpg',
          'type': 'image',
          'size': '2.5 MB',
        };
        break;
      case 'document':
        attachment = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': '作业要求文档.pdf',
          'type': 'document',
          'size': '1.2 MB',
        };
        break;
      case 'archive':
        attachment = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': '参考资料.zip',
          'type': 'archive',
          'size': '15.8 MB',
        };
        break;
      default:
        return;
    }
    
    setState(() {
      _attachments.add(attachment);
    });
  }

  /// 移除附件
  void _removeAttachment(Map<String, dynamic> attachment) {
    setState(() {
      _attachments.remove(attachment);
    });
  }

  /// 获取文件图标
  IconData _getFileIcon(String type) {
    switch (type) {
      case 'image':
        return Icons.image;
      case 'document':
        return Icons.description;
      case 'archive':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
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

  /// 发布作业
  void _publishAssignment() {
    if (_formKey.currentState!.validate()) {
      // 验证截止时间
      if (_deadline == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请选择截止时间'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // 显示确认对话框
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认发布'),
          content: const Text('确定要发布这个作业吗？发布后学生将收到通知。'),
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
  Future<void> _performPublish() async {
    if (_isPublishing) return;
    
    try {
      setState(() {
        _isPublishing = true;
      });

      print('Debug: [发布作业] 开始发布作业');
      print('Debug: [发布作业] 课程ID: ${widget.courseId}');
      print('Debug: [发布作业] 作业标题: ${_titleController.text}');
      print('Debug: [发布作业] 作业类型: $_selectedType');
      print('Debug: [发布作业] 总分: ${_scoreController.text}');

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

      final token = await ApiService.getAuthToken();
      
      print('Debug: [发布作业] Token获取结果: ${token != null ? "成功" : "失败"}');
      
      if (token == null) {
        throw Exception('用户未登录');
      }

      // 构建作业数据
      final assignmentData = {
        'title': _titleController.text,
        'description': _contentController.text,
        'assignmentType': _selectedType.isNotEmpty ? _selectedType : 'homework',
        'totalScore': int.tryParse(_scoreController.text) ?? 100,
        'courseId': int.tryParse(widget.courseId ?? '1') ?? 1,
        'chapterId': _selectedChapter.isNotEmpty ? _selectedChapter : null,
        'publishTime': _publishTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'dueTime': _deadline?.toIso8601String() ?? DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'allowLateSubmission': _allowLateSubmission,
        'maxAttempts': 1,
        'attachmentRequired': false,
      };

      print('Debug: [发布作业] 作业数据: $assignmentData');
      print('Debug: [发布作业] 调用AssignmentService.createAssignment');

      final response = await AssignmentService.createAssignment(
        token: token,
        assignmentData: assignmentData,
      );

      print('Debug: [发布作业] API响应: $response');

      if (mounted) {
        Navigator.pop(context); // 关闭加载对话框
      }

      if (response['error'] == 0) {
        print('Debug: [发布作业] 发布成功');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('作业发布成功！'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          
          // 返回上一页
          Navigator.pop(context, true);
        }
      } else {
        print('Debug: [发布作业] 发布失败: ${response['message']}');
        throw Exception(response['message'] ?? '发布失败');
      }
    } catch (e) {
      print('Debug: [发布作业] 捕获异常: $e');
      
      if (mounted) {
        Navigator.pop(context); // 关闭加载对话框
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发布失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _scoreController.dispose();
    super.dispose();
  }
}
