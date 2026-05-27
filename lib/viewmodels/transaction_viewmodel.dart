import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transaction_model.dart';
import '../data/database/db_helper.dart';

class TransactionState {
  final List<TransactionModel> transactions;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final bool isLoading;

  TransactionState({
    required this.transactions,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.isLoading,
  });

  factory TransactionState.initial() => TransactionState(
        transactions: [],
        totalIncome: 0.0,
        totalExpense: 0.0,
        balance: 0.0,
        isLoading: false,
      );

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    double? totalIncome,
    double? totalExpense,
    double? balance,
    bool? isLoading,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  final int _userId;

  TransactionNotifier(this._userId) : super(TransactionState.initial()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true);
    final rawData = await DBHelper.instance.queryTransactionsByUser(_userId);
    final list = rawData.map((m) => TransactionModel.fromMap(m)).toList();

    double income = 0;
    double expense = 0;
    for (var tx in list) {
      if (tx.type == 'Entrada') {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    state = state.copyWith(
      transactions: list,
      totalIncome: income,
      totalExpense: expense,
      balance: income - expense,
      isLoading: false,
    );
  }

  Future<void> addTransaction(String title, double amount, String type, String category) async {
    final newTx = TransactionModel(
      userId: _userId,
      title: title,
      amount: amount,
      date: DateTime.now(),
      type: type,
      category: category,
    );

    await DBHelper.instance.insertTransaction(newTx.toMap());
    await loadTransactions();
  }

  Future<void> removeTransaction(int id) async {
    await DBHelper.instance.deleteTransaction(id);
    await loadTransactions();
  }
}

final transactionProvider = StateNotifierProvider.family<TransactionNotifier, TransactionState, int>((ref, userId) {
  return TransactionNotifier(userId);
});

// Provedor para gerenciar o ID do usuário autenticado globalmente
final authUserIdProvider = StateProvider<int>((ref) => 1);