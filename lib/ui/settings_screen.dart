import 'package:flutter/material.dart';

import '../actions/reminders.dart';
import '../data/settings.dart';
import '../theme.dart';
import 'scope.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final s = Scope.of(context).settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: s,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 48),
          children: [
            const _Heading('Hearing you'),
            _Choice(
              title: 'On this phone',
              subtitle: 'Free. Your words appear while you talk.',
              selected: s.hearing == Hearing.phone,
              onTap: () => s.setHearing(Hearing.phone),
            ),
            _Choice(
              title: 'OpenAI Whisper',
              subtitle: s.openAiKey.isEmpty
                  ? 'Better with accents and noise. Needs an OpenAI key.'
                  : 'Better with accents and noise. Words appear when you let go.',
              selected: s.hearing == Hearing.whisper,
              warning: s.hearing == Hearing.whisper && s.openAiKey.isEmpty
                  ? 'Add an OpenAI key below. Until then, your phone listens.'
                  : null,
              onTap: () => s.setHearing(Hearing.whisper),
            ),
            const _Heading('Sorting'),
            _Choice(
              title: 'Built-in rules',
              subtitle:
                  'Offline and private. Good with clear phrases like '
                  '“remind me to…” and “I need to…”.',
              selected: s.sorting == Sorting.builtIn,
              onTap: () => s.setSorting(Sorting.builtIn),
            ),
            _Choice(
              title: 'Claude',
              subtitle: 'Understands messy rambles. Needs a Claude API key.',
              selected: s.sorting == Sorting.claude,
              warning: s.sorting == Sorting.claude && s.claudeKey.isEmpty
                  ? 'Add a Claude key below. Until then, the built-in rules sort.'
                  : null,
              onTap: () => s.setSorting(Sorting.claude),
            ),
            _Choice(
              title: 'OpenAI',
              subtitle: 'Understands messy rambles. Needs an OpenAI key.',
              selected: s.sorting == Sorting.openai,
              warning: s.sorting == Sorting.openai && s.openAiKey.isEmpty
                  ? 'Add an OpenAI key below. Until then, the built-in rules sort.'
                  : null,
              onTap: () => s.setSorting(Sorting.openai),
            ),
            const _Heading('API keys'),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
              child: Text(
                'Keys stay on this phone in its secure storage. When you use '
                'an AI service, your recording or its words go to that '
                'service and nowhere else.',
                style: p.sans(13.5, color: p.faint, height: 1.45),
              ),
            ),
            _KeyField(
              label: 'OpenAI key',
              hint: 'sk-…',
              value: s.openAiKey,
              onSaved: s.setOpenAiKey,
            ),
            _KeyField(
              label: 'Claude key',
              hint: 'sk-ant-…',
              value: s.claudeKey,
              onSaved: s.setClaudeKey,
            ),
            Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 24),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                iconColor: p.faint,
                collapsedIconColor: p.faint,
                title: Text(
                  'Models',
                  style: p.sans(15, weight: FontWeight.w500),
                ),
                subtitle: Text(
                  '${s.whisperModel} · ${s.claudeModel} · ${s.openAiModel}',
                  style: p.sans(12.5, color: p.faint),
                ),
                children: [
                  _ModelField(
                    label: 'Whisper model',
                    value: s.whisperModel,
                    fallback: AppSettings.defaultWhisperModel,
                    onSaved: (v) => s.setModels(whisper: v),
                  ),
                  _ModelField(
                    label: 'Claude model',
                    value: s.claudeModel,
                    fallback: AppSettings.defaultClaudeModel,
                    onSaved: (v) => s.setModels(claude: v),
                  ),
                  _ModelField(
                    label: 'OpenAI model',
                    value: s.openAiModel,
                    fallback: AppSettings.defaultOpenAiModel,
                    onSaved: (v) => s.setModels(openAi: v),
                  ),
                ],
              ),
            ),
            const _Heading('Look'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: p.ink,
                  selectedForegroundColor: p.paper,
                  foregroundColor: p.ink,
                  side: BorderSide(color: p.rule),
                ),
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {s.themeMode},
                onSelectionChanged: (v) => s.setThemeMode(v.first),
              ),
            ),
            const _Heading('Your data'),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Icon(Icons.delete_outline_rounded, color: p.ink),
              title: Text('Delete all dumps', style: p.sans(15)),
              subtitle: Text(
                'Removes every dump and cancels its reminders.',
                style: p.sans(13, color: p.faint),
              ),
              onTap: () => _confirmClear(context),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Icon(Icons.info_outline_rounded, color: p.ink),
              title: Text('About Brain Dump', style: p.sans(15)),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Brain Dump',
                applicationLegalese:
                    'Type: Instrument Serif and Inter, SIL Open Font License.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final store = Scope.of(context).store;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete everything?'),
        content: const Text(
          'All dumps, tasks, notes, reminders and ideas will be gone. '
          'This can’t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await Reminders.instance.cancelAll();
    await store.clear();
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 26, 24, 6),
    child: Text(text, style: Paper.of(context).serif(24, italic: true)),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.warning,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 22,
                color: selected ? p.ink : p.faint,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: p.sans(15.5, weight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: p.sans(13.5, color: p.faint, height: 1.4),
                  ),
                  if (warning != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      warning!,
                      style: p.sans(
                        13,
                        weight: FontWeight.w600,
                        color: p.reminder,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyField extends StatefulWidget {
  const _KeyField({
    required this.label,
    required this.hint,
    required this.value,
    required this.onSaved,
  });

  final String label;
  final String hint;
  final String value;
  final Future<void> Function(String) onSaved;

  @override
  State<_KeyField> createState() => _KeyFieldState();
}

class _KeyFieldState extends State<_KeyField> {
  late final _c = TextEditingController(text: widget.value);
  bool _show = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
      child: TextField(
        controller: _c,
        obscureText: !_show,
        autocorrect: false,
        enableSuggestions: false,
        style: p.sans(15),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          labelStyle: p.sans(15, color: p.faint),
          suffixIcon: IconButton(
            tooltip: _show ? 'Hide' : 'Show',
            icon: Icon(
              _show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: p.faint,
            ),
            onPressed: () => setState(() => _show = !_show),
          ),
        ),
        onChanged: widget.onSaved,
      ),
    );
  }
}

class _ModelField extends StatefulWidget {
  const _ModelField({
    required this.label,
    required this.value,
    required this.fallback,
    required this.onSaved,
  });

  final String label;
  final String value;
  final String fallback;
  final Future<void> Function(String) onSaved;

  @override
  State<_ModelField> createState() => _ModelFieldState();
}

class _ModelFieldState extends State<_ModelField> {
  late final _c = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
      child: TextField(
        controller: _c,
        autocorrect: false,
        style: p.sans(15),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.fallback,
          labelStyle: p.sans(15, color: p.faint),
        ),
        onChanged: widget.onSaved,
      ),
    );
  }
}
