// The low-stock limit (DB v52) for people who already have data: an older
// database is upgraded in place with nothing lost, an older backup (database
// file or JSON) still restores, a new backup keeps the limits, and an older
// app can still open a v52 file (downgrade). Uses the real DatabaseHelper
// and BackupManager.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' show Sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiceo/backup/backup_manager.dart';
import 'package:invoiceo/common/common.dart';
import 'package:invoiceo/database/company_registry_service.dart';
import 'package:invoiceo/database/customer_service.dart';
import 'package:invoiceo/database/database_helper.dart';
import 'package:invoiceo/database/product_service.dart';
import 'package:invoiceo/models/customer.dart';
import 'package:invoiceo/models/product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late String supportDir;
  var counter = 0;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    root = Directory.systemTemp.createTempSync('invoiceo_low_stock_upgrade');
    supportDir = root.path;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => supportDir);
  });
  tearDownAll(() async {
    await DatabaseHelper().close();
    try {
      root.deleteSync(recursive: true);
    } catch (_) {}
  });

  Future<void> freshDb(String name) async {
    SharedPreferences.setMockInitialValues({});
    supportDir = p.join(root.path, '${name}_${counter++}');
    Directory(supportDir).createSync(recursive: true);
    await DatabaseHelper().switchToFile('$name.db');
  }

  Product product(String id, double stock, {int? limit, bool unlimited = false}) => Product(
      id: id, name: 'Item $id', description: 'd$id', price: 25.5, stock: stock,
      hsncode: '1001', tax_rate: 5, unit: 'kg', purchasePrice: 20,
      aliasName: 'அ$id', unlimitedStock: unlimited, lowStockLimit: limit);

  Customer customer(String id) => Customer(
      id: id, name: 'Customer $id', email: '', phone: '', address: '', gstin: '');

  /// What the file looked like before this release: no low_stock_limit
  /// column and user_version 51. Leaves the database closed.
  Future<String> makeItV51() async {
    final path = DatabaseHelper.path!;
    await DatabaseHelper().close();
    final raw = await openDatabase(path);
    await raw.execute('ALTER TABLE products DROP COLUMN low_stock_limit');
    await raw.delete('_migration_log', where: 'version >= 52');
    await raw.execute('PRAGMA user_version = 51');
    await raw.close();
    return path;
  }

  Future<List<String>> productColumns() async => (await (await DatabaseHelper().database)
          .rawQuery('PRAGMA table_info(products)'))
      .map((c) => c['name'] as String)
      .toList();

  Future<int> userVersion() async => Sqflite.firstIntValue(
      await (await DatabaseHelper().database).rawQuery('PRAGMA user_version'))!;

  Future<Map<String, Product>> byId() async => {
        for (final e in await ProductService.getAllProducts()) e.id: e
      };

  test('an existing v51 database upgrades in place: all data kept, default 10 unchanged',
      () async {
    await freshDb('upgrade');
    await ProductService.insertProduct(product('low', 8));
    await ProductService.insertProduct(product('ok', 40));
    await ProductService.insertProduct(product('out', 0));
    await ProductService.insertProduct(product('inf', 0, unlimited: true));
    await CustomerService.insertCustomer(customer('c1'));
    final path = await makeItV51();

    // Opening it the way the app does runs the real upgrade.
    await DatabaseHelper().switchToFile(p.basename(path));
    expect(await userVersion(), 52);
    expect(await productColumns(), contains('low_stock_limit'));

    final all = await byId();
    expect(all.keys.toSet(), {'low', 'ok', 'out', 'inf'});
    expect(all['low']!.stock, 8.0);
    expect(all['low']!.price, 25.5);
    expect(all['low']!.aliasName, 'அlow');
    expect(all['low']!.unit, 'kg');
    expect(all['low']!.purchasePrice, 20.0);
    expect(all['low']!.tax_rate, 5);
    expect(all['inf']!.unlimitedStock, isTrue);
    expect(all.values.every((e) => e.lowStockLimit == null), isTrue);
    expect((await CustomerService.getAllCustomers()).single.id, 'c1');

    // Same Low Stock list as before the upgrade (8 is low, 40 is fine).
    String ids(List<Product> l) => (l.map((e) => e.id).toList()..sort()).join(',');
    expect(ids(await ProductService.getProductListPage(offset: 0, limit: 20, tab: 'low')), 'low');
    expect(ids(await ProductService.getProductListPage(offset: 0, limit: 20, tab: 'out')), 'out');

    // And a limit can be set afterwards.
    await ProductService.updateProduct(product('ok', 40, limit: 50));
    expect(ids(await ProductService.getProductListPage(offset: 0, limit: 20, tab: 'low')), 'low,ok');

    // Opening the upgraded file again changes nothing.
    await DatabaseHelper().switchToFile(p.basename(path));
    expect(await userVersion(), 52);
    expect((await byId())['ok']!.lowStockLimit, 50);
  });

  test('an OLD database backup (v51 file) restores into the new app and is upgraded',
      () async {
    await freshDb('oldbackup');
    await ProductService.insertProduct(product('a', 3));
    await ProductService.insertProduct(product('b', 99));
    final path = await makeItV51();
    final oldBackup = p.join(root.path, 'old_${counter++}.invoicedb');
    File(path).copySync(oldBackup);

    // The app now holds different, newer data.
    await DatabaseHelper().switchToFile(p.basename(path));
    await ProductService.deleteProduct('a');
    await ProductService.insertProduct(product('z', 1, limit: 7));

    final r = await BackupManager().restoreBackup(backupPath: oldBackup);
    expect(r.success, isTrue, reason: r.message);
    expect(await userVersion(), 52);
    expect(await productColumns(), contains('low_stock_limit'));
    final all = await byId();
    expect(all.keys.toSet(), {'a', 'b'});
    expect(all['a']!.stock, 3.0);
    expect(all['a']!.lowStockLimit, isNull);
  });

  test('a new database backup keeps every limit', () async {
    await freshDb('newbackup');
    await ProductService.insertProduct(product('a', 30, limit: 40));
    await ProductService.insertProduct(product('b', 5));
    final made = await BackupManager().createBackup(
        companyId: defaultCompanyId, companyName: 'T', customPath: root.path);
    expect(made.success, isTrue, reason: made.message);
    await ProductService.updateProduct(product('a', 30, limit: 1));
    await ProductService.deleteProduct('b');

    final r = await BackupManager().restoreBackup(backupPath: made.filePath!);
    expect(r.success, isTrue, reason: r.message);
    final all = await byId();
    expect(all['a']!.lowStockLimit, 40);
    expect(all['b']!.lowStockLimit, isNull);
    expect(all['b']!.stock, 5.0);
  });

  test('JSON backups: a new one keeps limits; an old one (no such key) restores to default',
      () async {
    await freshDb('json');
    await ProductService.insertProduct(product('a', 30, limit: 40));
    await ProductService.insertProduct(product('b', 5));
    final made = await BackupManager().createBackup(
        companyId: defaultCompanyId,
        companyName: 'T',
        customPath: root.path,
        type: BackupType.json);
    expect(made.success, isTrue, reason: made.message);
    final json = jsonDecode(File(made.filePath!).readAsStringSync()) as Map<String, dynamic>;
    expect((json['products'] as List).any((r) => (r as Map)['low_stock_limit'] == 40), isTrue);

    await ProductService.deleteProduct('a');
    await ProductService.deleteProduct('b');
    var r = await BackupManager().restoreBackup(backupPath: made.filePath!);
    expect(r.success, isTrue, reason: r.message);
    expect((await byId())['a']!.lowStockLimit, 40);

    // The same file as an older app wrote it: no low_stock_limit key at all.
    for (final row in json['products'] as List) {
      (row as Map<String, dynamic>).remove('low_stock_limit');
    }
    final oldJson = File(p.join(root.path, 'old_${counter++}.json'))
      ..writeAsStringSync(jsonEncode(json));
    r = await BackupManager().restoreBackup(backupPath: oldJson.path);
    expect(r.success, isTrue, reason: r.message);
    final all = await byId();
    expect(all.keys.toSet(), {'a', 'b'});
    expect(all['a']!.lowStockLimit, isNull);
    expect(all['a']!.stock, 30.0);
  });

  test('downgrade: an older app (v51) can still open and use a v52 file', () async {
    await freshDb('downgrade');
    await ProductService.insertProduct(product('a', 30, limit: 40));
    final path = DatabaseHelper.path!;
    await DatabaseHelper().close();

    // The older app asks for version 51 and knows no onDowngrade.
    final old = await openDatabase(path, version: 51);
    final rows = await old.query('products');
    expect(rows.single['name'], 'Item a');
    expect(rows.single['stock'], 30.0);
    // Its own statements (no low_stock_limit anywhere) keep working.
    await old.insert('products', {
      'id': 'n', 'name': 'Made by old app', 'price': 1.0, 'stock': 2.0, 'unit': 'kg',
    });
    await old.update('products', {'price': 9.0}, where: 'id = ?', whereArgs: ['a']);
    await old.close();

    await DatabaseHelper().switchToFile(p.basename(path));
    final all = await byId();
    expect(all['a']!.price, 9.0);
    expect(all['a']!.lowStockLimit, 40, reason: 'the old app left the limit alone');
    expect(all['n']!.lowStockLimit, isNull);
  });
}
