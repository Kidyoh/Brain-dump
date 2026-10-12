import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../actions/reminders.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../data/when.dart';
import 'scope.dart';

/// What one tap on an item does: calendar, reminder, copy, share, done,
/// delete. Shows a snackbar for each so you know it worked.
class ItemActions {
  ItemActions(this.context)
    : store = Scope.of(context).store,
      _messenger = ScaffoldMessenger.maybeOf(context);

  final BuildContext context;
  final DumpStore store;

  // Kept so messages still show after the sheet that asked has closed.
  final ScaffoldMessengerState? _messenger;

  void _say(String message, {SnackBarAction? action}) {
    _messenger?.hideCurrentSnackBar();
    _messenger?.showSnackBar(SnackBar(content: Text(message), action: action));
  }

  /// Something sensible to start a picker on: the item's time if it's still
  /// ahead, else the next round hour (or 9 AM tomorrow late at night).
  static DateTime suggestedTime(Item item, DateTime now) {
    final due = item.due;
    if (due != null && due.isAfter(now)) {
      return item.allDay ? DateTime(due.year, due.month, due.day, 9) : due;
    }
    final next = DateTime(now.year, now.month, now.day, now.hour + 1);
    return next.hour >= 22 || next.hour < 7
        ? DateTime(now.year, now.month, now.day + 1, 9)
        : next;
  }

  Future<DateTime?> pickDateTime(DateTime initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> addToCalendar(Item item) async {
    final start = item.due ?? suggestedTime(item, DateTime.now());
    final event = Event(
      title: item.text,
      description: item.details,
      startDate: item.allDay
          ? DateTime(start.year, start.month, start.day)
          : start,
      endDate: item.allDay
          ? DateTime(start.year, start.month, start.day, 23, 59)
          : start.add(const Duration(minutes: 30)),
      allDay: item.allDay,
    );
    bool opened;
    try {
      opened = await Add2Calendar.addEvent2Cal(event);
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      _say('Couldn’t open a calendar app.');
      return;
    }
    item.inCalendar = true;
    await store.changed();
  }

  /// Sets a reminder at the item's time, or asks for one if it has none.
  Future<void> setReminder(Item item, {bool pick = false}) async {
    final now = DateTime.now();
    var at = item.due;
    if (pick || at == null || item.allDay || !at.isAfter(now)) {
      at = await pickDateTime(suggestedTime(item, now));
      if (at == null) return;
      if (!at.isAfter(DateTime.now())) {
        _say('That time has already passed.');
        return;
      }
    }
    if (item.notificationId != null) {
      await Reminders.instance.cancel(item.notificationId!);
    }
    final id = item.notificationId ?? store.nextNotificationId();
    final result = await Reminders.instance.schedule(
      id: id,
      at: at,
      title: item.text,
      body: item.details,
    );
    if (result == Scheduled.denied) {
      _say('Notifications are off for Brain Dump. Turn them on in Settings.');
      return;
    }
    item.notificationId = id;
    item.reminderAt = at;
    if (item.due == null || item.allDay) {
      item.due = at;
      item.allDay = false;
    }
    await store.changed();
    final label = whenLabel(at);
    if (result == Scheduled.inexact) {
      _say(
        'Reminder set for $label. It may come a few minutes late.',
        action: SnackBarAction(
          label: 'Fix',
          onPressed: Reminders.instance.allowExact,
        ),
      );
    } else {
      _say('Reminder set for $label.');
    }
  }

  Future<void> cancelReminder(Item item) async {
    if (item.notificationId != null) {
      await Reminders.instance.cancel(item.notificationId!);
    }
    final was = item.reminderAt;
    item.reminderAt = null;
    await store.changed();
    _say(
      'Reminder cancelled.',
      action: was == null || !was.isAfter(DateTime.now())
          ? null
          : SnackBarAction(
              label: 'Undo',
              onPressed: () => _restoreReminder(item, was),
            ),
    );
  }

  Future<void> _restoreReminder(Item item, DateTime at) async {
    final id = item.notificationId ?? store.nextNotificationId();
    await Reminders.instance.schedule(
      id: id,
      at: at,
      title: item.text,
      body: item.details,
    );
    item.notificationId = id;
    item.reminderAt = at;
    await store.changed();
  }

  String _plain(Item item) =>
      item.details == null ? item.text : '${item.text}\n${item.details}';

  Future<void> copy(Item item) async {
    await Clipboard.setData(ClipboardData(text: _plain(item)));
    _say('Copied.');
  }

  Future<void> share(Item item) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: _plain(item),
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> toggleDone(Item item) async {
    item.done = !item.done;
    if (item.done && item.hasReminder && item.notificationId != null) {
      await Reminders.instance.cancel(item.notificationId!);
      item.reminderAt = null;
    }
    HapticFeedback.selectionClick();
    await store.changed();
  }

  Future<void> delete(Item item) async {
    if (item.hasReminder && item.notificationId != null) {
      await Reminders.instance.cancel(item.notificationId!);
    }
    final reminder = item.hasReminder ? item.reminderAt : null;
    final undo = await store.removeItem(item);
    _say(
      'Deleted “${item.text}”.',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          undo();
          if (reminder != null) _restoreReminder(item, reminder);
        },
      ),
    );
  }
}
