import 'dart:convert';

import 'package:brain_dump/capture/capture.dart';
import 'package:brain_dump/data/models.dart';
import 'package:brain_dump/data/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hold, talk, let go: the dump is sorted and saved', () async {
    final f = await Fixture.create();
    await f.capture.start();
    expect(f.capture.phase, Phase.listening);
    f.voice.say('I need to buy oat milk. Remind me to call Sam tomorrow at 5');
    expect(f.capture.words, startsWith('I need to buy oat milk'));
    expect(f.capture.level, greaterThan(0));
    f.clock.advance(const Duration(seconds: 7));
    await f.capture.finish();

    final dump = f.capture.result!;
    expect(f.capture.phase, Phase.idle);
    expect(dump.seconds, 7);
    expect(dump.heardBy, Engine.phone);
    expect(dump.sortedBy, Engine.builtIn);
    expect(dump.items.map((i) => i.kind), [Kind.task, Kind.reminder]);
    expect(dump.items.last.due, DateTime(2026, 10, 13, 17));
    expect(f.store.dumps.single, same(dump));
  });

  test('a quick tap is not a dump', () async {
    final f = await Fixture.create();
    await f.capture.start();
    f.clock.advance(const Duration(milliseconds: 300));
    await f.capture.finish();
    expect(f.capture.phase, Phase.idle);
    expect(f.capture.tooShort, isTrue);
    expect(f.voice.cancelled, isTrue);
    expect(f.store.dumps, isEmpty);
  });

  test('silence explains itself', () async {
    final f = await Fixture.create();
    await f.capture.start();
    f.clock.advance(const Duration(seconds: 4));
    await f.capture.finish();
    expect(f.capture.phase, Phase.failed);
    expect(f.capture.error, contains('Didn’t catch anything'));
    expect(f.capture.canRetry, isFalse);
    f.capture.dismiss();
    expect(f.capture.phase, Phase.idle);
  });

  test('no microphone permission explains itself', () async {
    final f = await Fixture.create();
    f.voice.allowed = false;
    await f.capture.start();
    expect(f.capture.phase, Phase.failed);
    expect(f.capture.error, contains('needs the microphone'));
  });

  test('typed dumps are sorted the same way', () async {
    final f = await Fixture.create();
    await f.capture.submitText('Idea: a lamp that dims when you yawn');
    final dump = f.capture.result!;
    expect(dump.heardBy, Engine.typed);
    expect(dump.items.single.kind, Kind.idea);
  });

  test('sorts with Claude when it has a key', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'content': [
            {
              'type': 'tool_use',
              'name': 'save_brain_dump',
              'input': {
                'title': 'Milk',
                'items': [
                  {
                    'kind': 'task',
                    'text': 'Buy oat milk',
                    'details': null,
                    'due': null,
                    'all_day': false,
                  },
                ],
              },
            },
          ],
        }),
        200,
      ),
    );
    final f = await Fixture.create(
      prefs: {'sorting': 'claude'},
      secure: {'claude_key': 'sk-ant-x'},
      client: client,
    );
    expect(f.settings.effectiveSorting, Sorting.claude);
    await f.capture.submitText('uh I need oat milk');
    final dump = f.capture.result!;
    expect(dump.sortedBy, Engine.claude);
    expect(dump.title, 'Milk');
    expect(dump.items.single.text, 'Buy oat milk');
    expect(dump.note, isNull);
  });

  test('falls back to the built-in rules when the AI fails', () async {
    final client = MockClient((_) async => http.Response('{}', 500));
    final f = await Fixture.create(
      prefs: {'sorting': 'openai'},
      secure: {'openai_key': 'sk-x'},
      client: client,
    );
    await f.capture.submitText('I need to buy oat milk');
    final dump = f.capture.result!;
    expect(dump.sortedBy, Engine.builtIn);
    expect(dump.note, contains('Sorted on your phone instead'));
    expect(dump.items.single.text, 'Buy oat milk');
  });

  test('without a key, the choice quietly uses what works', () async {
    final f = await Fixture.create(
      prefs: {'sorting': 'openai', 'hearing': 'whisper'},
    );
    expect(f.settings.effectiveSorting, Sorting.builtIn);
    expect(f.settings.effectiveHearing, Hearing.phone);
  });

  test('stops by itself at 30 seconds', () async {
    final f = await Fixture.create();
    await f.capture.start();
    f.voice.say('I need to water the plants');
    f.clock.advance(const Duration(seconds: 31));
    // The ticker notices the time on its next tick.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(f.capture.result?.seconds, maxSeconds);
  });
}
