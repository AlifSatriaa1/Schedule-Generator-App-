import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:device_preview/device_preview.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app_state.dart';
import 'services/storage_service.dart';
import 'ui/onboarding_screen.dart';
import 'ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Inisialisasi locale Indonesia untuk DateFormat
  await initializeDateFormatting('id', null);

  // Load saved theme
  final savedTheme = await StorageService.getThemeMode();
  themeNotifier.value = [
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ][savedTheme];

  // Check if onboarding has been shown
  final onboardingDone = await StorageService.isOnboardingDone();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      defaultDevice: Devices.ios.iPhone11ProMax,
      devices: [Devices.ios.iPhone11ProMax],
      builder: (context) => MainApp(showOnboarding: !onboardingDone),
    ),
  );
}

class MainApp extends StatelessWidget {
  final bool showOnboarding;
  const MainApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (ctx, mode, child) {
        return MaterialApp(
          // Integrasi Device Preview
          locale: DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,

          debugShowCheckedModeBanner: false,
          title: 'AI Schedule Generator',
          themeMode: mode,

          // ─── Light Theme ──────────────────────────────────
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6C3CE1),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8F7FF),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF0EEFE),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                    color: Color(0xFF6C3CE1), width: 1.5),
              ),
              labelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6C3CE1).withAlpha(178)),
              prefixIconColor: const Color(0xFF6C3CE1),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C3CE1),
                foregroundColor: Colors.white,
                textStyle:
                    GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
            ),
          ),

          // ─── Dark Theme ───────────────────────────────────
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF9B6DFF),
              brightness: Brightness.dark,
            ).copyWith(
              surface: const Color(0xFF0F0E17),
              onSurface: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFF0F0E17),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF9B6DFF), width: 1.5),
              ),
              labelStyle: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white54),
              prefixIconColor: const Color(0xFF9B6DFF),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B6DFF),
                foregroundColor: Colors.white,
                textStyle:
                    GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
            ),
          ),

          home: showOnboarding
              ? const OnboardingScreen()
              : const HomeScreen(),
        );
      },
    );
  }
}