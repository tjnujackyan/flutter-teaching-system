import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/assignment_service.dart';
import '../services/file_upload_service.dart';

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
  int _daysLeft = 0;
  int _totalScore = 0;
  double _completionRate = 0.0;
  
  List<ReferenceResource> _references = [];
  Map<String, dynamic>? _assignmentData;
  bool _isLoading = true;
  String? _errorMessage;
  
  // 提交相关状态
  final TextEditingController _contentController = TextEditingController();
  bool _isSubmitting = false;
  List<CrossPlatformFile> _selectedFiles = [];
  
  @override
  void initState() {
    super.initState();
    _loadAssignmentDetail();
  }

  /// 加载作业详情
  Future<void> _loadAssignmentDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final token = await ApiService.getAuthToken();
      if (token == null) {
        throw Exception('用户未登录');
      }

      final response = await AssignmentService.getAssignmentDetail(
        token: token,
        assignmentId: int.parse(widget.assignmentId),
      );

      if (response['error'] == 0) {
        final data = response['body'];
        print('Debug: 作业详情数据 = $data');
        print('Debug: attachments = ${data['attachments']}');
        print('Debug: isSubmitted = ${data['isSubmitted']}');
        
        setState(() {
          _assignmentData = data;
          _totalScore = data['totalScore'] ?? 100;
          
          // 计算剩余天数
          if (data['deadline'] != null) {
            final deadline = DateTime.parse(data['deadline']);
            final now = DateTime.now();
            _daysLeft = deadline.difference(now).inDays;
            if (_daysLeft < 0) _daysLeft = 0;
          }
          
          // 解析参考资料
          if (data['attachments'] != null && data['attachments'] is List) {
            print('Debug: 开始解析 ${(data['attachments'] as List).length} 个附件');
            _references = (data['attachments'] as List).map((attachment) {
              print('Debug: 附件数据 = $attachment');
              return ReferenceResource(
                id: attachment['id'].toString(),
                name: attachment['fileName'] ?? '未知文件',
                size: _formatFileSize(attachment['fileSize'] ?? 0),
                uploadTime: _formatUploadTime(attachment['uploadTime']),
                type: _getResourceType(attachment['fileName'] ?? ''),
              );
            }).toList();
            print('Debug: 解析完成，共 ${_references.length} 个参考资料');
          } else {
            print('Debug: attachments 为空或不是列表');
          }
          
          // 检查是否已提交
          _isSubmitted = data['isSubmitted'] ?? false;
          print('Debug: _isSubmitted = $_isSubmitted');
          _completionRate = (data['completionRate'] ?? 0.0) / 100.0;
          
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? '加载失败');
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载作业详情失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// 格式化上传时间
  String _formatUploadTime(String? timeStr) {
    if (timeStr == null) return '未知时间';
    try {
      final time = DateTime.parse(timeStr);
      final now = DateTime.now();
      final diff = now.difference(time);
      
      if (diff.inDays > 0) return '${diff.inDays}天前上传';
      if (diff.inHours > 0) return '${diff.inHours}小时前上传';
      return '刚刚上传';
    } catch (e) {
      return '未知时间';
    }
  }

  /// 获取资源类型
  ResourceType _getResourceType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (ext == 'pdf') return ResourceType.pdf;
    if (ext == 'cpp' || ext == 'java' || ext == 'py') return ResourceType.cpp;
    if (ext == 'mp4' || ext == 'avi' || ext == 'mov') return ResourceType.video;
    return ResourceType.pdf;
  }

  /// 初始化参考资料（已废弃，改用API数据）
  void _initializeReferences() {
    // 不再使用静态数据
  }

  /// 下载资源
  Future<void> _downloadResource(ReferenceResource resource) async {
    // 显示下载进度对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('下载资源'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('正在下载: ${resource.name}'),
          ],
        ),
      ),
    );
    
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) {
        throw Exception('用户未登录');
      }

      // 调用下载服务
      await FileUploadService.downloadAssignmentAttachment(
        attachmentId: int.parse(resource.id),
        fileName: resource.name,
      );
      
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('下载完成'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('文件: ${resource.name}'),
                const SizedBox(height: 8),
                const Text('保存位置:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '下载文件夹/智慧教学/',
                    style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '提示: 您可以在浏览器下载管理或系统下载文件夹中找到该文件',
                  style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下载失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      setState(() => _isSubmitting = true);

      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('用户未登录');

      // 先提交作业内容
      final response = await AssignmentService.submitAssignment(
        token: token,
        assignmentId: int.parse(widget.assignmentId),
        content: _contentController.text.isNotEmpty ? _contentController.text : null,
        files: null, // 文件单独上传
      );
      
      if (response['error'] == 0) {
        // 如果有文件，上传文件
        if (_selectedFiles.isNotEmpty) {
          for (var file in _selectedFiles) {
            try {
              await FileUploadService.uploadSubmissionFile(
                assignmentId: int.parse(widget.assignmentId),
                file: file,
              );
            } catch (e) {
              debugPrint('上传文件失败: $e');
            }
          }
        }
      
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['body']['message'] ?? '作业提交成功'),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
          
          // 清空选择的文件
          _selectedFiles.clear();
          _contentController.clear();
          
          // 重新加载作业详情以显示最新提交
          await _loadAssignmentDetail();
        }
      } else {
        throw Exception(response['message'] ?? '提交失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAssignmentDetail,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 作业信息卡片
                      _buildAssignmentInfoCard(),
                      
                      // 统计信息
                      _buildStatsRow(),
                      
                      // 作业要求
                      _buildRequirementsSection(),
                      
                      // 参考资料（始终显示，即使为空）
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
    final description = _assignmentData?['description'] ?? '暂无作业要求';
    final deadline = _assignmentData?['deadline'] != null 
        ? DateTime.parse(_assignmentData!['deadline']).toString().substring(0, 16).replaceAll('T', ' ')
        : '未设置';
    
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
          
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.6,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
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
              Text(
                deadline,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFFFF5722),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
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
          
          if (_references.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  '暂无参考资料',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999999),
                  ),
                ),
              ),
            )
          else
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
          
          if (_isSubmitted) ...[
            // 已提交状态
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4CAF50),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF4CAF50),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '已提交',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                            if (_assignmentData?['attemptNumber'] != null)
                              Text(
                                '第 ${_assignmentData!['attemptNumber']} 次提交',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF666666),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_assignmentData?['submissionTime'] != null)
                    Text(
                      '提交时间: ${_formatSubmissionTime(_assignmentData!['submissionTime'])}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  if (_assignmentData?['content'] != null && (_assignmentData!['content'] as String).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      '提交内容:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _assignmentData!['content'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                  // 显示提交的文件
                  if (_assignmentData?['submissionAttachments'] != null && 
                      (_assignmentData!['submissionAttachments'] as List).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '提交文件:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(_assignmentData!['submissionAttachments'] as List).map((attachment) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file, size: 20, color: Color(0xFF666666)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    attachment['fileName'] ?? '未知文件',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  Text(
                                    _formatFileSize(attachment['fileSize'] ?? 0),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _downloadSubmissionFile(attachment),
                              icon: const Icon(Icons.download, size: 20, color: Color(0xFF4285F4)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  // 重新提交按钮
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _startSubmission,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4285F4),
                        side: const BorderSide(color: Color(0xFF4285F4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text(
                        '重新提交作业',
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
          ] else ...[
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

  /// 格式化提交时间
  String _formatSubmissionTime(String? timeStr) {
    if (timeStr == null) return '未知时间';
    try {
      final time = DateTime.parse(timeStr);
      return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '未知时间';
    }
  }

  /// 下载提交的文件
  Future<void> _downloadSubmissionFile(Map<String, dynamic> attachment) async {
    try {
      await FileUploadService.downloadAssignmentAttachment(
        attachmentId: attachment['id'],
        fileName: attachment['fileName'] ?? 'file',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('文件下载成功'),
            backgroundColor: Color(0xFF4CAF50),
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

  /// 构建提交底部弹窗
  Widget _buildSubmissionSheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('提交作业', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    TextField(
                      controller: _contentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: '请输入作业内容或说明（可选）',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4285F4))),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 文件上传区域 - 添加点击事件
                    GestureDetector(
                      onTap: () async {
                        try {
                          final file = await FileUploadService.pickSingleFile();
                          if (file != null) {
                            setSheetState(() => _selectedFiles.add(file));
                            setState(() {});
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('选择文件失败: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload, size: 36, color: Color(0xFF999999)),
                            SizedBox(height: 8),
                            Text('点击选择文件上传', style: TextStyle(color: Color(0xFF999999), fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    // 已选择的文件列表
                    if (_selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _selectedFiles.length,
                          itemBuilder: (context, index) {
                            final file = _selectedFiles[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Text(file.typeIcon, style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(file.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                        Text(file.formattedSize, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setSheetState(() => _selectedFiles.removeAt(index));
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.close, color: Color(0xFF666666), size: 20),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ] else
                      const Spacer(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitAssignment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4285F4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                            : const Text('确认提交', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}
