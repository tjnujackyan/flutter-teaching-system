import 'package:flutter/material.dart';
import 'change_password_page.dart';
import '../services/auth_service.dart';

/// 登录设备模型
class LoginDevice {
  final String id;
  final String name;
  final String type;
  final String location;
  final String time;
  final String ip;
  final bool isCurrent;

  LoginDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.time,
    required this.ip,
    required this.isCurrent,
  });
}

/// 账号安全页面
class AccountSecurityPage extends StatefulWidget {
  const AccountSecurityPage({super.key});

  @override
  State<AccountSecurityPage> createState() => _AccountSecurityPageState();
}

class _AccountSecurityPageState extends State<AccountSecurityPage> {
  List<LoginDevice> _loginDevices = [];
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _lastPasswordChangeTime;

  @override
  void initState() {
    super.initState();
    _loadSecurityData();
  }

  /// 加载安全相关数据
  Future<void> _loadSecurityData() async {
    try {
      // 并行加载个人信息和登录设备
      final profileResponse = AuthService.getProfileInfo();
      final devicesResponse = AuthService.getLoginDevices();
      
      final results = await Future.wait([profileResponse, devicesResponse]);
      
      if (results[0].isSuccess && results[1].isSuccess && mounted) {
        setState(() {
          _profileData = results[0].body;
          _parseLoginDevices(results[1].body);
          _parseLastPasswordChange();
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('加载数据失败: ${results[0].message ?? results[1].message}')),
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

  /// 解析登录设备数据
  void _parseLoginDevices(Map<String, dynamic>? devicesData) {
    if (devicesData == null || devicesData['devices'] == null) return;
    
    final List<dynamic> devices = devicesData['devices'];
    _loginDevices = devices.map((device) => LoginDevice(
      id: device['deviceId']?.toString() ?? device['id']?.toString() ?? '',
      name: device['deviceName'] ?? '未知设备',
      type: '${device['deviceType'] ?? ''}·${device['osVersion'] ?? ''}',
      location: '${device['location'] ?? ''}·${_formatTime(device['lastActiveTime'])}',
      time: _formatTime(device['lastActiveTime']),
      ip: 'IP: ${device['ipAddress'] ?? ''}',
      isCurrent: device['isCurrentDevice'] ?? false,
    )).toList();
  }

  /// 解析上次修改密码时间
  void _parseLastPasswordChange() {
    // 这里可以从个人信息或其他API获取上次修改密码时间
    // 暂时使用模拟数据，后续可以扩展API
    _lastPasswordChangeTime = '2024年9月15日';
  }

  /// 格式化时间显示
  String _formatTime(String? timeStr) {
    if (timeStr == null) return '未知时间';
    
    try {
      final DateTime time = DateTime.parse(timeStr);
      final DateTime now = DateTime.now();
      final Duration diff = now.difference(time);
      
      if (diff.inMinutes < 1) {
        return '刚刚活跃';
      } else if (diff.inHours < 1) {
        return '${diff.inMinutes}分钟前';
      } else if (diff.inDays < 1) {
        return '${diff.inHours}小时前';
      } else {
        return '${diff.inDays}天前';
      }
    } catch (e) {
      return timeStr;
    }
  }

  /// 显示移除设备对话框
  void _showLogoutDeviceDialog(LoginDevice device) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('移除设备'),
          content: Text('确定要移除设备 "${device.name}" 吗？该设备将被强制下线。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeDevice(device);
              },
              child: const Text(
                '移除',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 移除设备
  Future<void> _removeDevice(LoginDevice device) async {
    try {
      final response = await AuthService.removeLoginDevice(device.id);
      
      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('设备移除成功'),
            backgroundColor: Colors.green,
          ),
        );
        // 刷新设备列表
        _loadSecurityData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('移除失败: ${response.message}'),
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
          '账号安全',
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('安全帮助功能开发中')),
              );
            },
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
                  // 安全等级卡片
                  _buildSecurityLevelCard(),
                  
                  // 密码安全
                  _buildPasswordSecuritySection(),
                  
                  // 登录设备
                  _buildLoginDevicesSection(),
                ],
              ),
            ),
    );
  }

  /// 构建安全等级卡片
  Widget _buildSecurityLevelCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.security,
              color: Colors.white,
              size: 24,
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
                      '安全等级：高',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      '85',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '安全分',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '您的账号安全设置良好',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '安全进度                                85%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: 0.85,
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      minHeight: 6,
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

  /// 构建密码安全区域
  Widget _buildPasswordSecuritySection() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.lock,
                  color: Color(0xFF4285F4),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  '密码安全',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
          
          // 修改密码
          _buildSecurityItem(
            icon: Icons.lock_outline,
            iconColor: const Color(0xFF4285F4),
            title: '修改密码',
            subtitle: '上次修改：${_lastPasswordChangeTime ?? '未知'}',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordPage(),
                ),
              );
              // 如果密码修改成功，刷新数据
              if (result == true) {
                _loadSecurityData();
              }
            },
          ),
          
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          
          // 密码强度
          _buildSecurityItem(
            icon: Icons.check_circle,
            iconColor: const Color(0xFF10B981),
            title: '密码强度',
            subtitle: '当前密码强度良好',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '强',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  /// 构建登录设备区域
  Widget _buildLoginDevicesSection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.devices,
                  color: Color(0xFF666666),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  '登录设备',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    _loadSecurityData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('正在刷新设备列表...')),
                    );
                  },
                  child: const Row(
                    children: [
                      Icon(
                        Icons.refresh,
                        color: Color(0xFF4285F4),
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '刷新',
                        style: TextStyle(
                          color: Color(0xFF4285F4),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          ...List.generate(_loginDevices.length, (index) {
            final device = _loginDevices[index];
            return _buildDeviceItem(device, index < _loginDevices.length - 1);
          }),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 构建安全项目
  Widget _buildSecurityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (onTap != null && trailing == null)
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF999999),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }


  /// 构建设备项目
  Widget _buildDeviceItem(LoginDevice device, bool showDivider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: device.isCurrent ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFF666666).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getDeviceIcon(device.name),
                  color: device.isCurrent ? const Color(0xFF10B981) : const Color(0xFF666666),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        if (device.isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '当前',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      device.type,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          device.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF999999),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          device.ip,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!device.isCurrent)
                GestureDetector(
                  onTap: () {
                    _showLogoutDeviceDialog(device);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '移除',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: Color(0xFFF0F0F0)),
      ],
    );
  }

  /// 获取设备图标
  IconData _getDeviceIcon(String deviceName) {
    if (deviceName.contains('iPhone') || deviceName.contains('iPad')) {
      return Icons.phone_iphone;
    } else if (deviceName.contains('Mac')) {
      return Icons.laptop_mac;
    } else {
      return Icons.computer;
    }
  }

}
