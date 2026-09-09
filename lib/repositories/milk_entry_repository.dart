import 'package:milk_business/database/app_database.dart';
import 'package:milk_business/models/milk_entry.dart';

class MilkEntryRepository {
  Future<int> insert(MilkEntry entry) async {
    final db = await AppDatabase.instance.database;
    return db.insert('milk_entries', entry.toMap());
  }

  Future<List<MilkEntry>> fetchAll() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query('milk_entries', orderBy: 'date ASC');
    return maps.map(MilkEntry.fromMap).toList();
  }

  Future<List<MilkEntry>> fetchEntriesForCustomer(int customerId) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      'milk_entries',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date ASC',
    );

    return maps.map(MilkEntry.fromMap).toList();
  }

  Future<List<MilkEntry>> fetchEntriesForCustomerAndMonth(
    int customerId,
    int year,
    int month,
  ) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      'milk_entries',
      where: 'customer_id = ? AND date >= ? AND date < ?',
      whereArgs: [
        customerId,
        DateTime(year, month, 1).toIso8601String(),
        DateTime(year, month + 1, 1).toIso8601String(),
      ],
      orderBy: 'date ASC',
    );

    return maps.map(MilkEntry.fromMap).toList();
  }

  Future<List<MilkEntry>> fetchEntriesForDate(
    int customerId,
    DateTime date,
  ) async {
    final db = await AppDatabase.instance.database;
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day + 1);

    final maps = await db.query(
      'milk_entries',
      where: 'customer_id = ? AND date >= ? AND date < ?',
      whereArgs: [customerId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date ASC',
    );

    return maps.map(MilkEntry.fromMap).toList();
  }

  Future<int> update(MilkEntry entry) async {
    final db = await AppDatabase.instance.database;
    return db.update(
      'milk_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;
    return db.delete('milk_entries', where: 'id = ?', whereArgs: [id]);
  }
}
