import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// 教师个人信息页面
class TeacherProfileInfoPage extends StatefulWidget {
  const TeacherProfileInfoPage({super.key});

  @override
  State<TeacherProfileInfoPage> createState() => _TeacherProfileInfoPageState();
}

class _TeacherProfileInfoPageState extends State<TeacherProfileInfoPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _teacherIdController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  String _selectedGender = '男';
  DateTime? _selectedBirthdate;
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherIdController.dispose();
    _birthdateController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// 加载个人信息数据
  Future<void> _loadProfileData() async {
    try {
      final response = await AuthService.getProfileInfo();
      if (response.isSuccess && mounted) {
        setState(() {
          _profileData = response.body;
          _initializeFormData();
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('加载个人信息失败: ${response.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('网络错误，请检查网络连接')),
        );
      }
    }
  }

  /// 初始化表单数据
  void _initializeFormData() {
    if (_profileData == null) return;
    
    _nameController.text = _profileData!['name'] ?? '';
    _teacherIdController.text = _profileData!['teacherId'] ?? '';
    _departmentController.text = '${_profileData!['department'] ?? ''}·${_profileData!['title'] ?? ''}';
    _phoneController.text = _profileData!['phone'] ?? '';
    _emailController.text = _profileData!['email'] ?? '';
    
    // 设置性别
    final gender = _profileData!['gender'];
    if (gender != null) {
      _selectedGender = gender == 1 ? '男' : '女';
    }
    
    // 设置生日
    final birthDate = _profileData!['birthDate'];
    if (birthDate != null) {
      try {
        _selectedBirthdate = DateTime.parse(birthDate);
        _birthdateController.text = '${_selectedBirthdate!.year}/${_selectedBirthdate!.month.toString().padLeft(2, '0')}/${_selectedBirthdate!.day.toString().padLeft(2, '0')}';
      } catch (e) {
        // 日期解析失败，使用默认值
      }
    }
  }

  /// 保存个人信息
  Future<void> _saveProfile() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await AuthService.updateProfile(
        name: _nameController.text.trim(),
        gender: _selectedGender == '男' ? 1 : 0,
        birthDate: _selectedBirthdate?.toIso8601String().split('T')[0],
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('个人信息保存成功'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('保存失败: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('网络错误，请检查网络连接'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// 选择出生日期
  Future<void> _selectBirthdate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? DateTime(1980, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime(2005),
      locale: const Locale('zh', 'CN'),
    );
    
    if (picked != null && picked != _selectedBirthdate) {
      setState(() {
        _selectedBirthdate = picked;
        _birthdateController.text = '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
      });
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
          '个人信息',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save, color: Color(0xFF4CAF50)),
            onPressed: _isSaving ? null : _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
        child: Column(
          children: [
                  // 头像区域
            _buildAvatarSection(),
            
                  // 基本信息
                  _buildBasicInfoSection(),
          ],
        ),
      ),
    );
  }

  /// 构建头像区域
  Widget _buildAvatarSection() {
    final String nameInitial = _profileData?['name']?.substring(0, 1) ?? '教';
    
    return Container(
        color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(
                  child: Text(
                    nameInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('更换头像功能开发中')),
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _profileData?['name'] ?? '加载中...',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '工号：${_profileData?['teacherId'] ?? ''}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建基本信息区域
  Widget _buildBasicInfoSection() {
    return Container(
        color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.person,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
              '基本信息',
              style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
              ],
            ),
          ),
            
          // 真实姓名
          _buildInfoField(
            label: '真实姓名',
              controller: _nameController,
            hintText: '请输入真实姓名',
            ),
            
            // 工号
          _buildInfoField(
              label: '工号',
            controller: _teacherIdController,
            hintText: '请输入工号',
            enabled: false, // 工号不可编辑
          ),
            
            // 性别
            _buildGenderField(),
            
            // 出生日期
            _buildDateField(),
            
          // 院系职称
          _buildInfoField(
            label: '院系·职称',
            controller: _departmentController,
            hintText: '院系·职称',
            enabled: false, // 院系职称不可编辑
          ),
            
            // 手机号
          _buildInfoField(
              label: '手机号',
              controller: _phoneController,
            hintText: '请输入手机号',
            ),
            
            // 邮箱
          _buildInfoField(
              label: '邮箱',
              controller: _emailController,
            hintText: '请输入邮箱',
            ),
            
          const SizedBox(height: 20),
          ],
      ),
    );
  }

  /// 构建信息字段
  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
          TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Color(0xFF999999)),
              filled: true,
              fillColor: enabled ? Colors.white : const Color(0xFFF5F5F5),
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
              borderSide: const BorderSide(color: Color(0xFF4CAF50)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
        ),
    );
  }

  /// 构建性别字段
  Widget _buildGenderField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '性别',
          style: TextStyle(
              fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('男'),
                  value: '男',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                  activeColor: const Color(0xFF4CAF50),
                  contentPadding: EdgeInsets.zero,
                ),
          ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('女'),
                  value: '女',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                setState(() {
                      _selectedGender = value!;
                });
              },
                  activeColor: const Color(0xFF4CAF50),
                  contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
          ),
        ],
      ),
    );
  }

  /// 构建日期字段
  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '出生日期',
          style: TextStyle(
              fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
            onTap: _selectBirthdate,
          child: Container(
            width: double.infinity,
              padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                      _birthdateController.text.isEmpty ? '请选择出生日期' : _birthdateController.text,
                      style: TextStyle(
                      fontSize: 16,
                        color: _birthdateController.text.isEmpty ? const Color(0xFF999999) : const Color(0xFF333333),
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                    color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }
}
