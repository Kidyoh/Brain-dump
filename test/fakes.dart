import 'package:brain_dump/capture/brain.dart';
import 'package:brain_dump/capture/capture.dart';
import 'package:brain_dump/capture/voice.dart';
import 'package:brain_dump/data/settings.dart';
import 'package:brain_dump/data/store.dart';
import 'package:brain_dump/data/when.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// A microphone that "hears" whatever the test says.
class FakeVoice implements VoiceInput {
  FakeVoice({this.allowed = true});

  bool allowed;
  String heard = '';
  bool started = false;
  bool cancelled = false;
  void Function(String)? onWords;
  void Function(double)? onLevel;

  @override
  Future<bool> prepare() async => allowed;

  @override
  Future<void> start({
    required void Function(double level) onLevel,
    required void Function(String words) onWords,
  }) async {
    started = true;
    this.onWords = onWords;
    this.onLevel = onLevel;
  }

  /// Pretend the phone recognised some words.
  void say(String words, {double level = 0.6}) {
    heard = words;
    onLevel?.call(level);
    onWords?.call(words);
  }

  @override
  Future<Heard> stop() async => Heard(text: heard);

  @override
  Future<void> cancel() async => cancelled = true;
}

class Fixture {
  Fixture._(this.settings, this.store, this.voice, this.capture, this.clock);

  final AppSettings settings;
  final DumpStore store;
  final FakeVoice voice;
  final CaptureController capture;
  final FakeClock clock;

  static Future<Fixture> create({
    Map<String, Object> prefs = const {},
    Map<String, String> secure = const {},
    http.Client? client,
    DateTime? now,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    FlutterSecureStorage.setMockInitialValues(Map.of(secure));
    final p = await SharedPreferences.getInstance();
    final settings = AppSettings(p, const FlutterSecureStorage());
    await settings.load();
    final store = DumpStore(p)..load();
    final voice = FakeVoice();
    final clock = FakeClock(now ?? DateTime(2026, 10, 12, 13));
    // The screens read the same clock, so "Tomorrow" means the same day to
    // the sorter and to the labels, whatever day the tests run.
    appClock = clock.call;
    final capture = CaptureController(
      settings: settings,
      store: store,
      brain: Brain(settings, client: client),
      voiceFor: (_) => voice,
      clock: clock.call,
    );
    return Fixture._(settings, store, voice, capture, clock);
  }
}

class FakeClock {
  FakeClock(this.now);

  DateTime now;

  DateTime call() => now;

  void advance(Duration d) => now = now.add(d);
}
