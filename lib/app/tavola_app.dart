import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/design/tavola_theme.dart';
import '../core/state/theme_mode_controller.dart';
import 'tavola_router.dart';

class TavolaApp extends ConsumerWidget {
  const TavolaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final brightness = MediaQuery.platformBrightnessOf(context);
    final useDarkIcons = switch (themeMode) {
      ThemeMode.light => true,
      ThemeMode.dark => false,
      ThemeMode.system => brightness == Brightness.light,
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: useDarkIcons
            ? TavolaTheme.lightColorScheme.surface
            : TavolaTheme.darkColorScheme.surface,
        statusBarIconBrightness: useDarkIcons
            ? Brightness.dark
            : Brightness.light,
        systemNavigationBarIconBrightness: useDarkIcons
            ? Brightness.dark
            : Brightness.light,
      ),
      child: MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: TavolaTheme.light,
        darkTheme: TavolaTheme.dark,
        themeMode: themeMode,
        routerConfig: ref.watch(tavolaRouterProvider),
      ),
    );
  }
}
