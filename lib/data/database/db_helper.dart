import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    WidgetsFlutterBinding.ensureInitialized();

    final dbPath = kIsWeb
        ? 'financeiro_analytics.db'
        : join(await getDatabasesPath(), 'financeiro_analytics.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> registerUser(Map<String, dynamic> userMap) async {
    final db = await database;

    return await db.insert(
      'users',
      userMap,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<Map<String, dynamic>?> loginUser(
    String email,
    String password,
  ) async {
    final db = await database;

    final res = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [
        email.trim(),
        password.trim(),
      ],
    );

    if (res.isNotEmpty) {
      return res.first;
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> queryTransactionsByUser(
    int userId,
  ) async {
    final db = await database;

    return await db.query(
      'transactions',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await database;

    return await db.insert('transactions', row);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;

    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}