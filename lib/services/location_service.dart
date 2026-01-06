import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

/// 地理位置服务
class LocationService {
  /// 获取设备位置信息
  static Future<Map<String, dynamic>> getLocationInfo() async {
    try {
      // 检查位置服务是否启用
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print('位置服务未启用');
        }
        return _getDefaultLocationInfo();
      }

      // 检查位置权限
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) {
            print('位置权限被拒绝');
          }
          return _getDefaultLocationInfo();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print('位置权限被永久拒绝');
        }
        return _getDefaultLocationInfo();
      }

      // 获取当前位置
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      if (kDebugMode) {
        print('===== 位置信息 =====');
        print('纬度: ${position.latitude}');
        print('经度: ${position.longitude}');
        print('精度: ${position.accuracy}m');
      }

      // 根据经纬度获取地址信息
      String locationString = '未知位置';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          
          // 构建位置字符串
          List<String> locationParts = [];
          
          // 优先使用中文地址信息
          if (place.country != null && place.country!.isNotEmpty) {
            if (place.country != '中国' && place.country != 'China') {
              locationParts.add(place.country!);
            }
          }
          
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            locationParts.add(place.administrativeArea!);
          }
          
          if (place.locality != null && place.locality!.isNotEmpty) {
            locationParts.add(place.locality!);
          }
          
          if (locationParts.isEmpty) {
            // 如果没有获取到标准地址，尝试使用其他字段
            if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
              locationParts.add(place.subAdministrativeArea!);
            }
            if (place.subLocality != null && place.subLocality!.isNotEmpty) {
              locationParts.add(place.subLocality!);
            }
          }
          
          if (locationParts.isNotEmpty) {
            locationString = locationParts.join('·');
          }

          if (kDebugMode) {
            print('位置: $locationString');
            print('详细地址: ${place.toString()}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('地理编码失败: $e');
        }
        // 即使地理编码失败，也返回经纬度信息
        locationString = '位置(${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
      }

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'locationAccuracy': position.accuracy,
        'locationString': locationString,
        'hasLocationPermission': true,
        'timestamp': position.timestamp.toIso8601String(),
        'altitude': position.altitude,
        'heading': position.heading,
        'speed': position.speed,
      };
    } catch (e) {
      if (kDebugMode) {
        print('获取位置信息失败: $e');
      }
      return _getDefaultLocationInfo();
    }
  }

  /// 获取默认位置信息
  static Map<String, dynamic> _getDefaultLocationInfo() {
    return {
      'latitude': null,
      'longitude': null,
      'locationAccuracy': null,
      'locationString': '未知位置',
      'hasLocationPermission': false,
    };
  }

  /// 检查位置权限状态
  static Future<bool> hasLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      return false;
    }
  }

  /// 请求位置权限
  static Future<bool> requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      return false;
    }
  }

  /// 打开位置设置
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}

