import 'package:flutter/material.dart';
import 'dart:io';

/// 上传课程资料页面
class TeacherUploadMaterialsPage extends StatefulWidget {
  final String? courseId;
  final String? courseName;
  
  const TeacherUploadMaterialsPage({
    super.key,
    this.courseId,
    this.courseName,
  });

  @override
  State<TeacherUploadMaterialsPage> createState() => _TeacherUploadMaterialsPageState();
}

class _TeacherUploadMaterialsPageState extends State<TeacherUploadMaterialsPage> {
  final _formKey = GlobalKey<FormState>();
  
  // 表单控制器
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // 选择的值
  String _selectedType = '';
  String _selectedChapter = '';
  
  // 上传的文件列表
  List<Map<String, dynamic>> _uploadedFiles = [];
  
  // 资料类型选项
  final List<Map<String, String>> _materialTypes = [
    {'value': 'courseware', 'label': '课件资料'},
    {'value': 'video', 'label': '视频资料'},
    {'value': 'document', 'label': '文档资料'},
    {'value': 'code', 'label': '代码资料'},
    {'value': 'reference', 'label': '参考资料'},
  ];
  
  // 章节选项
  final List<Map<String, String>> _chapters = [
    {'value': 'chapter1', 'label': '选择章节'},
    {'value': 'chapter2', 'label': '第1章'},
    {'value': 'chapter3', 'label': '第2章'},
    {'value': 'chapter4', 'label': '第3章'},
    {'value': 'chapter5', 'label': '第4章'},
    {'value': 'chapter6', 'label': '第5章'},
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
          '上传课程资料',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _clearAll,
            icon: const Icon(Icons.refresh, color: Color(0xFF333333)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 选择文件区域
              _buildFileUploadSection(),
              
              const SizedBox(height: 16),
              
              // 待上传文件列表
              if (_uploadedFiles.isNotEmpty) _buildFileListSection(),
              
              const SizedBox(height: 16),
              
              // 资料信息
              _buildMaterialInfoSection(),
              
              const SizedBox(height: 100), // 为底部按钮留空间
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  /// 构建文件上传区域
  Widget _buildFileUploadSection() {
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
                  Icons.cloud_upload,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '选择文件',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 上传区域
          GestureDetector(
            onTap: _selectFiles,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
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
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      color: Color(0xFF94A3B8),
                      size: 30,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Text(
                    '点击上传文件',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  const Text(
                    '或将文件拖拽到此区域',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 文件类型标签
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFileTypeTag('PPT', const Color(0xFFD97706)),
                      _buildFileTypeTag('PDF', const Color(0xFFDC2626)),
                      _buildFileTypeTag('Word', const Color(0xFF2563EB)),
                      _buildFileTypeTag('视频', const Color(0xFF7C3AED)),
                      _buildFileTypeTag('音频', const Color(0xFFEF4444)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          const Text(
            '支持多文件上传，单个文件最大200MB，总大小不超过1GB',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建文件类型标签
  Widget _buildFileTypeTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  /// 构建文件列表区域
  Widget _buildFileListSection() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '待上传文件',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              
              TextButton.icon(
                onPressed: _clearAllFiles,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('清空'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF666666),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 文件列表
          ..._uploadedFiles.map((file) => _buildFileItem(file)),
          
          const SizedBox(height: 12),
          
          // 统计信息
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '总大小',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  _calculateTotalSize(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '文件数量',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${_uploadedFiles.length}个',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建文件项目
  Widget _buildFileItem(Map<String, dynamic> file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getFileTypeColor(file['type']),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileTypeIcon(file['type']),
              color: Colors.white,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${file['size']} · ${_getFileTypeLabel(file['type'])}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          
          IconButton(
            onPressed: () => _removeFile(file),
            icon: const Icon(
              Icons.close,
              color: Color(0xFFEF4444),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建资料信息区域
  Widget _buildMaterialInfoSection() {
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
                  Icons.info,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '资料信息',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 资料标题
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: '资料标题',
              hintText: '请输入资料标题（可选）',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLength: 50,
            onChanged: (value) {
              setState(() {});
            },
          ),
          
          const SizedBox(height: 16),
          
          // 资料类型和所属章节
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedType.isEmpty ? null : _selectedType,
                  decoration: InputDecoration(
                    labelText: '资料类型',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _materialTypes.map((type) {
                    return DropdownMenuItem(
                      value: type['value'],
                      child: Text(
                        type['label']!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value ?? '';
                    });
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: DropdownButtonFormField<String>(
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
                      child: Text(
                        chapter['label']!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedChapter = value ?? '';
                    });
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 资料描述
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: '资料描述',
              hintText: '请简要描述资料内容、用途等...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixText: '${_descriptionController.text.length}/300',
            ),
            maxLines: 4,
            maxLength: 300,
            onChanged: (value) {
              setState(() {});
            },
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
              onPressed: _uploadedFiles.isEmpty ? null : _uploadMaterials,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('上传资料'),
            ),
          ),
        ],
      ),
    );
  }

  /// 选择文件
  void _selectFiles() {
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
              leading: const Icon(Icons.image, color: Color(0xFF8B5CF6)),
              title: const Text('图片文件'),
              subtitle: const Text('JPG, PNG, GIF'),
              onTap: () {
                Navigator.pop(context);
                _addMockFile('image');
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Color(0xFF3B82F6)),
              title: const Text('文档文件'),
              subtitle: const Text('PDF, DOC, PPT'),
              onTap: () {
                Navigator.pop(context);
                _addMockFile('document');
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library, color: Color(0xFFEF4444)),
              title: const Text('视频文件'),
              subtitle: const Text('MP4, AVI, MOV'),
              onTap: () {
                Navigator.pop(context);
                _addMockFile('video');
              },
            ),
            ListTile(
              leading: const Icon(Icons.audiotrack, color: Color(0xFFF59E0B)),
              title: const Text('音频文件'),
              subtitle: const Text('MP3, WAV, AAC'),
              onTap: () {
                Navigator.pop(context);
                _addMockFile('audio');
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 添加模拟文件
  void _addMockFile(String type) {
    final Map<String, dynamic> file;
    
    switch (type) {
      case 'image':
        file = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': '壁纸4.jpg',
          'type': 'image',
          'size': '261.87 KB',
          'sizeBytes': 268162,
        };
        break;
      case 'document':
        file = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': '数据结构课件.pptx',
          'type': 'document',
          'size': '15.2 MB',
          'sizeBytes': 15943680,
        };
        break;
      case 'video':
        file = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': '算法演示视频.mp4',
          'type': 'video',
          'size': '128.5 MB',
          'sizeBytes': 134742016,
        };
        break;
      case 'audio':
        file = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': '课程录音.mp3',
          'type': 'audio',
          'size': '45.3 MB',
          'sizeBytes': 47513600,
        };
        break;
      default:
        return;
    }
    
    setState(() {
      _uploadedFiles.add(file);
    });
  }

  /// 移除文件
  void _removeFile(Map<String, dynamic> file) {
    setState(() {
      _uploadedFiles.remove(file);
    });
  }

  /// 清空所有文件
  void _clearAllFiles() {
    if (_uploadedFiles.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认清空'),
          content: const Text('确定要清空所有文件吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _uploadedFiles.clear();
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }

  /// 清空所有内容
  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置页面'),
        content: const Text('确定要清空所有内容并重置页面吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _uploadedFiles.clear();
                _titleController.clear();
                _descriptionController.clear();
                _selectedType = '';
                _selectedChapter = '';
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 计算总文件大小
  String _calculateTotalSize() {
    int totalBytes = _uploadedFiles.fold(0, (sum, file) => sum + (file['sizeBytes'] as int));
    
    if (totalBytes < 1024) {
      return '${totalBytes} B';
    } else if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else if (totalBytes < 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// 获取文件类型图标
  IconData _getFileTypeIcon(String type) {
    switch (type) {
      case 'image':
        return Icons.image;
      case 'document':
        return Icons.description;
      case 'video':
        return Icons.video_library;
      case 'audio':
        return Icons.audiotrack;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// 获取文件类型颜色
  Color _getFileTypeColor(String type) {
    switch (type) {
      case 'image':
        return const Color(0xFF8B5CF6);
      case 'document':
        return const Color(0xFF3B82F6);
      case 'video':
        return const Color(0xFFEF4444);
      case 'audio':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF666666);
    }
  }

  /// 获取文件类型标签
  String _getFileTypeLabel(String type) {
    switch (type) {
      case 'image':
        return '图片文件';
      case 'document':
        return '文档文件';
      case 'video':
        return '视频文件';
      case 'audio':
        return '音频文件';
      default:
        return '未知文件';
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

  /// 上传资料
  void _uploadMaterials() {
    if (_uploadedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先选择要上传的文件'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // 显示确认对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认上传'),
        content: Text('确定要上传 ${_uploadedFiles.length} 个文件吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performUpload();
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

  /// 执行上传操作
  void _performUpload() {
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
    
    // 模拟上传过程
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context); // 关闭加载对话框
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('成功上传 ${_uploadedFiles.length} 个文件！'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
      
      // 返回上一页
      Navigator.pop(context, true);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
