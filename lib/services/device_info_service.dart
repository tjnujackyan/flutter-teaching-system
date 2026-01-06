import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'location_service.dart';

/// 设备信息服务
class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  /// 获取设备信息
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    Map<String, dynamic> deviceData = {};

    try {
      if (kIsWeb) {
        // Web平台优先处理
        deviceData = await _getWebInfo();
      } else if (Platform.isAndroid) {
        deviceData = await _getAndroidInfo();
      } else if (Platform.isIOS) {
        deviceData = await _getIosInfo();
      } else if (Platform.isWindows) {
        deviceData = await _getWindowsInfo();
      } else if (Platform.isMacOS) {
        deviceData = await _getMacOsInfo();
      } else if (Platform.isLinux) {
        deviceData = await _getLinuxInfo();
      } else {
        deviceData = _getUnknownInfo();
      }
    } catch (e) {
      if (kDebugMode) {
        print('获取设备信息失败: $e');
      }
      // 如果插件失败，创建一个基本的设备信息
      deviceData = _getFallbackDeviceInfo(e.toString());
    }

    // 获取位置信息
    await _addLocationInfo(deviceData);

    return deviceData;
  }

  /// 添加位置信息到设备数据
  static Future<void> _addLocationInfo(Map<String, dynamic> deviceData) async {
    try {
      if (kDebugMode) {
        print('正在获取位置信息...');
      }
      
      // 获取位置信息
      final locationInfo = await LocationService.getLocationInfo();
      
      // 将位置信息添加到设备数据中
      deviceData.addAll(locationInfo);
      
      if (kDebugMode) {
        print('位置信息已添加: ${locationInfo['locationString']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('添加位置信息失败: $e');
      }
      // 如果获取失败，添加默认位置信息
      deviceData['latitude'] = null;
      deviceData['longitude'] = null;
      deviceData['locationAccuracy'] = null;
      deviceData['locationString'] = '未知位置';
      deviceData['hasLocationPermission'] = false;
    }
  }

  /// 获取备用设备信息（当插件失败时）
  static Map<String, dynamic> _getFallbackDeviceInfo(String error) {
    String platform = 'unknown';
    String deviceType = 'unknown';
    
    try {
      if (kIsWeb) {
        platform = 'Web';
        deviceType = 'desktop';
      } else if (Platform.isAndroid) {
        platform = 'Android';
        deviceType = 'mobile';
      } else if (Platform.isIOS) {
        platform = 'iOS';
        deviceType = 'mobile';
      } else if (Platform.isWindows) {
        platform = 'Windows';
        deviceType = 'desktop';
      } else if (Platform.isMacOS) {
        platform = 'macOS';
        deviceType = 'desktop';
      } else if (Platform.isLinux) {
        platform = 'Linux';
        deviceType = 'desktop';
      }
    } catch (e) {
      // 如果连Platform检查都失败，使用默认值
    }

    return {
      'deviceId': 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      'deviceName': '$platform 设备',
      'deviceType': deviceType,
      'osName': platform,
      'osVersion': 'Unknown',
      'browserName': null,
      'browserVersion': null,
      'error': 'Plugin failed: $error',
      'isFallback': true,
    };
  }

  /// 获取Android设备信息
  static Future<Map<String, dynamic>> _getAndroidInfo() async {
    AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
    
    if (kDebugMode) {
      print('===== Android 设备信息 =====');
      print('设备型号: ${androidInfo.model}');
      print('制造商: ${androidInfo.manufacturer}');
      print('Android 版本: ${androidInfo.version.release}');
      print('API 级别: ${androidInfo.version.sdkInt}');
      print('设备名称: ${androidInfo.device}');
      print('主板: ${androidInfo.board}');
      print('品牌: ${androidInfo.brand}');
      print('硬件: ${androidInfo.hardware}');
      print('设备ID: ${androidInfo.id}');
      print('指纹: ${androidInfo.fingerprint}');
      print('是否为物理设备: ${androidInfo.isPhysicalDevice}');
      print('Android 版本名称: ${androidInfo.version.codename}');
      print('安全补丁级别: ${androidInfo.version.securityPatch}');
    }

    return {
      'deviceId': androidInfo.id ?? 'unknown',
      'deviceName': '${androidInfo.brand} ${androidInfo.model}',
      'deviceType': 'mobile',
      'osName': 'Android',
      'osVersion': androidInfo.version.release,
      'browserName': null,
      'browserVersion': null,
      'manufacturer': androidInfo.manufacturer,
      'model': androidInfo.model,
      'brand': androidInfo.brand,
      'hardware': androidInfo.hardware,
      'board': androidInfo.board,
      'device': androidInfo.device,
      'fingerprint': androidInfo.fingerprint,
      'isPhysicalDevice': androidInfo.isPhysicalDevice,
      'apiLevel': androidInfo.version.sdkInt,
      'codename': androidInfo.version.codename,
      'securityPatch': androidInfo.version.securityPatch,
    };
  }

  /// 获取iOS设备信息
  static Future<Map<String, dynamic>> _getIosInfo() async {
    IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
    
    if (kDebugMode) {
      print('===== iOS 设备信息 =====');
      print('设备型号: ${iosInfo.model}');
      print('设备名称: ${iosInfo.name}');
      print('系统版本: ${iosInfo.systemVersion}');
      print('系统名称: ${iosInfo.systemName}');
      print('设备标识符: ${iosInfo.identifierForVendor}');
      print('是否为物理设备: ${iosInfo.isPhysicalDevice}');
    }

    return {
      'deviceId': iosInfo.identifierForVendor ?? 'unknown',
      'deviceName': '${iosInfo.name} (${iosInfo.model})',
      'deviceType': 'mobile',
      'osName': iosInfo.systemName,
      'osVersion': iosInfo.systemVersion,
      'browserName': null,
      'browserVersion': null,
      'manufacturer': 'Apple',
      'model': iosInfo.model,
      'name': iosInfo.name,
      'isPhysicalDevice': iosInfo.isPhysicalDevice,
      'localizedModel': iosInfo.localizedModel,
      'utsname': {
        'machine': iosInfo.utsname.machine,
        'nodename': iosInfo.utsname.nodename,
        'release': iosInfo.utsname.release,
        'sysname': iosInfo.utsname.sysname,
        'version': iosInfo.utsname.version,
      },
    };
  }

  /// 获取Windows设备信息
  static Future<Map<String, dynamic>> _getWindowsInfo() async {
    WindowsDeviceInfo windowsInfo = await _deviceInfoPlugin.windowsInfo;
    
    if (kDebugMode) {
      print('===== Windows 设备信息 =====');
      print('计算机名: ${windowsInfo.computerName}');
      print('用户名: ${windowsInfo.userName}');
      print('系统版本: ${windowsInfo.displayVersion}');
    }

    return {
      'deviceId': windowsInfo.deviceId,
      'deviceName': windowsInfo.computerName,
      'deviceType': 'desktop',
      'osName': 'Windows',
      'osVersion': windowsInfo.displayVersion,
      'browserName': null,
      'browserVersion': null,
      'computerName': windowsInfo.computerName,
      'userName': windowsInfo.userName,
      'numberOfCores': windowsInfo.numberOfCores,
      'systemMemoryInMegabytes': windowsInfo.systemMemoryInMegabytes,
    };
  }

  /// 获取macOS设备信息
  static Future<Map<String, dynamic>> _getMacOsInfo() async {
    MacOsDeviceInfo macInfo = await _deviceInfoPlugin.macOsInfo;
    
    if (kDebugMode) {
      print('===== macOS 设备信息 =====');
      print('计算机名: ${macInfo.computerName}');
      print('主机名: ${macInfo.hostName}');
      print('系统版本: ${macInfo.osRelease}');
    }

    return {
      'deviceId': macInfo.systemGUID ?? 'unknown',
      'deviceName': macInfo.computerName,
      'deviceType': 'desktop',
      'osName': 'macOS',
      'osVersion': macInfo.osRelease,
      'browserName': null,
      'browserVersion': null,
      'computerName': macInfo.computerName,
      'hostName': macInfo.hostName,
      'arch': macInfo.arch,
      'model': macInfo.model,
      'kernelVersion': macInfo.kernelVersion,
      'majorVersion': macInfo.majorVersion,
      'minorVersion': macInfo.minorVersion,
      'patchVersion': macInfo.patchVersion,
    };
  }

  /// 获取Linux设备信息
  static Future<Map<String, dynamic>> _getLinuxInfo() async {
    LinuxDeviceInfo linuxInfo = await _deviceInfoPlugin.linuxInfo;
    
    if (kDebugMode) {
      print('===== Linux 设备信息 =====');
      print('系统名称: ${linuxInfo.name}');
      print('版本: ${linuxInfo.version}');
      print('ID: ${linuxInfo.id}');
    }

    return {
      'deviceId': linuxInfo.machineId ?? 'unknown',
      'deviceName': linuxInfo.prettyName,
      'deviceType': 'desktop',
      'osName': 'Linux',
      'osVersion': linuxInfo.version,
      'browserName': null,
      'browserVersion': null,
      'name': linuxInfo.name,
      'version': linuxInfo.version,
      'id': linuxInfo.id,
      'idLike': linuxInfo.idLike,
      'versionCodename': linuxInfo.versionCodename,
      'versionId': linuxInfo.versionId,
      'prettyName': linuxInfo.prettyName,
      'buildId': linuxInfo.buildId,
      'variant': linuxInfo.variant,
      'variantId': linuxInfo.variantId,
    };
  }

  /// 获取Web设备信息
  static Future<Map<String, dynamic>> _getWebInfo() async {
    WebBrowserInfo webInfo = await _deviceInfoPlugin.webBrowserInfo;
    
    if (kDebugMode) {
      print('===== Web 设备信息 =====');
      print('浏览器名称: ${webInfo.browserName}');
      print('用户代理: ${webInfo.userAgent}');
      print('平台: ${webInfo.platform}');
    }

    return {
      'deviceId': 'web_${DateTime.now().millisecondsSinceEpoch}',
      'deviceName': '${webInfo.browserName?.name} 浏览器',
      'deviceType': 'desktop',
      'osName': webInfo.platform ?? 'Unknown',
      'osVersion': 'Unknown',
      'browserName': webInfo.browserName?.name,
      'browserVersion': webInfo.appVersion,
      'userAgent': webInfo.userAgent,
      'language': webInfo.language,
      'languages': webInfo.languages,
      'platform': webInfo.platform,
      'product': webInfo.product,
      'productSub': webInfo.productSub,
      'vendor': webInfo.vendor,
      'vendorSub': webInfo.vendorSub,
      'hardwareConcurrency': webInfo.hardwareConcurrency,
      'maxTouchPoints': webInfo.maxTouchPoints,
    };
  }

  /// 获取未知平台信息
  static Map<String, dynamic> _getUnknownInfo() {
    return {
      'deviceId': 'unknown_${DateTime.now().millisecondsSinceEpoch}',
      'deviceName': '未知设备',
      'deviceType': 'unknown',
      'osName': 'Unknown',
      'osVersion': 'Unknown',
      'browserName': null,
      'browserVersion': null,
      'error': '不支持的平台',
    };
  }

  /// 获取错误信息
  static Map<String, dynamic> _getErrorInfo(String error) {
    return {
      'deviceId': 'error_${DateTime.now().millisecondsSinceEpoch}',
      'deviceName': '获取失败',
      'deviceType': 'unknown',
      'osName': 'Unknown',
      'osVersion': 'Unknown',
      'browserName': null,
      'browserVersion': null,
      'error': error,
    };
  }

  /// 生成设备指纹
  static String generateDeviceFingerprint(Map<String, dynamic> deviceInfo) {
    final StringBuffer fingerprint = StringBuffer();
    
    fingerprint.write(deviceInfo['osName'] ?? '');
    fingerprint.write('_');
    fingerprint.write(deviceInfo['osVersion'] ?? '');
    fingerprint.write('_');
    fingerprint.write(deviceInfo['deviceType'] ?? '');
    fingerprint.write('_');
    fingerprint.write(deviceInfo['manufacturer'] ?? deviceInfo['brand'] ?? '');
    fingerprint.write('_');
    fingerprint.write(deviceInfo['model'] ?? '');
    
    return fingerprint.toString().toLowerCase().replaceAll(' ', '_');
  }
}
