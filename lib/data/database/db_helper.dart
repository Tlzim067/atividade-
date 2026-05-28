import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  // Bancos de dados em memória simulados para quando rodar no Navegador (Web)
  final List<Map<String, dynamic>> _webUsersMock = [];
  final List<Map<String, dynamic>> _webTransactionsMock = [];
  int _nextUserId = 1;
  int _nextTransactionId = 1;

  DBHelper._init();

  // Retorna o banco apenas se NÃO estiver na web
  Future<Database?> get database async {
    if (kIsWeb) return null; // Web não utiliza a instância física do sqflite
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    WidgetsFlutterBinding.ensureInitialized();
    final dbPath = join(await getDatabasesPath(), 'financeiro_analytics.db');

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

  // --- MÉTODOS DE USUÁRIO (LOGIN E CADASTRO) ---

  Future<int> registerUser(Map<String, dynamic> userMap) async {
    if (kIsWeb) {
      // Simulação Web: Verifica se o e-mail já existe
      final emailExists = _webUsersMock.any((u) => u['email'] == userMap['email']);
      if (emailExists) throw Exception('Email já cadastrado');

      final newUser = Map<String, dynamic>.from(userMap);
      newUser['id'] = _nextUserId++;
      _webUsersMock.add(newUser);
      return newUser['id'];
    }

    // Código Mobile nativo
    final db = await database;
    return await db!.insert(
      'users',
      userMap,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    if (kIsWeb) {
      // Simulação Web: Procura na lista local em memória
      try {
        return _webUsersMock.firstWhere(
          (u) => u['email'] == cleanEmail && u['password'] == cleanPassword,
        );
      } catch (_) {
        return null;
      }
    }

    // Código Mobile nativo
    final db = await database;
    final res = await db!.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [cleanEmail, cleanPassword],
    );

    if (res.isNotEmpty) return res.first;
    return null;
  }

  // --- MÉTODOS DE TRANSAÇÕES ---

  Future<List<Map<String, dynamic>>> queryTransactionsByUser(int userId) async {
    if (kIsWeb) {
      // Simulação Web: Filtra e ordena transações em memória
      final filtered = _webTransactionsMock.where((t) => t['userId'] == userId).toList();
      filtered.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
      return filtered;
    }

    // Código Mobile nativo
    final db = await database;
    return await db!.query(
      'transactions',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  Future<int> insertTransaction(Map<String, dynamic> row) async {
    if (kIsWeb) {
      // Simulação Web: Insere na lista em memória
      final newTx = Map<String, dynamic>.from(row);
      newTx['id'] = _nextTransactionId++;
      _webTransactionsMock.add(newTx);
      return newTx['id'];
    }

    // Código Mobile nativo
    final db = await database;
    return await db!.insert('transactions', row);
  }

  Future<int> deleteTransaction(int id) async {
    if (kIsWeb) {
      // Simulação Web: Remove da lista em memória
      final initialLength = _webTransactionsMock.length;
      _webTransactionsMock.removeWhere((t) => t['id'] == id);
      return initialLength - _webTransactionsMock.length;
    }

    // Código Mobile nativo
    final db = await database;
    return await db!.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}