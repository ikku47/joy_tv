import 'package:flutter/services.dart';

import '../utils/log_util.dart';

class DeviceProfileService {
  static const MethodChannel _channel = MethodChannel('com.example.joy_tv.device');
  static bool? _cachedIsTv;

  static Future<bool> isTvDevice() async {
    if (_cachedIsTv != null) return _cachedIsTv!;
    try {
      final result = await _channel.invokeMethod<bool>('is_tv_device');
      _cachedIsTv = result ?? false;
      logI('Native device profile detected: isTv=$_cachedIsTv', tag: 'DeviceProfile');
    } catch (e, st) {
      _cachedIsTv = false;
      logE('Failed to detect TV device profile', tag: 'DeviceProfile', error: e, stackTrace: st);
    }
    return _cachedIsTv!;
  }
}
