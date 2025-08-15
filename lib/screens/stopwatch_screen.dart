import 'dart:async';
import 'dart:io';
import 'package:material_color_utilities/quantize/quantizer_wu.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:clockmaster/helpers/icon_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../widgets/animated_fab.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(StopwatchTaskHandler());
}

bool firstStart = true;

class StopwatchTaskHandler extends TaskHandler {
  Stopwatch stopwatch = Stopwatch();
  Timer? timer;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    if (!firstStart) {
      stopwatch.start();
    } else {
      stopwatch.reset();
    }

    timer?.cancel();

    print('*** Foreground task STARTED ***');
    timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      FlutterForegroundTask.sendDataToMain({
        'elapsed': stopwatch.elapsedMilliseconds,
      });

      // Update notification text every second
      if (stopwatch.elapsedMilliseconds % 1000 < 100) {
        FlutterForegroundTask.updateService(
          notificationTitle: _formatTime(stopwatch.elapsedMilliseconds),
          notificationText: 'Stopwatch',
          notificationButtons: [
            NotificationButton(
              id: stopwatch.isRunning ? 'pause' : 'start',
              text: stopwatch.isRunning ? 'Pause' : 'Start',
            ),
            const NotificationButton(id: 'reset', text: 'Reset'),
          ],
        );
      }
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    timer?.cancel();
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map<String, dynamic>) {
      final action = data['action'] as String?;
      if (action == 'start') {
        stopwatch.start();
      } else if (action == 'pause') {
        stopwatch.stop();
      } else if (action == 'reset') {
        stopwatch.reset();
      }
    }
  }

  @override
  void onNotificationButtonPressed(String id) async {
    if (id == 'pause') {
      stopwatch.stop();
    } else if (id == 'start') {
      stopwatch.start();
    } else if (id == 'reset') {
      stopwatch.reset();
      _stopService();
    }
  }

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}

  Future<void> _stopService() async {
    await FlutterForegroundTask.stopService();
    firstStart = true;
    FlutterForegroundTask.sendDataToMain("resetFromNotification");
  }
}

String _formatTime(int ms) {
  final seconds = ((ms / 1000) % 60).floor();
  final minutes = ((ms / 60000) % 60).floor();
  final hours = (ms / 3600000).floor();

  final hoursStr = hours > 0 ? '${hours.toString().padLeft(2, '0')}:' : '';
  final minutesStr = minutes.toString().padLeft(2, '0');
  final secondsStr = seconds.toString().padLeft(2, '0');

  return '$hoursStr$minutesStr:$secondsStr';
}

class StopWatchScreen extends StatefulWidget {
  const StopWatchScreen({super.key});

  @override
  State<StopWatchScreen> createState() => _StopWatchScreenState();
}

class _StopWatchScreenState extends State<StopWatchScreen> {
  int _elapsed = 0;
  bool _isRunning = false;
  List<String> _laps = [];

  @override
  void initState() {
    super.initState();

    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initForegroundTask();
    });
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    super.dispose();
  }

  void _onReceiveTaskData(Object data) {
    if (data is Map<String, dynamic>) {
      final int? elapsed = data['elapsed'] as int?;
      if (elapsed != null) {
        setState(() {
          _elapsed = elapsed;
        });
      }
    } else if (data is String) {
      if (data == "resetFromNotification") {
        setState(() {
          _elapsed = 0;
          _isRunning = false;
        });
        final count = _laps.length;
        for (var i = count - 1; i >= 0; i--) {
          final removedItem = _laps.removeAt(i);
          _listKey.currentState?.removeItem(
            i,
            (context, animation) => FadeTransition(
              opacity: animation,
              child: ListTile(
                leading: Text('Lap ${i + 1}'),
                trailing: Text(removedItem),
              ),
            ),
            duration: Duration(milliseconds: 200),
          );
        }
      }
    }
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'stopwatch_channel',
        channelName: 'Stopwatch Service',
        channelDescription: 'Stopwatch is running',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        allowWakeLock: true,
        allowWifiLock: true,
        autoRunOnBoot: true,
        eventAction: ForegroundTaskEventAction.nothing(),
      ),
    );
  }

  Future<void> _startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return;
    }
    _initForegroundTask();
    await FlutterForegroundTask.startService(
      serviceId: 999,
      notificationTitle: _formatTime(_elapsed),
      notificationText: 'Stopwatch',
      notificationIcon: const NotificationIcon(
        metaDataName: "com.pranshulgg.service.stopwatch_icon",
      ),

      notificationButtons: [
        NotificationButton(
          id: _isRunning ? 'pause' : 'start',
          text: _isRunning ? 'Pause' : 'Start',
        ),
        const NotificationButton(id: 'reset', text: 'Reset'),
      ],
      notificationInitialRoute: '/',

      callback: startCallback,
    );
  }

  Future<void> _stopService() async {
    await FlutterForegroundTask.stopService();
  }

  void _sendAction(String action) {
    FlutterForegroundTask.sendDataToTask({'action': action});
  }

  void _startPause() async {
    if (!_isRunning) {
      firstStart = false;
      if (!await FlutterForegroundTask.isRunningService) {
        await _startService();
      }
      _sendAction('start');
    } else {
      _sendAction('pause');
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  void _reset() async {
    _sendAction('reset');
    setState(() {
      _isRunning = false;
      _elapsed = 0;
    });
    final count = _laps.length;
    for (var i = count - 1; i >= 0; i--) {
      final removedItem = _laps.removeAt(i);
      _listKey.currentState?.removeItem(
        i,
        (context, animation) => FadeTransition(
          opacity: animation,
          child: ListTile(
            leading: Text('Lap ${i + 1}'),
            trailing: Text(removedItem),
          ),
        ),
        duration: Duration(milliseconds: 200),
      );
    }
    await _stopService();
  }

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  void _lap() {
    final formattedLap = _formatTime(_elapsed);

    _laps.insert(0, formattedLap);

    _listKey.currentState?.insertItem(0, duration: Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final elapsedStr = _formatTime(_elapsed);
    final colorTheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInBack,
              switchOutCurve: Curves.easeOutBack,
              transitionBuilder: (child, animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0, 0.1),

                  end: Offset.zero,
                ).animate(animation);
                return SlideTransition(
                  position: offsetAnimation,

                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Text(
                elapsedStr,
                key: ValueKey<String>(elapsedStr),
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width / 3.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Divider(),
            Expanded(
              child: AnimatedList(
                key: _listKey,
                initialItemCount: _laps.length,
                itemBuilder: (context, index, animation) {
                  final lapNum = _laps.length - index;
                  final lapTime = _laps[index];

                  return FadeTransition(
                    opacity: animation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorTheme.tertiaryContainer,
                          foregroundColor: colorTheme.onTertiaryContainer,
                          child: Text("#$lapNum"),
                        ),
                        trailing: Text(
                          lapTime,
                          style: TextStyle(
                            color: colorTheme.secondary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 10,
              children: [
                AnimatedFAB(isRunning: _isRunning, onPressed: _startPause),
                FloatingActionButton.large(
                  shape: const CircleBorder(),
                  onPressed: _reset,
                  backgroundColor: colorTheme.secondaryContainer,
                  heroTag: "idk_cool_random_tag",

                  elevation: 0,
                  highlightElevation: 0,
                  child: IconWithWeight(
                    Symbols.restart_alt,
                    size: 40,
                    color: colorTheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),
            Container(
              width: 96 + 96,
              height: 70,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
              ),
              child: FloatingActionButton.extended(
                onPressed: _isRunning ? _lap : null,
                backgroundColor: colorTheme.secondaryContainer,
                heroTag: "idk_random_tag_stop_wow",

                label: Text(
                  "Lap",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
