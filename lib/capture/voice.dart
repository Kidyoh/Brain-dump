import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// What a voice input heard: words (from the phone's recogniser) or an
/// audio file (to send to Whisper).
class Heard {
  const Heard({this.text, this.audio});

  final String? text;
  final File? audio;
}

/// A microphone that can be started and stopped by the hold button.
abstract class VoiceInput {
  /// Asks for the microphone. False if it isn't available or was refused.
  Future<bool> prepare();

  /// Starts listening. [onLevel] gets loudness from 0 to 1 many times a
  /// second; [onWords] gets the words so far, if this input can tell.
  Future<void> start({
    required void Function(double level) onLevel,
    required void Function(String words) onWords,
  });

  Future<Heard> stop();

  Future<void> cancel();
}

/// The phone's own speech recognition: free, private on most phones, and
/// the words appear while you talk.
///
/// Android's recogniser ends a session after a pause, so while the button is
/// held a new session starts each time one ends, and the words are joined up.
class PhoneVoice implements VoiceInput {
  final _speech = SpeechToText();
  bool _ready = false;
  bool _active = false;
  String _said = '';
  String _partial = '';
  Completer<void>? _final;
  void Function(double)? _onLevel;
  void Function(String)? _onWords;

  String get _words => [_said, _partial].where((s) => s.isNotEmpty).join(' ');

  @override
  Future<bool> prepare() async {
    if (_ready) return true;
    try {
      _ready = await _speech.initialize(
        onStatus: _status,
        onError: (e) => _restartSoon(),
      );
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  void _status(String status) {
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _final?.complete();
      _final = null;
      _restartSoon();
    }
  }

  void _restartSoon() {
    if (!_active) return;
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_active && !_speech.isListening) _listen();
    });
  }

  Future<void> _listen() async {
    if (_partial.isNotEmpty) {
      _said = _words;
      _partial = '';
    }
    try {
      await _speech.listen(
        onResult: (r) {
          if (r.finalResult) {
            _partial = '';
            _said = [
              _said,
              r.recognizedWords,
            ].where((s) => s.isNotEmpty).join(' ');
          } else {
            _partial = r.recognizedWords;
          }
          _onWords?.call(_words);
        },
        onSoundLevelChange: (db) =>
            _onLevel?.call(((db + 2) / 12).clamp(0.0, 1.0)),
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
          autoPunctuation: true,
          listenFor: const Duration(seconds: 40),
          pauseFor: const Duration(seconds: 30),
        ),
      );
    } catch (_) {
      _restartSoon();
    }
  }

  @override
  Future<void> start({
    required void Function(double level) onLevel,
    required void Function(String words) onWords,
  }) async {
    _said = '';
    _partial = '';
    _onLevel = onLevel;
    _onWords = onWords;
    _active = true;
    await _listen();
  }

  @override
  Future<Heard> stop() async {
    _active = false;
    _final = Completer<void>();
    await _speech.stop();
    // Give the recogniser a moment to send its final words.
    await _final?.future.timeout(
      const Duration(milliseconds: 1500),
      onTimeout: () {},
    );
    final words = _words.trim();
    _onLevel = null;
    _onWords = null;
    return Heard(text: words);
  }

  @override
  Future<void> cancel() async {
    _active = false;
    _onLevel = null;
    _onWords = null;
    await _speech.cancel();
  }
}

/// Records a small AAC file for Whisper.
class RecorderVoice implements VoiceInput {
  final _recorder = AudioRecorder();
  StreamSubscription<Amplitude>? _levels;
  String? _path;

  @override
  Future<bool> prepare() => _recorder.hasPermission();

  @override
  Future<void> start({
    required void Function(double level) onLevel,
    required void Function(String words) onWords,
  }) async {
    final dir = await getTemporaryDirectory();
    _path = '${dir.path}/dump_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 48000,
      ),
      path: _path!,
    );
    _levels = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 80))
        .listen((a) {
          // dBFS: about -50 is a quiet room, 0 is as loud as it gets.
          final db = a.current.isFinite ? a.current : -60.0;
          onLevel(math.pow(((db + 50) / 50).clamp(0.0, 1.0), 1.4).toDouble());
        });
  }

  @override
  Future<Heard> stop() async {
    await _levels?.cancel();
    final path = await _recorder.stop() ?? _path;
    return Heard(audio: path == null ? null : File(path));
  }

  @override
  Future<void> cancel() async {
    await _levels?.cancel();
    await _recorder.cancel();
  }
}
