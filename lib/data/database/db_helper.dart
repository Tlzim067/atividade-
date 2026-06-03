import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;
  DBHelper._init();

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  List<Map<String, dynamic>> _parseList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return (json.decode(raw) as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) { return []; }
  }

  int _nextId(List<Map<String, dynamic>> list) {
    if (list.isEmpty) return 1;
    return list.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    WidgetsFlutterBinding.ensureInitialized();
    final dbPath = join(await getDatabasesPath(), 'financeiro_analytics.db');
    return await openDatabase(dbPath, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute("""CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL, email TEXT NOT NULL UNIQUE, password TEXT NOT NULL)""");
    await db.execute("""CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId INTEGER NOT NULL, title TEXT NOT NULL, amount REAL NOT NULL,
      date TEXT NOT NULL, type TEXT NOT NULL, category TEXT NOT NULL,
      FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE)""");
  }

  Future<int> registerUser(Map<String, dynamic> userMap) async {
    if (kIsWeb) {
      final prefs = await _prefs;
      final users = _parseList(prefs.getString('fin_users'));
      if (users.any((u) => u['email'] == userMap['email'])) throw Exception('Email ja cadastrado');
      final newUser = Map<String, dynamic>.from(userMap);
      newUser['id'] = _nextId(users);
      users.add(newUser);
      await prefs.setString('fin_users', json.encode(users));
      return newUser['id'] as int;
    }
    final db = await database;
    return await db!.insert('users', userMap, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final e = email.trim();
    final p = password.trim();
    if (kIsWeb) {
      final prefs = await _prefs;
      final users = _parseList(prefs.getString('fin_users'));
      try {
        return users.firstWhere((u) => u['email'].toString().trim() == e && u['password'].toString().trim() == p);
      } catch (_) { return null; }
    }
    final db = await database;
    final res = await db!.query('users', where: 'email = ? AND password = ?', whereArgs: [e, p]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<List<Map<String, dynamic>>> queryTransactionsByUser(int userId) async {
    if (kIsWeb) {
      final prefs = await _prefs;
      final txs = _parseList(prefs.getString('fin_transactions')).where((t) => t['userId'] == userId).toList();
      txs.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
      return txs;
    }
    final db = await database;
    return await db!.query('transactions', where: 'userId = ?', whereArgs: [userId], orderBy: 'date DESC');
  }

  Future<int> insertTransaction(Map<String, dynamic> row) async {
    if (kIsWeb) {
      final prefs = await _prefs;
      final txs = _parseList(prefs.getString('fin_transactions'));
      final newTx = Map<String, dynamic>.from(row);
      newTx['id'] = _nextId(txs);
      txs.add(newTx);
      await prefs.setString('fin_transactions', json.encode(txs));
      return newTx['id'] as int;
    }
    final db = await database;
    return await db!.insert('transactions', row);
  }

  Future<int> deleteTransaction(int id) async {
    if (kIsWeb) {
      final prefs = await _prefs;
      final txs = _parseList(prefs.getString('fin_transactions'));
      final before = txs.length;
      txs.removeWhere((t) => t['id'] == id);
      await prefs.setString('fin_transactions', json.encode(txs));
      return before - txs.length;
    }
    final db = await database;
    return await db!.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
