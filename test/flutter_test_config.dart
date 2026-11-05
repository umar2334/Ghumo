import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the real fonts for every test, so layout and overflow checks measure
/// the text users actually see rather than the placeholder test font.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> load(String family, String path) async {
    final bytes = File(path).readAsBytesSync();
    await (FontLoader(family)..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }

  await load('Inter', 'assets/fonts/Inter.ttf');
  await load(
    'MaterialIcons',
    '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  await testMain();
}
