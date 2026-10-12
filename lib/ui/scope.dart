import 'package:flutter/widgets.dart';

import '../capture/brain.dart';
import '../capture/capture.dart';
import '../data/settings.dart';
import '../data/store.dart';

/// Hands the app's state to every screen.
class Scope extends InheritedWidget {
  const Scope({
    super.key,
    required this.settings,
    required this.store,
    required this.brain,
    required this.capture,
    required super.child,
  });

  final AppSettings settings;
  final DumpStore store;
  final Brain brain;
  final CaptureController capture;

  static Scope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Scope>()!;

  @override
  bool updateShouldNotify(Scope oldWidget) =>
      settings != oldWidget.settings ||
      store != oldWidget.store ||
      capture != oldWidget.capture;
}
