import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'router/app_router.dart' show appRouter;
import 'services/app_settings_controller.dart';
import 'theme/app_theme.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Flutter Material/Cupertino `az` dəstəkləmir — framework üçün `en`/`ru` verilir.
/// Tətbiq mətnləri kodda azərbaycandır; [AppSettingsController.languageCode] `az` saxlanılır.
Locale materialLocaleForAppLanguage(String code) {
  switch (code) {
    case 'ru':
      return const Locale('ru');
    case 'en':
    case 'az':
    default:
      return const Locale('en');
  }
}

class QonsudanXidmetApp extends StatefulWidget {
  const QonsudanXidmetApp({super.key});

  @override
  State<QonsudanXidmetApp> createState() => _QonsudanXidmetAppState();
}

class _QonsudanXidmetAppState extends State<QonsudanXidmetApp> {
  @override
  void initState() {
    super.initState();
    AppSettingsController.instance.addListener(_onSettings);
  }

  void _onSettings() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppSettingsController.instance.removeListener(_onSettings);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppSettingsController.instance;
    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'Qonşudan Xidmət',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: s.themeMode,
      locale: materialLocaleForAppLanguage(s.languageCode),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
      ],
      routerConfig: appRouter,
    );
  }
}
