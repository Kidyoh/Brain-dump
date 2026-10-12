import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/models.dart';

/// The "Paper" look: warm paper, ink, Instrument Serif headlines and Inter
/// for everything else. Kind colours are hints (dots, rules, tints), never
/// big blocks. See docs/design/README.md.
@immutable
class Paper extends ThemeExtension<Paper> {
  const Paper({
    required this.paper,
    required this.card,
    required this.ink,
    required this.faint,
    required this.rule,
    required this.task,
    required this.reminder,
    required this.note,
    required this.idea,
  });

  final Color paper;
  final Color card;
  final Color ink;
  final Color faint;
  final Color rule;
  final Color task;
  final Color reminder;
  final Color note;
  final Color idea;

  static const light = Paper(
    paper: Color(0xFFF4EFE6),
    card: Color(0xFFFBF8F2),
    ink: Color(0xFF221F1A),
    faint: Color(0xFF857E70),
    rule: Color(0xFFE2DACB),
    task: Color(0xFFE9B949),
    reminder: Color(0xFFE5793F),
    note: Color(0xFF6E97C4),
    idea: Color(0xFF6FB07A),
  );

  static const dark = Paper(
    paper: Color(0xFF191714),
    card: Color(0xFF231F1B),
    ink: Color(0xFFF1EBDF),
    faint: Color(0xFF948C7F),
    rule: Color(0xFF332E28),
    task: Color(0xFFF0C55A),
    reminder: Color(0xFFF08A52),
    note: Color(0xFF8DB2DB),
    idea: Color(0xFF8CCB95),
  );

  static Paper of(BuildContext context) =>
      Theme.of(context).extension<Paper>() ?? light;

  Color kind(Kind k) => switch (k) {
    Kind.task => task,
    Kind.reminder => reminder,
    Kind.note => note,
    Kind.idea => idea,
  };

  /// Instrument Serif, for headlines and the live transcript.
  TextStyle serif(double size, {bool italic = false, Color? color}) =>
      TextStyle(
        fontFamily: 'InstrumentSerif',
        fontSize: size,
        height: 1.1,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        color: color ?? ink,
      );

  /// Inter, for everything else.
  TextStyle sans(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
  }) => TextStyle(
    fontFamily: 'Inter',
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color ?? ink,
  );

  @override
  Paper copyWith() => this;

  @override
  Paper lerp(Paper? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return Paper(
      paper: l(paper, other.paper),
      card: l(card, other.card),
      ink: l(ink, other.ink),
      faint: l(faint, other.faint),
      rule: l(rule, other.rule),
      task: l(task, other.task),
      reminder: l(reminder, other.reminder),
      note: l(note, other.note),
      idea: l(idea, other.idea),
    );
  }
}

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? Paper.dark : Paper.light;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: p.reminder,
        brightness: brightness,
      ).copyWith(
        primary: p.ink,
        onPrimary: p.paper,
        secondary: p.reminder,
        surface: p.paper,
        onSurface: p.ink,
        surfaceContainerLowest: p.card,
        surfaceContainerLow: p.card,
        surfaceContainer: p.card,
        surfaceContainerHigh: p.card,
        surfaceContainerHighest: p.rule,
        outline: p.faint,
        outlineVariant: p.rule,
      );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: p.paper,
    extensions: [p],
  );
  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: p.paper,
      surfaceTintColor: Colors.transparent,
      foregroundColor: p.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: p.serif(28),
      systemOverlayStyle: brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
    dividerTheme: DividerThemeData(color: p.rule, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.ink,
      contentTextStyle: p.sans(14, color: p.paper),
      actionTextColor: p.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.paper,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: p.rule,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.paper,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: p.serif(26),
      contentTextStyle: p.sans(15, color: p.ink, height: 1.4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.card,
      hintStyle: p.sans(15, color: p.faint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.rule),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.rule),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.ink, width: 1.4),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.ink,
      selectionColor: p.reminder.withValues(alpha: 0.3),
      selectionHandleColor: p.ink,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.ink,
        foregroundColor: p.paper,
        textStyle: p.sans(15, weight: FontWeight.w600),
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.ink,
        textStyle: p.sans(15, weight: FontWeight.w600),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.paper : p.faint,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.ink : p.rule,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: BorderSide(color: p.faint, width: 1.5),
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.ink : Colors.transparent,
      ),
      checkColor: WidgetStateProperty.all(p.paper),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: p.paper,
      surfaceTintColor: Colors.transparent,
      headerHeadlineStyle: p.serif(32),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: p.paper,
      dialBackgroundColor: p.card,
      hourMinuteColor: p.card,
    ),
  );
}
