import 'package:flutter/material.dart';

import 'capture/brain.dart';
import 'capture/capture.dart';
import 'data/settings.dart';
import 'data/store.dart';
import 'theme.dart';
import 'ui/home_screen.dart';
import 'ui/onboarding_screen.dart';
import 'ui/scope.dart';

class BrainDumpApp extends StatefulWidget {
  const BrainDumpApp({
    super.key,
    required this.settings,
    required this.store,
    this.capture,
  });

  final AppSettings settings;
  final DumpStore store;

  /// Swapped for a fake one in tests.
  final CaptureController? capture;

  @override
  State<BrainDumpApp> createState() => _BrainDumpAppState();
}

class _BrainDumpAppState extends State<BrainDumpApp> {
  late final Brain _brain = widget.capture?.brain ?? Brain(widget.settings);
  late final CaptureController _capture =
      widget.capture ??
      CaptureController(
        settings: widget.settings,
        store: widget.store,
        brain: _brain,
      );

  @override
  void dispose() {
    if (widget.capture == null) _capture.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scope(
      settings: widget.settings,
      store: widget.store,
      brain: _brain,
      capture: _capture,
      child: ListenableBuilder(
        listenable: widget.settings,
        builder: (context, _) => MaterialApp(
          title: 'Brain Dump',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: widget.settings.themeMode,
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: widget.settings.onboarded
                ? const HomeScreen(key: ValueKey('home'))
                : const OnboardingScreen(key: ValueKey('onboarding')),
          ),
        ),
      ),
    );
  }
}
