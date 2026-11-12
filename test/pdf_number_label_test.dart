// The A4 templates print "Invoice No: 00000001" (Quotation No, Receipt No, Credit Note No ...) before the
// document number, not a bare "#" that customers read as a missing number.
// With --dart-define=DOCS_OUT=<folder> the PDFs are also written there for a visual check.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiceo/common/common.dart';
import 'package:invoiceo/database/company_info_service.dart';
import 'package:invoiceo/database/database_helper.dart';
import 'package:invoiceo/database/settings_service.dart';
import 'package:invoiceo/models/company_info.dart';
import 'package:invoiceo/models/customer.dart';
import 'package:invoiceo/models/invoice.dart';
import 'package:invoiceo/models/invoice_item.dart';
import 'package:invoiceo/models/product.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_company_info_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_installation_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_invoice_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_payment_repository.dart';
import 'package:invoiceo/repositories/sqlite/sqlite_settings_repository.dart';
import 'package:invoiceo/services/backend_services.dart';
import 'package:invoiceo/services/pdf/pdf_service.dart';
import 'package:invoiceo/services/pdf/pdf_widgets.dart';

const _out = String.fromEnvironment('DOCS_OUT');

Invoice _doc(String type, {String? title, String number = '00000001'}) => Invoice(
      id: number,
      invoiceNumber: number,
      customer: Customer(id: 'c1', name: 'Kannan', phone: '12345 00011', email: '', address: 'Madurai', gstin: ''),
      type: type,
      invoiceTitle: title,
      items: [
        InvoiceItem(
            product: Product(
                id: 'p1', name: 'Wireless Mouse', description: '', price: 599, stock: 10, hsncode: '8471',
                tax_rate: 18, purchasePrice: 0),
            quantity: 2),
      ],
      date: DateTime(2026, 11, 11),
      taxMode: TaxMode.perItem,
      currencyCode: 'INR',
      currencySymbol: 'Rs.',
    );

void main() {
  group('pdfNumberLabel', () {
    test('names the document instead of "#"', () {
      expect(pdfNumberLabel(_doc('Invoice')), 'Invoice No');
      expect(pdfNumberLabel(_doc('Quotation')), 'Quotation No');
      expect(pdfNumberLabel(_doc('Receipt')), 'Receipt No');
      expect(pdfNumberLabel(_doc('Invoice', title: 'Tax Invoice')), 'Invoice No');
      expect(pdfNumberLabel(_doc('Invoice', title: 'Revised Invoice')), 'Invoice No');
      expect(pdfNumberLabel(_doc('Invoice', title: 'Invoice-cum-Bill of Supply')), 'Invoice No');
      expect(pdfNumberLabel(_doc('Invoice', title: 'Bill of Supply')), 'Bill No');
      expect(pdfNumberLabel(_doc('Invoice', title: 'Cash Bill')), 'Bill No');
      expect(pdfNumberLabel(_doc('Invoice', title: 'Credit Note')), 'Credit Note No');
      expect(pdfNumberLabel(_doc('Invoice', title: 'Debit Note')), 'Debit Note No');
      expect(pdfNumberLabel(_doc('Invoice', title: '  ')), 'Invoice No');
    });
  });

  group('A4 templates', () {
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
      tmp = Directory.systemTemp.createTempSync('invoiceo_number_label');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'), (call) async => tmp.path);
      // Serve assets (fonts) straight from the project folder, as in test/shaped_report_pdfs_test.dart.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler('flutter/assets',
          (message) async {
        final key = Uri.decodeFull(
            utf8.decode(message!.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes)));
        final file = File(key);
        if (!file.existsSync()) return null;
        return ByteData.sublistView(file.readAsBytesSync());
      });
      await DatabaseHelper().switchToFile('number_label.db');
      await CompanyInfoService.insertCompanyInfo(CompanyInfo(
          name: 'Sri Murugan Traders', address: '12, Big Bazaar Street, Madurai', phone: '12345 00010',
          email: '', website: '', gstin: '33ABCDE1234F1Z5'));
      if (_out.isNotEmpty) Directory(_out).createSync(recursive: true);
    });

    tearDownAll(() async {
      await DatabaseHelper().close();
      tmp.deleteSync(recursive: true);
    });

    for (final template in [
      InvoiceTemplate.classic,
      InvoiceTemplate.modern,
      InvoiceTemplate.executive,
      InvoiceTemplate.minimal,
    ]) {
      test('${template.name} makes invoice, quotation, receipt and credit note PDFs', () async {
        await SettingsService.setInvoiceTemplate(template);
        await SettingsService.setPageSize(PageSize.a4);
        for (final (name, doc) in [
          ('invoice', _doc('Invoice')),
          ('quotation', _doc('Quotation')),
          ('receipt', _doc('Receipt')),
          ('credit-note', _doc('Invoice', title: 'Credit Note')),
        ]) {
          final bytes = await (await PDFService.generateInvoicePDF(doc)).save();
          expect(bytes.length, greaterThan(1000));
          if (_out.isNotEmpty) File('$_out/${template.name}-$name.pdf').writeAsBytesSync(bytes);
        }
      });
    }
  });
}
