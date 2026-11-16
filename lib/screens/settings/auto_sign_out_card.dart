import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiceo/common/common.dart';
import 'package:invoiceo/common/constants.dart';
import 'package:invoiceo/l10n/app_localizations.dart';
import 'package:invoiceo/providers/repositories.dart';
import 'package:invoiceo/utils/saved_session.dart';
import 'package:invoiceo/utils/session_manager.dart';

/// A time in words: "2 days 4 hours", "30 minutes".
String describeAutoSignOut(AppLocalizations l10n, int minutes) {
  final d = minutes ~/ 1440, h = (minutes % 1440) ~/ 60, m = minutes % 60;
  return [
    if (d > 0) l10n.autoSignOutDaysCount(d),
    if (h > 0) l10n.autoSignOutHoursCount(h),
    if (m > 0) l10n.autoSignOutMinutesCount(m),
  ].join(' ');
}

/// Settings → Automatic sign-out: how long the app may sit unused before it asks for the password again.
/// 3 days unless the shop picks another: a ready-made choice (30 minutes to 3 days) or "Custom" (days, hours
/// and minutes, from 5 minutes to 30 days). The same time applies while the app is open and after it is closed
/// and opened again.
class AutoSignOutCard extends ConsumerStatefulWidget {
  const AutoSignOutCard({super.key});

  @override
  ConsumerState<AutoSignOutCard> createState() => _AutoSignOutCardState();
}

class _AutoSignOutCardState extends ConsumerState<AutoSignOutCard> {
  // Marks the "Custom" entry in the list.
  static const _custom = -1;

  int _minutes = kAutoSignOutDefaultMinutes;
  bool _customOpen = false;
  final _days = TextEditingController();
  final _hours = TextEditingController();
  final _mins = TextEditingController();

  bool get _isPreset => kAutoSignOutChoices.contains(_minutes);
  bool get _showBoxes => _customOpen || !_isPreset;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _days.dispose();
    _hours.dispose();
    _mins.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final saved = await ref
        .read(settingsRepositoryProvider)
        .getSetting(SettingKey.autoSignOutMinutes);
    if (!mounted) return;
    setState(() => _minutes = parseAutoSignOutMinutes(saved));
    _fillBoxes(_minutes);
  }

  void _fillBoxes(int minutes) {
    _days.text = '${minutes ~/ 1440}';
    _hours.text = '${(minutes % 1440) ~/ 60}';
    _mins.text = '${minutes % 60}';
  }

  /// What the three boxes add up to (an empty box is 0).
  int get _typed =>
      (int.tryParse(_days.text) ?? 0) * 1440 +
      (int.tryParse(_hours.text) ?? 0) * 60 +
      (int.tryParse(_mins.text) ?? 0);

  Future<void> _save(int minutes) async {
    setState(() => _minutes = minutes);
    await ref
        .read(settingsRepositoryProvider)
        .setSetting(SettingKey.autoSignOutMinutes, '$minutes');
    SessionManager.setLimit(Duration(minutes: minutes));
  }

  Future<void> _choose(int value) async {
    if (value == _custom) {
      _fillBoxes(_minutes);
      setState(() => _customOpen = true);
      return;
    }
    setState(() => _customOpen = false);
    _fillBoxes(value);
    await _save(value);
  }

  Future<void> _saveCustom() async {
    final t = _typed;
    if (!isValidAutoSignOutMinutes(t)) return;
    await _save(t);
    if (!mounted) return;
    setState(() => _customOpen = false); // a custom time keeps the boxes shown (it is not a ready-made choice)
  }

  String _label(AppLocalizations l10n, int minutes) => switch (minutes) {
        30 => l10n.autoSignOutOption30Minutes,
        60 => l10n.autoSignOutOption1Hour,
        120 => l10n.autoSignOutOption2Hours,
        240 => l10n.autoSignOutOption4Hours,
        480 => l10n.autoSignOutOption8Hours,
        1440 => l10n.autoSignOutOption1Day,
        _ => l10n.autoSignOutOption3Days,
      };

  Widget _box(String key, TextEditingController c, String label) => SizedBox(
        width: 110,
        child: TextField(
          key: ValueKey(key),
          controller: c,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          decoration: InputDecoration(
              labelText: label, isDense: true, border: const OutlineInputBorder()),
          // A tap selects the whole number, so typing replaces it ("0" or "3" does not turn into "05" or "32").
          onTap: () => c.selection =
              TextSelection(baseOffset: 0, extentOffset: c.text.length),
          onChanged: (_) => setState(() {}),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final typed = _typed;
    final valid = isValidAutoSignOutMinutes(typed);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.autoSignOutTitle,
            style: const TextStyle(
                fontSize: AppFontSize.large, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(l10n.autoSignOutSubtitle,
            style: TextStyle(
                fontSize: AppFontSize.small, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: scheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.autoSignOutLabel,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(l10n.autoSignOutHint,
                              style: TextStyle(
                                  fontSize: AppFontSize.xsmall,
                                  color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<int>(
                      key: const ValueKey('autoSignOutDropdown'),
                      value: _showBoxes ? _custom : _minutes,
                      underline: const SizedBox.shrink(),
                      items: [
                        for (final m in kAutoSignOutChoices)
                          DropdownMenuItem(value: m, child: Text(_label(l10n, m))),
                        DropdownMenuItem(
                          value: _custom,
                          child: Text(_isPreset
                              ? l10n.autoSignOutOptionCustom
                              : l10n.autoSignOutCustomValue(
                                  describeAutoSignOut(l10n, _minutes))),
                        ),
                      ],
                      onChanged: (m) {
                        if (m != null) _choose(m);
                      },
                    ),
                  ],
                ),
                if (_showBoxes) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _box('autoSignOutDays', _days, l10n.autoSignOutCustomDays),
                      _box('autoSignOutHours', _hours, l10n.autoSignOutCustomHours),
                      _box('autoSignOutMinutes', _mins, l10n.autoSignOutCustomMinutes),
                      FilledButton(
                        key: const ValueKey('autoSignOutSave'),
                        onPressed: valid && typed != _minutes ? _saveCustom : null,
                        child: Text(l10n.actionSave),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    valid
                        ? l10n.autoSignOutCustomSummary(describeAutoSignOut(l10n, typed))
                        : l10n.autoSignOutCustomRange,
                    key: const ValueKey('autoSignOutSummary'),
                    style: TextStyle(
                        fontSize: AppFontSize.xsmall,
                        color: valid ? scheme.onSurfaceVariant : scheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
