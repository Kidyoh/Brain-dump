import 'package:brain_dump/data/when.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Monday 12 October 2026, 1 PM.
  final now = DateTime(2026, 10, 12, 13, 0);

  FoundWhen find(String s) => findWhen(s, now)!;

  test('tomorrow at five thirty', () {
    final f = find('pick up Liya from practice tomorrow at five thirty');
    expect(f.when, DateTime(2026, 10, 13, 17, 30));
    expect(f.allDay, isFalse);
    expect(f.rest, 'pick up Liya from practice');
  });

  test('a weekday on its own is a whole day', () {
    final f = find('finish the slides for Thursday');
    expect(f.when, DateTime(2026, 10, 15, 9));
    expect(f.allDay, isTrue);
    expect(f.rest, 'finish the slides');
  });

  test("a possessive weekday keeps the sentence readable", () {
    expect(
      find("finish the slides for Thursday's pitch").rest,
      'finish the slides for the pitch',
    );
  });

  test('a weekday that is today means next week', () {
    expect(find('call mum on Monday').when, DateTime(2026, 10, 19, 9));
    expect(find('call mum on Sunday').when, DateTime(2026, 10, 18, 9));
  });

  test('clock times', () {
    expect(find('take the bins out at 7pm').when, DateTime(2026, 10, 12, 19));
    expect(
      find('meeting at 10:15 am tomorrow').when,
      DateTime(2026, 10, 13, 10, 15),
    );
    // "at 5" means the afternoon.
    expect(find('call Sam at 5').when, DateTime(2026, 10, 12, 17));
    // A time that has passed today means tomorrow.
    expect(find('stretch at 9am').when, DateTime(2026, 10, 13, 9));
    expect(
      find('lunch with Ana at noon tomorrow').when,
      DateTime(2026, 10, 13, 12),
    );
  });

  test('parts of the day', () {
    expect(find('water the plants tonight').when, DateTime(2026, 10, 12, 20));
    expect(find('gym tomorrow morning').when, DateTime(2026, 10, 13, 9));
    expect(
      find('call the bank tomorrow afternoon').when,
      DateTime(2026, 10, 13, 15),
    );
  });

  test('relative times', () {
    expect(
      find('check the oven in 20 minutes').when,
      DateTime(2026, 10, 12, 13, 20),
    );
    expect(find('move the car in an hour').when, DateTime(2026, 10, 12, 14));
    final f = find('renew the passport in 3 days');
    expect(f.when, DateTime(2026, 10, 15, 9));
    expect(f.allDay, isTrue);
  });

  test('next week is next Monday', () {
    expect(find('book flights next week').when, DateTime(2026, 10, 19, 9));
  });

  test('plain numbers are not times', () {
    expect(findWhen('buy 2 lemons and 12 eggs', now), isNull);
    expect(findWhen('the wifi password is sunflower22', now), isNull);
  });

  test('labels', () {
    expect(
      whenLabel(DateTime(2026, 10, 13, 17, 30), now: now),
      'Tomorrow, 5:30 PM',
    );
    expect(
      whenLabel(DateTime(2026, 10, 15, 9), allDay: true, now: now),
      'Thursday',
    );
    expect(
      whenLabel(DateTime(2026, 11, 3, 9), allDay: true, now: now),
      '3 Nov',
    );
    expect(clock(DateTime(2026, 1, 1, 0, 5)), '12:05 AM');
    expect(longDate(now), 'Monday, 12 October');
  });

  test('AI dates', () {
    expect(parseAiDate('2026-10-13T17:30'), DateTime(2026, 10, 13, 17, 30));
    expect(parseAiDate(null), isNull);
    expect(parseAiDate(''), isNull);
    expect(parseAiDate('soon'), isNull);
    expect(isoMinute(DateTime(2026, 3, 4, 5, 6)), '2026-03-04T05:06');
  });
}
