import 'package:brain_dump/data/local_sorter.dart';
import 'package:brain_dump/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 12, 13, 0);
  var n = 0;
  List<Item> sort(String s) =>
      sortLocally(s, now: now, newId: () => '${n++}').items;

  test('the sample ramble', () {
    final items = sort(
      'Okay so, I need to call the dentist and move my appointment, and '
      'remind me to pick up Liya from practice tomorrow at five thirty. Oh '
      'and buy oat milk and batteries. Idea, a podcast where two people swap '
      'phones for a day. The studio wifi password is sunflower22, write that '
      "down. And I have to finish the slides for Thursday's pitch.",
    );
    expect(
      [for (final i in items) (i.kind, i.text)],
      [
        (Kind.task, 'Call the dentist and move my appointment'),
        (Kind.reminder, 'Pick up Liya from practice'),
        (Kind.task, 'Buy oat milk and batteries'),
        (Kind.idea, 'A podcast where two people swap phones for a day'),
        (Kind.note, 'The studio wifi password is sunflower22'),
        (Kind.task, 'Finish the slides for the pitch'),
      ],
    );
    expect(items[1].due, DateTime(2026, 10, 13, 17, 30));
    expect(items[5].due, DateTime(2026, 10, 15, 9));
    expect(items[5].allDay, isTrue);
  });

  test('splits joined phrases and keeps what-if ideas whole', () {
    final items = sort(
      'um so tomorrow I gotta email Sara about the invoice and also remind me '
      'at 7pm to take the bins out. what if we made a board game about '
      "commuting. Mom's birthday is March 3rd",
    );
    expect(
      [for (final i in items) i.kind],
      [Kind.task, Kind.reminder, Kind.idea, Kind.note],
    );
    expect(items[0].text, 'Email Sara about the invoice');
    expect(items[0].due, DateTime(2026, 10, 13, 9));
    expect(items[1].text, 'Take the bins out');
    expect(items[1].due, DateTime(2026, 10, 12, 19));
    expect(items[2].text, 'What if we made a board game about commuting');
  });

  test('relative reminders', () {
    final items = sort('remind me in 20 minutes to check the oven');
    expect(items.single.kind, Kind.reminder);
    expect(items.single.text, 'Check the oven');
    expect(items.single.due, DateTime(2026, 10, 12, 13, 20));
  });

  test('nothing useful gives nothing', () {
    expect(sort(''), isEmpty);
    expect(sort('um. uh. okay.'), isEmpty);
  });

  test('a title from the first item', () {
    final r = sortLocally(
      'I need to buy a birthday present for Dan this weekend',
      now: now,
      newId: () => 'x',
    );
    expect(r.title, 'Buy a birthday present…');
  });
}
