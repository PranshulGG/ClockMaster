import 'package:flutter/services.dart';

class NotificationService {
  static const MethodChannel _channel = MethodChannel(
    'com.pranshulgg.alarm/alarm',
  );

  static Future<bool> checkPermission() async {
    return await _channel.invokeMethod('checkNotificationPermission') ?? false;
  }

  static Future<bool> requestPermission() async {
    return await _channel.invokeMethod('requestNotificationPermission') ??
        false;
  }
}
