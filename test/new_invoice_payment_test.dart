// The Payment section of the New Invoice form: Unpaid (nothing is recorded), Partial (the amount received now, less than
// the total) and Paid (the whole total), each with the same payment methods as the Apply Payment dialog.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:invoiceo/l10n/app_localizations.dart';
import 'package:invoiceo/models/customer.dart';
import 'package:invoiceo/models/invoice.dart';
import 'package:invoiceo/models/invoice_item.dart';
import 'package:invoiceo/models/invoice_payment.dart';
import 'package:invoiceo/models/product.dart';
import 'package:invoiceo/repositories/payment_repository.dart';
import 'package:invoiceo/utils/new_invoice_payment.dart';
import 'package:invoiceo/widgets/new_invoice_payment_section.dart';

class _Payments implements PaymentRepository {
  final calls = <Map<String, Object?>>[];
  @override
  Future<InvoicePayment> addPayment({
    required Invoice invoice,
    required double amountPaid,
    required DateTime datePaid,
    String? paymentMethod,
    String? notes,
  }) async {
    calls.add({'invoice': invoice.id, 'amount': amountPaid, 'date': datePaid, 'method': paymentMethod, 'notes': notes});
    return InvoicePayment(
        id: 'pay${calls.length}',
        invoiceId: invoice.id,
        invoiceNumber: invoice.invoiceNumber ?? invoice.id,
        receiptNumber: 'R${calls.length}',
        amountPaid: amountPaid,
        taxAmountPaid: 0,
        previouslyPaid: 0,
        balanceAfter: 0,
        datePaid: datePaid,
        paymentMethod: paymentMethod,
        notes: notes);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Invoice _invoice({double price = 500, int qty = 2}) => Invoice(
      id: 'i1',
      invoiceNumber: '00000001',
      customer: Customer(id: 'c1', name: 'Kannan', phone: '1', email: '', address: '', gstin: ''),
      items: [
        InvoiceItem(
            product: Product(
                id: 'p1', name: 'Mouse', description: '', price: price, stock: 10, hsncode: '', tax_rate: 0, purchasePrice: 0),
            quantity: qty.toDouble()),
      ],
      date: DateTime(2026, 11, 17),
      type: 'Invoice',
    );

void main() {
  group('validation', () {
    NewInvoicePaymentError? v(NewInvoicePaymentStatus s, String amount, [double total = 1000]) =>
        validateNewInvoicePayment(status: s, amountText: amount, total: total);

    test('Unpaid and Paid never need an amount', () {
      expect(v(NewInvoicePaymentStatus.unpaid, ''), isNull);
      expect(v(NewInvoicePaymentStatus.unpaid, 'abc'), isNull);
      expect(v(NewInvoicePaymentStatus.paid, ''), isNull);
    });

    test('Partial: empty, zero, text and negative are "enter the amount"', () {
      for (final t in ['', '  ', '0', '0.00', 'abc', '-5']) {
        expect(v(NewInvoicePaymentStatus.partial, t), NewInvoicePaymentError.amountMissing, reason: '"$t"');
      }
    });

    test('Partial: the whole total or more is "that is Paid"; less is fine', () {
      expect(v(NewInvoicePaymentStatus.partial, '1000'), NewInvoicePaymentError.amountNotLessThanTotal);
      expect(v(NewInvoicePaymentStatus.partial, '1000.00'), NewInvoicePaymentError.amountNotLessThanTotal);
      expect(v(NewInvoicePaymentStatus.partial, '1500'), NewInvoicePaymentError.amountNotLessThanTotal);
      expect(v(NewInvoicePaymentStatus.partial, '999.99'), isNull);
      expect(v(NewInvoicePaymentStatus.partial, '0.01'), isNull);
      expect(v(NewInvoicePaymentStatus.partial, '250'), isNull);
      expect(v(NewInvoicePaymentStatus.partial, '1,250.50', 5000), isNull, reason: 'a comma is accepted');
    });

    test('Partial on an invoice of nothing cannot be saved', () {
      expect(v(NewInvoicePaymentStatus.partial, '10', 0), NewInvoicePaymentError.amountNotLessThanTotal);
    });
  });

  group('the amount to record', () {
    double? a(NewInvoicePaymentStatus s, String t, double total) =>
        newInvoicePaymentAmount(status: s, amountText: t, total: total);

    test('Unpaid records nothing; Paid records the whole total; Partial the typed amount', () {
      expect(a(NewInvoicePaymentStatus.unpaid, '500', 1000), isNull);
      expect(a(NewInvoicePaymentStatus.paid, '', 1000), 1000);
      expect(a(NewInvoicePaymentStatus.paid, '5', 1234.5), 1234.5, reason: 'Paid ignores any typed amount');
      expect(a(NewInvoicePaymentStatus.partial, '400', 1000), 400);
      expect(a(NewInvoicePaymentStatus.partial, '400.456', 1000), 400.46);
    });

    test('Paid on a total of 0 records nothing', () {
      expect(a(NewInvoicePaymentStatus.paid, '', 0), isNull);
    });
  });

  group('recordNewInvoicePayment', () {
    test('Paid: one payment of the whole total, with the method, dated the invoice date', () async {
      final repo = _Payments();
      final inv = _invoice(); // 2 x 500 = 1000
      final recorded = await recordNewInvoicePayment(
          payments: repo,
          invoice: inv,
          status: NewInvoicePaymentStatus.paid,
          amountText: '',
          method: 'Online',
          notes: '  UPI 12345  ');
      expect(recorded, isTrue);
      expect(repo.calls, hasLength(1));
      expect(repo.calls.single, {
        'invoice': 'i1', 'amount': 1000.0, 'date': DateTime(2026, 11, 17), 'method': 'Online', 'notes': 'UPI 12345',
      });
    });

    test('Partial: the typed amount; an empty reference is stored as nothing', () async {
      final repo = _Payments();
      await recordNewInvoicePayment(
          payments: repo,
          invoice: _invoice(),
          status: NewInvoicePaymentStatus.partial,
          amountText: '300',
          method: 'Cash',
          notes: '   ');
      expect(repo.calls.single['amount'], 300.0);
      expect(repo.calls.single['method'], 'Cash');
      expect(repo.calls.single['notes'], isNull);
    });

    test('Unpaid: nothing is recorded', () async {
      final repo = _Payments();
      final recorded = await recordNewInvoicePayment(
          payments: repo,
          invoice: _invoice(),
          status: NewInvoicePaymentStatus.unpaid,
          amountText: '300',
          method: 'Cash',
          notes: '');
      expect(recorded, isFalse);
      expect(repo.calls, isEmpty);
    });
  });

  group('the methods', () {
    test('the same five as the Apply Payment dialog, Cash first', () {
      expect(kNewInvoicePaymentMethods, ['Cash', 'Bank Transfer', 'Check', 'Online', 'Other']);
      expect(kNewInvoiceDefaultPaymentMethod, 'Cash');
    });
  });

  group('the section', () {
    late NewInvoicePaymentStatus status;
    late String method;
    final amount = TextEditingController();
    final notes = TextEditingController();

    Future<void> open(WidgetTester tester, {double total = 1000, String? error}) async {
      status = NewInvoicePaymentStatus.unpaid;
      method = kNewInvoiceDefaultPaymentMethod;
      amount.clear();
      notes.clear();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, set) => SingleChildScrollView(
              child: NewInvoicePaymentSection(
                status: status,
                onStatusChanged: (s) => set(() => status = s),
                method: method,
                onMethodChanged: (m) => set(() => method = m),
                amountController: amount,
                notesController: notes,
                onAmountChanged: () => set(() {}),
                total: total,
                currencySymbol: 'Rs.',
                errorText: error,
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('starts on Unpaid: three choices, a note, no amount or method', (tester) async {
      await open(tester);
      expect(find.text('PAYMENT'), findsOneWidget);
      expect(find.byKey(const ValueKey('newInvoicePayUnpaid')), findsOneWidget);
      expect(find.byKey(const ValueKey('newInvoicePayPartial')), findsOneWidget);
      expect(find.byKey(const ValueKey('newInvoicePayPaid')), findsOneWidget);
      expect(find.byKey(const ValueKey('newInvoicePaymentUnpaidNote')), findsOneWidget);
      expect(find.byKey(const ValueKey('newInvoicePaymentAmount')), findsNothing);
      expect(find.byKey(const ValueKey('newInvoicePaymentMethod')), findsNothing);
    });

    testWidgets('Paid asks for the method (Cash chosen) and says the full amount is recorded', (tester) async {
      await open(tester, total: 1234.5);
      await tester.tap(find.byKey(const ValueKey('newInvoicePayPaid')));
      await tester.pumpAndSettle();
      expect(status, NewInvoicePaymentStatus.paid);
      expect(find.byKey(const ValueKey('newInvoicePaymentAmount')), findsNothing, reason: 'the whole total is taken');
      expect(find.byKey(const ValueKey('newInvoicePaymentMethod')), findsOneWidget);
      expect(find.byKey(const ValueKey('newInvoicePaymentNotes')), findsOneWidget);
      expect(find.textContaining('1,234.50'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('newInvoicePaymentMethod')));
      await tester.pumpAndSettle();
      for (final m in ['Cash', 'Bank Transfer', 'Cheque', 'Online', 'Other']) {
        expect(find.text(m), findsWidgets, reason: m);
      }
      await tester.tap(find.text('Online').last);
      await tester.pumpAndSettle();
      expect(method, 'Online');
    });

    testWidgets('Partial asks for the amount and shows the balance due as it is typed', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('newInvoicePayPartial')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('newInvoicePaymentAmount')), findsOneWidget);
      expect(find.byKey(const ValueKey('newInvoicePaymentMethod')), findsOneWidget);
      expect(find.textContaining('1,000.00'), findsOneWidget, reason: 'nothing typed: the whole total is still due');
      await tester.enterText(find.byKey(const ValueKey('newInvoicePaymentAmount')), '350');
      await tester.pumpAndSettle();
      expect(find.textContaining('650.00'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('newInvoicePaymentAmount')), '2000');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('newInvoicePaymentBalance')), findsOneWidget);
      expect(find.textContaining('0.00'), findsWidgets, reason: 'the balance never goes below zero');
    });

    testWidgets('letters cannot be typed in the amount', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('newInvoicePayPartial')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('newInvoicePaymentAmount')), '1a2b.5');
      expect(amount.text, '12.5');
    });

    testWidgets('going back to Unpaid hides the amount and method again', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('newInvoicePayPartial')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('newInvoicePayUnpaid')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('newInvoicePaymentAmount')), findsNothing);
      expect(find.byKey(const ValueKey('newInvoicePaymentMethod')), findsNothing);
      expect(find.byKey(const ValueKey('newInvoicePaymentUnpaidNote')), findsOneWidget);
    });

    testWidgets('an error is shown under the amount', (tester) async {
      await open(tester, error: 'Enter the amount received');
      await tester.tap(find.byKey(const ValueKey('newInvoicePayPartial')));
      await tester.pumpAndSettle();
      expect(find.text('Enter the amount received'), findsOneWidget);
    });
  });
}
