// End to end: the per-product low-stock limit in the Modern Add dialog and
// the Edit dialog, the Standard Add panel, Duplicate, the Low Stock chip and
// the tab counts, the Track-stock switch, digits-only typing, narrow window
// and Tamil.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiceo/database/database_helper.dart';
import 'package:invoiceo/database/product_service.dart';
import 'package:invoiceo/l10n/app_localizations.dart';
import 'package:invoiceo/layouts/modern/modern_page_header.dart';
import 'package:invoiceo/layouts/modern/modern_shell.dart';
import 'package:invoiceo/models/product.dart';
import 'package:invoiceo/models/user.dart';
import 'package:invoiceo/providers/sqlite_repository_overrides.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_company_info_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_installation_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_invoice_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_payment_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_settings_repository.dart';
import 'package:invoiceo/screens/product_management_screen_v2.dart';
import 'package:invoiceo/services/backend_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  var dbCounter = 0;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    BackendServices.configure(
      settings: SqliteSettingsRepository(),
      companyInfo: SqliteCompanyInfoRepository(),
      invoices: SqliteInvoiceRepository(),
      payments: SqlitePaymentRepository(),
      installation: SqliteInstallationRepository(),
    );
    tmp = Directory.systemTemp.createTempSync('invoiceo_modern_products');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => tmp.path);
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

  final admin = User(id: 'u', username: 'admin', password: '', userType: 'admin');

  /// Products: Rice (50), Dal (low, 5), Oil (out, 0), Soap (unlimited).
  /// Services: Repair (18%, SAC 9987), Delivery (0%, no SAC).
  Future<void> seed(WidgetTester tester) async {
    await tester.runAsync(() async {
      await DatabaseHelper().switchToFile('modern_products_${dbCounter++}.db');
      Product p(String id, String name, double price,
              {String type = 'product', double stock = 0, bool unlimited = false,
              int tax = 0, String hsn = '1006', double purchase = 0}) =>
          Product(id: id, name: name, description: '', price: price, stock: stock,
              hsncode: hsn, tax_rate: tax, type: type, unlimitedStock: unlimited,
              purchasePrice: purchase);
      await ProductService.insertProduct(p('p1', 'Rice', 60, stock: 50, purchase: 45));
      await ProductService.insertProduct(p('p2', 'Dal', 120, stock: 5));
      await ProductService.insertProduct(p('p3', 'Oil', 180, stock: 0));
      await ProductService.insertProduct(p('p4', 'Soap', 35, unlimited: true));
      await ProductService.insertProduct(
          p('s1', 'Repair', 500, type: 'service', tax: 18, hsn: '9987', unlimited: true));
      await ProductService.insertProduct(
          p('s2', 'Delivery', 40, type: 'service', hsn: '', unlimited: true));
      await ProductService.upsertProductMetadata(
          ProductMetadata(productId: 'p2', skuCode: 'DAL-500'));
    });
  }

  Future<void> pumpPage(WidgetTester tester,
      {String kind = 'product',
      bool modern = true,
      int initialTab = 0,
      Size size = const Size(1600, 1100),
      Locale? locale,
      bool inFrame = false,
      User? user}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final header = ValueNotifier<ModernPageHeader?>(null);
    addTearDown(header.dispose);
    final page = ProductManagementScreenV2(
        key: UniqueKey(),
        user: user ?? admin,
        modern: modern,
        kind: kind,
        initialTab: initialTab);
    final index = kind == 'service' ? 9 : 6;
    await tester.pumpWidget(ProviderScope(
      overrides: sqliteRepositoryOverrides,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: !inFrame
              ? page
              : Column(children: [
                  ModernTopBar(
                    username: 'admin',
                    isAdmin: true,
                    onSearch: () {},
                    onCreate: (_) {},
                    onUserAction: (_) {},
                    page: index,
                    pageTitle: kind == 'service' ? 'Services' : 'Products',
                    header: header,
                  ),
                  Expanded(child: ModernHeaderScope(page: index, notifier: header, child: page)),
                ]),
        ),
      ),
    ));
    await settle(tester);
    await settle(tester);
  }

  Finder row(String id) => find.byKey(ValueKey('prodRow_$id'));
  Finder field(String label) => find.widgetWithText(TextFormField, label);
  TextFormField fieldWidget(WidgetTester tester, String label) =>
      tester.widget<TextFormField>(field(label));

  Future<Product> saved(WidgetTester tester, String name) async {
    final all = await tester.runAsync(ProductService.getAllProducts);
    return all!.singleWhere((p) => p.name == name);
  }

  Future<void> openNew(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('modernNewProduct')));
    await settle(tester);
    expect(find.byKey(const ValueKey('modernAddDialog')), findsOneWidget);
  }

  Future<void> fill(WidgetTester tester, String name,
      {String price = '40', String purchase = '30', String? stock, String? limit}) async {
    await tester.enterText(field('Name'), name);
    await tester.enterText(field('Sale Price'), price);
    await tester.enterText(field('Purchase Price'), purchase);
    if (stock != null) await tester.enterText(field('Stock'), stock);
    if (limit != null) await tester.enterText(field('Low-stock limit'), limit);
  }

  testWidgets('Modern Add dialog: limit saved, shows as Low Stock above 10, chips agree',
      (tester) async {
    await seed(tester);
    await pumpPage(tester, inFrame: true);
    expect(find.text('Low Stock (1)'), findsOneWidget, reason: 'Dal 5 only, before');

    await openNew(tester);
    expect(find.text('Add New Product'), findsOneWidget);
    expect(find.text('General'.toUpperCase()), findsOneWidget);
    expect(find.text('Pricing'.toUpperCase()), findsOneWidget);
    expect(find.text('Inventory'.toUpperCase()), findsOneWidget);
    expect(find.byKey(const ValueKey('modernTrackStock')), findsOneWidget);
    expect(find.byType(SegmentedButton<String>), findsNothing);

    await fill(tester, 'Sugar', stock: '15', limit: '20');
    await tester.tap(find.text('Save Product'));
    await settle(tester);
    expect(find.byKey(const ValueKey('modernAddDialog')), findsNothing, reason: 'closed after save');

    final sugar = await saved(tester, 'Sugar');
    expect(sugar.stock, 15.0);
    expect(sugar.lowStockLimit, 20);
    expect(sugar.unlimitedStock, isFalse);
    // 15 is above the old fixed 10, but it is low for its own limit of 20.
    expect(find.text('Low Stock (2)'), findsOneWidget);
    expect(find.text('In Stock (2)'), findsOneWidget, reason: 'Rice and Soap, not Sugar');
    expect(row(sugar.id), findsOneWidget);
    expect(find.descendant(of: row(sugar.id), matching: find.text('Low Stock')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blank limit saves as default: 8 is low, 12 is in stock', (tester) async {
    await seed(tester);
    await pumpPage(tester, inFrame: true);
    await openNew(tester);
    await fill(tester, 'Tea', stock: '8');
    await tester.tap(find.text('Save Product'));
    await settle(tester);
    await openNew(tester);
    await fill(tester, 'Coffee', stock: '12');
    await tester.tap(find.text('Save Product'));
    await settle(tester);

    expect((await saved(tester, 'Tea')).lowStockLimit, isNull);
    expect((await saved(tester, 'Coffee')).lowStockLimit, isNull);
    expect(find.text('Low Stock (2)'), findsOneWidget, reason: 'Dal and Tea');
    expect(find.descendant(of: row((await saved(tester, 'Coffee')).id), matching: find.text('In Stock')),
        findsOneWidget);
  });

  testWidgets('limit field takes digits only; letters and a dot are dropped', (tester) async {
    await seed(tester);
    await pumpPage(tester, inFrame: true);
    await openNew(tester);
    await tester.enterText(field('Low-stock limit'), 'ab1.2x3');
    await tester.pump();
    expect(fieldWidget(tester, 'Low-stock limit').controller!.text, '123');
  });

  testWidgets('Track stock off hides Stock and the limit; saves unlimited with no limit',
      (tester) async {
    await seed(tester);
    await pumpPage(tester, inFrame: true);
    await openNew(tester);
    expect(field('Stock'), findsOneWidget);
    expect(field('Low-stock limit'), findsOneWidget);
    await tester.enterText(field('Low-stock limit'), '30');
    await tester.tap(find.byKey(const ValueKey('modernTrackStock')));
    await tester.pump();
    expect(field('Stock'), findsNothing);
    expect(field('Low-stock limit'), findsNothing);

    await fill(tester, 'Gift wrap');
    await tester.tap(find.text('Save Product'));
    await settle(tester);
    final item = await saved(tester, 'Gift wrap');
    expect(item.unlimitedStock, isTrue);
    expect(item.lowStockLimit, isNull, reason: 'the typed 30 is not kept for an untracked item');
  });

  testWidgets('Edit: shows the saved limit, changes it, and clears it', (tester) async {
    await seed(tester);
    await tester.runAsync(() async {
      await ProductService.updateProduct(Product(
          id: 'p2', name: 'Dal', description: '', price: 120, stock: 5, hsncode: '1006',
          tax_rate: 0, lowStockLimit: 3));
    });
    await pumpPage(tester, inFrame: true);
    // Dal has 5 left but its own limit is 3: not low any more.
    expect(find.text('Low Stock (0)'), findsOneWidget);
    expect(find.text('In Stock (3)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('prodEdit_p2')));
    await settle(tester);
    expect(fieldWidget(tester, 'Low-stock limit').controller!.text, '3');
    await tester.enterText(field('Low-stock limit'), '9');
    await tester.tap(find.text('Save Changes'));
    await settle(tester);
    expect((await saved(tester, 'Dal')).lowStockLimit, 9);
    expect(find.text('Low Stock (1)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('prodEdit_p2')));
    await settle(tester);
    await tester.enterText(field('Low-stock limit'), '');
    await tester.tap(find.text('Save Changes'));
    await settle(tester);
    expect((await saved(tester, 'Dal')).lowStockLimit, isNull);
    expect(find.text('Low Stock (1)'), findsOneWidget, reason: 'back to the default 10');
  });

  testWidgets('Duplicate keeps the limit', (tester) async {
    await seed(tester);
    await tester.runAsync(() async {
      await ProductService.updateProduct(Product(
          id: 'p1', name: 'Rice', description: '', price: 60, stock: 50, hsncode: '1006',
          tax_rate: 0, lowStockLimit: 25));
    });
    await pumpPage(tester, inFrame: true);
    await tester.tap(find.byKey(const ValueKey('prodDuplicate_p1')));
    await settle(tester);
    expect((await saved(tester, 'Rice (copy)')).lowStockLimit, 25);
  });

  testWidgets('Standard layout Add panel has the limit and saves it', (tester) async {
    await seed(tester);
    await pumpPage(tester, modern: false);
    await tester.tap(find.byIcon(Icons.add).first);
    await settle(tester);
    if (field('Name').evaluate().isEmpty) {
      await tester.tap(find.textContaining('New Product').first);
      await settle(tester);
    }
    expect(field('Low-stock limit'), findsOneWidget);
    await tester.enterText(field('Name'), 'Std item');
    await tester.enterText(field('Sale Price'), '10');
    await tester.enterText(field('Purchase Price'), '5');
    await tester.enterText(field('Stock'), '14');
    await tester.enterText(field('Low-stock limit'), '15');
    await tester.tap(find.text('Save Product'));
    await settle(tester);
    final item = await saved(tester, 'Std item');
    expect(item.lowStockLimit, 15);
    expect(item.stock, 14.0);
  });

  testWidgets('no overflow: narrow window and Tamil, Add and Edit dialogs', (tester) async {
    for (final (size, locale) in [
      (const Size(600, 900), null),
      (const Size(1000, 640), const Locale('ta')),
    ]) {
      await seed(tester);
      await pumpPage(tester, inFrame: true, size: size, locale: locale);
      await tester.tap(find.byKey(const ValueKey('modernNewProduct')));
      await settle(tester);
      expect(find.byKey(const ValueKey('modernAddDialog')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'add $size $locale');
      await tester.tap(find.byIcon(Icons.close).last);
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('prodEdit_p2')));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: 'edit $size $locale');
    }
  });
}
