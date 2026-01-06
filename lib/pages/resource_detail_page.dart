import 'package:flutter/material.dart';
import '../services/resource_service.dart';
import '../models/resource_models.dart';

/// 资料详情页面
class ResourceDetailPage extends StatefulWidget {
  final int courseId;
  final int resourceId;
  final String resourceTitle;

  const ResourceDetailPage({
    Key? key,
    required this.courseId,
    required this.resourceId,
    required this.resourceTitle,
  }) : super(key: key);

  @override
  State<ResourceDetailPage> createState() => _ResourceDetailPageState();
}

class _ResourceDetailPageState extends State<ResourceDetailPage> {
  final ResourceService _resourceService = ResourceService();
  
  ResourceDetailResponse? _resourceDetail;
  bool _isLoading = true;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadResourceDetail();
  }

  /// 加载资料详情
  Future<void> _loadResourceDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _resourceService.getResourceDetail(
        courseId: widget.courseId,
        resourceId: widget.resourceId,
      );

      if (response['error'] == 0) {
        setState(() {
          _resourceDetail = ResourceDetailResponse.fromJson(response['body']);
        });
      } else {
        _showErrorSnackBar(response['message'] ?? '加载失败');
      }
    } catch (e) {
      _showErrorSnackBar('加载资料详情失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 下载资料
  Future<void> _downloadResource() async {
    if (_resourceDetail == null || _isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      // 这里应该实现实际的下载逻辑
      // 由于Flutter Web的限制，这里只是模拟下载进度
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {
          _downloadProgress = i / 100;
        });
      }

      _showSuccessSnackBar('下载完成');
    } catch (e) {
      _showErrorSnackBar('下载失败: $e');
    } finally {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
    }
  }

  /// 显示成功提示
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.resourceTitle),
        actions: [
          if (_resourceDetail?.resource.isDownloadable == true)
            IconButton(
              onPressed: _isDownloading ? null : _downloadResource,
              icon: _isDownloading 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      value: _downloadProgress,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download),
              tooltip: '下载资料',
            ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _resourceDetail == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('加载失败', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResourceInfo(),
                  const SizedBox(height: 24),
                  _buildAccessStats(),
                  const SizedBox(height: 24),
                  _buildRelatedResources(),
                ],
              ),
            ),
    );
  }

  /// 构建资料信息卡片
  Widget _buildResourceInfo() {
    final resource = _resourceDetail!.resource;
    final uploader = _resourceDetail!.uploader;
    final course = _resourceDetail!.course;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 资料标题和图标
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _resourceService.getFileTypeIcon(resource.fileExtension),
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
                        resource.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        resource.fileName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 资料描述
            if (resource.description != null && resource.description!.isNotEmpty) ...[
              const Text(
                '资料描述',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                resource.description!,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
            ],
            
            // 资料信息
            const Text(
              '资料信息',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            _buildInfoRow('所属课程', '${course.icon} ${course.courseName}'),
            _buildInfoRow('文件大小', _resourceService.formatFileSize(resource.fileSize)),
            _buildInfoRow('文件类型', resource.fileType.toUpperCase()),
            _buildInfoRow('资料分类', _resourceService.getCategoryName(resource.category)),
            if (resource.chapterName != null && resource.chapterName!.isNotEmpty)
              _buildInfoRow('所属章节', resource.chapterName!),
            _buildInfoRow('上传者', uploader.name),
            _buildInfoRow('上传时间', _formatDateTime(resource.createdAt)),
            _buildInfoRow('更新时间', _formatDateTime(resource.updatedAt)),
            
            const SizedBox(height: 16),
            
            // 权限信息
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: resource.isPublic ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    resource.isPublic ? '公开资料' : '仅教师可见',
                    style: TextStyle(
                      color: resource.isPublic ? Colors.green[800] : Colors.orange[800],
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: resource.isDownloadable ? Colors.blue[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    resource.isDownloadable ? '允许下载' : '仅在线查看',
                    style: TextStyle(
                      color: resource.isDownloadable ? Colors.blue[800] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建访问统计卡片
  Widget _buildAccessStats() {
    final stats = _resourceDetail!.accessStats;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '访问统计',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('总查看次数', stats.totalViews.toString(), Icons.visibility),
                ),
                Expanded(
                  child: _buildStatItem('总下载次数', stats.totalDownloads.toString(), Icons.download),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('今日查看', stats.todayViews.toString(), Icons.today),
                ),
                Expanded(
                  child: _buildStatItem('今日下载', stats.todayDownloads.toString(), Icons.file_download),
                ),
              ],
            ),
            
            if (stats.recentAccess.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                '最近访问',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...stats.recentAccess.take(5).map((access) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      access.actionType == 'download' ? Icons.download : Icons.visibility,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      access.userName,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      _formatDateTime(access.accessTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建相关资料卡片
  Widget _buildRelatedResources() {
    final relatedResources = _resourceDetail!.relatedResources;
    
    if (relatedResources.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '相关资料',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ...relatedResources.map((resource) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Text(
                  _resourceService.getFileTypeIcon(resource.fileExtension),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              title: Text(
                resource.title,
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                _resourceService.formatFileSize(resource.fileSize),
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResourceDetailPage(
                      courseId: widget.courseId,
                      resourceId: resource.id,
                      resourceTitle: resource.title,
                    ),
                  ),
                );
              },
            )).toList(),
          ],
        ),
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[600]),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}
