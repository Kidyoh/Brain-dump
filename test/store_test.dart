import 'package:brain_dump/data/models.dart';
import 'package:brain_dump/data/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Dump _dump(String id, List<Item> items) => Dump(
  id: id,
  createdAt: DateTime(2026, 10, 12, 9),
  transcript: 'words for $id',
  items: items,
  seconds: 12,
  heardBy: Engine.whisper,
  sortedBy: Engine.claude,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('saves and loads dumps with every field', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = DumpStore(prefs);
    await store.add(
      _dump('a', [
        Item(
          id: '1',
          kind: Kind.reminder,
          text: 'Pick up Liya',
          details: 'From practice',
          due: DateTime(2026, 10, 13, 17, 30),
          reminderAt: DateTime(2026, 10, 13, 17, 30),
          notificationId: 4,
          inCalendar: true,
        ),
        Item(id: '2', kind: Kind.task, text: 'Buy milk', done: true),
      ]),
    );

    final again = DumpStore(prefs)..load();
    final d = again.dumps.single;
    expect(d.transcript, 'words for a');
    expect(d.seconds, 12);
    expect(d.heardBy, Engine.whisper);
    expect(d.sortedBy, Engine.claude);
    final r = d.items.first;
    expect(r.kind, Kind.reminder);
    expect(r.details, 'From practice');
    expect(r.due, DateTime(2026, 10, 13, 17, 30));
    expect(r.reminderAt, DateTime(2026, 10, 13, 17, 30));
    expect(r.notificationId, 4);
    expect(r.inCalendar, isTrue);
    expect(d.items.last.done, isTrue);
    expect(again.openItems.map((i) => i.id), ['1']);
    expect(again.openCount(Kind.reminder), 1);
    expect(again.openCount(Kind.task), 0);
  });

  test('newest dump first; delete and undo', () async {
    final store = DumpStore(await SharedPreferences.getInstance());
    final milk = Item(id: 'm', kind: Kind.task, text: 'Milk');
    await store.add(_dump('old', [milk]));
    await store.add(_dump('new', [Item(id: 'i', kind: Kind.idea, text: 'Hm')]));
    expect(store.dumps.map((d) => d.id), ['new', 'old']);

    final undo = await store.removeItem(milk);
    expect(store.items.map((i) => i.id), ['i']);
    undo();
    expect(store.items.map((i) => i.id), ['i', 'm']);

    final undoDump = await store.removeDump(store.dumps.first);
    expect(store.dumps.map((d) => d.id), ['old']);
    undoDump();
    expect(store.dumps.map((d) => d.id), ['new', 'old']);
  });

  test('up next is open, timed and soonest first', () async {
    final store = DumpStore(await SharedPreferences.getInstance());
    final now = DateTime(2026, 10, 12, 13);
    await store.add(
      _dump('a', [
        Item(
          id: 'later',
          kind: Kind.task,
          text: 'b',
          due: DateTime(2026, 10, 15),
        ),
        Item(id: 'none', kind: Kind.task, text: 'c'),
        Item(
          id: 'soon',
          kind: Kind.reminder,
          text: 'a',
          due: DateTime(2026, 10, 12, 17),
        ),
        Item(
          id: 'stale',
          kind: Kind.task,
          text: 'd',
          due: DateTime(2026, 10, 10),
        ),
        Item(
          id: 'done',
          kind: Kind.task,
          text: 'e',
          due: DateTime(2026, 10, 13),
          done: true,
        ),
      ]),
    );
    expect(store.upNext(now).map((i) => i.id), ['soon', 'later']);
  });

  test('notification ids keep counting up', () async {
    final store = DumpStore(await SharedPreferences.getInstance());
    expect(store.nextNotificationId(), 1);
    expect(store.nextNotificationId(), 2);
  });
}
