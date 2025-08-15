import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:provider/provider.dart';
import '../notifiers/settings_notifier.dart';

class WorldClockScreen extends StatefulWidget {
  const WorldClockScreen({super.key});

  @override
  State<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends State<WorldClockScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  late Box<String> box;
  List<String> savedTimezones = [];

  bool get is24HourFormat =>
      context.watch<UnitSettingsNotifier>().timeFormat == "24 hr";
  bool get showSeconds => context.watch<UnitSettingsNotifier>().showSeconds;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
    });
    box = Hive.box<String>('savedTimezones');
    savedTimezones = box.values.toList();

    box.watch().listen((event) {
      setState(() {
        savedTimezones = box.values.toList();
      });
    });
  }

  void deleteTimezone(int index) {
    box.deleteAt(index);
  }

  String formatOffset(Duration offset) {
    String sign = offset.isNegative ? '-' : '+';
    int hours = offset.inHours.abs();
    int minutes = offset.inMinutes.abs() % 60;
    return '$sign${hours}h ${minutes}m';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get formattedTime {
    String pattern = is24HourFormat
        ? (showSeconds ? 'HH:mm:ss' : 'HH:mm')
        : (showSeconds ? 'hh:mm:ss' : 'hh:mm');
    return DateFormat(pattern).format(_now);
  }

  String get amPm {
    if (is24HourFormat) return '';
    return DateFormat('a').format(_now);
  }

  // Different date formats:
  String get dateFormat1 => DateFormat.yMd().format(_now);
  String get dateFormat2 => DateFormat.yMMMMEEEEd().format(_now);
  String get dateFormat3 => DateFormat('EEEE, dd MMM yyyy').format(_now);

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),

            Column(
              children: [
                Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: formattedTime,

                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width / 5,
                            fontWeight: FontWeight.w200,
                            color: colorTheme.onSurface,
                          ),
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: Text(
                            amPm,
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width /
                                  11, // smaller size
                              fontWeight: FontWeight.w500,
                              color: colorTheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Text(
                  dateFormat1,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 26),
                savedTimezones.isNotEmpty
                    ? Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          "Saved timezones",
                          style: TextStyle(
                            color: colorTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : SizedBox.shrink(),

                ...savedTimezones.asMap().entries.map((entry) {
                  int index = entry.key;
                  String tzName = entry.value;
                  final location = tz.getLocation(tzName);
                  final tzTime = tz.TZDateTime.from(_now.toUtc(), location);

                  final formattedTzTime = is24HourFormat
                      ? DateFormat('HH:mm').format(tzTime)
                      : DateFormat('hh:mm a').format(tzTime);

                  final offset = tzTime.timeZoneOffset;

                  final isFirst = index == 0;
                  final isLast = index == savedTimezones.length - 1;
                  final firstRadius = isFirst ? 18.0 : 0.0;
                  final lastRadius = isLast ? 18.0 : 0.0;

                  return Container(
                    padding: EdgeInsets.only(
                      left: 10,
                      top: isFirst ? 10 : 2,
                      bottom: isLast ? 130 : 0,
                      right: 10,
                    ),
                    child: Dismissible(
                      key: Key(tzName + index.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(firstRadius),
                            topRight: Radius.circular(firstRadius),
                            bottomLeft: Radius.circular(lastRadius),
                            bottomRight: Radius.circular(lastRadius),
                          ),
                          color: colorTheme.errorContainer,
                        ),
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(
                          Icons.delete,
                          color: colorTheme.onErrorContainer,
                        ),
                      ),

                      onDismissed: (direction) {
                        final removedTz = savedTimezones[index];
                        box.deleteAt(index);

                        bool undoPressed = false;

                        ScaffoldMessenger.of(context).clearSnackBars();

                        final controller = ScaffoldMessenger.of(context)
                            .showSnackBar(
                              SnackBar(
                                content: Text('$removedTz deleted'),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () {
                                    undoPressed = true;
                                    // Restore in Hive directly
                                    box.add(removedTz);
                                  },
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                      },

                      child: ListTile(
                        tileColor: colorTheme.surfaceContainerLowest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(firstRadius),
                            topRight: Radius.circular(firstRadius),
                            bottomLeft: Radius.circular(lastRadius),
                            bottomRight: Radius.circular(lastRadius),
                          ),
                        ),
                        title: Text(formatCityName(tzName)),
                        subtitle: Text(formatOffset(offset)),
                        trailing: Text(
                          formattedTzTime,
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width / 11,
                            fontWeight: FontWeight.w500,
                            color: colorTheme.secondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String formatCityName(String tzName) {
  // Split by '/', get last part (city)
  final city = tzName.split('/').last;

  // Replace underscores with spaces
  final cityWithSpaces = city.replaceAll('_', ' ');

  // Capitalize words (optional, for nicer display)
  return cityWithSpaces
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1);
      })
      .join(' ');
}
