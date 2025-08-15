import 'package:flutter/material.dart';
import '../helpers/preferences_helper.dart';

class UnitSettingsNotifier extends ChangeNotifier {
  // Default values
  String _timeFormat = "12 hr";
  bool _showSeconds = false;

  // Getters
  String get timeFormat => _timeFormat;
  bool get showSeconds => _showSeconds;

  UnitSettingsNotifier() {
    _loadAllSettings();
  }

  Future<void> _loadAllSettings() async {
    _timeFormat =
        await PreferencesHelper.getString("timeFormat") ?? _timeFormat;
    _showSeconds =
        await PreferencesHelper.getBool("showSeconds") ?? _showSeconds;
    notifyListeners();
  }

  // Setters with notification

  void updateTimeUnit(String value) {
    if (_timeFormat != value) {
      _timeFormat = value;
      PreferencesHelper.setString("timeFormat", value);
      notifyListeners();
    }
  }

  void updateShowSeconds(bool value) {
    if (_showSeconds != value) {
      _showSeconds = value;
      PreferencesHelper.setBool("showSeconds", value);
      notifyListeners();
    }
  }
}
