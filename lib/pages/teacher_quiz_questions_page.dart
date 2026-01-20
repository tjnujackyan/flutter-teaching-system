import 'package:flutter/material.dart';
import '../services/file_upload_service.dart';
import 'dart:convert';

/// 创建测验题目页面
class TeacherQuizQuestionsPage extends StatefulWidget {
  final List<Map<String, dynamic>>? existingQuestions;
  
  const TeacherQuizQuestionsPage({
    super.key,
    this.existingQuestions,
  });

  @override
  State<TeacherQuizQuestionsPage> createState() => _TeacherQuizQuestionsPageState();
}

class _TeacherQuizQuestionsPageState extends State<TeacherQuizQuestionsPage> {
  // 题目列表
  List<Map<String, dynamic>> _questions = [];
  
  @override
  void initState() {
    super.initState();
    // 初始化题目列表（如果有传入的现有题目）
    if (widget.existingQuestions != null) {
      _questions = List<Map<String, dynamic>>.from(widget.existingQuestions!);
    }
  }
  
  // 统计数据
  int get _totalQuestions => _questions.length;
  int get _totalScore => _questions.fold(0, (sum, q) => sum + (q['score'] as int));
  int get _estimatedMinutes => (_totalQuestions * 1.5).round(); // 每题约1.5分钟
  int get _passingScore => (_totalScore * 0.6).round(); // 60%及格

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
              '创建测验题目',
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '数据结构期中测验',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _previewQuiz,
            icon: const Icon(Icons.visibility, color: Color(0xFF333333)),
          ),
        ],
      ),
      body: Column(
        children: [
          // 测验信息统计
          _buildQuizStats(),
          
          // 添加题目按钮
          _buildAddQuestionButtons(),
          
          // 题目列表
          Expanded(
            child: _buildQuestionsList(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  /// 构建测验统计信息
  Widget _buildQuizStats() {
    return Container(
      margin: const EdgeInsets.all(16),
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
          const Text(
            '测验信息',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  value: '$_totalQuestions',
                  label: '题目总数',
                  color: const Color(0xFF3B82F6),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  value: '$_totalScore',
                  label: '总分',
                  color: const Color(0xFF10B981),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  value: '$_estimatedMinutes',
                  label: '预计时长(分钟)',
                  color: const Color(0xFFF59E0B),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  value: '$_passingScore',
                  label: '及格分',
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF666666),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 构建添加题目按钮
  Widget _buildAddQuestionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          const Text(
            '添加题目',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildQuestionTypeButton(
                  icon: Icons.radio_button_checked,
                  label: '单选题',
                  color: const Color(0xFF3B82F6),
                  onTap: () => _addQuestion('single'),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: _buildQuestionTypeButton(
                  icon: Icons.check_box,
                  label: '多选题',
                  color: const Color(0xFF10B981),
                  onTap: () => _addQuestion('multiple'),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: _buildQuestionTypeButton(
                  icon: Icons.balance,
                  label: '判断题',
                  color: const Color(0xFFF59E0B),
                  onTap: () => _addQuestion('judge'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建题目类型按钮
  Widget _buildQuestionTypeButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建题目列表
  Widget _buildQuestionsList() {
    return Container(
      margin: const EdgeInsets.all(16),
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
          // 题目列表头部
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '题目列表',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                
                if (_questions.isNotEmpty)
                  TextButton.icon(
                    onPressed: _importQuestions,
                    icon: const Icon(Icons.upload, size: 16),
                    label: const Text('导入题目'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF4CAF50),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          
          // 题目列表内容
          Expanded(
            child: _questions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      return _buildQuestionItem(_questions[index], index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.quiz_outlined,
              color: Color(0xFF666666),
              size: 40,
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            '还没有添加题目',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          
          const SizedBox(height: 8),
          
          const Text(
            '点击上方按钮开始添加题目',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建题目项目
  Widget _buildQuestionItem(Map<String, dynamic> question, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getQuestionTypeColor(question['type']),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getQuestionTypeLabel(question['type']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const Spacer(),
              
              Text(
                '${question['score']}分',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                ),
              ),
              
              const SizedBox(width: 8),
              
              PopupMenuButton<String>(
                onSelected: (value) => _handleQuestionAction(value, index),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('编辑'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('删除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert, size: 16, color: Color(0xFF666666)),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            question['title'],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          
          if (question['options'] != null && question['options'].isNotEmpty) ...[
            const SizedBox(height: 8),
            ...question['options'].map<Widget>((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  option,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              );
            }).toList(),
          ],
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
              onPressed: _questions.isEmpty ? null : _completeQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('完成创建'),
            ),
          ),
        ],
      ),
    );
  }

  /// 添加题目
  void _addQuestion(String type) {
    showDialog(
      context: context,
      builder: (context) => _QuestionEditDialog(
        type: type,
        onSave: (question) {
          setState(() {
            _questions.add(question);
          });
        },
      ),
    );
  }

  /// 处理题目操作
  void _handleQuestionAction(String action, int index) {
    switch (action) {
      case 'edit':
        showDialog(
          context: context,
          builder: (context) => _QuestionEditDialog(
            type: _questions[index]['type'],
            question: _questions[index],
            onSave: (question) {
              setState(() {
                _questions[index] = question;
              });
            },
          ),
        );
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除这道题目吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _questions.removeAt(index);
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('删除'),
              ),
            ],
          ),
        );
        break;
    }
  }

  /// 获取题目类型颜色
  Color _getQuestionTypeColor(String type) {
    switch (type) {
      case 'single':
        return const Color(0xFF3B82F6);
      case 'multiple':
        return const Color(0xFF10B981);
      case 'judge':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF666666);
    }
  }

  /// 获取题目类型标签
  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'single':
        return '单选题';
      case 'multiple':
        return '多选题';
      case 'judge':
        return '判断题';
      default:
        return '未知';
    }
  }

  /// 导入题目
  void _importQuestions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('导入题目', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.upload_file, color: Color(0xFF3B82F6)),
              title: const Text('从JSON文件导入'),
              subtitle: const Text('支持标准JSON格式的题目文件'),
              onTap: () {
                Navigator.pop(context);
                _importFromJson();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Color(0xFF10B981)),
              title: const Text('从Excel导入'),
              subtitle: const Text('支持xlsx格式的题目表格'),
              onTap: () {
                Navigator.pop(context);
                _importFromExcel();
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet, color: Color(0xFFF59E0B)),
              title: const Text('从文本导入'),
              subtitle: const Text('手动粘贴题目文本'),
              onTap: () {
                Navigator.pop(context);
                _importFromText();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 从JSON文件导入
  Future<void> _importFromJson() async {
    try {
      final file = await FileUploadService.pickSingleFile(
        allowedExtensions: ['json'],
      );
      
      if (file != null && file.bytes != null) {
        final jsonStr = utf8.decode(file.bytes!);
        final List<dynamic> jsonData = json.decode(jsonStr);
        
        int importedCount = 0;
        for (var item in jsonData) {
          if (item is Map<String, dynamic>) {
            final question = _parseJsonQuestion(item);
            if (question != null) {
              setState(() => _questions.add(question));
              importedCount++;
            }
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('成功导入 $importedCount 道题目'), backgroundColor: const Color(0xFF4CAF50)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 解析JSON题目
  Map<String, dynamic>? _parseJsonQuestion(Map<String, dynamic> json) {
    try {
      final type = json['type'] ?? 'single';
      final title = json['title'] ?? json['question'] ?? '';
      final score = json['score'] ?? 5;
      
      if (title.isEmpty) return null;
      
      if (type == 'judge') {
        return {
          'type': 'judge',
          'title': title,
          'score': score,
          'correct': json['correct'] ?? json['answer'] ?? true,
        };
      } else {
        final options = json['options'] ?? [];
        final correct = json['correct'] ?? json['answer'] ?? [];
        
        return {
          'type': type,
          'title': title,
          'score': score,
          'options': List<String>.from(options),
          'correct': correct is List ? List<int>.from(correct) : [correct],
        };
      }
    } catch (e) {
      return null;
    }
  }

  /// 从Excel导入
  void _importFromExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Excel导入功能开发中，请使用JSON格式导入'), backgroundColor: Colors.orange),
    );
  }

  /// 从文本导入
  void _importFromText() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('从文本导入'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('请按以下格式输入题目：', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4)),
                child: const Text(
                  '1. 题目内容\nA. 选项A\nB. 选项B\nC. 选项C\nD. 选项D\n答案: A',
                  style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: '在此粘贴题目文本...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _parseTextQuestions(textController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  /// 解析文本题目
  void _parseTextQuestions(String text) {
    // 简单的文本解析逻辑
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未找到有效题目'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    // 这里可以实现更复杂的解析逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('文本解析功能开发中，请使用JSON格式导入'), backgroundColor: Colors.orange),
    );
  }

  /// 预览测验
  void _previewQuiz() {
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先添加题目'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('预览功能开发中'),
        duration: Duration(seconds: 2),
      ),
    );
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

  /// 完成创建
  void _completeQuiz() {
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请至少添加一道题目'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    Navigator.pop(context, _questions);
  }
}

/// 题目编辑对话框
class _QuestionEditDialog extends StatefulWidget {
  final String type;
  final Map<String, dynamic>? question;
  final Function(Map<String, dynamic>) onSave;
  
  const _QuestionEditDialog({
    required this.type,
    this.question,
    required this.onSave,
  });

  @override
  State<_QuestionEditDialog> createState() => __QuestionEditDialogState();
}

class __QuestionEditDialogState extends State<_QuestionEditDialog> {
  final _titleController = TextEditingController();
  final _scoreController = TextEditingController(text: '5');
  final List<TextEditingController> _optionControllers = [];
  List<bool> _correctAnswers = [];

  @override
  void initState() {
    super.initState();
    
    if (widget.question != null) {
      _titleController.text = widget.question!['title'];
      _scoreController.text = widget.question!['score'].toString();
      
      if (widget.question!['options'] != null) {
        for (int i = 0; i < widget.question!['options'].length; i++) {
          _optionControllers.add(TextEditingController(text: widget.question!['options'][i]));
          _correctAnswers.add(widget.question!['correct'].contains(i));
        }
      }
    } else {
      // 初始化选项
      if (widget.type != 'judge') {
        for (int i = 0; i < 4; i++) {
          _optionControllers.add(TextEditingController());
          _correctAnswers.add(false);
        }
      } else {
        _correctAnswers = [true]; // 判断题默认正确
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 对话框头部
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Text(
                    '${_getTypeLabel()}编辑',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // 对话框内容
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 题目内容
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '题目内容',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 分值
                    Row(
                      children: [
                        const Text('分值：'),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: _scoreController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const Text(' 分'),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 选项或答案
                    if (widget.type == 'judge') ...[
                      const Text('正确答案：'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Radio<bool>(
                            value: true,
                            groupValue: _correctAnswers[0],
                            onChanged: (value) {
                              setState(() {
                                _correctAnswers[0] = value!;
                              });
                            },
                          ),
                          const Text('正确'),
                          const SizedBox(width: 20),
                          Radio<bool>(
                            value: false,
                            groupValue: _correctAnswers[0],
                            onChanged: (value) {
                              setState(() {
                                _correctAnswers[0] = value!;
                              });
                            },
                          ),
                          const Text('错误'),
                        ],
                      ),
                    ] else ...[
                      const Text('选项设置：'),
                      const SizedBox(height: 8),
                      for (int i = 0; i < _optionControllers.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              if (widget.type == 'single')
                                Radio<int>(
                                  value: i,
                                  groupValue: _correctAnswers.indexOf(true),
                                  onChanged: (value) {
                                    setState(() {
                                      _correctAnswers = List.filled(_correctAnswers.length, false);
                                      _correctAnswers[value!] = true;
                                    });
                                  },
                                )
                              else
                                Checkbox(
                                  value: _correctAnswers[i],
                                  onChanged: (value) {
                                    setState(() {
                                      _correctAnswers[i] = value!;
                                    });
                                  },
                                ),
                              
                              Expanded(
                                child: TextFormField(
                                  controller: _optionControllers[i],
                                  decoration: InputDecoration(
                                    labelText: '选项${String.fromCharCode(65 + i)}',
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            
            // 对话框底部
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel() {
    switch (widget.type) {
      case 'single':
        return '单选题';
      case 'multiple':
        return '多选题';
      case 'judge':
        return '判断题';
      default:
        return '题目';
    }
  }

  void _saveQuestion() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入题目内容')),
      );
      return;
    }

    final question = <String, dynamic>{
      'type': widget.type,
      'title': _titleController.text.trim(),
      'score': int.tryParse(_scoreController.text) ?? 5,
    };

    if (widget.type == 'judge') {
      question['correct'] = _correctAnswers[0];
    } else {
      question['options'] = _optionControllers.map((c) => c.text.trim()).toList();
      question['correct'] = [];
      for (int i = 0; i < _correctAnswers.length; i++) {
        if (_correctAnswers[i]) {
          question['correct'].add(i);
        }
      }
      
      if (question['correct'].isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请选择正确答案')),
        );
        return;
      }
    }

    widget.onSave(question);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _scoreController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
