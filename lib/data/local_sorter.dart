import 'models.dart';
import 'when.dart';

/// Sorts a ramble with plain rules, on the phone, with no network.
///
/// It's the fallback when no AI key is set or the AI can't be reached. It
/// splits the ramble into phrases, then looks for cue words: "remind me" is a
/// reminder, "idea" or "what if" is an idea, "need to" or a verb like "buy"
/// is a task, and anything with a password, number or address is a note.
SortResult sortLocally(
  String transcript, {
  required DateTime now,
  required String Function() newId,
}) {
  final items = <Item>[];
  for (final phrase in splitPhrases(transcript)) {
    final item = _classify(phrase, now, newId);
    if (item != null) items.add(item);
  }
  return SortResult(items: items, title: _title(items));
}

const _actionVerbs =
    'buy|get|grab|call|ring|phone|email|e-mail|text|message|book|pay|finish|'
    'send|pick up|drop off|schedule|make|write|clean|fix|order|cancel|reply|'
    'check|submit|renew|return|print|sign|prepare|plan|wash|water|feed|tidy|'
    'take|bring|start|update|review|read|watch|learn|practice|practise|'
    'look into|sort out|figure out|ask|tell|invite|meet';

final _splitRe = RegExp(
  '(?:[,;]\\s*|\\s+)(?:and also|oh and|also|plus|and then|then|and|oh|but)\\s+'
  '(?=(?:i need|i have|i\'ve got|i gotta|i got to|i should|i must|i want to|'
  'need to|have to|gotta|remind|remember|don\'t forget|dont forget|idea|maybe|'
  'what if|note|$_actionVerbs)\\b)',
  caseSensitive: false,
);

final _fillerRe = RegExp(
  r'^(?:(?:okay|ok|so|um+|uh+|erm|like|well|right|alright|yeah|and|oh|also|'
  r'anyway|basically|actually|hmm+)\b[\s,.]*)+',
  caseSensitive: false,
);

/// Breaks a ramble into phrases that are each about one thing.
List<String> splitPhrases(String transcript) {
  final out = <String>[];
  final sentences = transcript
      .replaceAll(RegExp(r'\s+'), ' ')
      .split(RegExp(r'(?<=[.!?])\s+|\n+'));
  for (final s in sentences) {
    for (final part in s.split(_splitRe)) {
      final p = part
          .replaceFirst(_fillerRe, '')
          .replaceAll(RegExp(r'^[\s,.;:-]+|[\s,;:-]+$'), '')
          .trim();
      if (p.split(' ').length >= 2 || p.length > 6) out.add(p);
    }
  }
  return out;
}

final _reminderRe = RegExp(
  r"\b(remind me|don'?t (let me )?forget|remember to|set a reminder|alarm)\b",
  caseSensitive: false,
);
final _ideaRe = RegExp(
  r'\b(idea|what if|maybe (we|i) (could|should)|it would be (cool|nice|fun|great)|'
  r'imagine|how about|wouldn.?t it be|could be (cool|fun)|concept|app that|'
  r'business|startup|podcast|song|story about)\b',
  caseSensitive: false,
);
final _noteRe = RegExp(
  r"\b(note( that| to self)?|write (that|this|it) down|password|passcode|pin|"
  r"code is|number is|address is|is at|lives at|birthday|fyi|for the record|"
  r"keep in mind)\b|\d{3,}",
  caseSensitive: false,
);
final _taskRe = RegExp(
  "\\b(need to|have to|has to|got to|gotta|should|must|todo|to do|"
  "i want to|don't let me)\\b|^(?:please\\s+)?($_actionVerbs)\\b",
  caseSensitive: false,
);

final _leadRe = RegExp(
  r"^(?:(?:i|we) (?:really |also |still )?(?:need|have|got|want) to|i'?ve got to|"
  r"(?:i|we) (?:gotta|should|must)|need to|have to|gotta|"
  r"remind me (?:to|that|about)?|remember to|don'?t (?:let me )?forget (?:to|about)?|"
  r"set a reminder (?:to|for)?|(?:an |one |another )?idea(?:\s+is)?[:,]?|"
  r"(?:make a )?note(?: that| to self)?[:,]?|fyi|please)\s+",
  caseSensitive: false,
);
final _tailRe = RegExp(
  r'[,.]?\s*(?:write (?:that|this|it) down|note that|remind me|okay|ok|please|'
  r'or something|you know)\s*[.!]?$',
  caseSensitive: false,
);

Item? _classify(String phrase, DateTime now, String Function() newId) {
  Kind kind;
  if (_reminderRe.hasMatch(phrase)) {
    kind = Kind.reminder;
  } else if (_ideaRe.hasMatch(phrase)) {
    kind = Kind.idea;
  } else if (_noteRe.hasMatch(phrase) && !_taskRe.hasMatch(phrase)) {
    kind = Kind.note;
  } else if (_taskRe.hasMatch(phrase)) {
    kind = Kind.task;
  } else {
    kind = Kind.note;
  }

  var text = phrase;
  DateTime? due;
  var allDay = false;
  if (kind == Kind.task || kind == Kind.reminder) {
    final found = findWhen(text, now);
    if (found != null) {
      due = found.when;
      allDay = found.allDay;
      text = found.rest;
    }
  }
  // "Idea, a podcast…" keeps "a podcast…"; strip cue words at both ends.
  for (var i = 0; i < 3; i++) {
    final before = text;
    text = text.replaceFirst(_leadRe, '').replaceFirst(_tailRe, '').trim();
    text = text.replaceFirst(_fillerRe, '').trim();
    if (text == before) break;
  }
  text = text.replaceAll(RegExp(r'^[\s,.;:-]+|[\s,;:-]+$'), '').trim();
  if (text.endsWith('.')) text = text.substring(0, text.length - 1);
  if (text.isEmpty) return null;
  text = text[0].toUpperCase() + text.substring(1);

  return Item(id: newId(), kind: kind, text: text, due: due, allDay: allDay);
}

String? _title(List<Item> items) {
  if (items.isEmpty) return null;
  final words = items.first.text.split(' ');
  return words.length <= 4 ? items.first.text : '${words.take(4).join(' ')}…';
}
