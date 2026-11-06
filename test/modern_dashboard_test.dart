// The Modern layout's dashboard: one design (no Default / Classic / Bento /
// Simple choice), with real numbers from the database.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiceo/database/customer_service.dart';
import 'package:invoiceo/database/database_helper.dart';
import 'package:invoiceo/database/invoice_service.dart';
import 'package:invoiceo/database/payment_service.dart';
import 'package:invoiceo/database/product_service.dart';
import 'package:invoiceo/database/report_service.dart';
import 'package:invoiceo/l10n/app_localizations.dart';
import 'package:invoiceo/layouts/modern/modern_dashboard.dart';
import 'package:invoiceo/models/customer.dart';
import 'package:invoiceo/models/invoice.dart';
import 'package:invoiceo/models/invoice_item.dart';
import 'package:invoiceo/models/product.dart';
import 'package:invoiceo/models/user.dart';
import 'package:invoiceo/providers/sqlite_repository_overrides.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_company_info_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_installation_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_invoice_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_payment_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_settings_repository.dart';
import 'package:invoiceo/services/backend_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── pure helpers ──────────────────────────────────────────────────────────
  group('helpers', () {
    test('a whole month compares with the whole month before', () {
      final oct = modernMonthRange(DateTime(2026, 10, 17));
      expect(oct.start, DateTime(2026, 10, 1));
      expect(oct.end, DateTime(2026, 10, 31));
      expect(modernIsWholeMonth(oct), isTrue);
      final sep = modernPreviousRange(oct);
      expect(sep.start, DateTime(2026, 9, 1));
      expect(sep.end, DateTime(2026, 9, 30));
      // January goes back to the December before
      final dec = modernPreviousRange(modernMonthRange(DateTime(2026, 1, 5)));
      expect(dec.start, DateTime(2025, 12, 1));
      expect(dec.end, DateTime(2025, 12, 31));
    });

    test('any other range compares with the same number of days before it', () {
      final r = DateTimeRange(start: DateTime(2026, 10, 11), end: DateTime(2026, 10, 20));
      expect(modernIsWholeMonth(r), isFalse);
      final p = modernPreviousRange(r);
      expect(p.start, DateTime(2026, 10, 1));
      expect(p.end, DateTime(2026, 10, 10));
    });

    test('percent change', () {
      expect(modernPercentChange(112, 100)!.round(), 12);
      expect(modernPercentChange(92, 100)!.round(), -8);
      expect(modernPercentChange(0, 0), 0);
      expect(modernPercentChange(50, 0), isNull, reason: 'nothing to compare with');
    });

    test('status counts: overdue counts only as overdue', () {
      InvoiceStatusRow row(String status, bool overdue) => InvoiceStatusRow(
          id: 'x', date: '2026-10-01', customerName: 'c', total: 1, paid: 0,
          outstanding: 1, daysOverdue: overdue ? 3 : 0, hasNoDueDate: false,
          status: status, isOverdue: overdue);
      final c = ModernStatusCounts.fromRows([
        row('Paid', false), row('Paid', false), row('Unpaid', false),
        row('Partial', false), row('Unpaid', true), row('Partial', true),
      ]);
      expect([c.paid, c.unpaid, c.partial, c.overdue, c.total], [2, 1, 1, 2, 6]);
    });

    group('quick filters', () {
      final wed = DateTime(2026, 10, 28, 16, 30); // a Wednesday

      DateTimeRange r(int y1, int m1, int d1, int y2, int m2, int d2) =>
          DateTimeRange(start: DateTime(y1, m1, d1), end: DateTime(y2, m2, d2));

      test('today is one day', () {
        expect(modernPresetRange(ModernPreset.today, wed), r(2026, 10, 28, 2026, 10, 28));
      });

      test('a week runs Monday to Sunday, from any day of it', () {
        final week = r(2026, 10, 26, 2026, 11, 1);
        expect(modernPresetRange(ModernPreset.thisWeek, wed), week);
        expect(modernPresetRange(ModernPreset.thisWeek, DateTime(2026, 10, 26)), week,
            reason: 'Monday');
        expect(modernPresetRange(ModernPreset.thisWeek, DateTime(2026, 11, 1, 23, 59)), week,
            reason: 'Sunday still belongs to the week that began on Monday');
        // across a year end
        expect(modernPresetRange(ModernPreset.thisWeek, DateTime(2026, 1, 1)),
            r(2025, 12, 29, 2026, 1, 4));
      });

      test('this month and last month are whole calendar months', () {
        expect(modernPresetRange(ModernPreset.thisMonth, wed), r(2026, 10, 1, 2026, 10, 31));
        expect(modernPresetRange(ModernPreset.lastMonth, wed), r(2026, 9, 1, 2026, 9, 30));
        expect(modernPresetRange(ModernPreset.lastMonth, DateTime(2026, 1, 15)),
            r(2025, 12, 1, 2025, 12, 31));
      });

      test('a range is recognised as its quick filter, or as custom', () {
        for (final p in [
          ModernPreset.today,
          ModernPreset.thisWeek,
          ModernPreset.thisMonth,
          ModernPreset.lastMonth,
        ]) {
          expect(modernPresetOf(modernPresetRange(p, wed), wed), p);
        }
        expect(modernPresetOf(r(2026, 10, 11, 2026, 10, 20), wed), ModernPreset.custom);
        // the same dates under another day's clock are not "today"
        expect(modernPresetOf(modernPresetRange(ModernPreset.today, wed), DateTime(2026, 10, 29)),
            ModernPreset.custom);
      });

      test('today compares with yesterday, a week with the 7 days before it', () {
        final y = modernPreviousRange(modernPresetRange(ModernPreset.today, wed));
        expect(y, r(2026, 10, 27, 2026, 10, 27));
        final w = modernPreviousRange(modernPresetRange(ModernPreset.thisWeek, wed));
        expect(w, r(2026, 10, 19, 2026, 10, 25));
      });
    });

    group('sales overview chart', () {
      final wed = DateTime(2026, 10, 28, 14, 30);

      test('the grain follows the range: hours, days, months', () {
        expect(modernTrendBucket(modernPresetRange(ModernPreset.today, wed)), TrendBucket.hour);
        expect(modernTrendBucket(modernPresetRange(ModernPreset.thisWeek, wed)), TrendBucket.day);
        expect(modernTrendBucket(modernPresetRange(ModernPreset.thisMonth, wed)), TrendBucket.day);
        expect(modernTrendBucket(DateTimeRange(start: DateTime(2026, 8, 1), end: DateTime(2026, 10, 31))),
            TrendBucket.day, reason: '92 days');
        expect(modernTrendBucket(DateTimeRange(start: DateTime(2026, 7, 1), end: DateTime(2026, 10, 31))),
            TrendBucket.month, reason: 'more than about three months');
      });

      test('days still to come are left out, empty days are zero', () {
        final pts = modernFillTrend(
            modernPresetRange(ModernPreset.thisWeek, wed), wed, TrendBucket.day, const [
          TrendPoint(key: '2026-10-26', billed: 0, collected: 500, outstanding: 40),
          TrendPoint(key: '2026-10-28', billed: 0, collected: 10, outstanding: 0),
        ]);
        expect(pts.map((p) => p.at.day), [26, 27, 28], reason: 'Mon, Tue, Wed: not Thu to Sun');
        expect(pts.map((p) => p.collected), [500, 0, 10]);
        expect(pts.map((p) => p.outstanding), [40, 0, 0]);
      });

      test('a finished month shows every day', () {
        final pts = modernFillTrend(
            modernPresetRange(ModernPreset.lastMonth, wed), wed, TrendBucket.day, const []);
        expect(pts.length, 30);
        expect(pts.first.at, DateTime(2026, 9, 1));
        expect(pts.last.at, DateTime(2026, 9, 30));
      });

      test('today shows the hours so far', () {
        final pts = modernFillTrend(
            modernPresetRange(ModernPreset.today, wed), wed, TrendBucket.hour, const [
          TrendPoint(key: '2026-10-28 09', billed: 0, collected: 120, outstanding: 30),
        ]);
        expect(pts.length, 15, reason: '00:00 to 14:00');
        expect(pts[9].at, DateTime(2026, 10, 28, 9));
        expect(pts[9].collected, 120);
        expect(pts[9].outstanding, 30);
        expect(pts.where((p) => p.collected > 0).length, 1);
      });

      test('a past day shows all 24 hours', () {
        final pts = modernFillTrend(
            DateTimeRange(start: DateTime(2026, 10, 20), end: DateTime(2026, 10, 20)),
            wed, TrendBucket.hour, const []);
        expect(pts.length, 24);
      });

      test('a long range is grouped by month', () {
        final pts = modernFillTrend(
            DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 12, 31)),
            wed, TrendBucket.month, const [
          TrendPoint(key: '2026-03', billed: 0, collected: 70, outstanding: 0),
        ]);
        expect(pts.length, 10, reason: 'January to October');
        expect(pts[2].collected, 70);
      });

      test('a range that has not started has no points', () {
        final pts = modernFillTrend(
            DateTimeRange(start: DateTime(2026, 11, 2), end: DateTime(2026, 11, 8)),
            wed, TrendBucket.day, const []);
        expect(pts, isEmpty);
      });

      test('always at least two points, so a line can be drawn', () {
        // First day of the month: only one day has started.
        final first = DateTime(2026, 11, 1, 9);
        final month = modernFillTrend(
            modernPresetRange(ModernPreset.thisMonth, first), first, TrendBucket.day, const []);
        expect(month.length, 2);
        // Just after midnight: only the 00:00 hour has started.
        final night = DateTime(2026, 10, 28, 0, 20);
        final hours = modernFillTrend(
            modernPresetRange(ModernPreset.today, night), night, TrendBucket.hour, const []);
        expect(hours.length, 2);
      });
    });
  });

  // ── the page with real data ───────────────────────────────────────────────
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
    tmp = Directory.systemTemp.createTempSync('invoiceo_modern_dashboard');
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
    for (var i = 0; i < 14; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  final customer = Customer(
      id: 'c1', name: 'Test Customer', email: '', phone: '', address: '', gstin: '');

  Product product(String id, String name, double stock, {bool unlimited = false}) => Product(
      id: id, name: name, description: '', price: 100, stock: stock, hsncode: '',
      tax_rate: 0, unlimitedStock: unlimited);

  // This month: one paid (200), one partly paid (300, 100 paid), one unpaid
  // (400, due later), one overdue (500, due yesterday). Last month: one paid
  // (100). Stock: Camphor 6, Dal 8 (low), Oil 0 (out), Soap unlimited.
  Future<void> seed() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 5);
    await CustomerService.insertCustomer(customer);
    final rice = product('p1', 'Rice', 500);
    await ProductService.insertProduct(rice);
    await ProductService.insertProduct(product('p2', 'Camphor', 6));
    await ProductService.insertProduct(product('p3', 'Dal', 8));
    await ProductService.insertProduct(product('p4', 'Oil', 0));
    await ProductService.insertProduct(product('p5', 'Soap', 0, unlimited: true));
    // A service with tracked stock at 0: not a product, so not in the
    // Products count or the low-stock card.
    await ProductService.insertProduct(Product(
        id: 's1', name: 'Repair', description: '', price: 500, stock: 0,
        hsncode: '', tax_rate: 0, type: 'service'));

    Future<Invoice> inv(String id, double qty, DateTime date, DateTime due) async {
      final i = Invoice(
          id: id, customer: customer, items: [InvoiceItem(product: rice, quantity: qty)],
          date: date, dueDate: due, type: 'Invoice');
      await InvoiceService.insertInvoice(i);
      return i;
    }

    final i0 = await inv('i0', 1, lastMonth, lastMonth.add(const Duration(days: 10)));
    await PaymentService.addPayment(invoice: i0, amountPaid: 100, datePaid: lastMonth);
    final i1 = await inv('i1', 2, monthStart, now.add(const Duration(days: 20)));
    await PaymentService.addPayment(invoice: i1, amountPaid: 200, datePaid: monthStart);
    final i2 = await inv('i2', 3, monthStart, now.add(const Duration(days: 20)));
    await PaymentService.addPayment(invoice: i2, amountPaid: 100, datePaid: monthStart);
    await inv('i3', 4, monthStart, now.add(const Duration(days: 20)));
    await inv('i4', 5, monthStart, DateTime(now.year, now.month, now.day - 1));
  }

  Future<List<String>> open(WidgetTester tester,
      {Size size = const Size(1600, 1400), bool withData = true}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await DatabaseHelper().switchToFile('modern_dashboard_${dbCounter++}.db');
      if (withData) await seed();
    });
    final calls = <String>[];
    await tester.pumpWidget(ProviderScope(
      overrides: sqliteRepositoryOverrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ModernDashboard(
            user: User(id: 'u1', username: 'admin', password: 'x', userType: 'admin'),
            onEditInvoice: (i) => calls.add('edit ${i.id}'),
            onCloneInvoice: (i, t) => calls.add('clone ${i.id} $t'),
            onCreateDocument: (t) => calls.add('create $t'),
            onOpenPage: (p) => calls.add('page $p'),
            onAddCustomer: () => calls.add('add customer'),
            onAddProduct: () => calls.add('add product'),
          ),
        ),
      ),
    ));
    await settle(tester);
    return calls;
  }

  group('page', () {
    testWidgets('header: title, greeting, and Today as the range', (tester) async {
      await open(tester, withData: false);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.textContaining('admin'), findsWidgets);
      expect(find.textContaining('👋'), findsOneWidget);
      expect(find.text("Here's what's happening with your business today."), findsOneWidget);
      final now = DateTime.now();
      final month = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][now.month - 1];
      final today = '$month ${now.day.toString().padLeft(2, '0')}, ${now.year}';
      final header = find.byKey(const ValueKey('modernDashRange'));
      expect(find.descendant(of: header, matching: find.textContaining('Today')), findsOneWidget);
      expect(find.descendant(of: header, matching: find.textContaining(today)), findsOneWidget);
      // the Sales Overview starts on Today too
      expect(find.descendant(
          of: find.byKey(const ValueKey('modernDashTrendRange')), matching: find.text('Today')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('only one design: no dashboard layout choices', (tester) async {
      await open(tester, withData: false);
      for (final t in ['Classic', 'Bento', 'Simple Feed', 'Default']) {
        expect(find.text(t), findsNothing, reason: t);
      }
    });

    testWidgets('the four cards show this month, compared with last month', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('modernDashRange')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('modernPreset_thisMonth')));
      await settle(tester);
      expect(find.textContaining('300.00'), findsWidgets, reason: 'collected 200 + 100');
      expect(find.textContaining('1,100.00'), findsWidgets, reason: 'outstanding 200 + 400 + 500');
      expect(find.text('200%'), findsOneWidget, reason: 'collected 300 vs 100 last month');
      expect(find.text('vs last month'), findsWidgets);
      expect(find.text('5'), findsWidgets, reason: 'five products');
      expect(find.text('3 low stock'), findsOneWidget, reason: 'Camphor, Dal low; Oil out');
      expect(find.text('Repair'), findsNothing, reason: 'a service is not a low-stock product');
      expect(tester.takeException(), isNull);
    });

    testWidgets('invoice status: paid, partial, unpaid, overdue add up', (tester) async {
      await open(tester);
      // The page starts on Today; the sample invoices are spread over this month.
      await tester.tap(find.byKey(const ValueKey('modernDashRange')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('modernPreset_thisMonth')));
      await settle(tester);
      final status = find.byKey(const ValueKey('modernDashStatus'));
      expect(tester.widget<Text>(find.byKey(const ValueKey('modernDashStatusTotal'))).data, '4');
      for (final label in ['Paid', 'Unpaid', 'Partial', 'Overdue']) {
        expect(find.descendant(of: status, matching: find.text(label)), findsOneWidget);
      }
      expect(find.descendant(of: status, matching: find.text('25%')), findsNWidgets(4));
    });

    testWidgets('recent invoices list the latest five with their status', (tester) async {
      await open(tester);
      final recent = find.byKey(const ValueKey('modernDashRecent'));
      expect(find.descendant(of: recent, matching: find.text('Test Customer')), findsNWidgets(5));
      expect(find.descendant(of: recent, matching: find.text('Overdue')), findsOneWidget);
      expect(find.descendant(of: recent, matching: find.text('Partial')), findsOneWidget);
    });

    testWidgets('low stock: out of stock first, then the lowest; unlimited never',
        (tester) async {
      final calls = await open(tester);
      final low = find.byKey(const ValueKey('modernDashLowStock'));
      double y(String name) => tester.getTopLeft(find.descendant(of: low, matching: find.text(name))).dy;
      expect(y('Oil'), lessThan(y('Camphor')));
      expect(y('Camphor'), lessThan(y('Dal')));
      expect(find.descendant(of: low, matching: find.text('Soap')), findsNothing);
      expect(find.descendant(of: low, matching: find.text('Rice')), findsNothing);
      await tester.tap(find.descendant(of: low, matching: find.text('View all')));
      expect(calls, ['page 6']);
    });

    testWidgets('update stock from the low-stock list', (tester) async {
      await open(tester);
      final low = find.byKey(const ValueKey('modernDashLowStock'));
      final camphorRow = find.ancestor(
          of: find.descendant(of: low, matching: find.text('Camphor')),
          matching: find.byType(Row)).first;
      final rowY = tester.getCenter(camphorRow).dy;
      final editButtons = find.descendant(of: low, matching: find.byIcon(Icons.edit_outlined));
      final edit = editButtons.evaluate().map((e) => find.byWidget(e.widget)).firstWhere(
          (f) => (tester.getCenter(f).dy - rowY).abs() < 20);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('modernDashStockField')), '25');
      await tester.tap(find.text('Save'));
      await settle(tester);
      final p = await tester.runAsync(() => ProductService.getProductById('p2'));
      expect(p!.stock, 25);
      expect(find.descendant(of: low, matching: find.text('Camphor')), findsNothing,
          reason: 'no longer low');
    });

    testWidgets('quick actions', (tester) async {
      final calls = await open(tester, withData: false);
      final quick = find.byKey(const ValueKey('modernDashQuickActions'));
      for (final label in ['New Invoice', 'New Quotation', 'Add Customer', 'Add Product', 'View Reports', 'Settings']) {
        await tester.tap(find.descendant(of: quick, matching: find.text(label)));
      }
      expect(calls, [
        'create Invoice', 'create Quotation', 'add customer', 'add product', 'page 7', 'page 8',
      ]);
    });

    testWidgets('narrow window: everything stacks without overflow', (tester) async {
      await open(tester, size: const Size(700, 2600));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('modernDashSales')), findsOneWidget);
      expect(find.byKey(const ValueKey('modernDashStatus')), findsOneWidget);
    });
  });

  // ── the filters on the page ───────────────────────────────────────────────
  group('filters', () {
    Future<void> pick(WidgetTester tester, String menuKey, ModernPreset p) async {
      await tester.tap(find.byKey(ValueKey(menuKey)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('modernPreset_${p.name}')));
      await settle(tester);
    }

    // One sale made right now.
    Future<void> saleToday(WidgetTester tester) => tester.runAsync(() async {
          final rice = product('pt', 'Rice today', 500);
          await CustomerService.insertCustomer(customer);
          await ProductService.insertProduct(rice);
          final i = Invoice(
              id: 'itoday', customer: customer,
              items: [InvoiceItem(product: rice, quantity: 2)],
              date: DateTime.now(), dueDate: DateTime.now(), type: 'Invoice');
          await InvoiceService.insertInvoice(i);
          await PaymentService.addPayment(
              invoice: i, amountPaid: 50, datePaid: DateTime.now());
        });

    String statusTotal(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const ValueKey('modernDashStatusTotal'))).data!;

    testWidgets('both menus offer Today, This week, This month, Last month and Custom Range',
        (tester) async {
      await open(tester, withData: false);
      for (final key in ['modernDashRange', 'modernDashTrendRange']) {
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
        for (final p in ModernPreset.values) {
          expect(find.byKey(ValueKey('modernPreset_${p.name}')), findsOneWidget,
              reason: '$key: ${p.name}');
        }
        for (final gone in ['Last 3 months', 'This year', 'Last 6 months', 'Last 12 months']) {
          expect(find.text(gone), findsNothing, reason: '$key: $gone');
        }
        await tester.tap(find.byKey(const ValueKey('modernPreset_thisMonth')));
        await settle(tester);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('the header filter changes what the cards and invoice status add up',
        (tester) async {
      await open(tester, withData: false);
      await saleToday(tester);
      // The page was loaded before the sale: choosing a filter reloads it.
      await pick(tester, 'modernDashRange', ModernPreset.today);
      expect(statusTotal(tester), '1');
      expect(find.descendant(
          of: find.byKey(const ValueKey('modernDashRange')), matching: find.textContaining('Today')),
          findsOneWidget);

      await pick(tester, 'modernDashRange', ModernPreset.thisWeek);
      expect(statusTotal(tester), '1');
      await pick(tester, 'modernDashRange', ModernPreset.thisMonth);
      expect(statusTotal(tester), '1');
      await pick(tester, 'modernDashRange', ModernPreset.lastMonth);
      expect(statusTotal(tester), '0', reason: 'the sale was made today, not last month');
      expect(find.descendant(
          of: find.byKey(const ValueKey('modernDashRange')),
          matching: find.textContaining('Last month')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the Sales Overview has its own filter, and the header filter leaves it alone',
        (tester) async {
      await open(tester, withData: false);
      await saleToday(tester);
      final chartFilter = find.byKey(const ValueKey('modernDashTrendRange'));
      // Both start on Today.
      expect(find.descendant(of: chartFilter, matching: find.text('Today')), findsOneWidget);

      await pick(tester, 'modernDashTrendRange', ModernPreset.thisMonth);
      expect(find.descendant(of: chartFilter, matching: find.text('This month')), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget, reason: 'this month has a sale: daily chart');
      // the header filter did not move
      expect(find.descendant(
          of: find.byKey(const ValueKey('modernDashRange')),
          matching: find.textContaining('Today')), findsOneWidget);

      await pick(tester, 'modernDashTrendRange', ModernPreset.today);
      expect(find.descendant(of: chartFilter, matching: find.text('Today')), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget, reason: 'today has a sale: hourly chart');

      await pick(tester, 'modernDashTrendRange', ModernPreset.thisWeek);
      expect(find.descendant(of: chartFilter, matching: find.text('This week')), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);

      await pick(tester, 'modernDashTrendRange', ModernPreset.lastMonth);
      expect(find.byType(LineChart), findsNothing, reason: 'no sales last month');
      expect(find.text('No data for this period'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // ── the chart's data, from the database ───────────────────────────────────
  group('revenue trend by hour, day and month', () {
    test('billed, collected and outstanding land in the right bucket', () async {
      await DatabaseHelper().switchToFile('modern_dashboard_trend_${dbCounter++}.db');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final rice = product('pr', 'Rice', 500);
      await CustomerService.insertCustomer(customer);
      await ProductService.insertProduct(rice);

      Future<Invoice> sale(String id, double qty, DateTime when) async {
        final i = Invoice(
            id: id, customer: customer,
            items: [InvoiceItem(product: rice, quantity: qty)],
            date: when, dueDate: when, type: 'Invoice');
        await InvoiceService.insertInvoice(i);
        return i;
      }

      // Rice is 100 each. Today 10:15: 200, all paid. Today 15:40: 500, nothing
      // paid. Yesterday 11:00: 300, 100 paid.
      final a = await sale('ta', 2, DateTime(today.year, today.month, today.day, 10, 15));
      await PaymentService.addPayment(invoice: a, amountPaid: 200, datePaid: today);
      await sale('tc', 5, DateTime(today.year, today.month, today.day, 15, 40));
      final b = await sale('tb', 3, DateTime(yesterday.year, yesterday.month, yesterday.day, 11));
      await PaymentService.addPayment(invoice: b, amountPaid: 100, datePaid: yesterday);

      String two(int n) => n.toString().padLeft(2, '0');
      String dayKey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

      // days
      final days = await ReportService.getRevenueTrend(yesterday, today);
      expect(days.map((p) => p.key), [dayKey(yesterday), dayKey(today)]);
      expect(days[0].billed, 300);
      expect(days[0].collected, 100);
      expect(days[0].outstanding, 200);
      expect(days[1].billed, 700);
      expect(days[1].collected, 200);
      expect(days[1].outstanding, 500);

      // hours of today
      final hours =
          await ReportService.getRevenueTrend(today, today, bucket: TrendBucket.hour);
      expect(hours.map((p) => p.key), ['${dayKey(today)} 10', '${dayKey(today)} 15']);
      expect([hours[0].billed, hours[0].collected, hours[0].outstanding], [200, 200, 0]);
      expect([hours[1].billed, hours[1].collected, hours[1].outstanding], [500, 0, 500]);

      // months: yesterday and today may be in different months
      final months = await ReportService.getRevenueTrend(yesterday, today,
          bucket: TrendBucket.month);
      expect(months.fold<double>(0, (t, p) => t + p.billed), 1000);
      expect(months.fold<double>(0, (t, p) => t + p.collected), 300);
      expect(months.fold<double>(0, (t, p) => t + p.outstanding), 700);
    });
  });
}
