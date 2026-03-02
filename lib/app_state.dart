import 'package:flutter/material.dart';

/// Global theme notifier - accessible from all screens
final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.system);
