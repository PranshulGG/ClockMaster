import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home.dart';
import 'package:flutter/services.dart';
import 'helpers/preferences_helper.dart';
import 'utils/theme_controller.dart';
import 'package:provider/provider.dart';
import 'screens/alarm_screen.dart';
import 'services/alarm_service.dart';
import 'notifiers/settings_notifier.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await SharedPreferences.getInstance();

  FlutterForegroundTask.initCommunicationPort();

  await AlarmService.instance.init();
  await Hive.initFlutter();
  await Hive.openBox<String>('savedTimezones');

  await PreferencesHelper.init();

  final themeController = ThemeController();
  await themeController.initialize();
  await themeController.checkDynamicColorSupport();

  // FlutterForegroundTask.init(
  //   androidNotificationOptions: AndroidNotificationOptions(
  //     channelId: 'timer_channel',
  //     channelName: 'Timers',
  //     channelDescription: 'Running timers in background',
  //     channelImportance: NotificationChannelImportance.LOW,
  //     priority: NotificationPriority.LOW,
  //   ),
  //   iosNotificationOptions: const IOSNotificationOptions(),
  //   foregroundTaskOptions: ForegroundTaskOptions(
  //     eventAction: ForegroundTaskEventAction.repeat(1000),
  //     autoRunOnBoot: false,
  //   ),
  // );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeController),
        ChangeNotifierProvider(create: (_) => UnitSettingsNotifier()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final colorTheme = Theme.of(context).colorScheme;

    return MaterialApp(
      title: 'ClockMaster',
      debugShowCheckedModeBanner: false,
      theme:
          ThemeData.from(
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeController.seedColor,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ).copyWith(
            textTheme: ThemeData.light().textTheme.apply(
              fontFamily: 'OpenSans',
            ),
            highlightColor: Colors.transparent,

            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: SharedAxisPageTransitionsBuilder(
                  transitionType: SharedAxisTransitionType.horizontal,
                ),
                TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
                  transitionType: SharedAxisTransitionType.horizontal,
                ),
              },
            ),
          ),

      darkTheme:
          ThemeData.from(
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeController.seedColor,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ).copyWith(
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'OpenSans'),
            highlightColor: Colors.transparent,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: SharedAxisPageTransitionsBuilder(
                  transitionType: SharedAxisTransitionType.horizontal,
                ),
                TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
                  transitionType: SharedAxisTransitionType.horizontal,
                ),
              },
            ),
          ),

      themeMode: themeController.themeMode,
      home: const HomePage(),
    );
  }
}
