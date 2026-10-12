import 'package:brain_dump/app.dart';
import 'package:brain_dump/capture/capture.dart';
import 'package:brain_dump/ui/hold_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'fonts.dart';

Future<Fixture> _pumpApp(
  WidgetTester tester, {
  bool onboarded = true,
  Size size = const Size(390, 844),
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.runAsync(loadAppFonts);
  final f = await tester.runAsync(
    () => Fixture.create(prefs: {'onboarded': onboarded, 'theme': theme.name}),
  );
  await tester.pumpWidget(
    BrainDumpApp(settings: f!.settings, store: f.store, capture: f.capture),
  );
  await tester.pumpAndSettle();
  return f;
}

void main() {
  testWidgets('onboarding leads to the empty home screen', (tester) async {
    await _pumpApp(tester, onboarded: false);
    expect(find.text('Say it all.'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('It gets sorted.'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('One tap to act.'), findsOneWidget);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text("What's on\nyour mind?"), findsOneWidget);
    expect(find.text('Hold and ramble'), findsOneWidget);
    expect(find.textContaining('Try something like'), findsOneWidget);
  });

  testWidgets('hold to talk, let go, see it sorted, act on it', (tester) async {
    final f = await _pumpApp(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(HoldButton)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(f.capture.phase, Phase.listening);
    f.voice.say(
      'Okay so I need to call the dentist, and remind me to pick up Liya '
      'tomorrow at five thirty. The studio wifi password is sunflower22.',
    );
    f.clock.advance(const Duration(seconds: 12));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Listening'), findsOneWidget);
    expect(find.text('0:12 / 0:30'), findsOneWidget);
    expect(find.text('Let go when you’re done'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('12 seconds, sorted'), findsOneWidget);
    expect(find.text('Three things.'), findsOneWidget);
    expect(find.text('Call the dentist'), findsOneWidget);
    expect(find.text('Pick up Liya'), findsOneWidget);
    expect(find.text('Tomorrow, 5:30 PM'), findsOneWidget);
    expect(find.text('Add to calendar'), findsWidgets);
    expect(find.text('Set reminder'), findsOneWidget);

    // Copy the note.
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(copied, 'The studio wifi password is sunflower22');
    expect(find.text('Copied.'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    // Back home: the items are listed by kind, the reminder up next.
    expect(find.text('Up next'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(f.capture.phase, Phase.idle);
  });

  testWidgets('screen readers tap to start and tap again to stop', (
    tester,
  ) async {
    final f = await _pumpApp(tester);
    Semantics button() => tester.widget<Semantics>(
      find
          .descendant(
            of: find.byType(HoldButton),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(button().properties.label, 'Record a brain dump');
    button().properties.onTap!();
    await tester.pump(const Duration(milliseconds: 100));
    expect(f.capture.phase, Phase.listening);
    expect(button().properties.label, 'Recording. Tap to stop and sort.');
    f.voice.say('I need to buy stamps');
    f.clock.advance(const Duration(seconds: 3));
    button().properties.onTap!();
    await tester.pumpAndSettle();
    expect(find.text('One thing.'), findsOneWidget);
  });

  testWidgets('a quick tap hints to keep holding', (tester) async {
    final f = await _pumpApp(tester);
    await tester.tap(find.byType(HoldButton));
    await tester.pumpAndSettle();
    expect(f.capture.tooShort, isTrue);
    expect(find.text('Keep holding while you talk'), findsOneWidget);
  });

  testWidgets('type it, edit an item, tick it off, find it in history', (
    tester,
  ) async {
    final f = await _pumpApp(tester, size: const Size(360, 690));
    await tester.tap(find.text('or type it'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'I need to renew my passport. Idea: a lamp that dims when you yawn',
    );
    await tester.pump();
    await tester.tap(find.text('Sort it'));
    await tester.pumpAndSettle();
    expect(find.text('Two things.'), findsOneWidget);

    // Open the task and change it into a note.
    await tester.tap(find.text('Renew my passport'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Note'));
    await tester.pumpAndSettle();
    expect(f.store.items.first.kind.name, 'note');
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Turn it back into a task from home and tick it off.
    await tester.tap(find.text('Renew my passport'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Task'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(f.store.items.first.done, isTrue);
    expect(find.text('1 done'), findsOneWidget);

    await tester.tap(find.byTooltip('Past dumps'));
    await tester.pumpAndSettle();
    expect(find.text('Renew my passport'), findsOneWidget);
    expect(find.textContaining('I need to renew my passport'), findsOneWidget);
  });

  testWidgets('settings show the choices and warn about missing keys', (
    tester,
  ) async {
    final f = await _pumpApp(tester, theme: ThemeMode.dark);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Claude'));
    await tester.pumpAndSettle();
    expect(
      find.text('Add a Claude key below. Until then, the built-in rules sort.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Claude key'),
      ' sk-ant-123 ',
    );
    await tester.pumpAndSettle();
    expect(f.settings.claudeKey, 'sk-ant-123');
    expect(find.textContaining('Add a Claude key'), findsNothing);
  });
}
