// A product's own low-stock limit (v52): NULL keeps the old default of 10,
// a number moves that one product's Low Stock / In Stock line, the tab
// counts agree with the lists, and the column is added to a v51 database.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiceo/database/database_helper.dart';
import 'package:invoiceo/database/product_service.dart';
import 'package:invoiceo/models/product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  var dbCounter = 0;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tmp = Directory.systemTemp.createTempSync('invoiceo_low_stock_limit');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => tmp.path);
  });
  tearDownAll(() async {
    await DatabaseHelper().close();
    tmp.deleteSync(recursive: true);
  });

  Product p(String id, double stock, {int? limit, bool unlimited = false}) => Product(
      id: id, name: 'Item $id', description: '', price: 10, stock: stock,
      hsncode: '1001', tax_rate: 0, unlimitedStock: unlimited, lowStockLimit: limit);

  Future<List<String>> ids(String tab) async =>
      (await ProductService.getProductListPage(offset: 0, limit: 50, tab: tab))
          .map((e) => e.id)
          .toList()
        ..sort();

  setUp(() async {
    await DatabaseHelper().switchToFile('low_stock_limit_${dbCounter++}.db');
  });

  test('no limit set: low means 10 or less, exactly as before', () async {
    await ProductService.insertProduct(p('a', 10));
    await ProductService.insertProduct(p('b', 11));
    await ProductService.insertProduct(p('c', 0));
    expect(await ids('low'), ['a']);
    expect(await ids('in_stock'), ['b']);
    expect(await ids('out'), ['c']);
    expect(Product.defaultLowStockLimit, 10);
    expect(p('a', 10).effectiveLowStockLimit, 10);
  });

  test('a product limit moves that product only; in_stock + low + out = all', () async {
    await ProductService.insertProduct(p('a', 30, limit: 50)); // low: 30 <= 50
    await ProductService.insertProduct(p('b', 5, limit: 2)); // in stock: 5 > 2
    await ProductService.insertProduct(p('c', 8)); // default 10: low
    await ProductService.insertProduct(p('d', 0, limit: 50)); // out beats low
    await ProductService.insertProduct(p('e', 1, limit: 50, unlimited: true)); // never low
    expect(await ids('low'), ['a', 'c']);
    expect(await ids('in_stock'), ['b', 'e']);
    expect(await ids('out'), ['d']);
    final stats = await ProductService.getProductListStats();
    expect(stats.lowStock, 2);
    expect(stats.outOfStock, 1);
    expect(stats.all, 5);
  });

  test('the limit is saved, read back and cleared again', () async {
    await ProductService.insertProduct(p('a', 5, limit: 25));
    var back = (await ProductService.getProductListPage(offset: 0, limit: 5)).single;
    expect(back.lowStockLimit, 25);
    expect(back.effectiveLowStockLimit, 25);
    await ProductService.updateProduct(p('a', 5));
    back = (await ProductService.getProductListPage(offset: 0, limit: 5)).single;
    expect(back.lowStockLimit, isNull);
    expect(back.effectiveLowStockLimit, 10);
  });

  test('v51 -> v52 adds the column and keeps every row; NULL = default', () async {
    final db = await openDatabase(inMemoryDatabasePath, version: 51,
        onCreate: (db, v) async {
      await db.execute('CREATE TABLE products (id TEXT PRIMARY KEY, name TEXT, '
          'price REAL, stock REAL, unlimited_stock INTEGER DEFAULT 0)');
      await db.insert('products', {'id': 'p1', 'name': 'Rice', 'price': 60.0, 'stock': 7.0});
    });
    await DatabaseHelper().upgradeDbForTest(db, 51, 52);
    final cols = (await db.rawQuery('PRAGMA table_info(products)')).map((c) => c['name']);
    expect(cols, contains('low_stock_limit'));
    final row = (await db.query('products')).single;
    expect(row['name'], 'Rice');
    expect(row['stock'], 7.0);
    expect(row['low_stock_limit'], isNull);
    await db.close();
  });
}
