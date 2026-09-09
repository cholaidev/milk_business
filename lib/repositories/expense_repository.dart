import 'package:milk_business/database/app_database.dart';
import 'package:milk_business/models/expense.dart';
import 'package:sqflite/sqflite.dart';

class ExpenseRepository {
  Future<int> insert(Expense expense) async {
    final db = await AppDatabase.instance.database;
    return db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> fetchAll() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query('expenses', orderBy: 'date DESC');
    return maps.map(Expense.fromMap).toList();
  }

  Future<List<Expense>> fetchForFilter(DateTime start, DateTime end) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      'expenses',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map(Expense.fromMap).toList();
  }

  Future<int> update(Expense expense) async {
    final db = await AppDatabase.instance.database;
    return db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}
