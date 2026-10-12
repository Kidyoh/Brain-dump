// Sample content shared by the design exploration boards.
import 'package:flutter/material.dart';

enum Kind {
  task('Task', 'Tasks', Icons.check_circle_outline_rounded),
  reminder('Reminder', 'Reminders', Icons.alarm_rounded),
  note('Note', 'Notes', Icons.notes_rounded),
  idea('Idea', 'Ideas', Icons.lightbulb_outline_rounded);

  const Kind(this.label, this.plural, this.icon);

  final String label;
  final String plural;
  final IconData icon;
}

class SampleItem {
  const SampleItem(
    this.kind,
    this.text,
    this.action,
    this.actionShort,
    this.actionIcon, {
    this.when,
  });

  final Kind kind;
  final String text;
  final String? when;
  final String action;
  final String actionShort;
  final IconData actionIcon;
}

const sampleTranscript =
    'Okay so, I need to call the dentist and move my appointment, and remind '
    'me to pick up Liya from practice tomorrow at five thirty. Oh and buy oat '
    'milk and batteries. Idea, a podcast where two people swap phones for a '
    'day. The studio wifi password is sunflower22, write that down. And I '
    'have to finish the slides for Thursday’s pitch.';

const sampleItems = [
  SampleItem(
    Kind.task,
    'Call the dentist to move the appointment',
    'Add to calendar',
    'Calendar',
    Icons.event_rounded,
  ),
  SampleItem(
    Kind.reminder,
    'Pick up Liya from practice',
    'Set reminder',
    'Remind me',
    Icons.alarm_add_rounded,
    when: 'Tomorrow, 5:30 PM',
  ),
  SampleItem(
    Kind.task,
    'Buy oat milk and batteries',
    'Add to calendar',
    'Calendar',
    Icons.event_rounded,
  ),
  SampleItem(
    Kind.task,
    'Finish the slides for the pitch',
    'Add to calendar',
    'Calendar',
    Icons.event_rounded,
    when: 'Thursday',
  ),
  SampleItem(
    Kind.idea,
    'A podcast where two people swap phones for a day',
    'Share',
    'Share',
    Icons.ios_share_rounded,
  ),
  SampleItem(
    Kind.note,
    'Studio wifi password: sunflower22',
    'Copy',
    'Copy',
    Icons.content_copy_rounded,
  ),
];
