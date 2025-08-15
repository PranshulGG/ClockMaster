// lib/models/alarm.dart
import 'dart:convert';

class Alarm {
  final int id;
  int hour;
  int minute;
  String label;
  bool enabled;
  List<int> repeatDays;
  bool vibrate;
  String? sound;
  int snoozeMinutes;

  Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = 'Alarm',
    this.enabled = false,
    this.repeatDays = const [],
    this.vibrate = true,
    this.sound,
    this.snoozeMinutes = 5,
  });

  DateTime nextTriggerDateTime() {
    final now = DateTime.now();
    DateTime candidate = DateTime(now.year, now.month, now.day, hour, minute);

    if (repeatDays.isNotEmpty) {
      int today = now.weekday;
      int addDays = 0;
      while (!repeatDays.contains((today + addDays - 1) % 7 + 1) ||
          candidate.isBefore(now)) {
        addDays++;
        candidate = DateTime(
          now.year,
          now.month,
          now.day + addDays,
          hour,
          minute,
        );
      }
      return candidate;
    }

    // No repeat: schedule tomorrow if time passed
    if (candidate.isBefore(now))
      candidate = candidate.add(const Duration(days: 1));
    return candidate;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'hour': hour,
    'minute': minute,
    'label': label,
    'enabled': enabled,
    'repeatDays': repeatDays,
    'vibrate': vibrate,
    'sound': sound,
    'snoozeMinutes': snoozeMinutes,
  };

  factory Alarm.fromMap(Map<String, dynamic> m) => Alarm(
    id: m['id'] as int,
    hour: m['hour'] as int,
    minute: m['minute'] as int,
    label: (m['label'] as String?) ?? 'Alarm',
    enabled: m['enabled'] ?? false,
    repeatDays: List<int>.from(m['repeatDays'] ?? []),
    vibrate: m['vibrate'] ?? true,
    sound: m['sound'],
    snoozeMinutes: m['snoozeMinutes'] ?? 5,
  );

  String toJson() => json.encode(toMap());
  factory Alarm.fromJson(String str) => Alarm.fromMap(json.decode(str));
}
