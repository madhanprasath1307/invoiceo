// The Forgot password page tells the person what to do in three numbered steps, shows the Installation ID with a
// copy button, and has a button that opens the support form.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiceo/common/app_config.dart';
import 'package:invoiceo/database/database_helper.dart';
import 'package:invoiceo/l10n/app_localizations.dart';
import 'package:invoiceo/providers/sqlite_repository_overrides.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_company_info_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_installation_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_invoice_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_payment_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_settings_repository.dart';
import 'package:invoiceo/providers/locale_provider.dart';
import 'package:invoiceo/screens/auth/forgot_password_screen.dart';
import 'package:invoiceo/services/backend_services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeLauncher extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  final opened = <String>[];
  @override
  get linkDelegate => null;
  @override
  Future<bool> canLaunch(String url) async => true;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    opened.add(url);
    return true;
  }
}

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
    tmp = Directory.systemTemp.createTempSync('invoiceo_forgot');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), (call) async => tmp.path);
  });
  tearDownAll(() async {
    await DatabaseHelper().close();
    tmp.deleteSync(recursive: true);
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets('three steps, the Installation ID, and a button that opens the support form', (tester) async {
    tester.view.physicalSize = const Size(1000, 1300);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final fake = _FakeLauncher();
    UrlLauncherPlatform.instance = fake;
    await tester.runAsync(() => DatabaseHelper().switchToFile('forgot.db'));

    await tester.pumpWidget(ProviderScope(
      overrides: sqliteRepositoryOverrides,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ForgotPasswordScreen(),
      ),
    ));
    await settle(tester);

    final l10n = AppLocalizations.of(tester.element(find.byType(ForgotPasswordScreen)))!;
    expect(find.text(l10n.resetPasswordIntro), findsOneWidget);
    expect(find.text(l10n.resetPasswordStep1Title), findsOneWidget);
    expect(find.text(l10n.resetPasswordStep2Title), findsOneWidget);
    expect(find.text(l10n.resetPasswordStep3Title), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    // The Installation ID is shown (a UUID) next to a copy button, and the two boxes of step 3 are still there.
    expect(find.byTooltip(l10n.resetPasswordCopyIdTooltip), findsOneWidget);
    expect(find.text(l10n.resetPasswordResponseCodeLabel), findsOneWidget);
    expect(find.text(l10n.resetPasswordVerifyButton), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('resetOpenSupport')));
    await settle(tester);
    expect(fake.opened, [AppConfig.supportForm]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a language button at the top right switches the page to Tamil', (tester) async {
    tester.view.physicalSize = const Size(1000, 1300);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    UrlLauncherPlatform.instance = _FakeLauncher();
    await tester.runAsync(() => DatabaseHelper().switchToFile('forgot_lang.db'));

    await tester.pumpWidget(ProviderScope(
      overrides: sqliteRepositoryOverrides,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          locale: ref.watch(localeProvider),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ForgotPasswordScreen(),
        ),
      ),
    ));
    await settle(tester);

    final en = AppLocalizations.of(tester.element(find.byType(ForgotPasswordScreen)))!;
    expect(find.text(en.resetPasswordTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('languageMenuButton')), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('languageMenuButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('தமிழ்').last);
    await settle(tester);

    final ta = AppLocalizations.of(tester.element(find.byType(ForgotPasswordScreen)))!;
    expect(ta.localeName, 'ta');
    expect(find.text(ta.resetPasswordTitle), findsOneWidget);
    expect(find.text(en.resetPasswordTitle), findsNothing);
  });
}
