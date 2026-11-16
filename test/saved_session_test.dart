// "Stay signed in": the app opens straight in as the last user when it was used less than the chosen time ago
// (3 days unless the shop picked 30 minutes to 1 day), and asks for the password again after that, after
// Logout, when the user is gone or their password changed, or when the clock was set back.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:invoiceo/common/common.dart';
import 'package:invoiceo/l10n/app_localizations.dart';
import 'package:invoiceo/models/user.dart';
import 'package:invoiceo/providers/repositories.dart';
import 'package:invoiceo/repositories/auth_repository.dart';
import 'package:invoiceo/repositories/settings_repository.dart';
import 'package:invoiceo/screens/settings/auto_sign_out_card.dart';
import 'package:invoiceo/utils/saved_session.dart';
import 'package:invoiceo/utils/session_manager.dart';

class _Auth implements AuthRepository {
  _Auth(this.users);
  final Map<String, User> users;
  @override
  Future<User?> getUserById(String id) async => users[id];
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Settings implements SettingsRepository {
  final values = <SettingKey, String>{};
  @override
  Future<String?> getSetting(SettingKey key) async => values[key];
  @override
  Future<void> setSetting(SettingKey key, String value) async => values[key] = value;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

User _user({String password = 'hash-1', bool passwordChanged = true, String id = 'u1'}) => User(
    id: id, username: 'admin', password: password, userType: 'admin', salt: 's', passwordChanged: passwordChanged);

void main() {
  late DateTime clock;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    clock = DateTime(2026, 11, 16, 10);
    SavedSession.now = () => clock;
  });
  tearDown(() {
    SavedSession.now = DateTime.now;
    SessionManager.dispose();
  });

  group('the idle time setting', () {
    test('3 days unless a time from 5 minutes to 30 days is saved', () {
      expect(kAutoSignOutDefaultMinutes, 4320);
      expect(parseAutoSignOutMinutes(null), 4320);
      expect(parseAutoSignOutMinutes(''), 4320);
      expect(parseAutoSignOutMinutes('banana'), 4320);
      expect(parseAutoSignOutMinutes('4'), 4320, reason: 'under 5 minutes');
      expect(parseAutoSignOutMinutes('0'), 4320);
      expect(parseAutoSignOutMinutes('-60'), 4320);
      expect(parseAutoSignOutMinutes('43201'), 4320, reason: 'over 30 days');
      expect(parseAutoSignOutMinutes('99999'), 4320);
      expect(parseAutoSignOutMinutes('5'), 5);
      expect(parseAutoSignOutMinutes('43200'), 43200);
      expect(parseAutoSignOutMinutes('3120'), 3120, reason: '2 days 4 hours');
      for (final m in [30, 60, 120, 240, 480, 1440, 4320]) {
        expect(parseAutoSignOutMinutes('$m'), m);
      }
    });
  });

  group('SavedSession', () {
    test('used a minute ago: opens as the same user', () async {
      final u = _user();
      await SavedSession.save(u);
      clock = clock.add(const Duration(minutes: 1));
      final back = await SavedSession.restore(_Auth({'u1': u}), 4320);
      expect(back?.id, 'u1');
    });

    test('2 days 23 hours unused: still in. 3 days unused: Login', () async {
      final u = _user();
      await SavedSession.save(u);
      clock = clock.add(const Duration(days: 2, hours: 23));
      expect(await SavedSession.restore(_Auth({'u1': u}), 4320), isNotNull);
      clock = clock.add(const Duration(hours: 1, minutes: 1));
      expect(await SavedSession.restore(_Auth({'u1': u}), 4320), isNull);
    });

    test('every use pushes the end back: used daily means never asked again', () async {
      final u = _user();
      await SavedSession.save(u);
      for (var day = 0; day < 10; day++) {
        clock = clock.add(const Duration(days: 2));
        expect(await SavedSession.restore(_Auth({'u1': u}), 4320), isNotNull, reason: 'day $day');
        await SavedSession.touch();
      }
    });

    test('a shorter choice applies after a restart too: 30 minutes', () async {
      final u = _user();
      await SavedSession.save(u);
      clock = clock.add(const Duration(minutes: 29));
      expect(await SavedSession.restore(_Auth({'u1': u}), 30), isNotNull);
      clock = clock.add(const Duration(minutes: 2));
      expect(await SavedSession.restore(_Auth({'u1': u}), 30), isNull);
      // the same gap is fine on the 1 day choice
      expect(await SavedSession.restore(_Auth({'u1': u}), 1440), isNotNull);
    });

    test('Logout forgets the sign-in', () async {
      final u = _user();
      await SavedSession.save(u);
      await SavedSession.clear();
      expect(await SavedSession.restore(_Auth({'u1': u}), 4320), isNull);
      await SavedSession.touch(); // using the app after logout must not bring it back
      expect(await SavedSession.restore(_Auth({'u1': u}), 4320), isNull);
    });

    test('a changed password, a deleted user, or a password change still due: Login', () async {
      await SavedSession.save(_user());
      expect(await SavedSession.restore(_Auth({'u1': _user(password: 'hash-2')}), 4320), isNull,
          reason: 'password changed');
      expect(await SavedSession.restore(_Auth({}), 4320), isNull, reason: 'user deleted');
      expect(await SavedSession.restore(_Auth({'u1': _user(passwordChanged: false)}), 4320), isNull,
          reason: 'must still change the password');
      expect(await SavedSession.restore(_Auth({'u1': _user()}), 4320), isNotNull, reason: 'unchanged: in');
    });

    test('a clock set back by more than a few minutes is not trusted', () async {
      final u = _user();
      await SavedSession.save(u);
      clock = clock.subtract(const Duration(days: 1));
      expect(await SavedSession.restore(_Auth({'u1': u}), 4320), isNull);
    });

    test('the stamp never holds the password itself', () {
      expect(SavedSession.stampOf(_user(password: 'plain-secret')), isNot(contains('plain-secret')));
      expect(SavedSession.stampOf(_user(password: 'a')), isNot(SavedSession.stampOf(_user(password: 'b'))));
    });

    test('nothing saved: Login', () async {
      expect(await SavedSession.restore(_Auth({'u1': _user()}), 4320), isNull);
    });
  });

  group('the idle timer', () {
    testWidgets('3 days by default: 2 days idle is fine, past 3 days it signs out', (tester) async {
      var timedOut = 0;
      SessionManager.initialize(() => timedOut++);
      expect(SessionManager.limit, const Duration(days: 3));
      await tester.pump(const Duration(minutes: 31));
      expect(timedOut, 0, reason: 'the old 30 minutes no longer applies');
      await tester.pump(const Duration(days: 2));
      expect(timedOut, 0);
      await tester.pump(const Duration(days: 1));
      expect(timedOut, 1);
    });

    testWidgets('setLimit(30 minutes) signs out after 30 idle minutes, and activity restarts the count',
        (tester) async {
      var timedOut = 0;
      SessionManager.initialize(() => timedOut++);
      SessionManager.setLimit(const Duration(minutes: 30));
      await tester.pump(const Duration(minutes: 20));
      SessionManager.onUserActivity();
      await tester.pump(const Duration(minutes: 20));
      expect(timedOut, 0, reason: '20 minutes since the last use');
      await tester.pump(const Duration(minutes: 11));
      expect(timedOut, 1);
    });
  });

  group('the Settings card', () {
    Future<_Settings> open(WidgetTester tester, [String? saved]) async {
      final repo = _Settings();
      if (saved != null) repo.values[SettingKey.autoSignOutMinutes] = saved;
      await tester.pumpWidget(ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SingleChildScrollView(child: AutoSignOutCard())),
        ),
      ));
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('shows 3 days until another is picked; the choices run from 30 minutes to 3 days',
        (tester) async {
      await open(tester);
      expect(find.text('3 days (recommended)'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('autoSignOutDropdown')));
      await tester.pumpAndSettle();
      for (final t in ['30 minutes', '1 hour', '2 hours', '4 hours', '8 hours', '1 day']) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
    });

    testWidgets('picking 30 minutes saves it and applies it to the running timer', (tester) async {
      var timedOut = 0;
      SessionManager.initialize(() => timedOut++);
      final repo = await open(tester);
      await tester.tap(find.byKey(const ValueKey('autoSignOutDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('30 minutes').last);
      await tester.pumpAndSettle();
      expect(repo.values[SettingKey.autoSignOutMinutes], '30');
      expect(SessionManager.limit, const Duration(minutes: 30));
      await tester.pump(const Duration(minutes: 31));
      expect(timedOut, 1);
    });

    Future<void> pickCustom(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('autoSignOutDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom…').last);
      await tester.pumpAndSettle();
    }

    Future<void> type(WidgetTester tester, String key, String text) async {
      await tester.enterText(find.byKey(ValueKey(key)), text);
      await tester.pump();
    }

    testWidgets('Custom: 2 days 4 hours is saved and applied; the list then shows it', (tester) async {
      SessionManager.initialize(() {});
      final repo = await open(tester);
      expect(find.byKey(const ValueKey('autoSignOutDays')), findsNothing);
      await pickCustom(tester);
      expect(find.byKey(const ValueKey('autoSignOutDays')), findsOneWidget);
      await type(tester, 'autoSignOutDays', '2');
      await type(tester, 'autoSignOutHours', '4');
      await type(tester, 'autoSignOutMinutes', '0');
      expect(find.text('Signs out after 2 days 4 hours without use'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('autoSignOutSave')));
      await tester.pumpAndSettle();
      expect(repo.values[SettingKey.autoSignOutMinutes], '3120');
      expect(SessionManager.limit, const Duration(minutes: 3120));
      expect(find.text('Custom: 2 days 4 hours'), findsOneWidget);
      SessionManager.dispose(); // no timer may outlive the test
    });

    testWidgets('Custom: under 5 minutes, over 30 days or all zeros cannot be saved', (tester) async {
      final repo = await open(tester);
      await pickCustom(tester);
      FilledButton save() => tester.widget<FilledButton>(find.byKey(const ValueKey('autoSignOutSave')));
      await type(tester, 'autoSignOutDays', '0');
      await type(tester, 'autoSignOutHours', '0');
      await type(tester, 'autoSignOutMinutes', '4');
      expect(save().onPressed, isNull);
      expect(find.text('Choose a time from 5 minutes to 30 days.'), findsOneWidget);
      await type(tester, 'autoSignOutMinutes', '5');
      expect(save().onPressed, isNotNull);
      await type(tester, 'autoSignOutMinutes', '0');
      expect(save().onPressed, isNull, reason: 'all zeros');
      await type(tester, 'autoSignOutDays', '31');
      expect(save().onPressed, isNull, reason: '31 days');
      await type(tester, 'autoSignOutDays', '30');
      expect(save().onPressed, isNotNull, reason: 'exactly 30 days');
      await type(tester, 'autoSignOutHours', '1');
      expect(save().onPressed, isNull, reason: '30 days 1 hour');
      expect(repo.values.containsKey(SettingKey.autoSignOutMinutes), isFalse, reason: 'nothing was saved');
    });

    testWidgets('tapping a box selects its number, so typing replaces it', (tester) async {
      await open(tester, '4320');
      await pickCustom(tester);
      for (final key in ['autoSignOutDays', 'autoSignOutHours', 'autoSignOutMinutes']) {
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pump();
        final c = tester.widget<TextField>(find.byKey(ValueKey(key))).controller!;
        expect(c.selection, TextSelection(baseOffset: 0, extentOffset: c.text.length), reason: key);
      }
    });

    testWidgets('empty boxes count as 0; letters cannot be typed', (tester) async {
      await open(tester);
      await pickCustom(tester);
      await type(tester, 'autoSignOutDays', '');
      await type(tester, 'autoSignOutHours', '');
      await type(tester, 'autoSignOutMinutes', '45');
      expect(find.text('Signs out after 45 minutes without use'), findsOneWidget);
      await type(tester, 'autoSignOutMinutes', '4a5');
      expect(tester.widget<TextField>(find.byKey(const ValueKey('autoSignOutMinutes'))).controller!.text, '45');
    });

    testWidgets('a saved custom time is shown with its boxes when the page opens', (tester) async {
      await open(tester, '3120');
      expect(find.text('Custom: 2 days 4 hours'), findsOneWidget);
      expect(tester.widget<TextField>(find.byKey(const ValueKey('autoSignOutDays'))).controller!.text, '2');
      expect(tester.widget<TextField>(find.byKey(const ValueKey('autoSignOutHours'))).controller!.text, '4');
    });

    testWidgets('going back to a ready-made choice hides the boxes and saves it', (tester) async {
      final repo = await open(tester, '3120');
      await tester.tap(find.byKey(const ValueKey('autoSignOutDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 hour').last);
      await tester.pumpAndSettle();
      expect(repo.values[SettingKey.autoSignOutMinutes], '60');
      expect(find.byKey(const ValueKey('autoSignOutDays')), findsNothing);
    });

    testWidgets('a saved choice is shown when the page opens', (tester) async {
      await open(tester, '60');
      expect(find.text('1 hour'), findsOneWidget);
    });
  });
}
