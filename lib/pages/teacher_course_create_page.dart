import 'package:flutter/material.dart';
import '../services/course_service.dart';

/// 创建课程页面
class TeacherCourseCreatePage extends StatefulWidget {
  const TeacherCourseCreatePage({super.key});

  @override
  State<TeacherCourseCreatePage> createState() => _TeacherCourseCreatePageState();
}

class _TeacherCourseCreatePageState extends State<TeacherCourseCreatePage> {
  final _formKey = GlobalKey<FormState>();
  
  // 表单控制器
  final _courseNameController = TextEditingController();
  final _courseCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  // 选择的值
  String? _selectedCredits;
  String? _selectedCourseType;
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _selectedDays = [];
  
  // 课程图标
  String _selectedIcon = 'laptop-code';
  Color _selectedIconColor = const Color(0xFF3B82F6);
  
  // 配置数据
  CourseCreateConfigResponse? _config;
  bool _isLoadingConfig = true;
  String? _configError;
  
  // 可选图标
  final List<Map<String, dynamic>> _iconOptions = [
    {'icon': Icons.computer, 'name': 'laptop-code', 'color': Color(0xFF3B82F6)},
    {'icon': Icons.book, 'name': 'book', 'color': Color(0xFF10B981)},
    {'icon': Icons.calculate, 'name': 'calculator', 'color': Color(0xFFF59E0B)},
    {'icon': Icons.science, 'name': 'flask', 'color': Color(0xFF8B5CF6)},
    {'icon': Icons.language, 'name': 'globe', 'color': Color(0xFF06B6D4)},
    {'icon': Icons.palette, 'name': 'paint-brush', 'color': Color(0xFFEF4444)},
  ];
  
  bool _showIconPicker = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  /// 加载课程创建配置
  Future<void> _loadConfig() async {
    try {
      final response = await CourseService.getCourseCreateConfig();
      
      if (response.isSuccess && response.body != null) {
        setState(() {
          _config = response.body;
          _isLoadingConfig = false;
          
          // 设置默认值 - 使用第一个预设图标
          if (_iconOptions.isNotEmpty) {
            _selectedIcon = _iconOptions.first['name'];
            _selectedIconColor = _iconOptions.first['color'];
          }
        });
      } else {
        setState(() {
          _configError = response.message ?? '加载配置失败';
          _isLoadingConfig = false;
        });
      }
    } catch (e) {
      setState(() {
        _configError = '网络错误：$e';
        _isLoadingConfig = false;
      });
    }
  }

  /// 解析颜色字符串
  Color _parseColor(String colorStr) {
    try {
      final cleanColor = colorStr.replaceAll('#', '');
      return Color(int.parse('FF$cleanColor', radix: 16));
    } catch (e) {
      return const Color(0xFF3B82F6); // 默认颜色
    }
  }

  /// 获取选中的图标数据
  IconData _getSelectedIconData() {
    try {
      final iconOption = _iconOptions.firstWhere((icon) => icon['name'] == _selectedIcon);
      return iconOption['icon'] as IconData;
    } catch (e) {
      // 如果找不到匹配的图标，返回默认图标
      return Icons.computer;
    }
  }

  /// 构建错误提示组件
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              _configError ?? '加载配置失败',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadConfig,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
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
        title: const Text(
          '创建课程',
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
      body: _isLoadingConfig
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            )
          : _configError != null
              ? _buildErrorWidget()
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // 课程图标选择
                        _buildIconSection(),
                        
                        const SizedBox(height: 16),
                        
                        // 基本信息
                        _buildBasicInfoSection(),
                        
                        const SizedBox(height: 16),
                        
                        // 课程描述
                        _buildDescriptionSection(),
                        
                        const SizedBox(height: 16),
                        
                        // 教学安排
                        _buildScheduleSection(),
                        
                        const SizedBox(height: 100), // 为底部按钮留空间
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: _isLoadingConfig || _configError != null 
          ? null 
          : _buildBottomButtons(),
    );
  }

  /// 构建图标选择区域
  Widget _buildIconSection() {
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
              Icon(Icons.image, color: const Color(0xFF4CAF50), size: 20),
              const SizedBox(width: 8),
              const Text(
                '课程图标',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showIconPicker = !_showIconPicker;
                  });
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _selectedIconColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getSelectedIconData(),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '选择图标',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '点击左侧图标选择合适的课程图标',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showIconPicker = !_showIconPicker;
                        });
                      },
                      icon: const Icon(Icons.palette, size: 16),
                      label: const Text('更换图标'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F5F5),
                        foregroundColor: const Color(0xFF666666),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (_showIconPicker) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _iconOptions.length,
              itemBuilder: (context, index) {
                final option = _iconOptions[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = option['name'];
                      _selectedIconColor = option['color'];
                      _showIconPicker = false;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: option['color'],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      option['icon'],
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
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
              Icon(Icons.info, color: const Color(0xFF10B981), size: 20),
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
          
          // 课程名称
          TextFormField(
            controller: _courseNameController,
            decoration: InputDecoration(
              labelText: '课程名称 *',
              hintText: '请输入课程名称',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixText: '${_courseNameController.text.length}/50',
            ),
            maxLength: 50,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入课程名称';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {});
            },
          ),
          
          const SizedBox(height: 16),
          
          // 课程代码
          TextFormField(
            controller: _courseCodeController,
            decoration: InputDecoration(
              labelText: '课程代码',
              hintText: '如：CS2021001（可选）',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLength: 20,
          ),
          
          const SizedBox(height: 16),
          
          // 学分和课程类型
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCredits,
                  decoration: InputDecoration(
                    labelText: '学分 *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['1', '2', '3', '4', '5', '6'].map((credits) {
                    return DropdownMenuItem(
                      value: credits,
                      child: Text('${credits}学分'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCredits = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return '请选择学分';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCourseType,
                  decoration: InputDecoration(
                    labelText: '课程类型 *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(value: 'required', child: Text('必修课')),
                    DropdownMenuItem(value: 'elective', child: Text('选修课')),
                    DropdownMenuItem(value: 'public', child: Text('公共课')),
                    DropdownMenuItem(value: 'professional', child: Text('专业课')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCourseType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return '请选择类型';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 课程分类
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: '课程分类',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              DropdownMenuItem(value: 'computer', child: Text('计算机科学')),
              DropdownMenuItem(value: 'math', child: Text('数学')),
              DropdownMenuItem(value: 'physics', child: Text('物理')),
              DropdownMenuItem(value: 'chemistry', child: Text('化学')),
              DropdownMenuItem(value: 'biology', child: Text('生物')),
              DropdownMenuItem(value: 'language', child: Text('语言文学')),
              DropdownMenuItem(value: 'art', child: Text('艺术设计')),
              DropdownMenuItem(value: 'business', child: Text('商业管理')),
              DropdownMenuItem(value: 'other', child: Text('其他')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
          ),
        ],
      ),
    );
  }

  /// 构建课程描述区域
  Widget _buildDescriptionSection() {
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
              Icon(Icons.description, color: const Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 8),
              const Text(
                '课程描述',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: '请详细描述课程内容、教学目标、适用对象等信息...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  if (_descriptionController.text.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('确认清空'),
                        content: const Text('确定要清空课程描述吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () {
                              _descriptionController.clear();
                              Navigator.pop(context);
                              setState(() {});
                            },
                            child: const Text('确定'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.clear),
              ),
            ),
            maxLines: 5,
            maxLength: 500,
            onChanged: (value) {
              setState(() {});
            },
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_descriptionController.text.length}/500 字符',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  _descriptionController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('清空'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF666666),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建教学安排区域
  Widget _buildScheduleSection() {
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
              Icon(Icons.schedule, color: const Color(0xFF8B5CF6), size: 20),
              const SizedBox(width: 8),
              const Text(
                '教学安排',
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
          
          // 开始和结束日期
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectStartDate(),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '开始日期 *',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _startDate != null 
                              ? '${_startDate!.year}/${_startDate!.month}/${_startDate!.day}'
                              : 'yyyy/mm/dd',
                          style: TextStyle(
                            fontSize: 16,
                            color: _startDate != null 
                                ? const Color(0xFF333333)
                                : const Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectEndDate(),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '结束日期 *',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _endDate != null 
                              ? '${_endDate!.year}/${_endDate!.month}/${_endDate!.day}'
                              : 'yyyy/mm/dd',
                          style: TextStyle(
                            fontSize: 16,
                            color: _endDate != null 
                                ? const Color(0xFF333333)
                                : const Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 教学周数
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '教学周数',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                Text(
                  _calculateWeeks(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 上课时间
          const Text(
            '上课时间',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['周一', '周二', '周三', '周四', '周五'].map((day) {
              final isSelected = _selectedDays.contains(day);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDays.remove(day);
                    } else {
                      _selectedDays.add(day);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFF4CAF50).withOpacity(0.1)
                        : const Color(0xFFF8F9FA),
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFF4CAF50)
                          : Colors.transparent,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected 
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF333333),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // 上课地点
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: '上课地点',
              hintText: '如：教学楼A101（可选）',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
            child: OutlinedButton.icon(
              onPressed: _saveDraft,
              icon: const Icon(Icons.save),
              label: const Text('保存草稿'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4CAF50),
                side: const BorderSide(color: Color(0xFF4CAF50)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _createCourse,
              icon: const Icon(Icons.add),
              label: const Text('创建课程'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 选择开始日期
  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _startDate = date;
        // 如果结束日期早于开始日期，清空结束日期
        if (_endDate != null && _endDate!.isBefore(date)) {
          _endDate = null;
        }
      });
    }
  }

  /// 选择结束日期
  Future<void> _selectEndDate() async {
    final firstDate = _startDate ?? DateTime.now().add(const Duration(days: 7));
    
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? firstDate.add(const Duration(days: 112)), // 16周后
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  /// 计算教学周数
  String _calculateWeeks() {
    if (_startDate != null && _endDate != null) {
      final difference = _endDate!.difference(_startDate!).inDays;
      final weeks = (difference / 7).ceil();
      return '${weeks}周';
    }
    return '自动计算';
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

  /// 创建课程
  void _createCourse() {
    if (_formKey.currentState!.validate()) {
      // 验证必填项
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请选择开始和结束日期'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (_startDate!.isAfter(_endDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('结束日期必须晚于开始日期'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // 显示确认对话框
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认创建'),
          content: const Text('确定要创建这个课程吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performCreate();
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

  /// 执行创建操作
  void _performCreate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 检查必填字段
    if (_selectedCredits == null) {
      _showErrorMessage('请选择学分');
      return;
    }
    if (_selectedCourseType == null) {
      _showErrorMessage('请选择课程类型');
      return;
    }
    if (_selectedCategory == null) {
      _showErrorMessage('请选择课程分类');
      return;
    }
    if (_startDate == null || _endDate == null) {
      _showErrorMessage('请选择开始和结束日期');
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // 构建上课时间安排
      List<ScheduleItem>? schedule;
      if (_selectedDays.isNotEmpty) {
        schedule = _selectedDays.map((day) => ScheduleItem(
          weekday: _mapDayToWeekday(day),
          startTime: '08:00', // 可以根据需要调整
          endTime: '09:40',
        )).toList();
      }

      // 创建课程请求
      final request = CreateCourseRequest(
        name: _courseNameController.text.trim(),
        code: _courseCodeController.text.trim(),
        iconId: _mapIconNameToId(_selectedIcon),
        credits: int.parse(_selectedCredits!),
        courseType: _selectedCourseType!,
        category: _selectedCategory!,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        startDate: _formatDate(_startDate!),
        endDate: _formatDate(_endDate!),
        classroom: _locationController.text.trim().isEmpty 
            ? null 
            : _locationController.text.trim(),
        schedule: schedule,
        isDraft: false,
      );

      // 调用API创建课程
      final response = await CourseService.createCourse(request);

      if (response.isSuccess) {
        setState(() {
          _isCreating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('课程创建成功！'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );

        // 返回课程管理页面
        Navigator.pop(context, true);
      } else {
        setState(() {
          _isCreating = false;
        });
        _showErrorMessage(response.message ?? '创建课程失败');
      }
    } catch (e) {
      setState(() {
        _isCreating = false;
      });
      _showErrorMessage('网络错误：$e');
    }
  }

  /// 映射图标名称到API ID
  String _mapIconNameToId(String iconName) {
    switch (iconName) {
      case 'laptop-code':
        return 'computer';
      case 'book':
        return 'database';
      case 'calculator':
        return 'algorithm';
      case 'flask':
        return 'ai';
      case 'globe':
        return 'network';
      case 'paint-brush':
        return 'security';
      default:
        return 'computer';
    }
  }

  /// 映射星期到API格式
  String _mapDayToWeekday(String day) {
    switch (day) {
      case '周一':
        return 'monday';
      case '周二':
        return 'tuesday';
      case '周三':
        return 'wednesday';
      case '周四':
        return 'thursday';
      case '周五':
        return 'friday';
      default:
        return 'monday';
    }
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 显示错误消息
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseCodeController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
