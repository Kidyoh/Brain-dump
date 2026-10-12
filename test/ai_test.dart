import 'dart:convert';
import 'dart:io';

import 'package:brain_dump/data/ai.dart';
import 'package:brain_dump/data/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final now = DateTime(2026, 10, 12, 13, 0);
  var n = 0;
  String id() => '${n++}';

  const answer = {
    'title': 'Errands and a podcast',
    'items': [
      {
        'kind': 'reminder',
        'text': 'Pick up Liya from practice',
        'details': null,
        'due': '2026-10-13T17:30',
        'all_day': false,
      },
      {
        'kind': 'idea',
        'text': 'Podcast where two people swap phones',
        'details': 'For a day',
        'due': null,
        'all_day': false,
      },
      {'kind': 'task', 'text': '  ', 'details': null, 'due': null},
    ],
  };

  test('parses the sorted JSON and skips empty items', () {
    final r = parseSortJson(answer, newId: id);
    expect(r.title, 'Errands and a podcast');
    expect(r.items, hasLength(2));
    expect(r.items[0].kind, Kind.reminder);
    expect(r.items[0].due, DateTime(2026, 10, 13, 17, 30));
    expect(r.items[1].details, 'For a day');
  });

  test('the prompt carries the local time and weekday', () {
    expect(
      sortPrompt('hello', now),
      contains('Current local time: 2026-10-12T13:00 (Monday)'),
    );
  });

  group('OpenAI', () {
    test('sorts with a strict JSON schema', () async {
      late Map<String, dynamic> sent;
      final client = MockClient((req) async {
        expect(
          req.url.toString(),
          'https://api.openai.com/v1/chat/completions',
        );
        expect(req.headers['Authorization'], 'Bearer sk-test');
        sent = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': jsonEncode(answer), 'refusal': null},
              },
            ],
          }),
          200,
        );
      });
      final r = await OpenAiClient(
        apiKey: 'sk-test',
        client: client,
      ).sort('pick up Liya tomorrow at 5:30', now: now, newId: id);
      expect(r.items, hasLength(2));
      expect(sent['model'], 'gpt-4.1-mini');
      final format = sent['response_format'] as Map;
      expect(format['type'], 'json_schema');
      expect(format['json_schema']['strict'], isTrue);
      expect(format['json_schema']['schema'], sortSchema);
    });

    test('transcribes with Whisper', () async {
      final dir = await Directory.systemTemp.createTemp('bd');
      final audio = File('${dir.path}/a.m4a')..writeAsBytesSync([1, 2, 3]);
      final client = MockClient.streaming((req, body) async {
        expect(req.url.path, '/v1/audio/transcriptions');
        final text = utf8.decode(await body.toBytes(), allowMalformed: true);
        expect(text, contains('whisper-1'));
        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({'text': ' Hello there. '}))),
          200,
        );
      });
      final text = await OpenAiClient(
        apiKey: 'sk-test',
        client: client,
      ).transcribe(audio);
      expect(text, 'Hello there.');
      await dir.delete(recursive: true);
    });

    test('a bad key gets a plain message', () async {
      final client = MockClient(
        (_) async =>
            http.Response('{"error":{"message":"Incorrect key"}}', 401),
      );
      expect(
        OpenAiClient(
          apiKey: 'bad',
          client: client,
        ).sort('x', now: now, newId: id),
        throwsA(
          isA<AiException>().having(
            (e) => e.message,
            'message',
            contains('didn’t accept the API key'),
          ),
        ),
      );
    });

    test('offline gets a plain message', () async {
      final client = MockClient((_) async => throw const SocketException('no'));
      expect(
        OpenAiClient(
          apiKey: 'k',
          client: client,
        ).sort('x', now: now, newId: id),
        throwsA(
          isA<AiException>().having(
            (e) => e.message,
            'message',
            contains('Are you online?'),
          ),
        ),
      );
    });
  });

  group('Claude', () {
    test('sorts through a forced tool call', () async {
      late Map<String, dynamic> sent;
      final client = MockClient((req) async {
        expect(req.url.toString(), 'https://api.anthropic.com/v1/messages');
        expect(req.headers['x-api-key'], 'sk-ant-test');
        expect(req.headers['anthropic-version'], '2023-06-01');
        sent = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'content': [
              {
                'type': 'tool_use',
                'id': 'toolu_1',
                'name': 'save_brain_dump',
                'input': answer,
              },
            ],
            'stop_reason': 'tool_use',
          }),
          200,
        );
      });
      final r = await ClaudeClient(
        apiKey: 'sk-ant-test',
        client: client,
      ).sort('ramble', now: now, newId: id);
      expect(r.items.map((i) => i.kind), [Kind.reminder, Kind.idea]);
      expect(sent['model'], 'claude-haiku-5-5');
      expect(sent['tool_choice'], {'type': 'tool', 'name': 'save_brain_dump'});
      expect((sent['tools'] as List).single['input_schema'], sortSchema);
      expect(sent['system'], sortInstructions);
    });

    test('rate limits get a plain message', () async {
      final client = MockClient((_) async => http.Response('{}', 429));
      expect(
        ClaudeClient(
          apiKey: 'k',
          client: client,
        ).sort('x', now: now, newId: id),
        throwsA(
          isA<AiException>().having(
            (e) => e.message,
            'message',
            contains('rate limiting'),
          ),
        ),
      );
    });
  });
}
