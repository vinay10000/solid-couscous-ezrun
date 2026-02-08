import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WidgetPlatformService {
  static const MethodChannel _channel = MethodChannel(
    'com.ezrun.ezrun/days_counter_widget',
  );

  Future<void> updateWidget() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('updateWidget');
    } catch (_) {
      // Ignore platform errors
    }
  }

  Future<bool> checkWidgetExists() async {
    if (!_isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('checkWidgetExists');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPinWidget() async {
    if (!_isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('requestPinWidget');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
