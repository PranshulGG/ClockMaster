import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/alarm_data_model.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class AlarmService {
  static const MethodChannel _channel = MethodChannel(
    'com.pranshulgg.alarm/alarm',
  );

  static const _prefKey = 'alarms_v1';
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  AlarmService._privateConstructor();

  static final AlarmService instance = AlarmService._privateConstructor();

  Future<void> init() async {
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings(
      'baseline_timer_24',
    ); // must be added in drawable
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {},
    );
  }

  Future<List<Alarm>> loadAlarms() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_prefKey) ?? [];
    return raw.map((s) => Alarm.fromJson(s)).toList();
  }

  Future<void> saveAlarms(List<Alarm> alarms) async {
    final sp = await SharedPreferences.getInstance();
    final encoded = alarms.map((a) => a.toJson()).toList();
    await sp.setStringList(_prefKey, encoded);
  }

  Future<void> scheduleAlarm(Alarm alarm) async {
    final dt = alarm.nextTriggerDateTime().toUtc().millisecondsSinceEpoch;

    try {
      await _channel.invokeMethod('scheduleAlarm', {
        'id': alarm.id,
        'triggerAtMillisUtc': dt,
        'label': alarm.label,
        'vibrate': alarm.vibrate,
        'sound': alarm.sound,
        'recurring': alarm.repeatDays.isNotEmpty,
      });
    } on PlatformException {}
  }

  Future<void> cancelAlarm(int id) async {
    try {
      await _channel.invokeMethod('cancelAlarm', {'id': id});
    } on PlatformException {
      // fallback: cancel local notification
    }
  }

  Future<void> saveAndSchedule(Alarm alarm) async {
    final currentAlarms = await loadAlarms();

    final index = currentAlarms.indexWhere((a) => a.id == alarm.id);
    if (index >= 0) {
      currentAlarms[index] = alarm;
    } else {
      currentAlarms.add(alarm);
    }

    await saveAlarms(currentAlarms);

    if (alarm.enabled) {
      await scheduleAlarm(alarm);
    } else {
      await cancelAlarm(alarm.id);
    }
  }
}
