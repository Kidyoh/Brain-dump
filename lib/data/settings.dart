import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// How the app hears you.
enum Hearing {
  /// The phone's own speech recognition. Free, words appear as you talk.
  phone,

  /// Record audio and send it to OpenAI Whisper. Needs an OpenAI key.
  whisper,
}

/// How the app sorts what you said.
enum Sorting {
  /// Built-in rules, offline.
  builtIn,
  openai,
  claude,
}

/// Everything you can change in Settings. API keys live in the platform's
/// secure storage (Keystore / Keychain); the rest in shared preferences.
class AppSettings extends ChangeNotifier {
  AppSettings(this._prefs, this._secure);

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  static const defaultWhisperModel = 'whisper-1';
  static const defaultOpenAiModel = 'gpt-4.1-mini';
  static const defaultClaudeModel = 'claude-haiku-5-5';

  bool onboarded = false;
  Hearing hearing = Hearing.phone;
  Sorting sorting = Sorting.builtIn;
  ThemeMode themeMode = ThemeMode.system;
  String openAiKey = '';
  String claudeKey = '';
  String whisperModel = defaultWhisperModel;
  String openAiModel = defaultOpenAiModel;
  String claudeModel = defaultClaudeModel;

  Future<void> load() async {
    onboarded = _prefs.getBool('onboarded') ?? false;
    hearing =
        Hearing.values.asNameMap()[_prefs.getString('hearing')] ??
        Hearing.phone;
    sorting =
        Sorting.values.asNameMap()[_prefs.getString('sorting')] ??
        Sorting.builtIn;
    themeMode =
        ThemeMode.values.asNameMap()[_prefs.getString('theme')] ??
        ThemeMode.system;
    whisperModel = _prefs.getString('whisperModel') ?? defaultWhisperModel;
    openAiModel = _prefs.getString('openAiModel') ?? defaultOpenAiModel;
    claudeModel = _prefs.getString('claudeModel') ?? defaultClaudeModel;
    try {
      openAiKey = await _secure.read(key: 'openai_key') ?? '';
      claudeKey = await _secure.read(key: 'claude_key') ?? '';
    } catch (_) {
      // Unreadable after a restore to a new phone: start without keys.
    }
  }

  /// What will actually be used, given which keys are set.
  Hearing get effectiveHearing =>
      hearing == Hearing.whisper && openAiKey.isNotEmpty
      ? Hearing.whisper
      : Hearing.phone;

  Sorting get effectiveSorting => switch (sorting) {
    Sorting.openai when openAiKey.isNotEmpty => Sorting.openai,
    Sorting.claude when claudeKey.isNotEmpty => Sorting.claude,
    _ => Sorting.builtIn,
  };

  Engine get sortEngine => switch (effectiveSorting) {
    Sorting.openai => Engine.openai,
    Sorting.claude => Engine.claude,
    Sorting.builtIn => Engine.builtIn,
  };

  Future<void> setOnboarded() async {
    onboarded = true;
    notifyListeners();
    await _prefs.setBool('onboarded', true);
  }

  Future<void> setHearing(Hearing h) async {
    hearing = h;
    notifyListeners();
    await _prefs.setString('hearing', h.name);
  }

  Future<void> setSorting(Sorting s) async {
    sorting = s;
    notifyListeners();
    await _prefs.setString('sorting', s.name);
  }

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode = m;
    notifyListeners();
    await _prefs.setString('theme', m.name);
  }

  Future<void> setOpenAiKey(String k) async {
    openAiKey = k.trim();
    notifyListeners();
    await _secure.write(key: 'openai_key', value: openAiKey);
  }

  Future<void> setClaudeKey(String k) async {
    claudeKey = k.trim();
    notifyListeners();
    await _secure.write(key: 'claude_key', value: claudeKey);
  }

  Future<void> setModels({
    String? whisper,
    String? openAi,
    String? claude,
  }) async {
    String pick(String? v, String fallback) =>
        v == null || v.trim().isEmpty ? fallback : v.trim();
    if (whisper != null) {
      whisperModel = pick(whisper, defaultWhisperModel);
      await _prefs.setString('whisperModel', whisperModel);
    }
    if (openAi != null) {
      openAiModel = pick(openAi, defaultOpenAiModel);
      await _prefs.setString('openAiModel', openAiModel);
    }
    if (claude != null) {
      claudeModel = pick(claude, defaultClaudeModel);
      await _prefs.setString('claudeModel', claudeModel);
    }
    notifyListeners();
  }
}
