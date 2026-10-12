import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../data/ai.dart';
import '../data/local_sorter.dart';
import '../data/models.dart';
import '../data/settings.dart';

/// Turns audio into words and words into sorted items, using whatever
/// Settings says, and falling back to the built-in rules when the AI can't
/// help.
class Brain {
  Brain(this.settings, {this.client});

  final AppSettings settings;

  /// For tests; null uses a fresh client per request.
  final http.Client? client;
  static const _uuid = Uuid();

  String newId() => _uuid.v4();

  OpenAiClient get _openAi => OpenAiClient(
    apiKey: settings.openAiKey,
    transcribeModel: settings.whisperModel,
    sortModel: settings.openAiModel,
    client: client,
  );

  Future<String> transcribe(File audio) => _openAi.transcribe(audio);

  /// Sorts [transcript]. Returns the result, the engine that did it, and a
  /// note when it had to fall back to the built-in rules.
  Future<(SortResult, Engine, String?)> sort(
    String transcript,
    DateTime now,
  ) async {
    final wanted = settings.effectiveSorting;
    if (wanted != Sorting.builtIn) {
      try {
        final result = wanted == Sorting.openai
            ? await _openAi.sort(transcript, now: now, newId: newId)
            : await ClaudeClient(
                apiKey: settings.claudeKey,
                model: settings.claudeModel,
                client: client,
              ).sort(transcript, now: now, newId: newId);
        return (result, settings.sortEngine, null);
      } on AiException catch (e) {
        return (
          sortLocally(transcript, now: now, newId: newId),
          Engine.builtIn,
          '${e.message} Sorted on your phone instead.',
        );
      } catch (_) {
        return (
          sortLocally(transcript, now: now, newId: newId),
          Engine.builtIn,
          'The AI answer didn’t make sense. Sorted on your phone instead.',
        );
      }
    }
    return (
      sortLocally(transcript, now: now, newId: newId),
      Engine.builtIn,
      null,
    );
  }
}
