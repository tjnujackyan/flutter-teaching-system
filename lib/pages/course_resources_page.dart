import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html show window;
import '../services/resource_service.dart';
import '../services/file_upload_service.dart';
import '../services/api_service.dart';
import 'resource_detail_page.dart';

/// 课程资料管理页面
class CourseResourcesPage extends StatefulWidget {
  final int courseId;
  final String courseName;

  const CourseResourcesPage({
    Key? key,
    required this.courseId,
    required this.courseName,
  }) : super(key: key);

  @override
  State<CourseResourcesPage> createState() => _CourseResourcesPageState();
}

class _CourseResourcesPageState extends State<CourseResourcesPage> {
  final ResourceService _resourceService = ResourceService();
  
  List<Map<String, dynamic>> _resources = [];
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategory;
  bool _isLoading = false;
  bool _isUploading = false;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;

  // 默认分类配置
  static const List<Map<String, dynamic>> _defaultCategories = [
    {'key': 'courseware', 'name': '课件资料', 'icon': '📖'},
    {'key': 'reference', 'name': '参考资料', 'icon': '📚'},
    {'key': 'template', 'name': '作业模板', 'icon': '📝'},
    {'key': 'video', 'name': '视频资料', 'icon': '🎥'},
    {'key': 'code', 'name': '代码资料', 'icon': '💻'},
    {'key': 'other', 'name': '其他资料', 'icon': '📎'},
  ];

  @override
  void initState() {
    super.initState();
    _categories = List.from(_defaultCategories); // 先使用默认分类
    _loadCategories();
    _loadResources();
  }

  /// 加载资料分类配置
  Future<void> _loadCategories() async {
    try {
      final response = await _resourceService.getResourceCategories();
      if (response['error'] == 0 && response['body'] != null) {
        final loadedCategories = List<Map<String, dynamic>>.from(response['body']);
        if (loadedCategories.isNotEmpty) {
          setState(() {
            _categories = loadedCategories;
          });
        }
      }
    } catch (e) {
      // 加载失败时使用默认分类，不显示错误
      debugPrint('加载分类配置失败，使用默认分类: $e');
    }
  }

  /// 加载课程资料列表
  Future<void> _loadResources({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = 1;
        _resources.clear();
        _hasMore = true;
      }
    });

    try {
      final response = await _resourceService.getCourseResources(
        courseId: widget.courseId,
        category: _selectedCategory,
        page: _currentPage,
        size: _pageSize,
      );

      if (response['error'] == 0) {
        final data = response['body'];
        final newResources = List<Map<String, dynamic>>.from(data['resources'] ?? []);
        
        setState(() {
          if (refresh) {
            _resources = newResources;
          } else {
            _resources.addAll(newResources);
          }
          _hasMore = newResources.length >= _pageSize;
          _currentPage++;
        });
      }
    } catch (e) {
      _showErrorSnackBar('加载资料列表失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 上传资料 - 使用跨平台文件选择
  Future<void> _uploadResource() async {
    try {
      // 使用跨平台文件选择器
      final file = await FileUploadService.pickSingleFile();

      if (file != null) {
        // 显示上传对话框
        _showUploadDialog(file);
      }
    } catch (e) {
      _showErrorSnackBar('选择文件失败: $e');
    }
  }

  /// 显示上传对话框
  void _showUploadDialog(CrossPlatformFile file) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final chapterController = TextEditingController();
    String selectedCategory = _categories.isNotEmpty ? (_categories.first['key'] ?? 'other') : 'other';
    bool isPublic = true;
    bool isDownloadable = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('上传课程资料'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 文件信息
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(file.typeIcon, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(file.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(file.formattedSize, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // 资料标题
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '资料标题 *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                
                // 资料描述
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: '资料描述', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                
                // 分类选择
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: '资料分类 *', border: OutlineInputBorder()),
                  items: _categories.map((category) {
                    final key = category['key'] as String?;
                    final name = category['name'] as String?;
                    final icon = category['icon'] as String?;
                    
                    return DropdownMenuItem<String>(
                      value: key ?? 'other',
                      child: Row(
                        children: [
                          Text(icon ?? '📎', style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(name ?? '未知'),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedCategory = value!),
                ),
                const SizedBox(height: 16),
                
                // 章节名称
                TextField(
                  controller: chapterController,
                  decoration: const InputDecoration(labelText: '章节名称', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                
                // 权限设置
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('公开资料'),
                        subtitle: const Text('学生可见'),
                        value: isPublic,
                        onChanged: (value) => setState(() => isPublic = value!),
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('允许下载'),
                        subtitle: const Text('可下载'),
                        value: isDownloadable,
                        onChanged: (value) => setState(() => isDownloadable = value!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(
              onPressed: _isUploading ? null : () async {
                if (titleController.text.trim().isEmpty) {
                  _showErrorSnackBar('请输入资料标题');
                  return;
                }
                Navigator.pop(context);
                await _performUpload(
                  file: file,
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  category: selectedCategory,
                  chapterName: chapterController.text.trim(),
                  isPublic: isPublic,
                  isDownloadable: isDownloadable,
                );
              },
              child: _isUploading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('上传'),
            ),
          ],
        ),
      ),
    );
  }

  /// 执行上传 - 使用跨平台文件上传
  Future<void> _performUpload({
    required CrossPlatformFile file,
    required String title,
    String? description,
    required String category,
    String? chapterName,
    required bool isPublic,
    required bool isDownloadable,
  }) async {
    setState(() => _isUploading = true);

    try {
      final response = await FileUploadService.uploadCourseResource(
        courseId: widget.courseId,
        file: file,
        title: title,
        description: description,
        category: category,
        chapterName: chapterName,
        isPublic: isPublic,
        isDownloadable: isDownloadable,
      );

      if (response['error'] == 0) {
        _showSuccessSnackBar('资料上传成功');
        _loadResources(refresh: true);
      } else {
        _showErrorSnackBar(response['message'] ?? '上传失败');
      }
    } catch (e) {
      _showErrorSnackBar('上传失败: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// 删除资料
  Future<void> _deleteResource(Map<String, dynamic> resource) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除资料"${resource['title']}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _resourceService.deleteResource(resource['id']);
        if (response['error'] == 0) {
          _showSuccessSnackBar('删除成功');
          _loadResources(refresh: true);
        } else {
          _showErrorSnackBar(response['message'] ?? '删除失败');
        }
      } catch (e) {
        _showErrorSnackBar('删除失败: $e');
      }
    }
  }

  /// 编辑资料
  Future<void> _editResource(Map<String, dynamic> resource) async {
    final titleController = TextEditingController(text: resource['title']);
    final descriptionController = TextEditingController(text: resource['description'] ?? '');
    final chapterController = TextEditingController(text: resource['chapterName'] ?? '');
    String selectedCategory = resource['category'] ?? 'other';
    bool isPublic = resource['isPublic'] ?? true;
    bool isDownloadable = resource['isDownloadable'] ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('编辑资料信息'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '资料标题 *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: '资料描述', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: '资料分类 *', border: OutlineInputBorder()),
                  items: _categories.map((category) {
                    final key = category['key'] as String?;
                    final name = category['name'] as String?;
                    final icon = category['icon'] as String?;
                    
                    return DropdownMenuItem<String>(
                      value: key ?? 'other',
                      child: Row(
                        children: [
                          Text(icon ?? '📎', style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(name ?? '未知'),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedCategory = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: chapterController,
                  decoration: const InputDecoration(labelText: '章节名称', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('公开资料'),
                        value: isPublic,
                        onChanged: (value) => setState(() => isPublic = value!),
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('允许下载'),
                        value: isDownloadable,
                        onChanged: (value) => setState(() => isDownloadable = value!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  _showErrorSnackBar('请输入资料标题');
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final response = await _resourceService.updateResource(
          resourceId: resource['id'],
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          category: selectedCategory,
          chapterName: chapterController.text.trim(),
          isPublic: isPublic,
          isDownloadable: isDownloadable,
        );

        if (response['error'] == 0) {
          _showSuccessSnackBar('更新成功');
          _loadResources(refresh: true);
        } else {
          _showErrorSnackBar(response['message'] ?? '更新失败');
        }
      } catch (e) {
        _showErrorSnackBar('更新失败: $e');
      }
    }
  }

  /// 下载资料
  Future<void> _downloadResource(Map<String, dynamic> resource) async {
    try {
      setState(() => _isUploading = true);
      _showSuccessSnackBar('正在准备下载: ${resource['title']}');
      
      if (kIsWeb) {
        // Web平台使用 API 下载并创建 Blob
        final response = await _resourceService.downloadResource(
          courseId: widget.courseId,
          resourceId: resource['id'],
          savePath: '', // Web 不需要路径
        );
        
        _showSuccessSnackBar('下载完成');
      } else {
        // 移动端下载逻辑
        _showErrorSnackBar('移动端下载功能待实现');
      }
    } catch (e) {
      _showErrorSnackBar('下载失败: $e');
    } finally {
      setState(() => _isUploading = false);
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
        title: Text('${widget.courseName} - 课程资料'),
        actions: [
          IconButton(
            onPressed: _uploadResource,
            icon: const Icon(Icons.upload_file),
            tooltip: '上传资料',
          ),
        ],
      ),
      body: Column(
        children: [
          // 分类筛选
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('全部'),
                    selected: _selectedCategory == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = null;
                      });
                      _loadResources(refresh: true);
                    },
                  ),
                  const SizedBox(width: 8),
                  ..._categories.map((category) {
                    final key = category['key'] as String?;
                    final name = category['name'] as String?;
                    final icon = category['icon'] as String?;
                    final isSelected = _selectedCategory == key;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(icon ?? '📎'),
                            const SizedBox(width: 4),
                            Text(name ?? '未知'),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? key : null;
                          });
                          _loadResources(refresh: true);
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          
          // 资料列表
          Expanded(
            child: _resources.isEmpty && !_isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '暂无课程资料',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _resources.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _resources.length) {
                      // 加载更多指示器
                      if (!_isLoading) {
                        _loadResources();
                      }
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final resource = _resources[index];
                    return _buildResourceItem(resource);
                  },
                ),
          ),
        ],
      ),
    );
  }

  /// 构建资料项
  Widget _buildResourceItem(Map<String, dynamic> resource) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            _resourceService.getFileTypeIcon(resource['fileExtension'] ?? ''),
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          resource['title'] ?? '未知标题',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resource['description'] != null && resource['description'].isNotEmpty)
              Text(
                resource['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(int.parse(
                      _resourceService.getCategoryColor(resource['category'] ?? 'other')
                        .replaceFirst('#', '0xFF'),
                    )),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _resourceService.getCategoryName(resource['category'] ?? 'other'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _resourceService.formatFileSize(resource['fileSize'] ?? 0),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (resource['chapterName'] != null && resource['chapterName'].isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    resource['chapterName'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editResource(resource);
                break;
              case 'delete':
                _deleteResource(resource);
                break;
              case 'download':
                _downloadResource(resource);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('编辑'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('下载'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('删除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResourceDetailPage(
                courseId: widget.courseId,
                resourceId: resource['id'],
                resourceTitle: resource['title'] ?? '资料详情',
              ),
            ),
          );
        },
      ),
    );
  }
}
