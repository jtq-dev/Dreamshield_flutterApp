import 'package:shared_preferences/shared_preferences.dart';

class PersistenceService {
  static const _goalKey   = 'goal_hours';
  static const _themeKey  = 'theme_dark';
  static const _presetKey = 'mixer_preset';
  static const _alertModeKey = 'alert_mode';
  // ---- existing APIs ----
  Future<void> saveGoal(double hours) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_goalKey, hours);
  }

  Future<double> loadGoal() async {
    final p = await SharedPreferences.getInstance();
    return p.getDouble(_goalKey) ?? 7.5;
  }

  Future<void> saveDarkTheme(bool dark) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_themeKey, dark);
  }

  Future<bool> loadDarkTheme() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_themeKey) ?? false;
  }
  Future<void> saveAlertMode(int mode) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_alertModeKey, mode);
  }

  Future<int> loadAlertMode() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_alertModeKey) ?? 0;
  }

  Future<void> saveMixerPreset(String jsonPreset) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_presetKey, jsonPreset);
  }

  Future<String?> loadMixerPreset() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_presetKey);
  }

  // ---- add these generic helpers (used by ConsentSheet) ----
  Future<bool?> getBool(String key) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(key);
  }

  Future<void> setBool(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
  }
}
