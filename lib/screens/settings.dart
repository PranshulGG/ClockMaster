import 'package:flutter/material.dart';
import 'package:settings_tiles/settings_tiles.dart';
import '../utils/theme_controller.dart';
import 'package:provider/provider.dart';
import '../helpers/preferences_helper.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../helpers/icon_helper.dart';
import '../notifiers/settings_notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showTile = PreferencesHelper.getBool("usingCustomSeed") ?? false;
  bool _useCustomTile = PreferencesHelper.getBool("DynamicColors") == true
      ? false
      : true;
  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final currentMode = themeController.themeMode;
    final isSupported = themeController.isDynamicColorSupported;
    final currentTimeFormat =
        PreferencesHelper.getString("timeFormat") ?? "12 hr";
    final currentShowSeconds =
        PreferencesHelper.getBool("showSeconds") ?? false;

    final optionsTheme = {"Auto": "Auto", "Dark": "Dark", "Light": "Light"};
    final optionsTimeFormat = {"12 hr": "12 hr", "24 hr": "24 hr"};

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('Settings'),
            titleSpacing: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            scrolledUnderElevation: 1,
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                SettingSection(
                  styleTile: true,
                  title: SettingSectionTitle("App looks", noPadding: true),
                  tiles: [
                    SettingSingleOptionTile(
                      icon: IconWithWeight(Symbols.routine, fill: 1),
                      title: Text('App theme'),
                      dialogTitle: 'App theme',
                      value: SettingTileValue(
                        optionsTheme[currentMode == ThemeMode.light
                            ? "Light"
                            : currentMode == ThemeMode.system
                            ? "Auto"
                            : "Dark"]!,
                      ),
                      options: optionsTheme.values.toList(),
                      initialOption:
                          optionsTheme[currentMode == ThemeMode.light
                              ? "Light"
                              : currentMode == ThemeMode.system
                              ? "Auto"
                              : "Dark"]!,
                      onSubmitted: (value) {
                        setState(() {
                          final selectedKey = optionsTheme.entries
                              .firstWhere((e) => e.value == value)
                              .key;
                          PreferencesHelper.setString("AppTheme", selectedKey);
                          themeController.setThemeMode(
                            selectedKey == "Dark"
                                ? ThemeMode.dark
                                : selectedKey == "Auto"
                                ? ThemeMode.system
                                : ThemeMode.light,
                          );
                        });
                      },
                    ),

                    SettingSwitchTile(
                      enabled: _useCustomTile,
                      icon: IconWithWeight(Symbols.colorize, fill: 1),
                      title: Text("Use custom color"),
                      toggled:
                          PreferencesHelper.getBool("usingCustomSeed") ?? false,
                      onChanged: (value) {
                        setState(() {
                          PreferencesHelper.setBool("usingCustomSeed", value);
                          if (value == true) {
                            Provider.of<ThemeController>(
                              context,
                              listen: false,
                            ).setSeedColor(
                              PreferencesHelper.getColor(
                                    "CustomMaterialColor",
                                  ) ??
                                  Colors.blue,
                            );
                          } else {
                            Provider.of<ThemeController>(
                              context,
                              listen: false,
                            ).setSeedColor(Colors.blue);
                          }
                        });
                        _showTile = value;
                      },
                    ),

                    SettingColorTile(
                      enabled: _showTile,
                      icon: IconWithWeight(Symbols.colors, fill: 1),
                      title: Text('Primary color'),
                      description: Text(
                        'Select a seed color to generate the theme',
                      ),
                      dialogTitle: 'Color',
                      initialColor:
                          PreferencesHelper.getColor("CustomMaterialColor") ??
                          Colors.blue,
                      colorPickers: [ColorPickerType.primary],
                      onSubmitted: (value) {
                        setState(() {
                          PreferencesHelper.setColor(
                            "CustomMaterialColor",
                            value,
                          );
                          Provider.of<ThemeController>(
                            context,
                            listen: false,
                          ).setSeedColor(value);
                        });
                      },
                    ),

                    SettingSwitchTile(
                      enabled: isSupported
                          ? _showTile
                                ? false
                                : true
                          : false,
                      icon: IconWithWeight(Symbols.wallpaper, fill: 1),
                      title: Text("Dynamic colors"),

                      description: Text(
                        "${"Use wallpaper colors"} ${isSupported ? "" : "(Android 12+)"}",
                      ),
                      toggled:
                          PreferencesHelper.getBool("DynamicColors") ?? false,
                      onChanged: (value) async {
                        final themeController = context.read<ThemeController>();

                        PreferencesHelper.setBool("DynamicColors", value);

                        if (value) {
                          await themeController.loadDynamicColors();
                        } else {
                          Provider.of<ThemeController>(
                            context,
                            listen: false,
                          ).setSeedColor(Colors.blue);
                        }
                        setState(() {
                          if (value) {
                            _useCustomTile = false;
                          } else {
                            _useCustomTile = true;
                          }
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                SettingSection(
                  styleTile: true,
                  title: SettingSectionTitle("Clock", noPadding: true),
                  tiles: [
                    SettingSingleOptionTile(
                      icon: IconWithWeight(
                        Symbols.nest_clock_farsight_analog,
                        fill: 1,
                      ),
                      title: Text('Time format'),
                      value: SettingTileValue(
                        optionsTimeFormat[currentTimeFormat]!,
                      ),
                      dialogTitle: 'Time format',
                      options: optionsTimeFormat.values.toList(),
                      initialOption: optionsTimeFormat[currentTimeFormat]!,
                      onSubmitted: (value) {
                        final selectedKey = optionsTimeFormat.entries
                            .firstWhere((e) => e.value == value)
                            .key;
                        context.read<UnitSettingsNotifier>().updateTimeUnit(
                          selectedKey,
                        );
                        setState(() {});
                      },
                    ),
                    SettingSwitchTile(
                      icon: IconWithWeight(Symbols.timer_10_select, fill: 1),
                      title: Text("Display time with seconds"),
                      toggled: currentShowSeconds,
                      onChanged: (value) {
                        context.read<UnitSettingsNotifier>().updateShowSeconds(
                          value,
                        );
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
