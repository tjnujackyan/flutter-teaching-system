import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// 密码强度枚举
enum PasswordStrength {
  weak('弱', Color(0xFFEF4444)),
  medium('中等', Color(0xFFFF9800)),
  strong('强', Color(0xFF10B981));

  const PasswordStrength(this.label, this.color);
  final String label;
  final Color color;
}

/// 教师修改密码页面
class TeacherChangePasswordPage extends StatefulWidget {
  const TeacherChangePasswordPage({super.key});

  @override
  State<TeacherChangePasswordPage> createState() => _TeacherChangePasswordPageState();
}

class _TeacherChangePasswordPageState extends State<TeacherChangePasswordPage> {
  final TextEditingController _verificationCodeController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isVerificationSent = false;
  bool _isVerificationCompleted = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSendingCode = false;
  bool _isVerifying = false;
  bool _isChangingPassword = false;
  
  int _countdown = 0;
  PasswordStrength _passwordStrength = PasswordStrength.weak;
  String? _verifyToken;
  String? _maskedPhone;

  @override
  void dispose() {
    _verificationCodeController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 发送验证码
  Future<void> _sendVerificationCode() async {
    if (_isSendingCode) return;

    setState(() {
      _isSendingCode = true;
    });

    try {
      final response = await AuthService.sendVerificationCode(type: 'sms');
      
      if (response.isSuccess && mounted) {
        setState(() {
          _isVerificationSent = true;
          _countdown = 60;
          // 从响应中获取脱敏的手机号
          _maskedPhone = response.body?['maskedPhone'] ?? '138****5678';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('验证码已发送'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 启动倒计时
        _updateCountdown();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('发送失败: ${response.message}'),
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
          _isSendingCode = false;
        });
      }
    }
  }

  /// 更新倒计时
  void _updateCountdown() {
    if (_countdown > 0) {
      setState(() {
        _countdown--;
      });
      Future.delayed(const Duration(seconds: 1), _updateCountdown);
    }
  }

  /// 验证验证码
  Future<void> _verifyCode() async {
    if (_isVerifying || _verificationCodeController.text.length != 6) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final response = await AuthService.verifyCode(
        type: 'sms',
        code: _verificationCodeController.text,
      );
      
      if (response.isSuccess && mounted) {
        setState(() {
          _isVerificationCompleted = true;
          _verifyToken = response.body?['verifyToken'];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('验证码验证成功'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('验证失败: ${response.message}'),
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
          _isVerifying = false;
        });
      }
    }
  }

  /// 检查密码强度
  void _checkPasswordStrength(String password) {
    int score = 0;
    
    // 长度检查
    if (password.length >= 8) score++;
    
    // 包含大写字母
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    
    // 包含小写字母
    if (password.contains(RegExp(r'[a-z]'))) score++;
    
    // 包含数字
    if (password.contains(RegExp(r'[0-9]'))) score++;
    
    // 包含特殊字符
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    
    setState(() {
      if (score <= 2) {
        _passwordStrength = PasswordStrength.weak;
      } else if (score <= 4) {
        _passwordStrength = PasswordStrength.medium;
      } else {
        _passwordStrength = PasswordStrength.strong;
      }
    });
  }

  /// 修改密码
  Future<void> _changePassword() async {
    if (_isChangingPassword || _verifyToken == null) return;

    // 验证密码
    if (_newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入新密码')),
      );
      return;
    }
    
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('两次输入的密码不一致')),
      );
      return;
    }
    
    if (_newPasswordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码长度至少8个字符')),
      );
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      final response = await AuthService.changePasswordWithVerify(
        verifyToken: _verifyToken!,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      
      if (response.isSuccess && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('密码修改成功'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('修改失败: ${response.message}'),
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
          _isChangingPassword = false;
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
          '修改密码',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF666666)),
            onPressed: () {
              _showPasswordHelp();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 身份验证
            if (!_isVerificationCompleted) _buildVerificationSection(),
            
            // 设置新密码
            if (_isVerificationCompleted) _buildPasswordSection(),
          ],
        ),
      ),
    );
  }

  /// 构建身份验证区域
  Widget _buildVerificationSection() {
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
          const Row(
            children: [
              Icon(
                Icons.verified_user,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '身份验证',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '为了保护您的账号安全，请先完成身份验证',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 20),
          
          // 发送验证码按钮
          if (!_isVerificationSent)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSendingCode ? null : _sendVerificationCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: _isSendingCode 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.sms, size: 20),
                    label: Text(_isSendingCode ? '发送中...' : '发送手机验证码'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('发送邮箱验证码功能开发中')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF666666),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.email, size: 20),
                    label: const Text('发送邮箱验证码'),
                  ),
                ),
              ],
            ),
          
          // 验证码输入
          if (_isVerificationSent) ...[
            const Text(
              '验证码',
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
                  child: TextField(
                    controller: _verificationCodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: '请输入6位验证码',
                      hintStyle: const TextStyle(color: Color(0xFF999999)),
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
                      contentPadding: const EdgeInsets.all(16),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('验证'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '验证码已发送至 ${_maskedPhone ?? '138****5678'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _countdown == 0 ? _sendVerificationCode : null,
                  child: Text(
                    _countdown > 0 ? '重新发送($_countdown)' : '重新发送',
                    style: TextStyle(
                      fontSize: 12,
                      color: _countdown > 0 ? const Color(0xFF999999) : const Color(0xFF4CAF50),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 构建密码设置区域
  Widget _buildPasswordSection() {
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
          const Row(
            children: [
              Icon(
                Icons.lock_reset,
                color: Color(0xFF10B981),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '设置新密码',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 当前密码
          _buildPasswordField(
            label: '当前密码',
            controller: _currentPasswordController,
            hintText: '请输入当前密码',
            obscureText: _obscureCurrentPassword,
            onToggleVisibility: () {
              setState(() {
                _obscureCurrentPassword = !_obscureCurrentPassword;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // 新密码
          _buildPasswordField(
            label: '新密码',
            controller: _newPasswordController,
            hintText: '请输入新密码',
            obscureText: _obscureNewPassword,
            onToggleVisibility: () {
              setState(() {
                _obscureNewPassword = !_obscureNewPassword;
              });
            },
            onChanged: _checkPasswordStrength,
          ),
          
          // 密码强度指示器
          if (_newPasswordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  '密码强度',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _passwordStrength.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _passwordStrength.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: _passwordStrength.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          // 确认新密码
          _buildPasswordField(
            label: '确认新密码',
            controller: _confirmPasswordController,
            hintText: '请再次输入新密码',
            obscureText: _obscureConfirmPassword,
            onToggleVisibility: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          
          const SizedBox(height: 20),
          
          // 密码要求
          _buildPasswordRequirements(),
          
          const SizedBox(height: 24),
          
          // 确认修改按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isChangingPassword ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isChangingPassword
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          '修改中...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      '确认修改',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建密码输入字段
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
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
          obscureText: obscureText,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF999999)),
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
            contentPadding: const EdgeInsets.all(16),
            suffixIcon: IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF999999),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建密码要求
  Widget _buildPasswordRequirements() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Color(0xFFFF9800),
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                '密码要求',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildRequirementItem('至少8个字符'),
          _buildRequirementItem('包含大写字母'),
          _buildRequirementItem('包含小写字母'),
          _buildRequirementItem('包含数字'),
          _buildRequirementItem('包含特殊字符 (!@#\$%^&*)'),
        ],
      ),
    );
  }

  /// 构建要求项目
  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示密码帮助
  void _showPasswordHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('密码安全提示'),
        content: const Text(
          '为了保护您的账号安全，建议您：\n\n'
          '1. 使用至少8个字符的密码\n'
          '2. 包含大小写字母、数字和特殊字符\n'
          '3. 不要使用常见的密码组合\n'
          '4. 定期更换密码\n'
          '5. 不要在多个网站使用相同密码',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
