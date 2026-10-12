// Dates and times: reading them out of spoken English for the built-in
// sorter, reading the AI's ISO strings, and writing them for people.

/// A date found in a phrase, and the phrase with it taken out.
class FoundWhen {
  const FoundWhen(this.when, this.allDay, this.rest);

  final DateTime when;
  final bool allDay;
  final String rest;
}

const _numbers = {
  'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6, //
  'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10, 'eleven': 11, 'twelve': 12,
};
const _minutes = {
  "o'clock": 0, 'oclock': 0, 'fifteen': 15, 'thirty': 30, //
  'forty five': 45, 'forty-five': 45, 'oh five': 5, 'ten': 10, 'twenty': 20,
};
const _weekdays = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

final _hourWord = '(?:\\d{1,2}|${_numbers.keys.join('|')})';
final _minuteWord =
    "(?::(\\d{2})|\\s+(o'clock|oclock|fifteen|thirty|forty[ -]five|oh five|ten|twenty))";

final _timeRe = RegExp(
  '\\b(?:at\\s+|by\\s+|around\\s+)?($_hourWord)$_minuteWord?\\s*(a\\.?m\\.?|p\\.?m\\.?)?(?=\\W|\$)'
  '|\\b(noon|midday|midnight)\\b',
  caseSensitive: false,
);
final _partOfDayRe = RegExp(
  r'\b(?:in the |this )?(morning|afternoon|evening|tonight)\b',
  caseSensitive: false,
);
final _relativeRe = RegExp(
  r'\bin\s+(\d+|an?|one|two|three|five|ten|fifteen|twenty|thirty|forty[ -]five)\s+(minutes?|mins?|hours?|days?|weeks?)\b',
  caseSensitive: false,
);
final _dayRe = RegExp(
  '\\b(today|tomorrow|day after tomorrow|next week|this weekend|'
  '(?:on |this |next )?(?:${_weekdays.join('|')})(?:\'s)?)\\b',
  caseSensitive: false,
);

int? _num(String s) {
  final t = s.toLowerCase().trim();
  if (t == 'a' || t == 'an') return 1;
  return int.tryParse(t) ??
      _numbers[t] ??
      const {'fifteen': 15, 'twenty': 20, 'thirty': 30, 'forty five': 45}[t
          .replaceAll('-', ' ')];
}

/// Finds a date or time in [text], relative to [now].
///
/// Understands things like "tomorrow at five thirty", "on Thursday",
/// "at 7pm", "in 20 minutes", "tonight" and "next week". Returns null when
/// there's nothing time-like in the phrase.
FoundWhen? findWhen(String text, DateTime now) {
  var rest = text;
  DateTime? day;
  int? hour;
  var minute = 0;

  final rel = _relativeRe.firstMatch(rest);
  if (rel != null) {
    final n = _num(rel.group(1)!) ?? 1;
    final unit = rel.group(2)!.toLowerCase();
    final d = unit.startsWith('m')
        ? Duration(minutes: n)
        : unit.startsWith('h')
        ? Duration(hours: n)
        : unit.startsWith('d')
        ? Duration(days: n)
        : Duration(days: 7 * n);
    final when = now.add(d);
    final allDay = unit.startsWith('d') || unit.startsWith('w');
    return FoundWhen(
      allDay ? DateTime(when.year, when.month, when.day, 9) : when,
      allDay,
      _cut(rest, rel),
    );
  }

  final dm = _dayRe.firstMatch(rest);
  if (dm != null) {
    final w = dm.group(1)!.toLowerCase().replaceAll("'s", '');
    final today = DateTime(now.year, now.month, now.day);
    if (w == 'today') {
      day = today;
    } else if (w == 'tomorrow') {
      day = today.add(const Duration(days: 1));
    } else if (w == 'day after tomorrow') {
      day = today.add(const Duration(days: 2));
    } else if (w == 'next week') {
      day = today.add(Duration(days: 8 - today.weekday));
    } else if (w == 'this weekend') {
      day = today.add(Duration(days: (6 - today.weekday) % 7));
    } else {
      final name = w.replaceFirst(RegExp(r'^(on|this|next) '), '');
      final target = _weekdays.indexOf(name) + 1;
      var ahead = (target - today.weekday) % 7;
      if (ahead == 0) ahead = 7;
      day = today.add(Duration(days: ahead));
    }
    // "Thursday's pitch" becomes "the pitch".
    rest = _cut(rest, dm, insert: dm.group(0)!.endsWith("'s") ? 'the' : '');
  }

  final tm = _timeRe.firstMatch(rest);
  // A bare number ("buy 2 lemons") isn't a time: it needs "at", a minute
  // part, or am/pm next to it.
  if (tm != null) {
    final whole = tm.group(0)!.toLowerCase();
    final special = tm.group(5)?.toLowerCase();
    final looksLikeTime =
        special != null ||
        whole.startsWith('at ') ||
        whole.startsWith('by ') ||
        whole.startsWith('around ') ||
        tm.group(2) != null ||
        tm.group(3) != null ||
        tm.group(4) != null;
    if (looksLikeTime) {
      if (special != null) {
        hour = special == 'midnight' ? 0 : 12;
      } else {
        hour = _num(tm.group(1)!);
        if (tm.group(2) != null) {
          minute = int.parse(tm.group(2)!);
        } else if (tm.group(3) != null) {
          minute =
              _minutes[tm.group(3)!.toLowerCase().replaceAll('-', ' ')] ??
              _minutes[tm.group(3)!.toLowerCase()] ??
              0;
        }
        final ampm = tm.group(4)?.toLowerCase().replaceAll('.', '');
        if (hour != null) {
          if (ampm == 'pm' && hour < 12) hour += 12;
          if (ampm == 'am' && hour == 12) hour = 0;
          // "at 5" means 5 pm; nobody plans for 5 am out loud.
          if (ampm == null && hour >= 1 && hour <= 6) hour += 12;
        }
      }
      if (hour != null && hour < 24 && minute < 60) rest = _cut(rest, tm);
    }
  }

  final pm = _partOfDayRe.firstMatch(rest);
  if (pm != null) {
    final p = pm.group(1)!.toLowerCase();
    if (hour == null) {
      hour = switch (p) {
        'morning' => 9,
        'afternoon' => 15,
        'evening' => 19,
        _ => 20,
      };
    } else if (hour < 12 && p != 'morning') {
      hour += 12;
    }
    if (p == 'tonight') day ??= DateTime(now.year, now.month, now.day);
    rest = _cut(rest, pm);
  }

  if (day == null && hour == null) return null;
  if (hour == null) {
    return FoundWhen(DateTime(day!.year, day.month, day.day, 9), true, rest);
  }
  var when = day == null
      ? DateTime(now.year, now.month, now.day, hour, minute)
      : DateTime(day.year, day.month, day.day, hour, minute);
  if (day == null && !when.isAfter(now)) {
    when = when.add(const Duration(days: 1));
  }
  return FoundWhen(when, false, rest);
}

String _cut(String s, Match m, {String insert = ''}) {
  final out = s.substring(0, m.start) + insert + s.substring(m.end);
  return out
      .replaceAllMapped(RegExp(r'\s+([,.!?])'), (m) => m.group(1)!)
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .replaceAll(RegExp(r'\s+(at|on|by|for)\s*$', caseSensitive: false), '')
      .trim();
}

/// Reads the AI's local "YYYY-MM-DDTHH:MM" (or a full ISO string).
DateTime? parseAiDate(Object? v) {
  if (v is! String || v.trim().isEmpty) return null;
  final d = DateTime.tryParse(v.trim());
  if (d == null) return null;
  // Treat everything as wall-clock time where the person is.
  return d.isUtc && !v.endsWith('Z') ? d.toLocal() : d;
}

/// Writes [d] as local "YYYY-MM-DDTHH:MM", for prompts.
String isoMinute(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}T${two(d.hour)}:${two(d.minute)}';
}

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', //
  'August', 'September', 'October', 'November', 'December',
];
const _days = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

String weekdayName(DateTime d) => _days[d.weekday - 1];

/// "Sunday, 12 October"
String longDate(DateTime d) =>
    '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';

/// "5:30 PM"
String clock(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// "Today", "Tomorrow", "Thursday", "3 Nov".
String dayLabel(DateTime d, DateTime now) {
  final a = DateTime(d.year, d.month, d.day);
  final b = DateTime(now.year, now.month, now.day);
  final diff = a.difference(b).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  if (diff > 1 && diff < 7) return _days[d.weekday - 1];
  final s = '${d.day} ${_months[d.month - 1].substring(0, 3)}';
  return d.year == now.year ? s : '$s ${d.year}';
}

/// "Tomorrow, 5:30 PM" or "Thursday".
String whenLabel(DateTime d, {bool allDay = false, DateTime? now}) {
  final day = dayLabel(d, now ?? DateTime.now());
  return allDay ? day : '$day, ${clock(d)}';
}
