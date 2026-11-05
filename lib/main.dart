import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
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

/// Keeps the browser demo at phone width, since the app is designed for phones.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  static const double _maxWidth = 480;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = math.min(media.size.width, _maxWidth);
    return ColoredBox(
      color: const Color(0xFF050B0A),
      child: Center(
        child: SizedBox(
          width: width,
          child: MediaQuery(
            data: media.copyWith(size: Size(width, media.size.height)),
            child: ClipRect(child: child),
          ),
        ),
      ),
    );
  }
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
        builder: kIsWeb ? (context, child) => _PhoneFrame(child: child!) : null,
        home: widget.store.onboarded ? const MainShell() : const SplashScreen(),
      ),
    );
  }
}
