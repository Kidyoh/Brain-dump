import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'models.dart';
import 'when.dart';

/// Something went wrong talking to an AI service. [message] is written for
/// people.
class AiException implements Exception {
  AiException(this.message);

  final String message;

  @override
  String toString() => message;
}

const sortInstructions = '''
You sort a voice memo into a clean list. The person held a button and rambled
for up to 30 seconds, so expect filler words, false starts and run-on
sentences.

Each item is one of:
- task: something they need to do ("call the dentist", "buy oat milk").
- reminder: something they asked to be reminded of, or a personal
  appointment at a specific time ("remind me to…", "pick up Liya at 5:30").
- note: a fact worth keeping: passwords, numbers, names, addresses,
  birthdays, things someone said.
- idea: a creative thought, plan or "what if": products, stories, gifts,
  things to try.

Rules:
- Split separate things into separate items, but keep one errand together:
  "buy oat milk and batteries" is one task.
- Write each item as a short, clean line in the speaker's language, at most
  about 12 words. Tasks and reminders start with a verb. Drop filler, keep
  names, numbers and specifics exactly.
- Put anything extra that's worth keeping in details, otherwise null.
- due: when it's due or happening, as local time "YYYY-MM-DDTHH:MM", worked
  out from the current local time you're given. If only a day is said, use
  T09:00 and set all_day to true. If no time or day is said, due is null and
  all_day is false.
- Never invent items or details that weren't said. If nothing useful was
  said, return no items.
- title: a 2 to 5 word summary of the whole memo.''';

/// The JSON shape the AI must answer with.
const sortSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['title', 'items'],
  'properties': {
    'title': {'type': 'string'},
    'items': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['kind', 'text', 'details', 'due', 'all_day'],
        'properties': {
          'kind': {
            'type': 'string',
            'enum': ['task', 'reminder', 'note', 'idea'],
          },
          'text': {'type': 'string'},
          'details': {
            'type': ['string', 'null'],
          },
          'due': {
            'type': ['string', 'null'],
            'description': 'Local time as YYYY-MM-DDTHH:MM, or null.',
          },
          'all_day': {'type': 'boolean'},
        },
      },
    },
  },
};

String sortPrompt(String transcript, DateTime now) =>
    'Current local time: ${isoMinute(now)} (${weekdayName(now)}).\n\n'
    'Voice memo:\n"""\n${transcript.trim()}\n"""';

/// Turns the AI's JSON into items. Tolerates missing or odd fields.
SortResult parseSortJson(
  Map<String, Object?> json, {
  required String Function() newId,
}) {
  final items = <Item>[];
  for (final raw in (json['items'] as List? ?? const [])) {
    if (raw is! Map) continue;
    final text = (raw['text'] as String? ?? '').trim();
    if (text.isEmpty) continue;
    final details = (raw['details'] as String?)?.trim();
    items.add(
      Item(
        id: newId(),
        kind: Kind.parse(raw['kind'] as String?),
        text: text,
        details: details == null || details.isEmpty ? null : details,
        due: parseAiDate(raw['due']),
        allDay: raw['all_day'] == true,
      ),
    );
  }
  final title = (json['title'] as String?)?.trim();
  return SortResult(
    items: items,
    title: title == null || title.isEmpty ? null : title,
  );
}

const _timeout = Duration(seconds: 45);

String _httpError(String service, http.Response r) {
  String? detail;
  try {
    final j = jsonDecode(r.body);
    final e = j is Map ? j['error'] : null;
    detail = e is Map ? e['message'] as String? : e?.toString();
  } catch (_) {}
  return switch (r.statusCode) {
    401 || 403 => '$service didn’t accept the API key. Check it in Settings.',
    429 => '$service is rate limiting or out of credit. Try again shortly.',
    >= 500 => '$service is having trouble right now (${r.statusCode}).',
    _ => '$service said: ${detail ?? 'error ${r.statusCode}'}',
  };
}

Future<http.Response> _send(
  String service,
  Future<http.Response> Function() request,
) async {
  try {
    return await request().timeout(_timeout);
  } on SocketException {
    throw AiException('Can’t reach $service. Are you online?');
  } on HttpException {
    throw AiException('Can’t reach $service. Are you online?');
  } on http.ClientException {
    throw AiException('Can’t reach $service. Are you online?');
  } on Exception catch (e) {
    if (e.toString().contains('TimeoutException')) {
      throw AiException('$service took too long to answer.');
    }
    rethrow;
  }
}

/// OpenAI: Whisper for speech, chat completions with a strict JSON schema
/// for sorting.
class OpenAiClient {
  OpenAiClient({
    required this.apiKey,
    this.transcribeModel = 'whisper-1',
    this.sortModel = 'gpt-4.1-mini',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String transcribeModel;
  final String sortModel;
  final http.Client _client;

  static const _base = 'https://api.openai.com/v1';

  Future<String> transcribe(File audio) async {
    final r = await _send('OpenAI', () async {
      final req =
          http.MultipartRequest(
              'POST',
              Uri.parse('$_base/audio/transcriptions'),
            )
            ..headers['Authorization'] = 'Bearer $apiKey'
            ..fields['model'] = transcribeModel
            ..fields['response_format'] = 'json'
            ..files.add(await http.MultipartFile.fromPath('file', audio.path));
      return http.Response.fromStream(await _client.send(req));
    });
    if (r.statusCode != 200) throw AiException(_httpError('OpenAI', r));
    final text = (jsonDecode(r.body) as Map)['text'] as String? ?? '';
    return text.trim();
  }

  Future<SortResult> sort(
    String transcript, {
    required DateTime now,
    required String Function() newId,
  }) async {
    final r = await _send(
      'OpenAI',
      () => _client.post(
        Uri.parse('$_base/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': sortModel,
          'messages': [
            {'role': 'system', 'content': sortInstructions},
            {'role': 'user', 'content': sortPrompt(transcript, now)},
          ],
          'response_format': {
            'type': 'json_schema',
            'json_schema': {
              'name': 'brain_dump',
              'strict': true,
              'schema': sortSchema,
            },
          },
        }),
      ),
    );
    if (r.statusCode != 200) throw AiException(_httpError('OpenAI', r));
    final body = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, Object?>;
    final message =
        ((body['choices'] as List).first as Map)['message'] as Map? ?? {};
    if (message['refusal'] != null) {
      throw AiException('OpenAI wouldn’t sort this one.');
    }
    final content = message['content'] as String? ?? '{}';
    return parseSortJson(
      (jsonDecode(content) as Map).cast<String, Object?>(),
      newId: newId,
    );
  }
}

/// Claude: sorting through a forced tool call, whose input is the JSON.
class ClaudeClient {
  ClaudeClient({
    required this.apiKey,
    this.model = 'claude-haiku-5-5',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String model;
  final http.Client _client;

  static const _tool = 'save_brain_dump';

  Future<SortResult> sort(
    String transcript, {
    required DateTime now,
    required String Function() newId,
  }) async {
    final r = await _send(
      'Claude',
      () => _client.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'max_tokens': 2048,
          'system': sortInstructions,
          'tools': [
            {
              'name': _tool,
              'description': 'Save the sorted items from the voice memo.',
              'input_schema': sortSchema,
            },
          ],
          'tool_choice': {'type': 'tool', 'name': _tool},
          'messages': [
            {'role': 'user', 'content': sortPrompt(transcript, now)},
          ],
        }),
      ),
    );
    if (r.statusCode != 200) throw AiException(_httpError('Claude', r));
    final body = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, Object?>;
    for (final block in (body['content'] as List? ?? const [])) {
      if (block is Map && block['type'] == 'tool_use') {
        return parseSortJson(
          (block['input'] as Map).cast<String, Object?>(),
          newId: newId,
        );
      }
    }
    throw AiException('Claude didn’t send back a list.');
  }
}
