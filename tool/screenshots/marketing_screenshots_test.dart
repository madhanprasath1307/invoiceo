// Makes the website's app screenshots from the real Modern screens, with a
// sample shop (never your own data; phone numbers start with 1, which no
// Indian mobile does, so they cannot reach a real person). Run:
//   flutter test tool/screenshots/marketing_screenshots_test.dart
// Output: ../invoiceo-website/assets/images/screens/*.png (override with
// --dart-define=SCREENS_OUT=/some/folder). For the Tamil page add
// --dart-define=SHOT_LOCALE=ta, which writes *-ta.png with the app in Tamil
// (SHOT_LOCALE=hi: *-hi.png, the app in Hindi).
// --dart-define=SHOT_SETTINGS=true also writes settings-01.png ... (every
// Settings section, 1366 px wide and tall) for checking labels; those are not
// for the website, so give them their own SCREENS_OUT.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiceo/common/common.dart';
import 'package:invoiceo/database/company_info_service.dart';
import 'package:invoiceo/database/company_registry_service.dart';
import 'package:invoiceo/database/customer_service.dart';
import 'package:invoiceo/database/database_helper.dart';
import 'package:invoiceo/database/invoice_draft_service.dart';
import 'package:invoiceo/database/invoice_service.dart';
import 'package:invoiceo/database/payment_service.dart';
import 'package:invoiceo/database/product_service.dart';
import 'package:invoiceo/l10n/app_localizations.dart';
import 'package:invoiceo/layouts/ui_layout.dart';
import 'package:invoiceo/models/company_info.dart';
import 'package:invoiceo/models/customer.dart';
import 'package:invoiceo/models/invoice.dart';
import 'package:invoiceo/models/invoice_draft.dart';
import 'package:invoiceo/models/invoice_item.dart';
import 'package:invoiceo/models/product.dart';
import 'package:invoiceo/models/user.dart';
import 'package:invoiceo/providers/sqlite_repository_overrides.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_company_info_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_installation_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_invoice_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_payment_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_settings_repository.dart';
import 'package:invoiceo/screens/dashboard_screen.dart';
import 'package:invoiceo/services/backend_services.dart';
import 'package:invoiceo/theme/app_theme.dart';

const _outDefault = '../invoiceo-website/assets/images/screens';
const _out = String.fromEnvironment('SCREENS_OUT', defaultValue: _outDefault);
const _locale = String.fromEnvironment('SHOT_LOCALE');
const _suffix = _locale == '' ? '' : '-$_locale';
const _settings = bool.fromEnvironment('SHOT_SETTINGS');

Future<void> _loadFont(String family, List<String> files,
    {String? dir}) async {
  dir ??= '${Platform.environment['HOME']}/development/flutter/bin/cache/artifacts/material_fonts';
  final loader = FontLoader(family);
  for (final f in files) {
    final bytes = File('$dir/$f').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    BackendServices.configure(
      settings: SqliteSettingsRepository(),
      companyInfo: SqliteCompanyInfoRepository(),
      invoices: SqliteInvoiceRepository(),
      payments: SqlitePaymentRepository(),
      installation: SqliteInstallationRepository(),
    );
    tmp = Directory.systemTemp.createTempSync('invoiceo_screens');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => tmp.path);
    await _loadFont('Roboto', [
      'Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf', 'Roboto-Black.ttf',
    ]);
    await _loadFont('MaterialIcons', ['MaterialIcons-Regular.otf']);
    await _loadFont('NotoSansTamil', ['NotoSansTamil-Regular.ttf', 'NotoSansTamil-Bold.ttf'],
        dir: 'assets/fonts');
    await _loadFont('NotoSansDevanagari',
        ['NotoSansDevanagari-Regular.ttf', 'NotoSansDevanagari-Bold.ttf'],
        dir: 'assets/fonts');
    // The greeting's wave; a test has no system fonts to fall back on.
    final emoji = File('/System/Library/Fonts/Apple Color Emoji.ttc');
    if (emoji.existsSync()) {
      final loader = FontLoader('ShotEmoji')
        ..addFont(Future.value(ByteData.view(emoji.readAsBytesSync().buffer)));
      await loader.load();
    }
    Directory(_out).createSync(recursive: true);
  });

  Future<void> settle(WidgetTester tester, [int rounds = 14]) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await settle(tester);
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shotRoot')));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.5);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$name$_suffix.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
    // ignore: avoid_print
    print('saved $_out/$name$_suffix.png');
  }

  Future<void> seed() async {
    await DatabaseHelper().switchToFile('invoice_manager.db');
    // A new database already has a placeholder row: fill that one in.
    final existing = await CompanyInfoService.getCompanyInfo();
    final save = existing == null
        ? CompanyInfoService.insertCompanyInfo
        : CompanyInfoService.updateCompanyInfo;
    await save(CompanyInfo(
        id: existing?.id,
        name: 'Sri Murugan Traders', address: '12, Big Bazaar Street, Madurai 625001',
        phone: '12345 00010', email: 'billing@srimurugan.example', website: 'www.srimurugan.example',
        gstin: '33ABCDE1234F1Z5', panNumber: 'ABCDE1234F'));
    await BackendServices.settings.setSetting(SettingKey.uiLayout, UiLayout.modern.name);
    await CompanyRegistryService.ensureDefaultCompanyRegistered();

    final customers = [
      Customer(id: 'c1', name: 'Kannan', businessName: 'Kannan Stores', phone: '12345 00011',
          email: 'kannan@stores.example', address: '4, East Masi Street, Madurai', gstin: '33AAKCK1122L1Z9'),
      Customer(id: 'c2', name: 'Meena', businessName: 'Meena Textiles', phone: '12345 00012',
          email: '', address: 'Town Hall Road, Madurai', gstin: '33AAMCM3344N1Z2'),
      Customer(id: 'c3', name: 'Ravi Kumar', phone: '12345 00013', email: 'ravi@mail.example',
          address: 'Anna Nagar, Madurai', gstin: ''),
      Customer(id: 'c4', name: 'Anbu', businessName: 'Anbu Bakery', phone: '12345 00014',
          email: '', address: 'KK Nagar, Madurai', gstin: '33AAACA5566P1Z4'),
      Customer(id: 'c5', name: 'Lakshmi', phone: '12345 00015', email: '', address: '', gstin: ''),
      Customer(id: 'c6', name: 'Selvam', businessName: 'Selvam Hardware', phone: '12345 00016',
          email: '', address: 'Simmakkal, Madurai', gstin: ''),
      Customer(id: 'c7', name: 'Priya', phone: '12345 00017', email: 'priya@mail.example',
          address: 'Tallakulam, Madurai', gstin: ''),
    ];
    for (final c in customers) {
      await CustomerService.insertCustomer(c);
    }

    Product p(String id, String name, double price, double stock,
            {String hsn = '0902', int tax = 5, double cost = 0, String type = 'product',
            bool unlimited = false, String unit = 'pcs'}) =>
        Product(id: id, name: name, description: '', price: price, stock: stock, hsncode: hsn,
            tax_rate: tax, purchasePrice: cost, type: type, unlimitedStock: unlimited, unit: unit);
    final products = [
      p('p1', 'Wireless Mouse', 599, 42, hsn: '8471', cost: 440, tax: 18),
      p('p2', 'USB-C Cable 1m', 299, 6, hsn: '8544', cost: 190, tax: 18),
      p('p3', 'HDMI Cable 2m', 349, 35, hsn: '8544', cost: 240, tax: 18),
      p('p4', 'Dell 24" Monitor', 9499, 18, hsn: '8528', cost: 8300, tax: 18),
      p('p5', 'HD Webcam', 2499, 0, hsn: '8525', cost: 1900, tax: 18),
      p('p6', 'Mechanical Keyboard', 1899, 9, hsn: '8471', cost: 1450, tax: 18),
      p('p7', 'Laptop Stand', 899, 54, hsn: '9403', cost: 640, tax: 18),
      p('p8', 'Printer Paper A4 (500)', 349, 80, hsn: '4802', cost: 290, tax: 12),
      p('s1', 'Setup & Installation', 500, 0, hsn: '9987', tax: 18, type: 'service', unlimited: true),
      p('s2', 'Extended Warranty (1 yr)', 799, 0, hsn: '9987', tax: 18, type: 'service', unlimited: true),
    ];
    for (final x in products) {
      await ProductService.insertProduct(x);
    }
    await ProductService.upsertProductMetadata(
        ProductMetadata(productId: 'p1', skuCode: 'MSE-001'));

    final now = DateTime.now();
    Future<Invoice> invoice(Customer c, List<(int, double)> lines, int daysAgo,
        {double paid = 0, int? dueDays, String type = 'Invoice'}) async {
      final id = await InvoiceService.generateNextId();
      final number = await InvoiceService.generateNextInvoiceNumber(type);
      final inv = Invoice(
        id: id, invoiceNumber: number, customer: c, type: type,
        items: [for (final (i, q) in lines) InvoiceItem(product: products[i], quantity: q)],
        date: now.subtract(Duration(days: daysAgo)),
        dueDate: dueDays == null ? null : now.subtract(Duration(days: daysAgo - dueDays)),
        taxMode: TaxMode.perItem, currencyCode: 'INR', currencySymbol: 'Rs.',
      );
      await InvoiceService.insertInvoice(inv);
      final saved = (await InvoiceService.getInvoiceById(id))!;
      if (paid > 0) {
        await PaymentService.addPayment(
            invoice: saved, amountPaid: paid, datePaid: saved.date.add(const Duration(days: 2)));
      }
      return saved;
    }

    Future<void> paidInFull(Customer c, List<(int, double)> lines, int daysAgo) async {
      final inv = await invoice(c, lines, daysAgo);
      await PaymentService.addPayment(invoice: inv, amountPaid: inv.total, datePaid: inv.date);
    }

    // Six months of a growing shop: May → October.
    final k = customers;
    await paidInFull(k[0], [(3, 1), (6, 5), (7, 10)], 150);
    await paidInFull(k[1], [(3, 1), (0, 4)], 115);
    await paidInFull(k[3], [(5, 3), (7, 10)], 105);
    await paidInFull(k[0], [(3, 2), (6, 3)], 90);
    await paidInFull(k[5], [(0, 6), (1, 10), (2, 6)], 75);
    await paidInFull(k[1], [(3, 2), (5, 4), (0, 4)], 60);
    await paidInFull(k[3], [(6, 10), (7, 10)], 50);
    await paidInFull(k[6], [(4, 6), (0, 2)], 42);
    await paidInFull(k[0], [(3, 3), (6, 5)], 35);
    await invoice(k[1], [(3, 4), (5, 2)], 28, paid: 3000, dueDays: 15);
    await invoice(k[3], [(0, 12), (2, 10), (9, 1)], 28, dueDays: 10);
    await paidInFull(k[2], [(0, 10), (1, 12), (6, 5)], 20);
    await paidInFull(k[5], [(4, 6), (7, 12)], 12);
    await paidInFull(k[0], [(3, 4), (0, 6), (6, 8)], 7);
    await invoice(k[0], [(3, 2), (6, 8), (0, 6)], 6, paid: 2000, dueDays: 21);
    await paidInFull(k[4], [(7, 5), (0, 2)], 5);
    await paidInFull(k[1], [(3, 3), (5, 2)], 4);
    await paidInFull(k[6], [(5, 4), (8, 1)], 3);
    await invoice(k[2], [(5, 3), (1, 6)], 2, dueDays: 15);
    await paidInFull(k[5], [(6, 4), (7, 6)], 1);
    await invoice(k[3], [(0, 20), (3, 1)], 0, dueDays: 30);
    await invoice(k[1], [(3, 5), (5, 4)], 3, type: 'Quotation');
    await invoice(k[6], [(0, 6), (9, 2)], 1, type: 'Quotation');

    // Stock as a real shop would have it now: two low, one out.
    final db = await DatabaseHelper().database;
    for (final (id, stock) in [
      ('p1', 42), ('p2', 6), ('p3', 35), ('p4', 18),
      ('p5', 0), ('p6', 9), ('p7', 54), ('p8', 80),
    ]) {
      await db.update('products', {'stock': stock}, where: 'id = ?', whereArgs: [id]);
    }

    // A draft to open on the Create Invoice screen.
    await InvoiceDraftService.saveDraft(InvoiceDraft(
      id: 'draft-1',
      updatedAt: now,
      invoice: Invoice(
        id: '', customer: customers[0], type: 'Invoice', date: now,
        items: [
          InvoiceItem(product: products[0], quantity: 10),
          InvoiceItem(product: products[3], quantity: 2),
          InvoiceItem(product: products[6], quantity: 5),
          InvoiceItem(product: products[1], quantity: 12),
        ],
        taxMode: TaxMode.perItem, currencyCode: 'INR', currencySymbol: 'Rs.',
      ),
    ));
  }

  testWidgets('Invoiceo marketing screenshots', (tester) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.runAsync(seed);

    final container = ProviderContainer(overrides: sqliteRepositoryOverrides);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(
        key: const ValueKey('shotRoot'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light.copyWith(
              textTheme: AppTheme.light.textTheme
                  .apply(fontFamilyFallback: const ['NotoSansTamil', 'NotoSansDevanagari', 'ShotEmoji'])),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: _locale == '' ? null : Locale(_locale),
          home: DashboardScreen(
              User(id: 'u1', username: 'Madhan', password: 'x', userType: 'admin')),
        ),
      ),
    ));
    await settle(tester, 30);
    // The dashboard opens on Today; the picture shows last month, which has the shop's busy days.
    for (final key in ['modernDashRange', 'modernDashTrendRange']) {
      await tester.tap(find.byKey(ValueKey(key)));
      await settle(tester, 10);
      await tester.tap(find.byKey(const ValueKey('modernPreset_lastMonth')).last);
      await settle(tester, 30);
    }
    await shot(tester, 'dashboard');

    // The sidebar keys carry the label in the app's language.
    final l10n = lookupAppLocalizations(Locale(_locale == '' ? 'en' : _locale));
    Future<void> open(String nav) async {
      await tester.tap(find.byKey(ValueKey('modernNav_$nav')));
      await settle(tester, 20);
    }

    await open(l10n.navInvoices);
    await shot(tester, 'invoices');

    // The draft, opened on the Create Invoice screen.
    await tester.tap(find.byKey(const ValueKey('modernTabDrafts')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('draftContinue_draft-1')));
    await settle(tester, 30);
    await shot(tester, 'create-invoice');

    await open(l10n.navCustomers);
    await shot(tester, 'customers');
    await open(l10n.navProducts);
    await shot(tester, 'products');
    await open(l10n.navReports);
    await shot(tester, 'reports');

    // Forms and dialogs for the "How it works" page (nothing is saved).
    Future<void> closeDialog() async {
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester, 15);
    }
    await open(l10n.navCustomers);
    await tester.tap(find.text(l10n.customerMgmtNewCustomerButton).first);
    await settle(tester, 25);
    await shot(tester, 'customer-new');
    await closeDialog();
    await open(l10n.navProducts);
    await tester.tap(find.text(l10n.productMgmtNewProductButton).first);
    await settle(tester, 25);
    await shot(tester, 'product-new');
    await closeDialog();
    // Create the draft invoice and capture the "created" card. This changes the shop's data, so it comes after every other
    // screen that shows invoices or balances.
    await open(l10n.navInvoices);
    await tester.tap(find.byKey(const ValueKey('modernTabDrafts')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('draftContinue_draft-1')));
    await settle(tester, 30);
    await tester.tap(find.byKey(const ValueKey('modernCreate')));
    await settle(tester, 40);
    await tester.pump(const Duration(seconds: 6));   // the green "created" message goes away by itself
    await settle(tester, 10);
    final closeMessage = find.byIcon(Icons.close);   // any message still showing at the bottom is closed
    if (closeMessage.evaluate().isNotEmpty) {
      await tester.tap(closeMessage.last);
      await settle(tester, 10);
    }
    await shot(tester, 'invoice-created');

    // Settings → Company info: step 1 of "How it works" on the website.
    await open(l10n.navSettings);
    await tester.tap(find
        .descendant(of: find.byType(NavigationRail), matching: find.text(l10n.settingsNavCompanyInfoLabel))
        .first);
    await settle(tester, 20);
    await shot(tester, 'company-info');
    for (final (label, name) in [
      (l10n.invoiceSettingsAppBarTitle, 'settings-invoice'),
      (l10n.pdfSettingsTitle, 'settings-pdf'),
      (l10n.settingsNavBackupLabel, 'settings-backup'),
    ]) {
      await tester.tap(find.descendant(of: find.byType(NavigationRail), matching: find.text(label)).first);
      await settle(tester, 20);
      await shot(tester, name);
    }

    if (_settings) {
      // A common laptop width, and tall so most of each section shows.
      tester.view.physicalSize = const Size(1366, 2400);
      await settle(tester, 10);
      await open(l10n.navSettings);
      final sections = [
        l10n.settingsNavCompaniesLabel, l10n.settingsNavCompanyInfoLabel,
        l10n.settingsNavBackupLabel, l10n.settingsNavUsersLabel, l10n.pdfSettingsTitle,
        l10n.invoiceSettingsAppBarTitle, l10n.settingsNavProductDetailsLabel,
        l10n.settingsNavCustomizeLabel, l10n.settingsNavAccessibilityLabel,
        l10n.settingsNavSoftwareInfoLabel,
      ];
      for (var i = 0; i < sections.length; i++) {
        await tester.tap(find
            .descendant(of: find.byType(NavigationRail), matching: find.text(sections[i]))
            .first);
        await settle(tester, 20);
        await shot(tester, 'settings-${(i + 1).toString().padLeft(2, '0')}');
        // Invoice Settings has its own sub-pages: settings-06b ... 06g.
        if (sections[i] == l10n.invoiceSettingsAppBarTitle) {
          final subs = [
            l10n.invoiceSettingsSectionBranding, l10n.invoiceSettingsSectionTax,
            l10n.invoiceSettingsSectionItems, l10n.invoiceSettingsSectionCustomer,
            l10n.invoiceSettingsSectionColumns, l10n.customizationCustomFieldsTitle,
          ];
          for (var j = 0; j < subs.length; j++) {
            await tester.tap(find.text(subs[j]).first);
            await settle(tester, 20);
            await shot(tester, 'settings-06${'bcdefg'[j]}');
          }
        }
      }
    }
  });
}
