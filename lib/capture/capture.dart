import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/ai.dart';
import '../data/models.dart';
import '../data/settings.dart';
import '../data/store.dart';
import 'brain.dart';
import 'voice.dart';

enum Phase {
  idle,

  /// The button is held.
  listening,

  /// Turning audio into words, then words into items.
  working,

  /// Something went wrong; [CaptureController.error] says what.
  failed,
}

/// The longest ramble, in seconds.
const maxSeconds = 30;

/// Runs one brain dump: hold to listen, let go to transcribe and sort.
class CaptureController extends ChangeNotifier {
  CaptureController({
    required this.settings,
    required this.store,
    required this.brain,
    VoiceInput Function(Hearing)? voiceFor,
    DateTime Function()? clock,
  }) : _voiceFor = voiceFor ?? _defaultVoice,
       _clock = clock ?? DateTime.now;

  final AppSettings settings;
  final DumpStore store;
  final Brain brain;
  final VoiceInput Function(Hearing) _voiceFor;
  final DateTime Function() _clock;

  static final _phone = PhoneVoice();
  static final _recorder = RecorderVoice();
  static VoiceInput _defaultVoice(Hearing h) =>
      h == Hearing.whisper ? _recorder : _phone;

  Phase phase = Phase.idle;

  /// Seconds held so far, with tenths.
  double elapsed = 0;

  /// Loudness from 0 to 1, smoothed.
  double level = 0;

  /// Recent loudness, oldest first, for the waveform.
  final List<double> levels = [];

  /// Words heard so far (phone recognition only).
  String words = '';

  /// What's happening while [Phase.working].
  String stage = '';
  String? error;

  /// Set when the last hold was too short to count, so the UI can hint.
  bool tooShort = false;

  /// The dump that just finished, for the results screen.
  Dump? result;

  VoiceInput? _voice;
  Hearing _hearing = Hearing.phone;
  Timer? _ticker;
  DateTime? _startedAt;
  bool _stopping = false;

  // Kept so "Try again" can resend after a network error.
  File? _pendingAudio;
  String? _pendingText;
  int _pendingSeconds = 0;

  bool get canRetry => _pendingAudio != null || _pendingText != null;

  bool get busy => phase == Phase.listening || phase == Phase.working;

  Future<void> start() async {
    if (busy) return;
    tooShort = false;
    error = null;
    result = null;
    _hearing = settings.effectiveHearing;
    final voice = _voiceFor(_hearing);
    _voice = voice;
    phase = Phase.listening;
    elapsed = 0;
    level = 0;
    levels.clear();
    words = '';
    notifyListeners();

    final ok = await voice.prepare();
    if (!ok) {
      _fail(
        _hearing == Hearing.phone
            ? 'Brain Dump needs the microphone and speech recognition. '
                  'Allow them in your phone’s settings and try again.'
            : 'Brain Dump needs the microphone. Allow it in your phone’s '
                  'settings and try again.',
      );
      return;
    }
    // Let go before the microphone was ready: nothing to do.
    if (phase != Phase.listening) return;
    HapticFeedback.mediumImpact();
    _startedAt = _clock();
    try {
      await voice.start(
        onLevel: (l) => level = level * 0.4 + l * 0.6,
        onWords: (w) {
          words = w;
          notifyListeners();
        },
      );
    } catch (e) {
      _fail('Couldn’t start listening. Is another app using the microphone?');
      return;
    }
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      elapsed = _clock().difference(_startedAt!).inMilliseconds / 1000;
      levels.add(level);
      if (levels.length > 160) levels.removeAt(0);
      if (elapsed >= maxSeconds) {
        finish();
      } else {
        notifyListeners();
      }
    });
  }

  /// Called when the button is let go (or time runs out).
  Future<void> finish() async {
    if (phase != Phase.listening || _stopping) return;
    final voice = _voice;
    if (_startedAt == null || voice == null) {
      // Let go while still asking for permission.
      phase = Phase.idle;
      tooShort = true;
      notifyListeners();
      return;
    }
    _stopping = true;
    _ticker?.cancel();
    elapsed = _clock().difference(_startedAt!).inMilliseconds / 1000;
    final seconds = elapsed.round().clamp(1, maxSeconds);
    HapticFeedback.lightImpact();

    if (elapsed < 1.0) {
      await voice.cancel();
      _stopping = false;
      phase = Phase.idle;
      tooShort = true;
      _startedAt = null;
      notifyListeners();
      return;
    }

    phase = Phase.working;
    stage = _hearing == Hearing.whisper ? 'Listening back…' : 'Sorting…';
    notifyListeners();
    final Heard heard;
    try {
      heard = await voice.stop();
    } catch (_) {
      _stopping = false;
      _startedAt = null;
      _fail('The recording didn’t save. Try again.');
      return;
    }
    _stopping = false;
    _startedAt = null;
    _pendingSeconds = seconds;
    if (heard.audio != null) {
      _pendingAudio = heard.audio;
      await _transcribeAndSort();
    } else {
      _pendingText = heard.text ?? '';
      await _sort(Engine.phone);
    }
  }

  /// Sorts typed text the same way as a spoken dump.
  Future<void> submitText(String text) async {
    if (busy) return;
    error = null;
    result = null;
    _pendingText = text;
    _pendingSeconds = 0;
    phase = Phase.working;
    stage = 'Sorting…';
    words = text;
    notifyListeners();
    await _sort(Engine.typed);
  }

  Future<void> retry() async {
    if (_pendingAudio != null) {
      phase = Phase.working;
      error = null;
      notifyListeners();
      await _transcribeAndSort();
    } else if (_pendingText != null) {
      phase = Phase.working;
      error = null;
      notifyListeners();
      await _sort(_pendingSeconds == 0 ? Engine.typed : Engine.phone);
    }
  }

  Future<void> _transcribeAndSort() async {
    stage = 'Listening back…';
    notifyListeners();
    try {
      final text = await brain.transcribe(_pendingAudio!);
      _deleteAudio();
      _pendingText = text;
      words = text;
    } on AiException catch (e) {
      _fail(e.message);
      return;
    } catch (_) {
      _fail('Couldn’t turn the recording into words. Try again.');
      return;
    }
    await _sort(Engine.whisper);
  }

  Future<void> _sort(Engine heardBy) async {
    final text = (_pendingText ?? '').trim();
    if (text.isEmpty) {
      _pendingText = null;
      _fail(
        'Didn’t catch anything that time. Hold the button and talk, '
        'a little closer to the phone.',
      );
      return;
    }
    words = text;
    stage = 'Sorting…';
    notifyListeners();
    final now = _clock();
    final (sorted, sortedBy, note) = await brain.sort(text, now);
    final dump = Dump(
      id: brain.newId(),
      createdAt: now,
      transcript: text,
      items: sorted.items,
      title: sorted.title,
      seconds: _pendingSeconds,
      heardBy: heardBy,
      sortedBy: sortedBy,
      note: note,
    );
    await store.add(dump);
    _pendingText = null;
    result = dump;
    phase = Phase.idle;
    notifyListeners();
  }

  void _deleteAudio() {
    try {
      _pendingAudio?.deleteSync();
    } catch (_) {}
    _pendingAudio = null;
  }

  void _fail(String message) {
    _ticker?.cancel();
    error = message;
    phase = Phase.failed;
    notifyListeners();
  }

  /// Back to idle after an error or once the results have been shown.
  void dismiss() {
    if (phase == Phase.failed) {
      _deleteAudio();
      _pendingText = null;
    }
    phase = Phase.idle;
    error = null;
    result = null;
    tooShort = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _voice?.cancel();
    super.dispose();
  }
}
