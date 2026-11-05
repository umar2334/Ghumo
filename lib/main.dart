import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'state/app_scope.dart';
import 'state/app_store.dart';
import 'state/storage.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  final store = await AppStore.load(SharedPrefsStorage());
  runApp(GhumoApp(store: store, services: AppServices()));
}

class GhumoApp extends StatefulWidget {
  const GhumoApp({super.key, required this.store, required this.services});

  final AppStore store;
  final AppServices services;

  @override
  State<GhumoApp> createState() => _GhumoAppState();
}

class _GhumoAppState extends State<GhumoApp> {
  final _navigation = AppNavigation();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: widget.store,
      services: widget.services,
      navigation: _navigation,
      child: MaterialApp(
        title: 'Ghumo',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: widget.store.onboarded ? const MainShell() : const SplashScreen(),
      ),
    );
  }
}
