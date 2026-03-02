import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_model.dart';

class StorageService {
  static const String _historiesKey = 'schedule_histories';
  static const String _onboardingKey = 'onboarding_done';
  static const String _themeModeKey = 'theme_mode'; // 0=system,1=light,2=dark

  // ─── Onboarding ───────────────────────────────────────────────
  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  static Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  // ─── Theme ────────────────────────────────────────────────────
  static Future<int> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_themeModeKey) ?? 0;
  }

  static Future<void> setThemeMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode);
  }

  // ─── History ──────────────────────────────────────────────────
  static Future<List<ScheduleModel>> getHistories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historiesKey) ?? [];
    return raw.map((e) => ScheduleModel.fromMap(jsonDecode(e))).toList();
  }

  static Future<void> saveSchedule(ScheduleModel schedule) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historiesKey) ?? [];
    raw.insert(0, jsonEncode(schedule.toMap()));
    await prefs.setStringList(_historiesKey, raw);
  }

  static Future<void> deleteSchedule(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historiesKey) ?? [];
    raw.removeWhere((e) => jsonDecode(e)['id'] == id);
    await prefs.setStringList(_historiesKey, raw);
  }

  static Future<void> clearAllHistories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historiesKey);
  }
}
