import 'package:clockmaster/helpers/icon_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alarm_data_model.dart';
import '../services/alarm_service.dart';
import '../screens/alarm_edit_screen.dart';
import '../utils/snack_util.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../notifiers/settings_notifier.dart';
import 'package:provider/provider.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => AlarmScreenState();
}

class AlarmScreenState extends State<AlarmScreen> {
  List<Alarm> alarms = [];

  bool get is24HourFormat =>
      context.watch<UnitSettingsNotifier>().timeFormat == "24 hr";

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final loaded = await AlarmService.instance.loadAlarms();
    setState(() => alarms = loaded);
  }

  Future<void> _saveAndSchedule(Alarm alarm) async {
    await AlarmService.instance.saveAndSchedule(alarm);
    load();
  }

  Future<void> _delete(Alarm alarm) async {
    alarms.removeWhere((a) => a.id == alarm.id);
    await AlarmService.instance.cancelAlarm(alarm.id);
    await AlarmService.instance.saveAlarms(alarms);
    await load();
  }

  Future<void> _openEditor({Alarm? edit}) async {
    showModalBottomSheet<Alarm>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AlarmEditContent(alarm: edit),
      ),
    ).then((result) async {
      if (result is Alarm) {
        await _saveAndSchedule(result);
      }
    });
  }

  String formatTimeSeparateAmPm(Alarm a) {
    final dt = DateTime(0, 1, 1, a.hour, a.minute);
    final fullTime = DateFormat.jm().format(dt);

    final parts = fullTime.split(' ');
    final time = parts[0];
    final ampm = parts.length > 1 ? parts[1] : '';

    return '$time $ampm';
  }

  Map<String, String> getTimeAndAmPm(Alarm a) {
    final dt = DateTime(0, 1, 1, a.hour, a.minute);

    if (is24HourFormat) {
      final fullTime = DateFormat.Hm().format(dt);
      return {'time': fullTime, 'ampm': ''};
    } else {
      final fullTime = DateFormat.jm().format(dt);
      final regex = RegExp(
        r'(\d{1,2}:\d{2})(?:\s*)?(AM|PM)?',
        caseSensitive: false,
      );
      final match = regex.firstMatch(fullTime);

      if (match != null) {
        final time = match.group(1) ?? '';
        final ampm = match.group(2) ?? '';
        return {'time': time, 'ampm': ampm};
      }
      return {'time': fullTime, 'ampm': ''};
    }
  }

  String _repeatDaysText(List<int> days) {
    if (days.isEmpty) return 'One-time';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (days.length == 7) return 'Every day';
    return days.map((d) => names[d - 1]).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    // - ${a.label}
    return Scaffold(
      body: alarms.isEmpty
          ? Center(
              child: Opacity(
                opacity: 0.6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconWithWeight(
                      Symbols.alarm_off,
                      color: colorTheme.onSurfaceVariant,
                      size: 60,
                    ),
                    Text(
                      "No alarms",
                      style: TextStyle(
                        fontSize: 30,
                        color: colorTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: alarms.length,
              itemBuilder: (context, i) {
                final a = alarms[i];
                final resultAlarms = getTimeAndAmPm(a);
                final isLast = i == alarms.length - 1;

                return Dismissible(
                  key: ValueKey(a.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: colorTheme.errorContainer,
                    ),
                    child: Icon(
                      Icons.delete,
                      color: colorTheme.onErrorContainer,
                    ),
                  ),
                  onDismissed: (direction) {
                    _delete(a);
                    SnackUtil.showSnackBar(
                      context: context,
                      message: "Alarm deleted",
                    );
                  },
                  child: GestureDetector(
                    child: Container(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 10,
                        top: 12,
                      ),
                      margin: EdgeInsets.only(bottom: isLast ? 130 : 5),
                      decoration: BoxDecoration(
                        color: a.enabled
                            ? colorTheme.surfaceContainerLow
                            : colorTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _repeatDaysText(a.repeatDays),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: colorTheme.onSurfaceVariant,
                                ),
                              ),

                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: resultAlarms['time'],
                                      style: TextStyle(
                                        fontSize: 60,
                                        fontWeight: FontWeight.w200,
                                        color: colorTheme.onSurface,
                                      ),
                                    ),
                                    TextSpan(text: " "),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.baseline,
                                      baseline: TextBaseline.alphabetic,
                                      child: Text(
                                        resultAlarms['ampm'].toString(),
                                        style: TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w500,
                                          color: colorTheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                a.label,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorTheme.secondary,
                                ),
                              ),
                            ],
                          ),
                          // Column(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          //   children: [
                          Switch(
                            value: a.enabled,
                            thumbIcon: WidgetStateProperty.resolveWith<Icon?>(
                              (states) => states.contains(WidgetState.selected)
                                  ? Icon(
                                      Icons.notifications_active,
                                      color: colorTheme.primary,
                                    )
                                  : null,
                            ),
                            onChanged: (v) async {
                              a.enabled = v;
                              await _saveAndSchedule(a);
                              setState(() {});
                            },
                            // ),
                            // ],
                          ),
                        ],
                      ),
                    ),

                    onTap: () {
                      showModalBottomSheet<Alarm>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: colorTheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        builder: (context) => Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: AlarmEditContent(
                            alarm: a,
                            is24HourFormat: is24HourFormat,
                          ),
                        ),
                      ).then((result) async {
                        if (result is Alarm) {
                          await _saveAndSchedule(result);
                        }
                      });
                    },
                  ),
                );
              },
            ),
    );
  }
}
