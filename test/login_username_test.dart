// Sign-in by account name: letter case is ignored, and the Login screen lists
// the accounts in a drop-down and pre-fills the user who signed in last.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiceo/common/setting_key.dart';
import 'package:invoiceo/database/database_helper.dart';
import 'package:invoiceo/database/user_service.dart';
import 'package:invoiceo/l10n/app_localizations.dart';
import 'package:invoiceo/models/user.dart';
import 'package:invoiceo/providers/sqlite_repository_overrides.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_settings_repository.dart';
import 'package:invoiceo/screens/auth/login_screen.dart';
import 'package:invoiceo/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tmp;
  var dbCounter = 0;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    tmp = Directory.systemTemp.createTempSync('invoiceo_login');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => tmp.path);
  });
  tearDownAll(() async {
    await DatabaseHelper().close();
    tmp.deleteSync(recursive: true);
  });

  Future<void> freshDb(WidgetTester tester) => tester.runAsync(
      () => DatabaseHelper().switchToFile('login_${dbCounter++}.db'));

  Future<void> addUser(String id, String name, String password) =>
      UserService.insertUser(
          User(id: id, username: name, password: password, userType: 'user'));

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  group('sign-in ignores letter case', () {
    testWidgets('the typed name matches the account whatever its case',
        (tester) async {
      await freshDb(tester);
      await tester.runAsync(() async {
        await addUser('u1', 'Ravi', 'secret1');

        expect((await UserService.getUser('Ravi', 'secret1'))?.id, 'u1');
        expect((await UserService.getUser('ravi', 'secret1'))?.id, 'u1');
        expect((await UserService.getUser('RAVI', 'secret1'))?.id, 'u1');
        expect(await UserService.getUser('ravi', 'wrong'), isNull);
        expect(await UserService.getUser('nobody', 'secret1'), isNull);
      });
    });

    testWidgets('two accounts that differ only by case need the exact spelling',
        (tester) async {
      await freshDb(tester);
      await tester.runAsync(() async {
        await addUser('b1', 'Bob', 'p1');
        await addUser('b2', 'bob', 'p2');

        expect((await UserService.getUser('Bob', 'p1'))?.id, 'b1');
        expect((await UserService.getUser('bob', 'p2'))?.id, 'b2');
        // "BOB" fits both, so it is refused rather than guessed.
        expect(await UserService.getUser('BOB', 'p1'), isNull);
        expect(await UserService.getUser('BOB', 'p2'), isNull);
      });
    });

    testWidgets('the default admin/admin login still works', (tester) async {
      await freshDb(tester);
      await tester.runAsync(() async {
        expect((await UserService.getUser('admin', 'admin'))?.username, 'admin');
        expect((await UserService.getUser('Admin', 'admin'))?.username, 'admin');
      });
    });
  });

  group('Login screen user drop-down', () {
    Future<void> pumpLogin(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: sqliteRepositoryOverrides,
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LoginScreen(),
        ),
      ));
      await settle(tester);
    }

    /// A shop with its own accounts: the default admin/admin no longer works,
    /// so the first-run hint does not fill the form.
    Future<void> seedShop(WidgetTester tester, {String? lastUser}) async {
      await freshDb(tester);
      await tester.runAsync(() async {
        final admin = await UserService.getUserByUsername('admin');
        await UserService.updatePassword(admin!.id, 'owner-pass-1');
        await addUser('u1', 'Ravi', 'secret1');
        await addUser('u2', 'sita', 'secret2');
        if (lastUser != null) {
          await SqliteSettingsRepository()
              .setSetting(SettingKey.lastLoginUsername, lastUser);
        }
      });
    }

    // The username is a pick-only drop-down; its current choice ('' = none).
    String usernameText(WidgetTester tester) =>
        tester
            .widget<DropdownButtonFormField<String>>(
                find.byKey(const ValueKey('loginUserPicker')))
            .initialValue ??
        '';

    testWidgets('lists every account, sorted, and picking one fills the field',
        (tester) async {
      await seedShop(tester);
      await pumpLogin(tester);

      expect(usernameText(tester), isEmpty);
      await tester.tap(find.byKey(const ValueKey('loginUserPicker')));
      await tester.pumpAndSettle();

      final names = tester
          .widgetList<DropdownMenuItem<String>>(
              find.byType(DropdownMenuItem<String>))
          .map((i) => i.value)
          .toList();
      expect(names, ['admin', 'Ravi', 'sita']);

      await tester.tap(find.text('Ravi').last);
      await tester.pumpAndSettle();
      expect(usernameText(tester), 'Ravi');
    });

    testWidgets('the user who signed in last is pre-filled', (tester) async {
      await seedShop(tester, lastUser: 'sita');
      await pumpLogin(tester);
      expect(usernameText(tester), 'sita');
    });

    testWidgets('a remembered user who no longer exists is not pre-filled',
        (tester) async {
      await seedShop(tester, lastUser: 'deleted-user');
      await pumpLogin(tester);
      expect(usernameText(tester), isEmpty);
    });

    testWidgets('typing is not possible: the username is pick-only',
        (tester) async {
      await seedShop(tester);
      await pumpLogin(tester);
      // Only the password is a text box; the username is a drop-down.
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(const ValueKey('loginUserPicker')), findsOneWidget);
    });

    testWidgets('the manage-companies button shows a company icon and its name, not a gear',
        (tester) async {
      await seedShop(tester);
      await pumpLogin(tester);
      // TextButton.icon builds a private subclass of TextButton, so match by "is a".
      final btn = find.ancestor(
          of: find.text('Manage companies'),
          matching: find.byWidgetPredicate((w) => w is TextButton));
      expect(btn, findsOneWidget);
      expect(
          find.descendant(of: btn, matching: find.byIcon(Icons.corporate_fare)),
          findsOneWidget);
      expect(find.byIcon(Icons.settings), findsNothing);
    });

    testWidgets('a single account is chosen for you', (tester) async {
      await freshDb(tester);
      await tester.runAsync(() async {
        final admin = await UserService.getUserByUsername('admin');
        await UserService.updatePassword(admin!.id, 'owner-pass-1');
      });
      await pumpLogin(tester);
      expect(usernameText(tester), 'admin');
    });

    testWidgets('while admin/admin still works, the first-run hint wins',
        (tester) async {
      await freshDb(tester);
      await tester.runAsync(() async {
        await SqliteSettingsRepository()
            .setSetting(SettingKey.lastLoginUsername, 'sita');
      });
      await pumpLogin(tester);
      expect(usernameText(tester), 'admin');
    });
  });
}
