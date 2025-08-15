import 'package:flutter/material.dart';
import '../models/alarm_data_model.dart';
import 'package:settings_tiles/settings_tiles.dart';
import 'package:flutter/services.dart';

class AlarmEditContent extends StatefulWidget {
  final Alarm? alarm;
  final bool is24HourFormat;
  const AlarmEditContent({Key? key, this.alarm, this.is24HourFormat = false})
    : super(key: key);

  @override
  State<AlarmEditContent> createState() => _AlarmEditContentState();
}

class _AlarmEditContentState extends State<AlarmEditContent> {
  late TimeOfDay time;
  late TextEditingController labelController;
  List<int> repeatDays = [];
  bool vibrate = true;
  String? sound;

  @override
  void initState() {
    super.initState();
    if (widget.alarm != null) {
      time = TimeOfDay(hour: widget.alarm!.hour, minute: widget.alarm!.minute);
      labelController = TextEditingController(text: widget.alarm!.label);
      repeatDays = List.from(widget.alarm!.repeatDays);
      vibrate = widget.alarm!.vibrate;
      sound = widget.alarm!.sound;
    } else {
      time = TimeOfDay.now();
      labelController = TextEditingController();
    }
  }

  void toggleDay(int day) {
    setState(() {
      if (repeatDays.contains(day)) {
        repeatDays.remove(day);
      } else {
        repeatDays.add(day);
      }
    });
  }

  Future<void> _pickSound() async {
    const channel = MethodChannel('com.pranshulgg.alarm/alarm');
    try {
      final pickedSound = await channel.invokeMethod<String>('pickSound');
      if (pickedSound != null) {
        setState(() {
          sound = pickedSound;
        });
      }
    } catch (e) {
      debugPrint("Sound picking failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final is24HourFormat = widget.is24HourFormat;

    if (labelController.text.isEmpty) {
      labelController.text = "Your label";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colorTheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          SizedBox(height: 10),
          Text(
            widget.alarm == null ? 'Add Alarm' : 'Edit Alarm',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),

          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(alwaysUse24HourFormat: is24HourFormat),
                    child: child!,
                  );
                },
              );
              if (picked != null) setState(() => time = picked);
            },
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _formatTimeWithoutAmPm(time, is24HourFormat, context),
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width / 5,
                      fontFamily: "OpenSans",
                      fontWeight: FontWeight.bold,
                      color: colorTheme.onSurface,
                    ),
                  ),
                  TextSpan(text: " "),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: Text(
                      _getAmPm(time, is24HourFormat, context),
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width / 11,
                        fontWeight: FontWeight.w500,
                        color: colorTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          Wrap(
            spacing: 2,
            children: List.generate(7, (index) {
              const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              final dayNum = index + 1;
              final isFirst = index == 0;
              final isLast = index == 6;

              final firstRadius = isFirst ? 18.0 : 5.0;
              final lastRadius = isLast ? 18.0 : 5.0;

              final selected = repeatDays.contains(dayNum);
              return SizedBox(
                width: 40,
                height: 40,
                child: ChoiceChip(
                  label: Center(
                    child: Text(
                      days[index],
                      style: TextStyle(
                        color: selected
                            ? colorTheme.onTertiary
                            : colorTheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: selected
                        ? BorderRadius.circular(50)
                        : BorderRadius.only(
                            topLeft: Radius.circular(firstRadius),
                            bottomLeft: Radius.circular(firstRadius),
                            bottomRight: Radius.circular(lastRadius),
                            topRight: Radius.circular(lastRadius),
                          ),
                  ),
                  showCheckmark: false,
                  selectedColor: colorTheme.tertiary,
                  padding: EdgeInsets.all(0),
                  selected: selected,
                  onSelected: (_) => toggleDay(dayNum),
                ),
              );
            }),
          ),

          SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              child: SettingSection(
                styleTile: true,
                tiles: [
                  SettingTextFieldTile(
                    title: Text("Label"),
                    dialogTitle: "Label",
                    onSubmitted: (value) {
                      setState(() {
                        labelController.text = value;
                      });
                    },
                    initialText: labelController.text,
                    value: Text(labelController.text),
                  ),
                  SettingSwitchTile(
                    title: const Text('Vibrate'),
                    toggled: vibrate,
                    onChanged: (v) => setState(() => vibrate = v),
                  ),

                  SettingActionTile(
                    title: const Text('Sound'),
                    description: Text(sound ?? 'Default'),
                    onTap: _pickSound,
                  ),
                ],
              ),
            ),
          ),

          FilledButton.icon(
            onPressed: () {
              final id =
                  widget.alarm?.id ?? DateTime.now().millisecondsSinceEpoch;
              final newAlarm = Alarm(
                id: id,
                hour: time.hour,
                minute: time.minute,
                label: labelController.text.isEmpty
                    ? 'Alarm'
                    : labelController.text,
                enabled: true,
                repeatDays: repeatDays,
                vibrate: vibrate,
                sound: sound,
              );
              Navigator.pop(context, newAlarm);
            },
            icon: Icon(Icons.save, size: 20),
            label: Text(
              widget.alarm == null ? 'Add' : 'Save',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              minimumSize: Size(double.infinity, 58),
              backgroundColor: colorTheme.tertiaryContainer,
              foregroundColor: colorTheme.onTertiaryContainer,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// Helper functions
String _formatTimeWithoutAmPm(
  TimeOfDay time,
  bool is24HourFormat,
  BuildContext context,
) {
  if (is24HourFormat) {
    final hourStr = time.hour.toString().padLeft(2, '0');
    final minuteStr = time.minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  } else {
    final formatted = time.format(context);
    return formatted.split(' ')[0];
  }
}

String _getAmPm(TimeOfDay time, bool is24HourFormat, BuildContext context) {
  if (is24HourFormat) {
    return ''; // no AM/PM in 24hr format
  } else {
    final formatted = time.format(context);
    return formatted.split(' ').length > 1 ? formatted.split(' ')[1] : '';
  }
}
