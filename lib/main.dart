import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/settings.dart';
import 'data/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final settings = AppSettings(prefs, const FlutterSecureStorage());
  await settings.load();
  final store = DumpStore(prefs)..load();
  runApp(BrainDumpApp(settings: settings, store: store));
}
