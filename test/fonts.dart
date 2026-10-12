import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the app's real fonts (and Material icons) so widget tests lay text
/// out the way a phone does, instead of with the blocky test font.
Future<void> loadAppFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(f).readAsBytesSync())),
      );
    }
    await loader.load();
  }

  await family('Inter', [
    for (final w in [400, 500, 600, 700]) 'assets/fonts/Inter-w$w.ttf',
  ]);
  await family('InstrumentSerif', [
    'assets/fonts/InstrumentSerif-Regular.ttf',
    'assets/fonts/InstrumentSerif-Italic.ttf',
  ]);
  final flutterRoot = File(Platform.resolvedExecutable)
      .parent
      .parent
      .parent
      .parent
      .parent
      .parent
      .path;
  await family('MaterialIcons', [
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}
