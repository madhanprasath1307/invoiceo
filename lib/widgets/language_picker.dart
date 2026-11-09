import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiceo/l10n/app_localizations.dart';
import 'package:invoiceo/providers/locale_provider.dart';
import 'package:invoiceo/providers/repositories.dart';

// Each language's own name, in its own script — these are endonyms and are
// intentionally NOT translated (a language picker always shows "Français",
// never "French" translated into whatever language happens to be active).
const appLanguageNames = {
  'en': 'English',
  'ne': 'नेपाली',
  'bo': 'བོད་ཡིག',
  'fr': 'Français',
  'es': 'Español',
  'hi': 'हिन्दी',
  'ta': 'தமிழ்',
  'zh': '中文',
};

String appLanguageLabel(Locale locale) =>
    appLanguageNames[locale.languageCode] ?? locale.languageCode;

/// Small "BETA" pill — shown next to every language except English (the
/// only fully-reviewed one); the rest are machine-translated drafts still
/// being reviewed.
class BetaBadge extends StatelessWidget {
  const BetaBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Text(
        AppLocalizations.of(context)!.commonBeta,
        style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
            height: 1),
      ),
    );
  }
}

/// Shared language selector, reused by Settings (compact AppBar popup) and
/// the onboarding wizard (full-width dropdown field). Defaults to English;
/// every other language is tagged Beta.
class LanguagePicker extends ConsumerWidget {
  final bool compact;

  const LanguagePicker({super.key, this.compact = false});

  Future<void> _select(WidgetRef ref, Locale locale) async {
    applyAppLocale(ref, locale);
    await ref
        .read(settingsRepositoryProvider)
        .setAppLocale(localeToKey(locale));
  }

  Widget _itemLabel(Locale locale) {
    final isEnglish = locale.languageCode == 'en';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(appLanguageLabel(locale)),
        if (!isEnglish) ...[
          const SizedBox(width: 6),
          const BetaBadge(),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;

    if (compact) {
      return PopupMenuButton<Locale>(
        icon: const Icon(Icons.language),
        tooltip: appLanguageLabel(selected),
        onSelected: (locale) => _select(ref, locale),
        itemBuilder: (context) => [
          for (final locale in supportedAppLocales)
            PopupMenuItem(value: locale, child: _itemLabel(locale)),
        ],
      );
    }

    return DropdownButtonFormField<Locale>(
      value: selected,
      decoration: InputDecoration(
        labelText: l10n.commonLanguage,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final locale in supportedAppLocales)
          DropdownMenuItem(value: locale, child: _itemLabel(locale)),
      ],
      onChanged: (locale) {
        if (locale != null) _select(ref, locale);
      },
    );
  }
}

/// A labelled language button for the top corner of the sign-in pages: a globe, the name of the current
/// language in its own script, and a small arrow. Opens the same list as [LanguagePicker].
class LanguageMenuButton extends ConsumerWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme.primary;
    return PopupMenuButton<Locale>(
      key: const ValueKey('languageMenuButton'),
      tooltip: l10n.commonLanguage,
      onSelected: (locale) async {
        applyAppLocale(ref, locale);
        await ref.read(settingsRepositoryProvider).setAppLocale(localeToKey(locale));
      },
      itemBuilder: (context) => [
        for (final locale in supportedAppLocales)
          PopupMenuItem(
            value: locale,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(appLanguageLabel(locale)),
                if (locale.languageCode != 'en') ...[const SizedBox(width: 6), const BetaBadge()],
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 20, color: color),
            const SizedBox(width: 6),
            Text(appLanguageLabel(selected),
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            Icon(Icons.arrow_drop_down, color: color),
          ],
        ),
      ),
    );
  }
}
