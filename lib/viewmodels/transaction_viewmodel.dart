import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transaction_model.dart';
import '../data/database/db_helper.dart';

class TransactionState {
  final List<TransactionModel> transactions;
  final double balance;
  final double totalIncome;
  final double totalExpense;
  final bool isLoading;
  final String? errorMessage;

  const TransactionState({
    required this.transactions,
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.isLoading,
    this.errorMessage,
  });

  factory TransactionState.initial() => const TransactionState(
        transactions: [],
        balance: 0.0,
        totalIncome: 0.0,
        totalExpense: 0.0,
        isLoading: true,
      );

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    double? balance,
    double? totalIncome,
    double? totalExpense,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      balance: balance ?? this.balance,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  final int userId;
  final DBHelper _dbHelper = DBHelper.instance;

  TransactionNotifier(this.userId) : super(TransactionState.initial()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final txMaps = await _dbHelper.queryTransactionsByUser(userId);
      final txList = txMaps.map(TransactionModel.fromMap).toList();
      double income = 0.0;
      double expense = 0.0;
      for (final tx in txList) {
        if (tx.category == 'Poupança') {
          if (tx.type == 'Entrada') {
            expense += tx.amount;
          } else {
            income += tx.amount;
          }
        } else {
          if (tx.type == 'Entrada') {
            income += tx.amount;
          } else {
            expense += tx.amount;
          }
        }
      }
      state = TransactionState(
        transactions: txList,
        totalIncome: income,
        totalExpense: expense,
        balance: income - expense,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Erro: \$e');
    }
  }

  Future<void> addTransaction(String title, double amount, String type, String category) async {
    final newTx = TransactionModel(
      userId: userId, title: title, amount: amount, type: type, category: category,
      date: DateTime.now().toIso8601String().split('T')[0],
    );
    await _dbHelper.insertTransaction(newTx.toMap());
    await loadTransactions();
  }

  Future<void> removeTransaction(int id) async {
    await _dbHelper.deleteTransaction(id);
    await loadTransactions();
  }
}

final transactionProvider =
    StateNotifierProvider.family<TransactionNotifier, TransactionState, int>(
  (ref, userId) => TransactionNotifier(userId),
);
