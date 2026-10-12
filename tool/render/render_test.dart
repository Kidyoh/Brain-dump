// Renders app screens to PNG for the README and design review. Not part of
// the normal test run:
//
//   flutter test tool/render --update-goldens
//   cp tool/render/out/*.png docs/screenshots/
import 'dart:math' as math;

import 'package:brain_dump/app.dart';
import 'package:brain_dump/data/models.dart';
import 'package:brain_dump/ui/hold_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/fakes.dart';
import '../../test/fonts.dart';

const _ramble =
    'Okay so, I need to call the dentist and move my appointment, and remind '
    'me to pick up Liya from practice tomorrow at five thirty. Oh and buy oat '
    'milk and batteries. Idea, a podcast where two people swap phones for a '
    'day. The studio wifi password is sunflower22, write that down. And I '
    "have to finish the slides for Thursday's pitch.";

Future<Fixture> _app(
  WidgetTester tester, {
  bool onboarded = true,
  ThemeMode theme = ThemeMode.light,
  bool withHistory = false,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
  addTearDown(tester.view.reset);
  await tester.runAsync(loadAppFonts);
  final f = await tester.runAsync(
    () => Fixture.create(
      prefs: {'onboarded': onboarded, 'theme': theme.name},
      now: DateTime.now().copyWith(hour: 13, minute: 0),
    ),
  );
  if (withHistory) {
    f!.clock.advance(const Duration(hours: -26));
    await tester.runAsync(
      () => f.capture.submitText(
        'Book the car in for a service. Idea: a lamp that dims when you yawn. '
        "Dad's new number is 0911 23 45 67.",
      ),
    );
    f.capture.dismiss();
    f.clock.advance(const Duration(hours: 26));
    await tester.runAsync(() => f.capture.submitText(_ramble));
    final d = f.capture.result!;
    d.items.firstWhere((i) => i.kind == Kind.reminder).reminderAt = d.items
        .firstWhere((i) => i.kind == Kind.reminder)
        .due;
    f.capture.dismiss();
  }
  await tester.pumpWidget(
    BrainDumpApp(settings: f!.settings, store: f.store, capture: f.capture),
  );
  await tester.pumpAndSettle();
  return f;
}

Future<void> _snap(WidgetTester tester, String name) =>
    expectLater(find.byType(BrainDumpApp), matchesGoldenFile('out/$name.png'));

void main() {
  testWidgets('onboarding', (tester) async {
    await _app(tester, onboarded: false);
    await _snap(tester, 'onboarding_1');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await _snap(tester, 'onboarding_2');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await _snap(tester, 'onboarding_3');
  });

  testWidgets('empty home', (tester) async {
    await _app(tester);
    await _snap(tester, 'home_empty');
  });

  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    final suffix = theme == ThemeMode.dark ? '_dark' : '';

    testWidgets('home $suffix', (tester) async {
      await _app(tester, theme: theme, withHistory: true);
      await _snap(tester, 'home$suffix');
    });

    testWidgets('recording $suffix', (tester) async {
      final f = await _app(tester, theme: theme);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(HoldButton)),
      );
      final words = _ramble.split(' ');
      final rnd = math.Random(3);
      for (var i = 0; i < 140; i++) {
        f.clock.advance(const Duration(milliseconds: 100));
        final said = (i * words.length / 260).floor();
        f.voice.say(
          words.take(said).join(' '),
          level: 0.15 + rnd.nextDouble() * 0.85,
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      await _snap(tester, 'recording$suffix');
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('results $suffix', (tester) async {
      final f = await _app(tester, theme: theme);
      f.capture.addListener(() {});
      await tester.runAsync(() => f.capture.submitText(_ramble));
      await tester.pumpAndSettle();
      await _snap(tester, 'results$suffix');
    });
  }

  testWidgets('item sheet', (tester) async {
    await _app(tester, withHistory: true);
    await tester.tap(find.text('Pick up Liya from practice').first);
    await tester.pumpAndSettle();
    await _snap(tester, 'item_sheet');
  });

  testWidgets('history', (tester) async {
    await _app(tester, withHistory: true);
    await tester.tap(find.byTooltip('Past dumps'));
    await tester.pumpAndSettle();
    await _snap(tester, 'history');
  });

  testWidgets('settings', (tester) async {
    await _app(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await _snap(tester, 'settings');
  });
}
