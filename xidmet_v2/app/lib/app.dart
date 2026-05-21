import 'package:flutter/material.dart';
import 'router/router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeProvider.instance,
      builder: (context, mode, _) => MaterialApp.router(
        title: 'Qonşudan Xidmət',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(dark: false),
        darkTheme: buildTheme(dark: true),
        themeMode: mode,
        routerConfig: appRouter,
      ),
    );
  }
}
