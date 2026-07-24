import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  // The supplied Tavola handoff is a light interface. Keep it as the visual
  // default until a separately reviewed dark handoff is available.
  ThemeMode build() => ThemeMode.light;

  void setMode(ThemeMode mode) => state = mode;
}
