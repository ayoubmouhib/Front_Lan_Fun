import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/constants.dart';
import 'config/routes.dart';
import 'config/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Orientation: portrait on phones, all orientations on tablets/desktops
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Status bar style (light icons for when splash / dark surfaces show)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  // ── Determine initial route and theme before first frame
  final initialRoute = await _resolveInitialRoute();
  final savedTheme   = await _resolveSavedTheme();

  runApp(LinguaConnectApp(
    initialRoute: initialRoute,
    initialThemeMode: savedTheme,
  ));
}

// ─── Route resolution ─────────────────────────────────────────────────────────

Future<String> _resolveInitialRoute() async {
  try {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: AppConstants.keyAccessToken);
    return (token != null && token.isNotEmpty) ? Routes.home : Routes.splash;
  } catch (_) {
    return Routes.splash;
  }
}

// ─── Theme resolution (reads preference before first frame) ──────────────────

Future<ThemeMode> _resolveSavedTheme() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.keyThemeMode) ?? 'system';
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark'  => ThemeMode.dark,
      _       => ThemeMode.system,
    };
  } catch (_) {
    return ThemeMode.system;
  }
}

// ─── App widget ───────────────────────────────────────────────────────────────

class LinguaConnectApp extends StatelessWidget {
  const LinguaConnectApp({
    super.key,
    required this.initialRoute,
    required this.initialThemeMode,
  });

  final String initialRoute;
  final ThemeMode initialThemeMode;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // ── Themes ──────────────────────────────────────────────────────────
      theme:      AppTheme.lightTheme,
      darkTheme:  AppTheme.darkTheme,
      themeMode:  initialThemeMode,

      // ── Navigation ──────────────────────────────────────────────────────
      initialRoute: initialRoute,
      getPages: Routes.pages,
      defaultTransition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),

      // ── Locale ──────────────────────────────────────────────────────────
      locale: Get.deviceLocale,
      fallbackLocale: const Locale('en', 'US'),

      // ── Scroll ──────────────────────────────────────────────────────────
      scrollBehavior: const MaterialScrollBehavior(),
    );
  }
}
