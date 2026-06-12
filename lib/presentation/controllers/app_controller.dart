import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/constants.dart';

class AppController extends GetxController {
  static AppController get to => Get.find();

  final _themeMode = ThemeMode.system.obs;
  ThemeMode get themeMode => _themeMode.value;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.keyThemeMode) ?? 'system';
    _themeMode.value = _modeFromString(saved);
    Get.changeThemeMode(_themeMode.value);
  }

  void toggleTheme() {
    final next = Get.isDarkMode ? ThemeMode.light : ThemeMode.dark;
    _setTheme(next);
  }

  void setTheme(ThemeMode mode) => _setTheme(mode);

  Future<void> _setTheme(ThemeMode mode) async {
    _themeMode.value = mode;
    Get.changeThemeMode(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyThemeMode, _modeToString(mode));
  }

  static ThemeMode _modeFromString(String s) => switch (s) {
        'light' => ThemeMode.light,
        'dark'  => ThemeMode.dark,
        _       => ThemeMode.system,
      };

  static String _modeToString(ThemeMode m) => switch (m) {
        ThemeMode.light  => 'light',
        ThemeMode.dark   => 'dark',
        ThemeMode.system => 'system',
      };
}
