import 'package:flutter/material.dart';

/// What a piece of a ramble turned out to be.
enum Kind {
  task('Task', 'Tasks', Icons.check_circle_outline_rounded),
  reminder('Reminder', 'Reminders', Icons.alarm_rounded),
  note('Note', 'Notes', Icons.notes_rounded),
  idea('Idea', 'Ideas', Icons.lightbulb_outline_rounded);

  const Kind(this.label, this.plural, this.icon);

  final String label;
  final String plural;
  final IconData icon;

  static Kind parse(String? s) => switch (s?.toLowerCase().trim()) {
    'task' || 'todo' || 'to-do' => Kind.task,
    'reminder' => Kind.reminder,
    'idea' => Kind.idea,
    _ => Kind.note,
  };
}

/// One sorted thing: a task, note, reminder or idea.
class Item {
  Item({
    required this.id,
    required this.kind,
    required this.text,
    this.details,
    this.due,
    this.allDay = false,
    this.done = false,
    this.reminderAt,
    this.notificationId,
    this.inCalendar = false,
  });

  final String id;
  Kind kind;
  String text;
  String? details;

  /// When it's due or happening, if the ramble said so.
  DateTime? due;

  /// [due] is a day, not a time.
  bool allDay;
  bool done;

  /// When a reminder notification is scheduled, if one is.
  DateTime? reminderAt;
  int? notificationId;
  bool inCalendar;

  bool get hasReminder =>
      reminderAt != null && reminderAt!.isAfter(DateTime.now());

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'text': text,
    if (details != null) 'details': details,
    if (due != null) 'due': due!.millisecondsSinceEpoch,
    if (allDay) 'allDay': true,
    if (done) 'done': true,
    if (reminderAt != null) 'reminderAt': reminderAt!.millisecondsSinceEpoch,
    if (notificationId != null) 'nid': notificationId,
    if (inCalendar) 'cal': true,
  };

  factory Item.fromJson(Map<String, Object?> j) => Item(
    id: j['id'] as String,
    kind: Kind.parse(j['kind'] as String?),
    text: j['text'] as String? ?? '',
    details: j['details'] as String?,
    due: _date(j['due']),
    allDay: j['allDay'] == true,
    done: j['done'] == true,
    reminderAt: _date(j['reminderAt']),
    notificationId: j['nid'] as int?,
    inCalendar: j['cal'] == true,
  );
}

/// How a dump's words were captured and sorted, for the history screen.
enum Engine {
  phone('your phone'),
  whisper('Whisper'),
  typed('typing'),
  builtIn('built-in rules'),
  openai('OpenAI'),
  claude('Claude');

  const Engine(this.label);

  final String label;

  static Engine parse(String? s) =>
      Engine.values.firstWhere((e) => e.name == s, orElse: () => builtIn);
}

/// One recording and what it was sorted into.
class Dump {
  Dump({
    required this.id,
    required this.createdAt,
    required this.transcript,
    required this.items,
    this.title,
    this.seconds = 0,
    this.heardBy = Engine.phone,
    this.sortedBy = Engine.builtIn,
    this.note,
  });

  final String id;
  final DateTime createdAt;
  String transcript;
  final List<Item> items;
  String? title;
  final int seconds;
  final Engine heardBy;
  final Engine sortedBy;

  /// Shown on the results screen, e.g. why the sort fell back to offline.
  final String? note;

  Map<String, Object?> toJson() => {
    'id': id,
    'at': createdAt.millisecondsSinceEpoch,
    'transcript': transcript,
    'items': [for (final i in items) i.toJson()],
    if (title != null) 'title': title,
    'seconds': seconds,
    'heard': heardBy.name,
    'sorted': sortedBy.name,
  };

  factory Dump.fromJson(Map<String, Object?> j) => Dump(
    id: j['id'] as String,
    createdAt: _date(j['at']) ?? DateTime.now(),
    transcript: j['transcript'] as String? ?? '',
    items: [
      for (final i in (j['items'] as List? ?? const []))
        Item.fromJson((i as Map).cast<String, Object?>()),
    ],
    title: j['title'] as String?,
    seconds: j['seconds'] as int? ?? 0,
    heardBy: Engine.parse(j['heard'] as String?),
    sortedBy: Engine.parse(j['sorted'] as String?),
  );
}

/// What a sorter hands back before it becomes a [Dump].
class SortResult {
  const SortResult({required this.items, this.title});

  final List<Item> items;
  final String? title;
}

DateTime? _date(Object? v) =>
    v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;
