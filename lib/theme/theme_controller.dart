import 'package:flutter/material.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(
  (DateTime.now().toUtc().hour >= 6 && DateTime.now().toUtc().hour < 18) 
      ? ThemeMode.light 
      : ThemeMode.dark,
);
