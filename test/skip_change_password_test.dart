// The "Change Password Required" page (first login with the default password) has a "Skip for now" button: the person
// goes on into the app, the account is still marked "password not changed" (so the page comes back at the next login),
// and the normal Change Password page opened from the user menu has no skip.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiceo/database/database_helper.dart';
import 'package:invoiceo/database/user_service.dart';
import 'package:invoiceo/l10n/app_localizations.dart';
import 'package:invoiceo/models/user.dart';
import 'package:invoiceo/providers/sqlite_repository_overrides.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_company_info_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_installation_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_invoice_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_payment_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_settings_repository.dart';
import 'package:invoiceo/screens/auth/change_password_screen.dart';
import 'package:invoiceo/screens/onboarding/onboarding_screen.dart';
import 'package:invoiceo/services/backend_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    BackendServices.configure(
      settings: SqliteSettingsRepository(),
      companyInfo: SqliteCompanyInfoRepository(),
      invoices: SqliteInvoiceRepository(),
      payments: SqlitePaymentRepository(),
      installation: SqliteInstallationRepository(),
    );
    tmp = Directory.systemTemp.createTempSync('invoiceo_skip_pw');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), (call) async => tmp.path);
  });
  tearDownAll(() async {
    await DatabaseHelper().close();
    tmp.deleteSync(recursive: true);
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 14; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<User> openPage(WidgetTester tester, String db, {required bool forced}) async {
    tester.view.physicalSize = const Size(1200, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    late User user;
    await tester.runAsync(() async {
      await DatabaseHelper().switchToFile(db);
      user = (await UserService.getUserByUsername('admin'))!;
    });
    await tester.pumpWidget(ProviderScope(
      overrides: sqliteRepositoryOverrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChangePasswordScreen(user: user, forced: forced),
      ),
    ));
    await settle(tester);
    return user;
  }

  testWidgets('forced page: Skip for now goes on into the app and the account stays "not changed"', (tester) async {
    await openPage(tester, 'skip_a.db', forced: true);
    final l10n = AppLocalizations.of(tester.element(find.byType(ChangePasswordScreen)))!;
    expect(find.text(l10n.changePasswordSkipButton), findsOneWidget);
    expect(find.text(l10n.changePasswordSkipHint), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('skipChangePassword')));
    await settle(tester);
    expect(find.byType(ChangePasswordScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    final admin = await tester.runAsync(() => UserService.getUserByUsername('admin'));
    expect(admin!.passwordChanged, isFalse, reason: 'skipping changes nothing, so the page returns at the next login');
  });

  testWidgets('the normal Change Password page has no skip', (tester) async {
    await openPage(tester, 'skip_b.db', forced: false);
    expect(find.byKey(const ValueKey('skipChangePassword')), findsNothing);
    // It has a back button instead, which leaves the page.
    expect(find.byKey(const ValueKey('changePasswordBack')), findsOneWidget);
  });

  testWidgets('the Back button on the menu page returns to the page before it', (tester) async {
    tester.view.physicalSize = const Size(1200, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    late User user;
    await tester.runAsync(() async {
      await DatabaseHelper().switchToFile('skip_c.db');
      user = (await UserService.getUserByUsername('admin'))!;
    });
    await tester.pumpWidget(ProviderScope(
      overrides: sqliteRepositoryOverrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => ChangePasswordScreen(user: user))),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await settle(tester);
    expect(find.byType(ChangePasswordScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('changePasswordBack')));
    await settle(tester);
    expect(find.byType(ChangePasswordScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('the forced page has no back button', (tester) async {
    await openPage(tester, 'skip_d.db', forced: true);
    expect(find.byKey(const ValueKey('changePasswordBack')), findsNothing);
  });
}
