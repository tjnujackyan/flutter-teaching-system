import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/assignment_service.dart';

/// 参考资料模型
class ReferenceResource {
  final String id;
  final String name;
  final String size;
  final String uploadTime;
  final ResourceType type;

  ReferenceResource({
    required this.id,
    required this.name,
    required this.size,
    required this.uploadTime,
    required this.type,
  });
}

/// 资源类型枚举
enum ResourceType {
  pdf('PDF', Icons.picture_as_pdf, Color(0xFFE53935)),
  cpp('代码', Icons.code, Color(0xFF4CAF50)),
  video('视频', Icons.play_circle_filled, Color(0xFF2196F3));

  const ResourceType(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

/// 作业详情页面
class AssignmentDetailPage extends StatefulWidget {
  final String assignmentId;
  final String assignmentTitle;
  final String courseName;
  final String teacherName;

  const AssignmentDetailPage({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.courseName,
    required this.teacherName,
  });

  @override
  State<AssignmentDetailPage> createState() => _AssignmentDetailPageState();
}

class _AssignmentDetailPageState extends State<AssignmentDetailPage> {
  bool _isSubmitted = false;
  int _daysLeft = 3;
  int _totalScore = 100;
  double _completionRate = 0.85;
  
  List<ReferenceResource> _references = [];
  
  // 提交相关状态
  final TextEditingController _contentController = TextEditingController();
  bool _isSubmitting = false;
  List<File> _selectedFiles = [];
  
  @override
  void initState() {
    super.initState();
    _initializeReferences();
  }

  /// 初始化参考资料
  void _initializeReferences() {
    _references = [
      ReferenceResource(
        id: '1',
        name: '数据结构设计指南.pdf',
        size: '2.5MB',
        uploadTime: '昨天上传',
        type: ResourceType.pdf,
      ),
      ReferenceResource(
        id: '2',
        name: '示例代码模板.cpp',
        size: '15KB',
        uploadTime: '3天前上传',
        type: ResourceType.cpp,
      ),
      ReferenceResource(
        id: '3',
        name: '链表操作讲解视频',
        size: '25分钟',
        uploadTime: '1周前上传',
        type: ResourceType.video,
      ),
    ];
  }

  /// 下载资源
  void _downloadResource(ReferenceResource resource) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('开始下载：${resource.name}')),
    );
  }

  /// 播放视频
  void _playVideo(ReferenceResource resource) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('播放视频：${resource.name}')),
    );
  }

  /// 分享作业
  void _shareAssignment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能开发中')),
    );
  }

  /// 开始提交作业
  void _startSubmission() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSubmissionSheet(),
    );
  }

  /// 提交作业
  Future<void> _submitAssignment() async {
    if (_isSubmitting) return;
    
    try {
      print('Debug: [作业提交] 开始提交作业');
      print('Debug: [作业提交] 作业ID: ${widget.assignmentId}');
      print('Debug: [作业提交] 内容长度: ${_contentController.text.length}');
      print('Debug: [作业提交] 文件数量: ${_selectedFiles.length}');
      
      setState(() {
        _isSubmitting = true;
      });

      final token = await ApiService.getAuthToken();
      
      print('Debug: [作业提交] Token获取结果: ${token != null ? "成功" : "失败"}');
      
      if (token == null) {
        throw Exception('用户未登录');
      }

      print('Debug: [作业提交] 调用AssignmentService.submitAssignment');
      final response = await AssignmentService.submitAssignment(
        token: token,
        assignmentId: int.parse(widget.assignmentId),
        content: _contentController.text.isNotEmpty ? _contentController.text : null,
        files: _selectedFiles,
      );

      print('Debug: [作业提交] API响应: $response');
      
      if (response['error'] == 0) {
        print('Debug: [作业提交] 提交成功');
      
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('作业提交成功'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          setState(() {
            _isSubmitted = true;
          });
        }
      } else {
        print('Debug: [作业提交] 提交失败: ${response['message']}');
        throw Exception(response['message'] ?? '提交失败');
      }
    } catch (e) {
      print('Debug: [作业提交] 捕获异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '作业详情',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF666666)),
            onPressed: _shareAssignment,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 作业信息卡片
            _buildAssignmentInfoCard(),
            
            // 统计信息
            _buildStatsRow(),
            
            // 作业要求
            _buildRequirementsSection(),
            
            // 参考资料
            _buildReferencesSection(),
            
            // 我的提交
            _buildSubmissionSection(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 构建作业信息卡片
  Widget _buildAssignmentInfoCard() {
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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.code,
              color: Colors.white,
              size: 30,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.assignmentTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.courseName} · ${widget.teacherName}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '进行中',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '还有${_daysLeft}天',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计信息行
  Widget _buildStatsRow() {
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
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              value: '$_totalScore',
              label: '总分',
              color: const Color(0xFF4285F4),
            ),
          ),
          Expanded(
            child: _buildStatItem(
              value: '$_daysLeft',
              label: '剩余天数',
              color: const Color(0xFFFF9800),
            ),
          ),
          Expanded(
            child: _buildStatItem(
              value: '${(_completionRate * 100).toInt()}%',
              label: '完成率',
              color: const Color(0xFF4CAF50),
            ),
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
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  /// 构建作业要求区域
  Widget _buildRequirementsSection() {
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
              const Icon(
                Icons.assignment,
                color: Color(0xFF4285F4),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '作业要求',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            '题目：设计并实现一个学生成绩管理系统',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          
          const SizedBox(height: 12),
          
          const Text(
            '要求：',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          
          const SizedBox(height: 8),
          
          ..._buildRequirementsList(),
          
          const SizedBox(height: 16),
          
          _buildSubmissionFormat(),
          
          const SizedBox(height: 16),
          
          _buildDeadline(),
        ],
      ),
    );
  }

  /// 构建要求列表
  List<Widget> _buildRequirementsList() {
    final requirements = [
      '使用链表或数据库实现学生信息存储',
      '实现增删改查基本功能',
      '支持按成绩排序和统计功能',
      '提供友好的用户界面',
      '代码需要有详细注释',
    ];

    return requirements.map((requirement) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF4285F4),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              requirement,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }

  /// 构建提交格式
  Widget _buildSubmissionFormat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '提交格式：',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '源代码文件（.cpp/.java）+ 设计文档（.doc/.pdf）+ 运行截图',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建截止时间
  Widget _buildDeadline() {
    return Row(
      children: [
        const Icon(
          Icons.schedule,
          color: Color(0xFFFF5722),
          size: 20,
        ),
        const SizedBox(width: 8),
        const Text(
          '截止时间：',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const Text(
          '2024年10月25日 23:59',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFFFF5722),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// 构建参考资料区域
  Widget _buildReferencesSection() {
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
            children: [
              const Icon(
                Icons.library_books,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '参考资料',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          ...List.generate(_references.length, (index) {
            return _buildReferenceItem(_references[index]);
          }),
        ],
      ),
    );
  }

  /// 构建参考资料项目
  Widget _buildReferenceItem(ReferenceResource resource) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: resource.type.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              resource.type.icon,
              color: resource.type.color,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${resource.size} · ${resource.uploadTime}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          
          IconButton(
            onPressed: () {
              if (resource.type == ResourceType.video) {
                _playVideo(resource);
              } else {
                _downloadResource(resource);
              }
            },
            icon: Icon(
              resource.type == ResourceType.video ? Icons.play_arrow : Icons.download,
              color: const Color(0xFF4285F4),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建提交区域
  Widget _buildSubmissionSection() {
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
              const Icon(
                Icons.cloud_upload,
                color: Color(0xFFFF9800),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '我的提交',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          if (!_isSubmitted) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFE082),
                  style: BorderStyle.solid,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_upload,
                      color: Color(0xFFFF9800),
                      size: 30,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Text(
                    '尚未提交作业',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  const Text(
                    '请在截止时间前完成作业提交',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startSubmission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text(
                        '开始提交作业',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建提交底部弹窗
  Widget _buildSubmissionSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 拖拽指示器
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 标题
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              '提交作业',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ),
          
          // 内容区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // 作业内容输入
                  TextField(
                    controller: _contentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: '请输入作业内容或说明（可选）',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF4285F4)),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 文件上传区域
                  Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 40,
                          color: Color(0xFF999999),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '点击或拖拽文件到此处上传',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 提交按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitAssignment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              '确认提交',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}
