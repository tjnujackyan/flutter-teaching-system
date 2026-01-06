import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_service.dart';
import 'device_info_service.dart';

/// 登录请求模型
class LoginRequest {
  final String username;
  final String password;
  final bool? rememberMe;

  LoginRequest({
    required this.username,
    required this.password,
    this.rememberMe,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'username': username,
      'password': password,
    };
    if (rememberMe != null) {
      json['rememberMe'] = rememberMe!;
    }
    return json;
  }
}

/// 用户资料模型
class UserProfile {
  final String? studentId;
  final String? teacherId;
  final String name;
  final String? avatar;
  final String? major;
  final String? className;
  final String? grade;
  final String? title;
  final String? department;
  final String? office;
  final String? phone;
  final String? email;
  final bool isFirstLogin;

  UserProfile({
    this.studentId,
    this.teacherId,
    required this.name,
    this.avatar,
    this.major,
    this.className,
    this.grade,
    this.title,
    this.department,
    this.office,
    this.phone,
    this.email,
    this.isFirstLogin = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      studentId: json['studentId'],
      teacherId: json['teacherId'],
      name: json['name'] ?? '',
      avatar: json['avatar'],
      major: json['major'],
      className: json['className'],
      grade: json['grade'],
      title: json['title'],
      department: json['department'],
      office: json['office'],
      phone: json['phone'],
      email: json['email'],
      isFirstLogin: json['isFirstLogin'] ?? false,
    );
  }
}

/// 登录响应模型
class LoginResponse {
  final String token;
  final String userId;
  final String username;
  final String userType;
  final UserProfile? profile;

  LoginResponse({
    required this.token,
    required this.userId,
    required this.username,
    required this.userType,
    this.profile,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? '',
      userId: json['userId']?.toString() ?? '',
      username: json['username'] ?? '',
      userType: json['userType'] ?? '',
      profile: json['profile'] != null 
          ? UserProfile.fromJson(json['profile']) 
          : null,
    );
  }
}

/// 认证服务类
class AuthService {
  /// 学生登录
  static Future<ApiResponse<LoginResponse>> studentLogin({
    required String username,
    required String password,
  }) async {
    final request = LoginRequest(
      username: username,
      password: password,
    );

    final response = await ApiService.request<LoginResponse>(
      '/api/auth/student/login',
      data: request.toJson(),
      fromJson: (json) => LoginResponse.fromJson(json),
    );

    // 如果登录成功，保存token和用户信息
    if (response.isSuccess && response.body?.token != null) {
      await ApiService.saveAuthToken(response.body!.token);
      await _saveUserInfo(response.body!);
      
      // 登录成功后自动发送设备信息
      _sendDeviceInfoOnLogin();
    }

    return response;
  }

  /// 教师登录
  static Future<ApiResponse<LoginResponse>> teacherLogin({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    final request = LoginRequest(
      username: username,
      password: password,
      rememberMe: rememberMe,
    );

    final response = await ApiService.request<LoginResponse>(
      '/api/auth/teacher/login',
      data: request.toJson(),
      fromJson: (json) => LoginResponse.fromJson(json),
    );

    // 如果登录成功，保存token和用户信息
    if (response.isSuccess && response.body?.token != null) {
      await ApiService.saveAuthToken(response.body!.token);
      await _saveUserInfo(response.body!);
      
      // 登录成功后自动发送设备信息
      _sendDeviceInfoOnLogin();
    }

    return response;
  }

  /// 退出登录
  static Future<ApiResponse<void>> logout() async {
    final response = await ApiService.request<void>(
      '/api/auth/logout',
      data: {},
    );
    
    // 无论接口是否成功，都清除本地token和用户信息
    await ApiService.clearAuthToken();
    await _clearUserInfo();
    
    return response;
  }

  /// 检查是否已登录
  static Future<bool> isLoggedIn() async {
    final token = await ApiService.getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// 刷新Token
  static Future<ApiResponse<Map<String, dynamic>>> refreshToken() async {
    final response = await ApiService.request<Map<String, dynamic>>(
      '/api/auth/refresh-token',
      data: {},
      fromJson: (json) => json,
    );

    // 如果刷新成功，保存新token
    if (response.isSuccess && response.body?['token'] != null) {
      await ApiService.saveAuthToken(response.body!['token']);
    }

    return response;
  }

  /// 获取用户信息
  static Future<ApiResponse<LoginResponse>> getUserInfo() async {
    final response = await ApiService.request<LoginResponse>(
      '/api/auth/user-info',
      data: {},
      fromJson: (json) => LoginResponse.fromJson(json),
    );

    return response;
  }

  /// 修改密码
  static Future<ApiResponse<void>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await ApiService.request<void>(
      '/api/auth/change-password',
      data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );

    return response;
  }

  /// 发送忘记密码验证码
  static Future<ApiResponse<Map<String, dynamic>>> sendForgotPasswordCode({
    required String username,
    required String userType,
    required String method,
  }) async {
    final response = await ApiService.request<Map<String, dynamic>>(
      '/api/auth/forgot-password/send-code',
      data: {
        'username': username,
        'userType': userType,
        'method': method,
      },
      fromJson: (json) => json,
    );

    return response;
  }

  /// 验证忘记密码验证码
  static Future<ApiResponse<Map<String, dynamic>>> verifyForgotPasswordCode({
    required String username,
    required String userType,
    required String code,
  }) async {
    final response = await ApiService.request<Map<String, dynamic>>(
      '/api/auth/forgot-password/verify-code',
      data: {
        'username': username,
        'userType': userType,
        'code': code,
      },
      fromJson: (json) => json,
    );

    return response;
  }

  /// 重置密码
  static Future<ApiResponse<void>> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await ApiService.request<void>(
      '/api/auth/forgot-password/reset',
      data: {
        'resetToken': resetToken,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );

    return response;
  }

  /// 获取微信登录二维码
  static Future<ApiResponse<Map<String, dynamic>>> getWechatQRCode({
    required String userType,
  }) async {
    final response = await ApiService.request<Map<String, dynamic>>(
      '/api/auth/wechat/qrcode',
      data: {
        'userType': userType,
      },
      fromJson: (json) => json,
    );

    return response;
  }

  /// 检查微信登录状态
  static Future<ApiResponse<Map<String, dynamic>>> checkWechatLoginStatus({
    required String scene,
  }) async {
    final response = await ApiService.request<Map<String, dynamic>>(
      '/api/auth/wechat/check-status',
      data: {
        'scene': scene,
      },
      fromJson: (json) => json,
    );

    // 如果微信登录成功，保存token和用户信息
    if (response.isSuccess && 
        response.body?['status'] == 'confirmed' &&
        response.body?['token'] != null) {
      await ApiService.saveAuthToken(response.body!['token']);
      
      // 构建LoginResponse对象保存用户信息
      final loginResponse = LoginResponse(
        token: response.body!['token'],
        userId: response.body!['userId'] ?? '',
        username: response.body!['username'] ?? '',
        userType: response.body!['userType'] ?? '',
      );
      await _saveUserInfo(loginResponse);
    }

    return response;
  }

  /// 保存用户信息到本地存储
  static Future<void> _saveUserInfo(LoginResponse loginResponse) async {
    // 这里可以使用SharedPreferences保存用户信息
    // 暂时预留接口
  }

  /// 清除本地用户信息
  static Future<void> _clearUserInfo() async {
    // 这里可以清除SharedPreferences中的用户信息
    // 暂时预留接口
  }

  // ==================== 个人中心相关API ====================

  /// 获取个人基本信息
  static Future<ApiResponse<Map<String, dynamic>>> getProfileInfo() async {
    return await ApiService.request<Map<String, dynamic>>(
      '/api/user/profile/info',
      method: 'GET',
      fromJson: (json) => json,
    );
  }

  /// 获取个人统计信息
  static Future<ApiResponse<Map<String, dynamic>>> getProfileStats() async {
    return await ApiService.request<Map<String, dynamic>>(
      '/api/user/profile/stats',
      method: 'GET',
      fromJson: (json) => json,
    );
  }

  /// 更新个人信息
  static Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    String? name,
    int? gender,
    String? birthDate,
    String? phone,
    String? email,
    String? avatar,
    String? office,
    String? title,
  }) async {
    final Map<String, dynamic> data = {};
    
    if (name != null) data['name'] = name;
    if (gender != null) data['gender'] = gender;
    if (birthDate != null) data['birthDate'] = birthDate;
    if (phone != null) data['phone'] = phone;
    if (email != null) data['email'] = email;
    if (avatar != null) data['avatar'] = avatar;
    if (office != null) data['office'] = office;
    if (title != null) data['title'] = title;

    return await ApiService.request<Map<String, dynamic>>(
      '/api/user/profile/update',
      method: 'PUT',
      data: data,
      fromJson: (json) => json,
    );
  }

  /// 上传头像
  static Future<ApiResponse<Map<String, dynamic>>> uploadAvatar(File avatarFile) async {
    try {
      final apiService = ApiService();
      
      // 创建FormData
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          avatarFile.path,
          filename: avatarFile.path.split('/').last,
        ),
      });

      final response = await apiService.post(
        '/api/user/profile/avatar',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      
      return ApiResponse.fromJson(response, (json) => json);
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        error: 500,
        message: '头像上传失败: $e',
      );
    }
  }

  /// 获取登录设备列表
  static Future<ApiResponse<Map<String, dynamic>>> getLoginDevices() async {
    return await ApiService.request<Map<String, dynamic>>(
      '/api/user/security/devices',
      method: 'GET',
      fromJson: (json) => json,
    );
  }

  /// 移除登录设备
  static Future<ApiResponse<void>> removeLoginDevice(String deviceId) async {
    return await ApiService.request<void>(
      '/api/user/security/devices/$deviceId',
      method: 'DELETE',
      fromJson: (json) => null,
    );
  }

  /// 发送验证码（修改密码）
  static Future<ApiResponse<Map<String, dynamic>>> sendVerificationCode({
    required String type, // 'sms' 或 'email'
  }) async {
    return await ApiService.request<Map<String, dynamic>>(
      '/api/user/security/send-verification',
      data: {
        'type': type,
      },
      fromJson: (json) => json,
    );
  }

  /// 验证码验证（修改密码）
  static Future<ApiResponse<Map<String, dynamic>>> verifyCode({
    required String type,
    required String code,
  }) async {
    return await ApiService.request<Map<String, dynamic>>(
      '/api/user/security/verify-code',
      data: {
        'type': type,
        'code': code,
      },
      fromJson: (json) => json,
    );
  }

  /// 修改密码（带验证）
  static Future<ApiResponse<void>> changePasswordWithVerify({
    required String verifyToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return await ApiService.request<void>(
      '/api/user/security/change-password',
      method: 'POST',
      data: {
        'verifyToken': verifyToken,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
      fromJson: (json) => null,
    );
  }

  // ==================== 设备信息管理 ====================

  /// 发送设备信息到服务器
  static Future<ApiResponse<Map<String, dynamic>>> sendDeviceInfo() async {
    try {
      // 获取设备信息
      final deviceInfo = await DeviceInfoService.getDeviceInfo();
      
      // 发送到服务器
      return await ApiService.request<Map<String, dynamic>>(
        '/api/user/security/device-info',
        method: 'POST',
        data: deviceInfo,
        fromJson: (json) => json,
      );
    } catch (e) {
      // 如果获取设备信息失败，返回错误响应
      return ApiResponse<Map<String, dynamic>>(
        error: 9999,
        message: '获取设备信息失败: $e',
        body: null,
      );
    }
  }

  /// 登录时自动发送设备信息
  static Future<void> _sendDeviceInfoOnLogin() async {
    try {
      final response = await sendDeviceInfo();
      if (response.isSuccess) {
        print('设备信息发送成功');
      } else {
        print('设备信息发送失败: ${response.message}');
      }
    } catch (e) {
      print('发送设备信息时出错: $e');
    }
  }
}
