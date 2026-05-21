import 'package:flutter/material.dart';
import 'app.dart';
import 'services/auth_service.dart';
import 'theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    AuthService.instance.init(),
    ThemeProvider.instance.init(),
  ]);
  runApp(const App());
}
