import 'package:milk_business/database/app_database.dart';
import 'package:milk_business/models/customer.dart';
import 'package:sqflite/sqflite.dart';

class CustomerRepository {
  Future<int> insert(Customer customer) async {
    final db = await AppDatabase.instance.database;
    return db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> fetchAll() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query('customers', orderBy: 'name ASC');
    return maps.map(Customer.fromMap).toList();
  }

  Future<Customer?> fetchById(int id) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return Customer.fromMap(maps.first);
  }

  Future<int> update(Customer customer) async {
    final db = await AppDatabase.instance.database;
    return db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;
    return db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }
}
